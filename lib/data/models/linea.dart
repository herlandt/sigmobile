// lib/data/models/linea.dart
import 'package:latlong2/latlong.dart';
import 'punto_geo.dart';

/// Modelo liviano para la lista de líneas (sin geometría)
class LineaResumen {
  final String id;
  final String numero;
  final String nombre;
  final String? descripcion;
  final bool activa;

  const LineaResumen({
    required this.id,
    required this.numero,
    required this.nombre,
    this.descripcion,
    required this.activa,
  });

  factory LineaResumen.fromJson(Map<String, dynamic> json) => LineaResumen(
        id: json['id'] as String,
        numero: json['numero'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        activa: json['activa'] as bool,
      );
}

/// Modelo completo con recorridos GeoJSON para el mapa
class LineaDetalle {
  final String id;
  final String numero;
  final String nombre;
  final String? descripcion;
  final bool activa;

  // Coordenadas de la ruta parseadas a List<LatLng> para flutter_map
  final List<LatLng> recorridoIda;
  final List<LatLng> recorridoVuelta;

  // Puntos extremos para los marcadores verde/rojo
  final PuntoGeo? puntoPartidaIda;
  final PuntoGeo? puntoLlegadaIda;
  final PuntoGeo? puntoPartidaVuelta;
  final PuntoGeo? puntoLlegadaVuelta;

  const LineaDetalle({
    required this.id,
    required this.numero,
    required this.nombre,
    this.descripcion,
    required this.activa,
    required this.recorridoIda,
    required this.recorridoVuelta,
    this.puntoPartidaIda,
    this.puntoLlegadaIda,
    this.puntoPartidaVuelta,
    this.puntoLlegadaVuelta,
  });

  factory LineaDetalle.fromJson(Map<String, dynamic> json) {
    return LineaDetalle(
      id: json['id'] as String,
      numero: json['numero'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activa: json['activa'] as bool,
      recorridoIda: _parseGeoJson(json['recorrido_ida']),
      recorridoVuelta: _parseGeoJson(json['recorrido_vuelta']),
      puntoPartidaIda: json['punto_partida_ida'] != null
          ? PuntoGeo.fromJson(json['punto_partida_ida'])
          : null,
      puntoLlegadaIda: json['punto_llegada_ida'] != null
          ? PuntoGeo.fromJson(json['punto_llegada_ida'])
          : null,
      puntoPartidaVuelta: json['punto_partida_vuelta'] != null
          ? PuntoGeo.fromJson(json['punto_partida_vuelta'])
          : null,
      puntoLlegadaVuelta: json['punto_llegada_vuelta'] != null
          ? PuntoGeo.fromJson(json['punto_llegada_vuelta'])
          : null,
    );
  }

  /// GeoJSON [longitud, latitud] → LatLng(latitud, longitud) para flutter_map
  static List<LatLng> _parseGeoJson(dynamic geojson) {
    if (geojson == null) return [];
    final coords = geojson['coordinates'] as List<dynamic>?;
    if (coords == null) return [];
    return coords
        .map((c) {
          try {
            return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
          } catch (_) {
            return null;
          }
        })
        .whereType<LatLng>()
        .toList();
  }

  List<LatLng> recorridoPorSentido(String sentido) =>
      sentido == 'ida' ? recorridoIda : recorridoVuelta;

  PuntoGeo? partidaPorSentido(String sentido) =>
      sentido == 'ida' ? puntoPartidaIda : puntoPartidaVuelta;

  PuntoGeo? llegadaPorSentido(String sentido) =>
      sentido == 'ida' ? puntoLlegadaIda : puntoLlegadaVuelta;
}
