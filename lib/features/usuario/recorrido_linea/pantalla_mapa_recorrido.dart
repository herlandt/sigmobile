// lib/features/usuario/recorrido_linea/pantalla_mapa_recorrido.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/linea.dart';
import '../../../shared/providers/lineas_provider.dart';
import '../../../shared/widgets/mapa_widget.dart';
import '../../../shared/widgets/marcadores_mapa.dart';
import '../../../shared/widgets/flechas_ruta.dart';
import '../../../shared/utils/polilinea_offset.dart';

class PantallaMapaRecorrido extends ConsumerWidget {
  final String lineaId;
  final String sentido;
  final String lineaNombre;

  const PantallaMapaRecorrido({
    super.key,
    required this.lineaId,
    required this.sentido,
    required this.lineaNombre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineaAsync = ref.watch(lineaDetalleProvider(lineaId));

    return Scaffold(
      appBar: AppBar(
        title: Text(lineaNombre),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: lineaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (linea) => _MapaConRuta(linea: linea, sentido: sentido),
      ),
    );
  }
}

class _MapaConRuta extends StatelessWidget {
  final LineaDetalle linea;
  final String sentido;

  const _MapaConRuta({required this.linea, required this.sentido});

  @override
  Widget build(BuildContext context) {
    final polilineas = <Polyline>[];
    final marcadores = <Marker>[];
    // En "ambos" se corre cada sentido un poco a su derecha para que no se
    // superpongan. 4 m por lado (≈8 m de separación) entra en la calzada y no
    // se monta sobre las casas como pasaba con un offset grande.
    final esAmbos = sentido == 'ambos';
    const offsetM = 4.0;

    // Línea circular: un solo recorrido (la "vuelta" es la misma ida).
    // Se dibuja UNA línea sin offset y las flechas marcan el sentido del lazo.
    if (linea.esCircular) {
      if (linea.recorridoIda.isNotEmpty) {
        polilineas.add(Polyline(
          points: linea.recorridoIda,
          color: Colors.blue[700]!,
          strokeWidth: 4,
        ));
        if (linea.puntoPartidaIda != null) {
          marcadores.add(marcadorPartida(LatLng(
            linea.puntoPartidaIda!.latitud,
            linea.puntoPartidaIda!.longitud,
          )));
        }
        marcadores.addAll(generarFlechas(linea.recorridoIda));
      }
      final centro = linea.recorridoIda.isNotEmpty
          ? linea.recorridoIda[linea.recorridoIda.length ~/ 2]
          : const LatLng(-17.7834, -63.1822);
      return Stack(
        children: [
          MapaWidget(
            centroInicial: centro,
            zoomInicial: 13,
            polilineas: polilineas,
            marcadores: marcadores,
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            child: _Leyenda(sentido: 'circular'),
          ),
        ],
      );
    }

    if (sentido == 'ida' || sentido == 'ambos') {
      if (linea.recorridoIda.isNotEmpty) {
        polilineas.add(Polyline(
          points: esAmbos
              ? desplazarSiSolapa(
                  linea.recorridoIda, linea.recorridoVuelta, offsetM)
              : linea.recorridoIda,
          color: Colors.blue[700]!,
          strokeWidth: 4,
        ));
        if (linea.puntoPartidaIda != null) {
          marcadores.add(marcadorPartida(LatLng(
            linea.puntoPartidaIda!.latitud,
            linea.puntoPartidaIda!.longitud,
          )));
        }
        if (linea.puntoLlegadaIda != null) {
          marcadores.add(marcadorLlegada(LatLng(
            linea.puntoLlegadaIda!.latitud,
            linea.puntoLlegadaIda!.longitud,
          )));
        }
        marcadores.addAll(generarFlechas(linea.recorridoIda));
      }
    }

    if (sentido == 'vuelta' || sentido == 'ambos') {
      if (linea.recorridoVuelta.isNotEmpty) {
        polilineas.add(Polyline(
          points: esAmbos
              ? desplazarSiSolapa(
                  linea.recorridoVuelta, linea.recorridoIda, offsetM)
              : linea.recorridoVuelta,
          color: Colors.orange[700]!,
          strokeWidth: 4,
        ));
        if (linea.puntoPartidaVuelta != null) {
          marcadores.add(marcadorPartida(LatLng(
            linea.puntoPartidaVuelta!.latitud,
            linea.puntoPartidaVuelta!.longitud,
          )));
        }
        if (linea.puntoLlegadaVuelta != null) {
          marcadores.add(marcadorLlegada(LatLng(
            linea.puntoLlegadaVuelta!.latitud,
            linea.puntoLlegadaVuelta!.longitud,
          )));
        }
        if (sentido == 'vuelta') {
          marcadores.addAll(generarFlechas(linea.recorridoVuelta));
        }
      }
    }

    final puntosCentro =
        sentido == 'vuelta' ? linea.recorridoVuelta : linea.recorridoIda;
    final centro = puntosCentro.isNotEmpty
        ? puntosCentro[puntosCentro.length ~/ 2]
        : const LatLng(-17.7834, -63.1822);

    return Stack(
      children: [
        MapaWidget(
          centroInicial: centro,
          zoomInicial: 13,
          polilineas: polilineas,
          marcadores: marcadores,
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: _Leyenda(sentido: sentido),
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  final String sentido;
  const _Leyenda({required this.sentido});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sentido == 'circular')
            _ItemLeyenda(
                color: Colors.blue[700]!, texto: 'Recorrido circular'),
          if (sentido == 'ida' || sentido == 'ambos')
            _ItemLeyenda(color: Colors.blue[700]!, texto: 'Ida'),
          if (sentido == 'vuelta' || sentido == 'ambos')
            _ItemLeyenda(color: Colors.orange[700]!, texto: 'Vuelta'),
          if (sentido != 'circular') ...const [
            _ItemLeyenda(color: Colors.green, texto: 'Partida'),
            _ItemLeyenda(color: Colors.red, texto: 'Llegada'),
          ] else
            const _ItemLeyenda(color: Colors.green, texto: 'Partida'),
        ],
      ),
    );
  }
}

class _ItemLeyenda extends StatelessWidget {
  final Color color;
  final String texto;
  const _ItemLeyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 4, color: color),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
