// lib/core/constants/api_endpoints.dart

import '../config/app_config.dart';

class ApiEndpoints {
  // La URL base viene de AppConfig: por defecto el backend en Render (HTTPS).
  // Para desarrollo local, override con --dart-define=API_BASE_URL=...
  static const String baseUrl = AppConfig.apiBaseUrl;

  // Autenticación
  static const String login = '$baseUrl/auth/login';

  // Conductores
  static const String registroConductor = '$baseUrl/conductores/registro';
  static const String perfilConductor   = '$baseUrl/conductores/me';

  // Microbuses
  static const String registroMicrobus  = '$baseUrl/microbuses/registro';
  static const String misMicrobuses     = '$baseUrl/microbuses/mis-microbuses';

  // Recorridos (conductor)
  static const String iniciarRecorrido  = '$baseUrl/recorridos/iniciar';
  static String telemetria(String id)   => '$baseUrl/recorridos/$id/telemetria';
  static String terminarRecorrido(String id) => '$baseUrl/recorridos/$id/terminar';
  static String salirRecorrido(String id)    => '$baseUrl/recorridos/$id/salir';

  // Líneas (usuario)
  static const String lineas            = '$baseUrl/lineas';
  static String lineaDetalle(String id) => '$baseUrl/lineas/$id';
  static const String lineasCercanas    = '$baseUrl/lineas/cercanas';
  static String microbusesActivos(String id) => '$baseUrl/lineas/$id/microbuses-activos';
  static String etaLinea(String id)     => '$baseUrl/lineas/$id/eta';

  // WebSocket (usuario) — host derivado de AppConfig (ws:// o wss://).
  static String wsPosiciones(String id) =>
      '${AppConfig.wsBaseUrl}/ws/lineas/$id/posiciones';
}
