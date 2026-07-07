// lib/shared/widgets/flechas_ruta.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

List<Marker> generarFlechas(List<LatLng> puntos,
    {double intervaloMetros = 300}) {
  if (puntos.length < 2) return [];

  final flechas = <Marker>[];
  double distanciaAcumulada = 0;

  for (int i = 1; i < puntos.length; i++) {
    final p1 = puntos[i - 1];
    final p2 = puntos[i];

    final dist = const Distance().as(LengthUnit.Meter, p1, p2);
    distanciaAcumulada += dist;

    if (distanciaAcumulada >= intervaloMetros) {
      distanciaAcumulada = 0;

      final angulo = _calcularAngulo(p1, p2);
      final mitad = LatLng(
        (p1.latitude + p2.latitude) / 2,
        (p1.longitude + p2.longitude) / 2,
      );

      flechas.add(Marker(
        point: mitad,
        width: 20,
        height: 20,
        child: Transform.rotate(
          angle: angulo * pi / 180,
          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
        ),
      ));
    }
  }
  return flechas;
}

double _calcularAngulo(LatLng p1, LatLng p2) {
  final dy = p2.latitude - p1.latitude;
  final dx = p2.longitude - p1.longitude;
  return atan2(dx, dy) * 180 / pi;
}
