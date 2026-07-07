// lib/shared/services/ruta_peatonal_service.dart
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Calcula la geometría peatonal **siguiendo las calles** entre dos puntos,
/// usando el servidor público OSRM de FOSSGIS (perfil a pie). Así la caminata
/// no se dibuja como una recta que atraviesa manzanas.
///
/// Si el servicio falla (sin internet, timeout, etc.) devuelve `null` y el
/// llamador usa la línea recta como respaldo.
class RutaPeatonalService {
  RutaPeatonalService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ));

  final Dio _dio;

  static const _base =
      'https://routing.openstreetmap.de/routed-foot/route/v1/foot';

  Future<List<LatLng>?> calcular(LatLng a, LatLng b) async {
    final coords =
        '${a.longitude},${a.latitude};${b.longitude},${b.latitude}';
    try {
      final r = await _dio.get('$_base/$coords', queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
      });
      final data = r.data as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final coordsList =
          (routes.first['geometry']['coordinates'] as List?) ?? const [];
      if (coordsList.length < 2) return null;
      // GeoJSON viene como [lon, lat]; flutter_map usa LatLng(lat, lon).
      return coordsList
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
