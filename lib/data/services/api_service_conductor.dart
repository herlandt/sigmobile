// lib/data/services/api_service_conductor.dart
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/conductor.dart';
import '../models/microbus.dart';
import '../models/recorrido.dart';
import 'token_storage.dart';

/// Cliente HTTP del CONDUCTOR. Adjunta automáticamente el JWT (Bearer) guardado
/// en el almacenamiento seguro. Lo reutilizan los servicios de microbús y recorridos.
class ApiServiceConductor {
  late final Dio _dio;
  final TokenStorage _tokens;

  ApiServiceConductor(this._tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      // Timeouts amplios por el cold start del backend en Render (plan free):
      // la primera petición tras inactividad puede tardar ~30-50 s en responder.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.leer();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// Dio autenticado, para que otros servicios del conductor lo reutilicen.
  Dio get dio => _dio;

  // ── Auth ────────────────────────────────────────────────────────────────
  Future<String> login(String email, String password) async {
    try {
      final r = await _dio.post('/auth/login',
          data: {'email': email, 'password': password});
      return (r.data as Map<String, dynamic>)['access_token'] as String;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) throw Exception('Email o contraseña incorrectos');
      if (code == 403) throw Exception('Cuenta desactivada');
      throw Exception('No se pudo iniciar sesión');
    }
  }

  Future<Conductor> getPerfil() async {
    final r = await _dio.get('/conductores/me');
    return Conductor.fromJson(r.data as Map<String, dynamic>);
  }

  // ── Registro de conductor ─────────────────────────────────────────────────
  Future<Conductor> registrarConductor({
    required String documentoIdentidad,
    required String nombre,
    required String fechaNacimiento, // ISO YYYY-MM-DD
    required String sexo,
    required String telefono,
    required String email,
    required String password,
    required String categoriaLicencia,
    required String fotoPath,
  }) async {
    final form = FormData.fromMap({
      'documento_identidad': documentoIdentidad,
      'nombre': nombre,
      'fecha_nacimiento': fechaNacimiento,
      'sexo': sexo,
      'telefono': telefono,
      'email': email,
      'password': password,
      'categoria_licencia': categoriaLicencia,
      'foto': await MultipartFile.fromFile(
        fotoPath,
        filename: _nombreArchivo(fotoPath),
        contentType: _tipoImagen(fotoPath),
      ),
    });
    try {
      final r = await _dio.post('/conductores/registro',
          data: form, options: Options(contentType: 'multipart/form-data'));
      return Conductor.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_mensajeError(e, 'No se pudo registrar el conductor'));
    }
  }

  // ── Microbuses ────────────────────────────────────────────────────────────
  Future<List<Microbus>> getMisMicrobuses() async {
    final r = await _dio.get('/microbuses/mis-microbuses');
    return (r.data as List)
        .map((j) => Microbus.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Microbus> registrarMicrobus({
    required String placa,
    required String modelo,
    required int cantidadAsientos,
    required String lineaId,
    required String numeroInterno,
    required String fechaAsignacion, // ISO YYYY-MM-DD
    required List<String> fotosPaths,
  }) async {
    final form = FormData();
    form.fields.addAll([
      MapEntry('placa', placa),
      MapEntry('modelo', modelo),
      MapEntry('cantidad_asientos', cantidadAsientos.toString()),
      MapEntry('linea_id', lineaId),
      MapEntry('numero_interno', numeroInterno),
      MapEntry('fecha_asignacion', fechaAsignacion),
    ]);
    for (final p in fotosPaths) {
      form.files.add(MapEntry(
        'fotos',
        await MultipartFile.fromFile(p,
            filename: _nombreArchivo(p), contentType: _tipoImagen(p)),
      ));
    }
    try {
      final r = await _dio.post('/microbuses/registro',
          data: form, options: Options(contentType: 'multipart/form-data'));
      return Microbus.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_mensajeError(e, 'No se pudo registrar el microbús'));
    }
  }

  // ── Recorridos ──────────────────────────────────────────────────────────
  Future<RecorridoIniciado> iniciarRecorrido({
    required String microbusId,
    required String sentido,
    required double longitud,
    required double latitud,
  }) async {
    try {
      final r = await _dio.post('/recorridos/iniciar', data: {
        'microbus_id': microbusId,
        'sentido': sentido,
        'longitud': longitud,
        'latitud': latitud,
      });
      return RecorridoIniciado.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_mensajeError(e, 'No se pudo iniciar el recorrido'));
    }
  }

  Future<RecorridoResumen> terminarRecorrido(
    String recorridoId, {
    required double longitud,
    required double latitud,
  }) async {
    try {
      final r = await _dio.post('/recorridos/$recorridoId/terminar',
          data: {'longitud': longitud, 'latitud': latitud});
      return RecorridoResumen.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_mensajeError(e, 'No se pudo terminar el recorrido'));
    }
  }

  Future<RecorridoResumen> salirRecorrido(
    String recorridoId, {
    required double longitud,
    required double latitud,
    required String motivo,
  }) async {
    try {
      final r = await _dio.post('/recorridos/$recorridoId/salir', data: {
        'longitud': longitud,
        'latitud': latitud,
        'motivo_salida': motivo,
      });
      return RecorridoResumen.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_mensajeError(e, 'No se pudo registrar la salida'));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _nombreArchivo(String path) => path.split(RegExp(r'[\\/]')).last;

  DioMediaType _tipoImagen(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return DioMediaType('image', 'png');
    if (p.endsWith('.webp')) return DioMediaType('image', 'webp');
    return DioMediaType('image', 'jpeg'); // jpg/jpeg/desconocido
  }

  String _mensajeError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final d = data['detail'].toString();
      if (d.isNotEmpty) return d;
    }
    final code = e.response?.statusCode;
    if (code == 401) return 'Sesión expirada, iniciá sesión de nuevo';
    if (code == 409) return 'Ya existe un registro con esos datos';
    if (code == 422) return 'Datos o imagen inválidos';
    return fallback;
  }
}
