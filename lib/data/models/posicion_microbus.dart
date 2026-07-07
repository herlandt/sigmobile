// lib/data/models/posicion_microbus.dart
import 'package:latlong2/latlong.dart';

class PosicionMicrobus {
  final String microbusId;
  final String placa;
  final String numeroInterno;
  final double longitud;
  final double latitud;
  final double velocidad;
  final String sentido;

  const PosicionMicrobus({
    required this.microbusId,
    required this.placa,
    required this.numeroInterno,
    required this.longitud,
    required this.latitud,
    required this.velocidad,
    required this.sentido,
  });

  factory PosicionMicrobus.fromJson(Map<String, dynamic> json) =>
      PosicionMicrobus(
        microbusId:    json['microbus_id'] as String,
        placa:         json['placa'] as String,
        numeroInterno: json['numero_interno'] as String,
        longitud:      (json['longitud'] as num).toDouble(),
        latitud:       (json['latitud'] as num).toDouble(),
        velocidad:     (json['velocidad'] as num).toDouble(),
        sentido:       json['sentido'] as String,
      );

  LatLng get coordenadas => LatLng(latitud, longitud);
}
