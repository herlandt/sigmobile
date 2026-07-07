// lib/features/conductor/recorrido/pantalla_iniciar_recorrido.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/recorrido_background.dart';
import '../../../data/services/recorrido_storage.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/microbus_provider.dart';

class PantallaIniciarRecorrido extends ConsumerStatefulWidget {
  const PantallaIniciarRecorrido({super.key});

  @override
  ConsumerState<PantallaIniciarRecorrido> createState() =>
      _PantallaIniciarRecorridoState();
}

class _PantallaIniciarRecorridoState
    extends ConsumerState<PantallaIniciarRecorrido> {
  String? _microbusId;
  String _sentido = 'ida';
  bool _cargando = false;

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  Future<bool> _asegurarUbicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _snack('Activá la ubicación (GPS) del dispositivo');
      return false;
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      _snack('Se necesita permiso de ubicación para el recorrido');
      return false;
    }
    return true;
  }

  Future<void> _iniciar() async {
    if (_microbusId == null) {
      _snack('Elegí un microbús');
      return;
    }
    if (!await _asegurarUbicacion()) return;

    setState(() => _cargando = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final api = ref.read(apiServiceConductorProvider);
      final rec = await api.iniciarRecorrido(
        microbusId: _microbusId!,
        sentido: _sentido,
        longitud: pos.longitude,
        latitud: pos.latitude,
      );
      await RecorridoStorage().guardarActivo(rec.recorridoId);
      await RecorridoBackground().iniciar();
      if (!mounted) return;
      context.go('/conductor/recorrido/activo');
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final microbusesAsync = ref.watch(misMicrobusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar recorrido'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: microbusesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
              child: Text('No se pudieron cargar tus microbuses')),
          data: (lista) {
            if (lista.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Primero registrá un microbús'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/conductor/microbuses/nuevo'),
                      child: const Text('Registrar microbús'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _microbusId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Microbús', border: OutlineInputBorder()),
                  items: lista
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text('${m.placa} · interno ${m.numeroInterno}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _microbusId = v),
                ),
                const SizedBox(height: 20),
                const Text('Sentido'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ida', label: Text('Ida')),
                    ButtonSegment(value: 'vuelta', label: Text('Vuelta')),
                  ],
                  selected: {_sentido},
                  onSelectionChanged: (s) => setState(() => _sentido = s.first),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Al iniciar, la app enviará tu ubicación cada 30 s mientras dure '
                    'el recorrido (servicio en primer plano).',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _iniciar,
                    icon: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.play_arrow),
                    label: Text(_cargando ? 'Iniciando...' : 'Iniciar recorrido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
