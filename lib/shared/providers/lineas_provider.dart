// lib/shared/providers/lineas_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/linea.dart';
import '../../data/models/posicion_microbus.dart';
import '../../data/services/api_service_usuario.dart';
import '../../data/services/websocket_service.dart';

final apiServiceUsuarioProvider = Provider<ApiServiceUsuario>(
  (ref) => ApiServiceUsuario(),
);

/// Entero inicial del número de línea, para ordenar 1,2,…,10,110 y no 1,10,110,2
/// (el número es texto). Las que no empiezan con dígito quedan al final.
int _ordenLinea(String numero) {
  final m = RegExp(r'^\d+').firstMatch(numero.trim());
  return m != null ? int.parse(m.group(0)!) : 1 << 30;
}

final lineasProvider = FutureProvider<List<LineaResumen>>((ref) async {
  final api = ref.read(apiServiceUsuarioProvider);
  final data = await api.getLineas();
  final lineas = data.map((j) => LineaResumen.fromJson(j)).toList();
  lineas.sort((a, b) {
    final c = _ordenLinea(a.numero).compareTo(_ordenLinea(b.numero));
    return c != 0 ? c : a.numero.compareTo(b.numero);
  });
  return lineas;
});

final lineaDetalleProvider = FutureProvider.family<LineaDetalle, String>(
  (ref, lineaId) async {
    final api = ref.read(apiServiceUsuarioProvider);
    final data = await api.getLineaDetalle(lineaId);
    return LineaDetalle.fromJson(data);
  },
);

final websocketServiceProvider =
    Provider.family.autoDispose<WebSocketService, String>(
  (ref, lineaId) {
    final service = WebSocketService(lineaId: lineaId);
    ref.onDispose(() => service.desconectar());
    return service;
  },
);

final posicionesStreamProvider =
    StreamProvider.family.autoDispose<PosicionMicrobus, String>(
  (ref, lineaId) {
    final service = ref.watch(websocketServiceProvider(lineaId));
    service.conectar();
    return service.posiciones;
  },
);
