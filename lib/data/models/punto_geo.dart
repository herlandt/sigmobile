// lib/data/models/punto_geo.dart

class PuntoGeo {
  final double longitud;
  final double latitud;

  const PuntoGeo({required this.longitud, required this.latitud});

  factory PuntoGeo.fromJson(Map<String, dynamic> json) => PuntoGeo(
        longitud: (json['longitud'] as num).toDouble(),
        latitud: (json['latitud'] as num).toDouble(),
      );
}
