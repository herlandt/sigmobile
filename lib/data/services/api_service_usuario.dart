// lib/data/services/api_service_usuario.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';

class ApiServiceUsuario {
  late final Dio _dio;

  ApiServiceUsuario() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (o) => debugPrint(o.toString()),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, handler) {
        String mensaje;
        switch (error.response?.statusCode) {
          case 404:
            mensaje = 'No encontrado';
          case 401:
            mensaje = 'No autorizado';
          case 422:
            mensaje = 'Datos inválidos';
          case 500:
            mensaje = 'Error del servidor';
          default:
            mensaje = 'Sin conexión al servidor';
        }
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          message: mensaje,
        ));
      },
    ));
  }

  Future<List<dynamic>> getLineas() async {
    final response = await _dio.get('/lineas');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getLineaDetalle(String lineaId) async {
    final response = await _dio.get('/lineas/$lineaId');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getLineasCercanas({
    required double lon,
    required double lat,
    int radioMetros = 500,
  }) async {
    final response = await _dio.get('/lineas/cercanas', queryParameters: {
      'lon': lon,
      'lat': lat,
      'radio': radioMetros,
    });
    return response.data as List<dynamic>;
  }

  /// Paradas cercanas a un punto, con las líneas que pasan y el ETA del próximo micro.
  Future<Map<String, dynamic>?> getParadasCercanas({
    required double lon,
    required double lat,
    int radioMetros = 500,
  }) async {
    try {
      final response = await _dio.get('/lineas/paradas-cercanas', queryParameters: {
        'lon': lon,
        'lat': lat,
        'radio': radioMetros,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getEta({
    required String lineaId,
    required double lon,
    required double lat,
    required String sentido,
  }) async {
    try {
      final response = await _dio.get(
        '/lineas/$lineaId/eta',
        queryParameters: {'lon': lon, 'lat': lat, 'sentido': sentido},
      );
      final lista = response.data as List<dynamic>;
      return lista.isNotEmpty ? lista.first as Map<String, dynamic> : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Rutas óptimas (varias alternativas) entre dos puntos. La 1ra tiene menos
  /// transbordos. Devuelve null si no hay ruta (404).
  Future<List<dynamic>?> getRutasOptimas({
    required double origenLon,
    required double origenLat,
    required double destinoLon,
    required double destinoLat,
  }) async {
    try {
      final response = await _dio.get('/rutas/optima', queryParameters: {
        'origen_lon': origenLon,
        'origen_lat': origenLat,
        'destino_lon': destinoLon,
        'destino_lat': destinoLat,
      });
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
