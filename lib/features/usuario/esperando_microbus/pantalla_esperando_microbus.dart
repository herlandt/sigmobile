// lib/features/usuario/esperando_microbus/pantalla_esperando_microbus.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/linea.dart';
import '../../../data/models/posicion_microbus.dart';
import '../../../shared/providers/lineas_provider.dart';
import '../../../shared/widgets/mapa_widget.dart';
import '../../../shared/widgets/marcadores_mapa.dart';

class PantallaEsperandoMicrobus extends ConsumerStatefulWidget {
  final LineaResumen linea;
  const PantallaEsperandoMicrobus({super.key, required this.linea});

  @override
  ConsumerState<PantallaEsperandoMicrobus> createState() =>
      _PantallaEsperandoMicrobusState();
}

class _PantallaEsperandoMicrobusState
    extends ConsumerState<PantallaEsperandoMicrobus> {
  String _sentido = 'ida';
  LatLng? _posicionUsuario;
  final Map<String, PosicionMicrobus> _microbuses = {};
  double? _etaMinutos;
  bool _cargandoEta = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionUsuario();
  }

  Future<void> _obtenerUbicacionUsuario() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _posicionUsuario = LatLng(pos.latitude, pos.longitude);
      });
      await _actualizarEta();
    } catch (_) {
      setState(() {
        _posicionUsuario = const LatLng(-17.7834, -63.1822);
      });
    }
  }

  Future<void> _actualizarEta() async {
    if (_posicionUsuario == null) return;
    setState(() => _cargandoEta = true);
    try {
      final api = ref.read(apiServiceUsuarioProvider);
      final eta = await api.getEta(
        lineaId: widget.linea.id,
        lon: _posicionUsuario!.longitude,
        lat: _posicionUsuario!.latitude,
        sentido: _sentido,
      );
      setState(() {
        _etaMinutos = eta != null
            ? (eta['eta_minutos'] as num).toDouble()
            : null;
      });
    } catch (_) {
      setState(() => _etaMinutos = null);
    } finally {
      setState(() => _cargandoEta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      posicionesStreamProvider(widget.linea.id),
      (_, next) {
        next.whenData((posicion) {
          if (posicion.sentido == _sentido) {
            setState(() {
              _microbuses[posicion.microbusId] = posicion;
            });
            _actualizarEta();
          }
        });
      },
    );

    ref.watch(posicionesStreamProvider(widget.linea.id));

    final lineaAsync = ref.watch(lineaDetalleProvider(widget.linea.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Esperando Línea ${widget.linea.numero}'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _SelectorSentido(
            sentido: _sentido,
            onChange: (s) {
              setState(() {
                _sentido = s;
                _microbuses.clear();
                _etaMinutos = null;
              });
              _actualizarEta();
            },
          ),
        ),
      ),
      body: Column(
        children: [
          _PanelEta(etaMinutos: _etaMinutos, cargando: _cargandoEta),
          Expanded(
            child: lineaAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (linea) => _construirMapa(linea),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirMapa(LineaDetalle linea) {
    final puntos =
        _sentido == 'ida' ? linea.recorridoIda : linea.recorridoVuelta;
    final marcadores = <Marker>[];

    for (final mb in _microbuses.values) {
      marcadores.add(marcadorMicrobus(mb.coordenadas, mb.numeroInterno));
    }

    if (_posicionUsuario != null) {
      marcadores.add(marcadorUsuario(_posicionUsuario!));
    }

    final partida = _sentido == 'ida'
        ? linea.puntoPartidaIda
        : linea.puntoPartidaVuelta;
    final llegada = _sentido == 'ida'
        ? linea.puntoLlegadaIda
        : linea.puntoLlegadaVuelta;

    if (partida != null) {
      marcadores.add(
          marcadorPartida(LatLng(partida.latitud, partida.longitud)));
    }
    if (llegada != null) {
      marcadores.add(
          marcadorLlegada(LatLng(llegada.latitud, llegada.longitud)));
    }

    return MapaWidget(
      centroInicial: _posicionUsuario ?? const LatLng(-17.7834, -63.1822),
      zoomInicial: 14,
      controlador: _mapController,
      polilineas: puntos.isNotEmpty
          ? [
              Polyline(
                  points: puntos,
                  color: Colors.green[700]!,
                  strokeWidth: 4)
            ]
          : [],
      marcadores: marcadores,
    );
  }
}

class _SelectorSentido extends StatelessWidget {
  final String sentido;
  final ValueChanged<String> onChange;
  const _SelectorSentido({required this.sentido, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(
            label: 'Ida',
            activo: sentido == 'ida',
            onTap: () => onChange('ida')),
        const SizedBox(width: 12),
        _Chip(
            label: 'Vuelta',
            activo: sentido == 'vuelta',
            onTap: () => onChange('vuelta')),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.green[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: activo ? Colors.green[800] : Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PanelEta extends StatelessWidget {
  final double? etaMinutos;
  final bool cargando;
  const _PanelEta({this.etaMinutos, required this.cargando});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.green[50],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: cargando
          ? const Center(
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : etaMinutos != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Próximo microbús en ${etaMinutos!.toStringAsFixed(1)} min',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : const Text(
                  'No hay microbuses activos en este momento',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
    );
  }
}
