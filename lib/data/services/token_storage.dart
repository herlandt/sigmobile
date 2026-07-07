// lib/data/services/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro del JWT del conductor (Keystore en Android, Keychain en iOS).
class TokenStorage {
  static const _kToken = 'jwt_conductor';
  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> guardar(String token) =>
      _storage.write(key: _kToken, value: token);

  Future<String?> leer() => _storage.read(key: _kToken);

  Future<void> borrar() => _storage.delete(key: _kToken);
}
