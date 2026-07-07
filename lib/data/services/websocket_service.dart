// lib/data/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_endpoints.dart';
import '../models/posicion_microbus.dart';

class WebSocketService {
  final String lineaId;

  WebSocketChannel? _channel;
  StreamController<PosicionMicrobus>? _controller;
  bool _activo = false;
  int _intentosReconexion = 0;
  static const int _maxIntentos = 5;

  WebSocketService({required this.lineaId});

  Stream<PosicionMicrobus> get posiciones {
    _controller ??= StreamController<PosicionMicrobus>.broadcast();
    return _controller!.stream;
  }

  Future<void> conectar() async {
    _activo = true;
    _intentosReconexion = 0;
    await _conectar();
  }

  Future<void> _conectar() async {
    if (!_activo) return;

    try {
      final uri = Uri.parse(ApiEndpoints.wsPosiciones(lineaId));
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (mensaje) {
          _intentosReconexion = 0;
          try {
            final json = jsonDecode(mensaje as String) as Map<String, dynamic>;
            final posicion = PosicionMicrobus.fromJson(json);
            if (_controller != null && !(_controller!.isClosed)) {
              _controller!.add(posicion);
            }
          } catch (e) {
            debugPrint('WebSocket: error parseando mensaje: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _channel?.sink.close();
          _channel = null;
          _reconectar();
        },
        onDone: () {
          debugPrint('WebSocket cerrado');
          _channel = null;
          _reconectar();
        },
      );
    } catch (e) {
      debugPrint('WebSocket: no se pudo conectar: $e');
      _reconectar();
    }
  }

  Future<void> _reconectar() async {
    if (!_activo || _intentosReconexion >= _maxIntentos) return;

    _intentosReconexion++;
    final espera = Duration(seconds: _intentosReconexion * 2);
    debugPrint('WebSocket: reconectando en ${espera.inSeconds}s '
        '(intento $_intentosReconexion/$_maxIntentos)');

    await Future.delayed(espera);
    await _conectar();
  }

  Future<void> desconectar() async {
    _activo = false;
    await _channel?.sink.close();
    await _controller?.close();
    _channel = null;
    _controller = null;
  }
}
