// lib/features/usuario/ruta_optima/pantalla_ruta_optima.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/ruta_optima.dart';
import '../../../shared/providers/lineas_provider.dart';
import '../../../shared/services/ruta_peatonal_service.dart';
import '../../../shared/widgets/marcadores_mapa.dart';

const _coloresTramo = <Color>[
  Colors.blue,
  Colors.deepOrange,
  Colors.purple,
  Colors.teal,
  Colors.brown,
  Colors.pink,
  Colors.indigo,
];

/// Color por tramo: las caminatas en gris; cada línea de micro un color distinto.
List<Color> coloresPorTramo(RutaOptima ruta) {
  final out = <Color>[];
  var li = 0;
  for (final t in ruta.tramos) {
    if (t.esCaminata) {
      out.add(Colors.grey);
    } else {
      out.add(_coloresTramo[li % _coloresTramo.length]);
      li++;
    }
  }
  return out;
}

class PantallaRutaOptima extends ConsumerStatefulWidget {
  const PantallaRutaOptima({super.key});

  @override
  ConsumerState<PantallaRutaOptima> createState() => _PantallaRutaOptimaState();
}

class _PantallaRutaOptimaState extends ConsumerState<PantallaRutaOptima> {
  LatLng? _origen;
  LatLng? _destino;
  List<RutaOptima> _rutas = [];
  int _seleccion = 0;
  bool _cargando = false;
  String? _error;

  final RutaPeatonalService _peatonal = RutaPeatonalService();
  // Geometría peatonal (siguiendo calles) por tramo de caminata, cacheada.
  final Map<String, List<LatLng>> _walkCache = {};

  RutaOptima? get _rutaSel =>
      _rutas.isEmpty ? null : _rutas[_seleccion.clamp(0, _rutas.length - 1)];

  String _walkKey(LatLng a, LatLng b) =>
      '${a.latitude},${a.longitude};${b.latitude},${b.longitude}';

  /// Para la ruta seleccionada, pide la geometría peatonal real de cada tramo
  /// de caminata y la cachea. Al llegar, refresca el mapa.
  Future<void> _cargarCaminatas() async {
    final ruta = _rutaSel;
    if (ruta == null) return;
    for (final t in ruta.tramos) {
      if (!t.esCaminata || t.puntos.length < 2) continue;
      final a = t.puntos.first;
      final b = t.puntos.last;
      final key = _walkKey(a, b);
      if (_walkCache.containsKey(key)) continue;
      final path = await _peatonal.calcular(a, b);
      if (!mounted) return;
      if (path != null && path.length >= 2) {
        setState(() => _walkCache[key] = path);
      }
    }
  }

  void _onTapMapa(LatLng punto) {
    setState(() {
      if (_origen == null) {
        _origen = punto;
      } else if (_destino == null) {
        _destino = punto;
      } else {
        _origen = punto;
        _destino = null;
        _rutas = [];
        _error = null;
      }
    });
  }

  void _limpiar() {
    setState(() {
      _origen = null;
      _destino = null;
      _rutas = [];
      _seleccion = 0;
      _error = null;
    });
  }

  Future<void> _calcular() async {
    if (_origen == null || _destino == null) return;
    setState(() {
      _cargando = true;
      _error = null;
      _rutas = [];
    });
    try {
      final api = ref.read(apiServiceUsuarioProvider);
      final lista = await api.getRutasOptimas(
        origenLon: _origen!.longitude,
        origenLat: _origen!.latitude,
        destinoLon: _destino!.longitude,
        destinoLat: _destino!.latitude,
      );
      setState(() {
        _cargando = false;
        if (lista == null || lista.isEmpty) {
          _error = 'No se encontró una ruta entre esos puntos';
        } else {
          _rutas = lista
              .map((j) => RutaOptima.fromJson(j as Map<String, dynamic>))
              .toList();
          _seleccion = 0;
        }
      });
      if (_rutas.isNotEmpty) _cargarCaminatas();
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error al calcular la ruta';
      });
    }
  }

  List<Polyline> _polilineas() {
    final ruta = _rutaSel;
    if (ruta == null) return [];
    final colores = coloresPorTramo(ruta);
    final lineas = <Polyline>[];
    for (var i = 0; i < ruta.tramos.length; i++) {
      final t = ruta.tramos[i];
      var puntos = t.puntos;
      // La caminata se rutea por calles (OSRM); si aún no llegó, recta.
      if (t.esCaminata && puntos.length >= 2) {
        puntos = _walkCache[_walkKey(puntos.first, puntos.last)] ?? puntos;
      }
      lineas.add(Polyline(
        points: puntos,
        color: colores[i],
        strokeWidth: t.esCaminata ? 3 : 5,
        // Caminata = línea punteada; micro = línea sólida.
        pattern: t.esCaminata ? const StrokePattern.dotted() : const StrokePattern.solid(),
      ));
    }
    return lineas;
  }

  List<Marker> _marcadores() {
    return [
      if (_origen != null) marcadorPartida(_origen!),
      if (_destino != null) marcadorLlegada(_destino!),
    ];
  }

  String get _instruccion {
    if (_origen == null) return 'Tocá el mapa para marcar el ORIGEN (A)';
    if (_destino == null) return 'Tocá el mapa para marcar el DESTINO (B)';
    return 'Tocá "Calcular" o el mapa para reiniciar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta óptima'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Limpiar',
            onPressed: _limpiar,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.touch_app, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(_instruccion)),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(-17.7834, -63.1822),
                initialZoom: 13,
                minZoom: 10,
                maxZoom: 19,
                onTap: (_, punto) => _onTapMapa(punto),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.microbuses.sig',
                  maxNativeZoom: 19,
                ),
                PolylineLayer(polylines: _polilineas()),
                MarkerLayer(markers: _marcadores()),
              ],
            ),
          ),
          _PanelInferior(
            puedeCalcular: _origen != null && _destino != null && !_cargando,
            cargando: _cargando,
            error: _error,
            rutas: _rutas,
            seleccion: _seleccion,
            onCalcular: _calcular,
            onSeleccionar: (i) {
              setState(() => _seleccion = i);
              _cargarCaminatas();
            },
          ),
        ],
      ),
    );
  }
}

class _PanelInferior extends StatelessWidget {
  final bool puedeCalcular;
  final bool cargando;
  final String? error;
  final List<RutaOptima> rutas;
  final int seleccion;
  final VoidCallback onCalcular;
  final ValueChanged<int> onSeleccionar;

  const _PanelInferior({
    required this.puedeCalcular,
    required this.cargando,
    required this.error,
    required this.rutas,
    required this.seleccion,
    required this.onCalcular,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: puedeCalcular ? onCalcular : null,
              icon: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.alt_route),
              label: Text(cargando ? 'Calculando...' : 'Calcular ruta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          if (rutas.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Selector de opciones (la 1ra = menos transbordos)
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rutas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) =>
                    _OpcionCard(indice: i, ruta: rutas[i], seleccionada: i == seleccion,
                        onTap: () => onSeleccionar(i)),
              ),
            ),
            _Resultado(ruta: rutas[seleccion]),
          ],
        ],
      ),
    );
  }
}

class _OpcionCard extends StatelessWidget {
  final int indice;
  final RutaOptima ruta;
  final bool seleccionada;
  final VoidCallback onTap;

  const _OpcionCard({
    required this.indice,
    required this.ruta,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionada ? Colors.blue[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: seleccionada ? Colors.blue.shade900 : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opción ${indice + 1}',
                style: TextStyle(
                    fontSize: 11,
                    color: seleccionada ? Colors.white70 : Colors.grey[600])),
            Text('${ruta.tiempoTotalMin.round()} min',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: seleccionada ? Colors.white : Colors.black87)),
            Row(
              children: [
                Icon(Icons.swap_horiz,
                    size: 13,
                    color: seleccionada ? Colors.white70 : Colors.grey[600]),
                const SizedBox(width: 2),
                Text('${ruta.transbordos} transb.',
                    style: TextStyle(
                        fontSize: 11,
                        color: seleccionada ? Colors.white70 : Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  final RutaOptima ruta;
  const _Resultado({required this.ruta});

  @override
  Widget build(BuildContext context) {
    final colores = coloresPorTramo(ruta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Metric(Icons.schedule, '${ruta.tiempoTotalMin.toStringAsFixed(0)} min'),
            _Metric(Icons.swap_horiz, '${ruta.transbordos} transb.'),
            _Metric(Icons.straighten,
                '${(ruta.distanciaTotalM / 1000).toStringAsFixed(1)} km'),
          ],
        ),
        const SizedBox(height: 6),
        if (!ruta.enServicio)
          Row(children: [
            const Icon(Icons.nightlight_round, size: 14, color: Colors.deepOrange),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Fuera de horario de servicio (05:30–24:00); la espera es estimada.',
                style: TextStyle(fontSize: 11, color: Colors.deepOrange[700]),
              ),
            ),
          ])
        else
          Text(
            'Próximo micro ~${(ruta.frecuenciaMin / 2).round()} min · espera total ~${ruta.esperaTotalMin.round()} min '
            '(frecuencia ~${ruta.frecuenciaMin.round()} min)',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        const Divider(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ruta.tramos.length,
            itemBuilder: (context, i) {
              final t = ruta.tramos[i];
              if (t.esCaminata) {
                return ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.directions_walk, size: 18, color: Colors.white),
                  ),
                  title: const Text('Caminar'),
                  subtitle: Text(
                      '${t.distanciaM.round()} m · ${(t.tiempoSeg / 60).ceil()} min'),
                );
              }
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: colores[i],
                  child: Text(
                    t.lineaNumero.replaceAll(RegExp(r'^L0*'), ''),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                title: Text('Línea ${t.lineaNumero} (${t.sentido})'),
                subtitle: Text(
                    'Esperás ~${t.esperaMin.round()} min · viaje ${(t.tiempoSeg / 60).round()} min · ${t.paradas.length} paradas'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Metric(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: Colors.blue[800]),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
