// lib/core/config/app_config.dart
//
// Configuración por entorno. Los valores se inyectan en tiempo de compilación
// con --dart-define (no se hardcodea la IP/host en el código).
//
// Ejemplos:
//   Emulador Android (default, no requiere flags):
//     flutter run
//   Dispositivo físico en la LAN:
//     flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
//   Producción (HTTPS/WSS):
//     flutter build apk --dart-define=API_BASE_URL=https://api.midominio.com \
//                       --dart-define=APP_ENV=production
//
// El WebSocket se deriva automáticamente de API_BASE_URL (http→ws, https→wss),
// salvo que se defina WS_BASE_URL explícitamente.

class AppConfig {
  /// URL base del backend HTTP/HTTPS.
  /// Default: IP del PC en la LAN, para probar en un dispositivo físico.
  /// - Dispositivo físico (misma Wi-Fi que el PC): usar la IP del PC (ej. 192.168.0.15).
  /// - Emulador Android: pasar --dart-define=API_BASE_URL=http://10.0.2.2:8000
  /// Si tu IP cambia, actualizá este valor (o pasá --dart-define al ejecutar).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.11:8000',
  );

  /// Override opcional del host del WebSocket. Vacío => se deriva de apiBaseUrl.
  static const String _wsOverride = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: '',
  );

  /// Entorno lógico de la app: "development" | "production".
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// URL base del WebSocket (ws:// o wss://), derivada de apiBaseUrl.
  static String get wsBaseUrl {
    if (_wsOverride.isNotEmpty) return _wsOverride;
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    }
    if (apiBaseUrl.startsWith('http://')) {
      return apiBaseUrl.replaceFirst('http://', 'ws://');
    }
    return apiBaseUrl;
  }

  /// true si la API usa TLS (https/wss).
  static bool get isSecure => apiBaseUrl.startsWith('https://');

  static bool get isProduction => environment == 'production';
}
