// lib/core/config/app_config.dart
//
// Configuración por entorno. Por defecto la app apunta al backend en producción
// (Render), así que basta con `flutter run` — no hace falta ningún flag.
//
// Ejemplos:
//   Producción (default, no requiere flags):
//     flutter run
//   Backend local en el emulador Android (10.0.2.2 = localhost del PC):
//     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
//   Backend local en un dispositivo físico en la misma Wi-Fi (IP del PC):
//     flutter run --dart-define=API_BASE_URL=http://192.168.1.11:8000
//
// El WebSocket se deriva automáticamente de API_BASE_URL (http→ws, https→wss),
// salvo que se defina WS_BASE_URL explícitamente.

class AppConfig {
  /// URL base del backend HTTP/HTTPS.
  /// Default: backend desplegado en Render (HTTPS) — la app conecta sin flags.
  /// Para desarrollo contra un backend local, pasar --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://microbuses-sig-backend.onrender.com',
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
