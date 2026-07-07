// lib/data/services/recorrido_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste el id del recorrido activo, para que el servicio en background y la
/// pantalla puedan retomarlo (incluso tras reabrir la app).
class RecorridoStorage {
  static const _kId = 'recorrido_activo_id';
  final FlutterSecureStorage _storage;

  RecorridoStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> guardarActivo(String recorridoId) =>
      _storage.write(key: _kId, value: recorridoId);

  Future<String?> leerActivo() => _storage.read(key: _kId);

  Future<void> borrarActivo() => _storage.delete(key: _kId);
}
