// lib/shared/providers/lineas_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/linea.dart';
import '../../data/models/posicion_microbus.dart';
import '../../data/services/api_service_usuario.dart';
import '../../data/services/websocket_service.dart';

final apiServiceUsuarioProvider = Provider<ApiServiceUsuario>(
  (ref) => ApiServiceUsuario(),
);

final lineasProvider = FutureProvider<List<LineaResumen>>((ref) async {
  final api = ref.read(apiServiceUsuarioProvider);
  final data = await api.getLineas();
  return data.map((j) => LineaResumen.fromJson(j)).toList();
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
