// lib/shared/widgets/mapa_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaWidget extends StatelessWidget {
  final LatLng centroInicial;
  final double zoomInicial;
  final List<Polyline> polilineas;
  final List<Marker> marcadores;
  final MapController? controlador;

  const MapaWidget({
    super.key,
    this.centroInicial = const LatLng(-17.7834, -63.1822),
    this.zoomInicial = 13.0,
    this.polilineas = const [],
    this.marcadores = const [],
    this.controlador,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        initialCenter: centroInicial,
        initialZoom: zoomInicial,
        minZoom: 10,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.microbuses.sig',
          maxNativeZoom: 19,
        ),
        if (polilineas.isNotEmpty)
          PolylineLayer(polylines: polilineas),
        if (marcadores.isNotEmpty)
          MarkerLayer(markers: marcadores),
      ],
    );
  }
}
