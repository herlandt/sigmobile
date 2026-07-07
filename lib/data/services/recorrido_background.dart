// lib/data/services/recorrido_background.dart
//
// Telemetría en segundo plano mediante un FOREGROUND SERVICE (flutter_background_service):
// mientras hay un recorrido activo, un isolate escucha el GPS en modo navegación
// (stream con distanceFilter) y envía la posición a POST /recorridos/{id}/telemetria,
// aunque la app esté en background o la pantalla apagada.
//
// Precisión:
//  - getPositionStream(bestForNavigation, distanceFilter 10 m) en vez de despertar
//    el GPS en frío cada 30 s: fixes más precisos y recorrido más fino.
//  - Se descartan fixes con accuracy > _precisionMaxM (ruido urbano de ±50-100 m)
//    y saltos que impliquen una velocidad imposible (> _saltoMaxMs). Tras varios
//    rechazos seguidos se acepta el fix igual, para recuperarse si el micro
//    realmente se movió o el GPS del equipo es pobre.
//  - La distancia recorrida se acumula SOLO con fixes aceptados, así el ruido
//    no infla los kilómetros.
//  - Cada envío incluye precision_m (accuracy del fix) para poder filtrar en la BD.
import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config/app_config.dart';
import 'recorrido_storage.dart';
import 'token_storage.dart';

const String canalNotificacion = 'recorrido_telemetria';
const int _notifId = 888;
const Duration _intervaloEnvio = Duration(seconds: 10);
const int _distanceFilterM = 10; // el stream emite recién al moverse esto
const double _precisionMaxM = 35; // fixes menos precisos se descartan
const double _saltoMaxMs = 22.2; // ~80 km/h: más rápido que eso es ruido
const int _rechazosMax = 5; // tras N rechazos seguidos se acepta igual

/// Configura el servicio (llamar una vez en main, antes de runApp).
Future<void> configurarServicioRecorrido() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartRecorrido,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: canalNotificacion,
      initialNotificationTitle: 'Recorrido en curso',
      initialNotificationContent: 'Preparando envío de ubicación...',
      foregroundServiceNotificationId: _notifId,
      foregroundServiceTypes: const [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStartRecorrido,
      onBackground: _onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async => true;

/// Punto de entrada del isolate de background.
@pragma('vm:entry-point')
void onStartRecorrido(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final token = await TokenStorage().leer();
  final recorridoId = await RecorridoStorage().leerActivo();
  if (token == null || token.isEmpty || recorridoId == null) {
    await service.stopSelf();
    return;
  }

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  ));

  Position? ultima; // último fix ACEPTADO
  var enviada = false; // ¿ultima ya fue enviada al backend?
  var rechazosSeguidos = 0;
  double distanciaM = 0;
  final inicio = DateTime.now();
  Timer? timer;
  StreamSubscription<Position>? gpsSub;

  service.on('detener').listen((_) async {
    timer?.cancel();
    await gpsSub?.cancel();
    await service.stopSelf();
  });

  /// Filtro de calidad del fix. Devuelve true si hay que descartarlo.
  bool esRuido(Position pos) {
    if (rechazosSeguidos >= _rechazosMax) return false; // recuperación
    if (pos.accuracy > 0 && pos.accuracy > _precisionMaxM) return true;
    if (ultima != null) {
      final dt = pos.timestamp.difference(ultima!.timestamp).inMilliseconds / 1000.0;
      if (dt > 0) {
        final d = Geolocator.distanceBetween(
            ultima!.latitude, ultima!.longitude, pos.latitude, pos.longitude);
        if (d / dt > _saltoMaxMs) return true; // salto imposible
      }
    }
    return false;
  }

  void alRecibirFix(Position pos) {
    if (esRuido(pos)) {
      rechazosSeguidos++;
      return;
    }
    rechazosSeguidos = 0;
    if (ultima != null) {
      distanciaM += Geolocator.distanceBetween(
          ultima!.latitude, ultima!.longitude, pos.latitude, pos.longitude);
    }
    ultima = pos;
    enviada = false;
  }

  Future<void> enviar() async {
    final pos = ultima;
    if (pos == null) return; // todavía sin fix aceptado
    // Si no hubo fix nuevo (micro detenido), se reenvía la última posición como
    // latido para que el backend siga viendo al micro activo.
    try {
      final ahora = DateTime.now();
      final transcurrido = ahora.difference(inicio).inSeconds;
      final velocidadKmh =
          (!enviada && pos.speed.isFinite && pos.speed > 0) ? pos.speed * 3.6 : 0.0;

      await dio.post('/recorridos/$recorridoId/telemetria', data: {
        'longitud': pos.longitude,
        'latitud': pos.latitude,
        'fecha': _fecha(ahora),
        'hora': _hora(ahora),
        'velocidad': double.parse(velocidadKmh.toStringAsFixed(2)),
        'distancia_recorrida': double.parse((distanciaM / 1000).toStringAsFixed(3)),
        'tiempo_transcurrido': transcurrido,
        'precision_m': pos.accuracy.isFinite
            ? double.parse(pos.accuracy.toStringAsFixed(1))
            : null,
      });
      enviada = true;

      service.invoke('update', {
        'lat': pos.latitude,
        'lon': pos.longitude,
        'velocidad': velocidadKmh,
        'distancia_km': distanciaM / 1000,
        'tiempo_seg': transcurrido,
      });

      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: 'Recorrido en curso',
          content:
              '${(distanciaM / 1000).toStringAsFixed(1)} km · ${(transcurrido / 60).round()} min',
        );
      }
    } catch (_) {
      // Errores puntuales de red: se reintenta en el próximo tick.
    }
  }

  // Primer fix rápido para no esperar a moverse 10 m.
  try {
    alRecibirFix(await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ));
    await enviar();
  } catch (_) {}

  gpsSub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: _distanceFilterM,
    ),
  ).listen(alRecibirFix, onError: (_) {
    // GPS momentáneamente no disponible: el timer sigue reenviando la última.
  });

  timer = Timer.periodic(_intervaloEnvio, (_) => enviar());
}

String _fecha(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

/// Fachada para que la UI controle el servicio.
class RecorridoBackground {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> iniciar() => _service.startService();

  void detener() => _service.invoke('detener');

  Future<bool> estaCorriendo() => _service.isRunning();

  /// Actualizaciones en vivo emitidas por el isolate.
  Stream<Map<String, dynamic>?> get updates => _service.on('update');
}
