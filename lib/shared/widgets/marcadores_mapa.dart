// lib/shared/widgets/marcadores_mapa.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Marker marcadorPartida(LatLng punto) => Marker(
      point: punto,
      width: 36,
      height: 36,
      child: const Icon(Icons.location_on, color: Colors.green, size: 36),
    );

Marker marcadorLlegada(LatLng punto) => Marker(
      point: punto,
      width: 36,
      height: 36,
      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
    );

Marker marcadorUsuario(LatLng punto) => Marker(
      point: punto,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );

Marker marcadorMicrobus(LatLng punto, String etiqueta) => Marker(
      point: punto,
      width: 48,
      height: 56,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber[700],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(etiqueta,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const Icon(Icons.directions_bus, color: Colors.amber, size: 28),
        ],
      ),
    );
