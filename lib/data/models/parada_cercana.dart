// lib/data/models/parada_cercana.dart
import 'package:latlong2/latlong.dart';

class LineaEnParada {
  final String numero;
  final String sentido; // 'ida' | 'vuelta'
  final int etaMin;

  const LineaEnParada({
    required this.numero,
    required this.sentido,
    required this.etaMin,
  });

  factory LineaEnParada.fromJson(Map<String, dynamic> j) => LineaEnParada(
        numero: j['numero'] as String,
        sentido: j['sentido'] as String,
        etaMin: (j['eta_min'] as num).toInt(),
      );
}

class ParadaCercana {
  final double longitud;
  final double latitud;
  final double distanciaM;
  final List<LineaEnParada> lineas;

  const ParadaCercana({
    required this.longitud,
    required this.latitud,
    required this.distanciaM,
    required this.lineas,
  });

  factory ParadaCercana.fromJson(Map<String, dynamic> j) => ParadaCercana(
        longitud: (j['longitud'] as num).toDouble(),
        latitud: (j['latitud'] as num).toDouble(),
        distanciaM: (j['distancia_m'] as num).toDouble(),
        lineas: (j['lineas'] as List)
            .map((l) => LineaEnParada.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  LatLng get coordenadas => LatLng(latitud, longitud);
}

class ParadasCercanas {
  final bool enServicio;
  final double frecuenciaMin;
  final List<ParadaCercana> paradas;

  const ParadasCercanas({
    required this.enServicio,
    required this.frecuenciaMin,
    required this.paradas,
  });

  factory ParadasCercanas.fromJson(Map<String, dynamic> j) => ParadasCercanas(
        enServicio: j['en_servicio'] as bool? ?? true,
        frecuenciaMin: (j['frecuencia_min'] as num?)?.toDouble() ?? 15.0,
        paradas: (j['paradas'] as List)
            .map((p) => ParadaCercana.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

/// Línea que pasa cerca de un punto (de GET /lineas/cercanas).
class LineaCercana {
  final String lineaId;
  final String numero;
  final String nombre;
  final double distanciaMinimaM;
  final bool pasaIda;
  final bool pasaVuelta;

  const LineaCercana({
    required this.lineaId,
    required this.numero,
    required this.nombre,
    required this.distanciaMinimaM,
    required this.pasaIda,
    required this.pasaVuelta,
  });

  factory LineaCercana.fromJson(Map<String, dynamic> j) => LineaCercana(
        lineaId: j['linea_id'] as String,
        numero: j['numero'] as String,
        nombre: j['nombre'] as String,
        distanciaMinimaM: (j['distancia_minima_m'] as num).toDouble(),
        pasaIda: j['pasa_ida'] as bool? ?? false,
        pasaVuelta: j['pasa_vuelta'] as bool? ?? false,
      );
}
