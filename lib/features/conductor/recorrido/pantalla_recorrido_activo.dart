// lib/features/conductor/recorrido/pantalla_recorrido_activo.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/recorrido.dart';
import '../../../data/services/recorrido_background.dart';
import '../../../data/services/recorrido_storage.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/marcadores_mapa.dart';

class PantallaRecorridoActivo extends ConsumerStatefulWidget {
  const PantallaRecorridoActivo({super.key});

  @override
  ConsumerState<PantallaRecorridoActivo> createState() =>
      _PantallaRecorridoActivoState();
}

class _PantallaRecorridoActivoState
    extends ConsumerState<PantallaRecorridoActivo> {
  final RecorridoBackground _bg = RecorridoBackground();
  final MapController _mapa = MapController();
  StreamSubscription<Map<String, dynamic>?>? _sub;

  String? _recorridoId;
  bool _cargandoId = true;
  bool _finalizando = false;

  LatLng? _pos;
  double _distanciaKm = 0;
  int _tiempoSeg = 0;
  double _velocidad = 0;

  @override
  void initState() {
    super.initState();
    _cargarId();
    _sub = _bg.updates.listen((data) {
      if (data == null || !mounted) return;
      setState(() {
        _pos = LatLng((data['lat'] as num).toDouble(), (data['lon'] as num).toDouble());
        _velocidad = (data['velocidad'] as num?)?.toDouble() ?? 0;
        _distanciaKm = (data['distancia_km'] as num?)?.toDouble() ?? 0;
        _tiempoSeg = (data['tiempo_seg'] as num?)?.toInt() ?? 0;
      });
      _mapa.move(_pos!, _mapa.camera.zoom);
    });
  }

  Future<void> _cargarId() async {
    final id = await RecorridoStorage().leerActivo();
    if (!mounted) return;
    setState(() {
      _recorridoId = id;
      _cargandoId = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<({double lon, double lat})> _ubicacionActual() async {
    try {
      final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return (lon: p.longitude, lat: p.latitude);
    } catch (_) {
      return (lon: _pos?.longitude ?? -63.1822, lat: _pos?.latitude ?? -17.7834);
    }
  }

  String _fmtTiempo(int seg) {
    final m = seg ~/ 60;
    final s = seg % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  Future<void> _terminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminar recorrido'),
        content: const Text('¿Finalizar el recorrido normalmente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Terminar')),
        ],
      ),
    );
    if (ok != true) return;
    await _finalizar((api, id, u) =>
        api.terminarRecorrido(id, longitud: u.lon, latitud: u.lat));
  }

  Future<void> _salir() async {
    final ctrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir por fuerza mayor'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Motivo', hintText: 'Ej. falla mecánica'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Salir')),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty) return;
    await _finalizar((api, id, u) =>
        api.salirRecorrido(id, longitud: u.lon, latitud: u.lat, motivo: motivo));
  }

  Future<void> _finalizar(
    Future<RecorridoResumen> Function(
            dynamic api, String id, ({double lon, double lat}) u)
        accion,
  ) async {
    final id = _recorridoId;
    if (id == null) return;
    setState(() => _finalizando = true);
    try {
      final u = await _ubicacionActual();
      final api = ref.read(apiServiceConductorProvider);
      final resumen = await accion(api, id, u);
      _bg.detener();
      await RecorridoStorage().borrarActivo();
      if (!mounted) return;
      await _mostrarResumen(resumen);
      if (!mounted) return;
      context.go('/conductor');
    } catch (e) {
      if (!mounted) return;
      setState(() => _finalizando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _mostrarResumen(RecorridoResumen r) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recorrido finalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${r.tipoFinalizacion ?? "-"}'),
            Text('Distancia: ${r.distanciaTotalKm?.toStringAsFixed(2) ?? "0"} km'),
            Text('Tiempo: ${_fmtTiempo(r.tiempoTotalSeg ?? 0)}'),
            if (r.motivoSalida != null) Text('Motivo: ${r.motivoSalida}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_recorridoId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recorrido'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No hay un recorrido activo'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/conductor/recorrido'),
                child: const Text('Iniciar uno'),
              ),
            ],
          ),
        ),
      );
    }

    final centro = _pos ?? const LatLng(-17.7834, -63.1822);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorrido activo'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(initialCenter: centro, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.microbuses.sig',
                  maxNativeZoom: 19,
                ),
                if (_pos != null)
                  MarkerLayer(markers: [marcadorMicrobus(_pos!, 'Yo')]),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(Icons.schedule, _fmtTiempo(_tiempoSeg)),
                    _Stat(Icons.straighten,
                        '${_distanciaKm.toStringAsFixed(2)} km'),
                    _Stat(Icons.speed, '${_velocidad.toStringAsFixed(0)} km/h'),
                  ],
                ),
                if (_pos == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Esperando primera posición GPS...',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _finalizando ? null : _salir,
                        icon: const Icon(Icons.warning_amber),
                        label: const Text('Salir'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[800]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _finalizando ? null : _terminar,
                        icon: _finalizando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.stop),
                        label: const Text('Terminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Stat(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: Colors.green[700]),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
