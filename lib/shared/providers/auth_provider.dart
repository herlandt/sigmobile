// lib/shared/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/conductor.dart';
import '../../data/services/api_service_conductor.dart';
import '../../data/services/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiServiceConductorProvider = Provider<ApiServiceConductor>(
  (ref) => ApiServiceConductor(ref.read(tokenStorageProvider)),
);

enum AuthEstado { desconocido, autenticado, noAutenticado }

class AuthState {
  final AuthEstado estado;
  final Conductor? conductor;
  final bool cargando;
  final String? error;

  const AuthState({
    this.estado = AuthEstado.desconocido,
    this.conductor,
    this.cargando = false,
    this.error,
  });

  AuthState copyWith({
    AuthEstado? estado,
    Conductor? conductor,
    bool? cargando,
    String? error,
  }) =>
      AuthState(
        estado: estado ?? this.estado,
        conductor: conductor ?? this.conductor,
        cargando: cargando ?? this.cargando,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiServiceConductor _api;
  final TokenStorage _tokens;

  AuthNotifier(this._api, this._tokens) : super(const AuthState()) {
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    final token = await _tokens.leer();
    if (token == null || token.isEmpty) {
      state = const AuthState(estado: AuthEstado.noAutenticado);
      return;
    }
    try {
      final conductor = await _api.getPerfil();
      state = AuthState(estado: AuthEstado.autenticado, conductor: conductor);
    } catch (_) {
      await _tokens.borrar();
      state = const AuthState(estado: AuthEstado.noAutenticado);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final token = await _api.login(email.trim(), password);
      await _tokens.guardar(token);
      final conductor = await _api.getPerfil();
      state = AuthState(estado: AuthEstado.autenticado, conductor: conductor);
      return true;
    } catch (e) {
      state = AuthState(
        estado: AuthEstado.noAutenticado,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _tokens.borrar();
    state = const AuthState(estado: AuthEstado.noAutenticado);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(apiServiceConductorProvider),
    ref.read(tokenStorageProvider),
  ),
);
