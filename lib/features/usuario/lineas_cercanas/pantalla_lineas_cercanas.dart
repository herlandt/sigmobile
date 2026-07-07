// lib/features/usuario/lineas_cercanas/pantalla_lineas_cercanas.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/linea.dart';
import '../../../data/models/parada_cercana.dart';
import '../../../shared/providers/lineas_provider.dart';
import '../../../shared/widgets/marcadores_mapa.dart';

const _radiosDisponibles = [300, 500, 800];

class PantallaLineasCercanas extends ConsumerStatefulWidget {
  const PantallaLineasCercanas({super.key});

  @override
  ConsumerState<PantallaLineasCercanas> createState() =>
      _PantallaLineasCercanasState();
}

class _PantallaLineasCercanasState
    extends ConsumerState<PantallaLineasCercanas> {
  final MapController _mapa = MapController();
  LatLng? _punto;
  int _radio = 500;
  ParadasCercanas? _paradas;
  List<LineaCercana> _lineas = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ubicarme();
  }

  Future<void> _ubicarme() async {
    LatLng destino = const LatLng(-17.7834, -63.1822); // SCZ por defecto
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
        if (p != LocationPermission.denied && p != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          destino = LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _punto = destino);
    _mapa.move(destino, 15);
    _buscar();
  }

  void _onTap(LatLng p) {
    setState(() => _punto = p);
    _buscar();
  }

  Future<void> _buscar() async {
    final punto = _punto;
    if (punto == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceUsuarioProvider);
      final pr = await api.getParadasCercanas(
          lon: punto.longitude, lat: punto.latitude, radioMetros: _radio);
      final lr = await api.getLineasCercanas(
          lon: punto.longitude, lat: punto.latitude, radioMetros: _radio);
      if (!mounted) return;
      setState(() {
        _paradas = pr != null ? ParadasCercanas.fromJson(pr) : null;
        _lineas =
            lr.map((j) => LineaCercana.fromJson(j as Map<String, dynamic>)).toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar (¿backend encendido?)';
      });
    }
  }

  void _verParada(ParadaCercana p) {
    final enServicio = _paradas?.enServicio ?? true;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.directions_bus, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Líneas en esta parada (${p.lineas.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              if (!enServicio)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Fuera de horario de servicio (05:30–24:00); el tiempo es estimado.',
                    style: TextStyle(fontSize: 12, color: Colors.deepOrange[700]),
                  ),
                ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: p.lineas.length,
                  itemBuilder: (_, i) {
                    final l = p.lineas[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue[800],
                        child: Text(l.numero,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      title: Text('Línea ${l.numero} (${l.sentido})'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('~${l.etaMin} min',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirRecorrido(LineaCercana lc) {
    context.push('/usuario/recorrido/${lc.lineaId}',
        extra: LineaResumen(
            id: lc.lineaId, numero: lc.numero, nombre: lc.nombre, activa: true));
  }

  List<Marker> _marcadores() {
    final out = <Marker>[];
    if (_punto != null) out.add(marcadorUsuario(_punto!));
    for (final p in _paradas?.paradas ?? <ParadaCercana>[]) {
      out.add(Marker(
        point: p.coordenadas,
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () => _verParada(p),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue[800]!, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
            ),
            child: Icon(Icons.directions_bus, size: 16, color: Colors.blue[800]),
          ),
        ),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas cercanas'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        onPressed: _ubicarme,
        child: const Icon(Icons.my_location),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue[50],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.touch_app, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                const Expanded(
                    child: Text('Tocá el mapa o usá tu ubicación. Tocá una parada para ver líneas y ETA.',
                        style: TextStyle(fontSize: 12))),
                ..._radiosDisponibles.map((r) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text('${r}m', style: const TextStyle(fontSize: 11)),
                        selected: _radio == r,
                        onSelected: (_) {
                          setState(() => _radio = r);
                          _buscar();
                        },
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: _punto ?? const LatLng(-17.7834, -63.1822),
                initialZoom: 15,
                minZoom: 10,
                maxZoom: 19,
                onTap: (_, p) => _onTap(p),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.microbuses.sig',
                  maxNativeZoom: 19,
                ),
                if (_punto != null)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _punto!,
                      radius: _radio.toDouble(),
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 1,
                    ),
                  ]),
                MarkerLayer(markers: _marcadores()),
              ],
            ),
          ),
          _PanelLineas(
            cargando: _cargando,
            error: _error,
            lineas: _lineas,
            cantParadas: _paradas?.paradas.length ?? 0,
            onLinea: _abrirRecorrido,
          ),
        ],
      ),
    );
  }
}

class _PanelLineas extends StatelessWidget {
  final bool cargando;
  final String? error;
  final List<LineaCercana> lineas;
  final int cantParadas;
  final ValueChanged<LineaCercana> onLinea;

  const _PanelLineas({
    required this.cargando,
    required this.error,
    required this.lineas,
    required this.cantParadas,
    required this.onLinea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            if (cargando)
              const SizedBox(
                  width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            if (cargando) const SizedBox(width: 8),
            Text(
              error ??
                  (cargando
                      ? 'Buscando...'
                      : '${lineas.length} líneas · $cantParadas paradas en el radio'),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: error != null ? Colors.red : Colors.black87),
            ),
          ]),
          if (error == null && lineas.isNotEmpty) ...[
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lineas.length,
                itemBuilder: (_, i) {
                  final l = lineas[i];
                  final sent = [
                    if (l.pasaIda) 'ida',
                    if (l.pasaVuelta) 'vuelta',
                  ].join(' / ');
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blue[700],
                      child: Text(l.numero,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                    title: Text(l.nombre),
                    subtitle: Text('${l.distanciaMinimaM.round()} m · $sent'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onLinea(l),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
