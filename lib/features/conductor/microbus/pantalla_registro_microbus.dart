// lib/features/conductor/microbus/pantalla_registro_microbus.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/linea.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/lineas_provider.dart';
import '../../../shared/providers/microbus_provider.dart';

class PantallaRegistroMicrobus extends ConsumerStatefulWidget {
  const PantallaRegistroMicrobus({super.key});

  @override
  ConsumerState<PantallaRegistroMicrobus> createState() =>
      _PantallaRegistroMicrobusState();
}

class _PantallaRegistroMicrobusState
    extends ConsumerState<PantallaRegistroMicrobus> {
  final _formKey = GlobalKey<FormState>();
  final _placa = TextEditingController();
  final _modelo = TextEditingController();
  final _asientos = TextEditingController();
  final _interno = TextEditingController();

  String? _lineaId;
  DateTime _fechaAsig = DateTime.now();
  final List<XFile> _fotos = [];
  bool _cargando = false;

  @override
  void dispose() {
    _placa.dispose();
    _modelo.dispose();
    _asientos.dispose();
    _interno.dispose();
    super.dispose();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegirFotos() async {
    final imgs = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (imgs.isNotEmpty) setState(() => _fotos.addAll(imgs));
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lineaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elegí una línea')));
      return;
    }
    if (_fotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agregá al menos una foto')));
      return;
    }
    setState(() => _cargando = true);
    try {
      final api = ref.read(apiServiceConductorProvider);
      await api.registrarMicrobus(
        placa: _placa.text.trim(),
        modelo: _modelo.text.trim(),
        cantidadAsientos: int.parse(_asientos.text.trim()),
        lineaId: _lineaId!,
        numeroInterno: _interno.text.trim(),
        fechaAsignacion: _iso(_fechaAsig),
        fotosPaths: _fotos.map((f) => f.path).toList(),
      );
      ref.invalidate(misMicrobusesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microbús registrado')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineasAsync = ref.watch(lineasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar microbús'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _campo(_placa, 'Placa'),
              _campo(_modelo, 'Modelo'),
              _campo(_asientos, 'Cantidad de asientos',
                  tipo: TextInputType.number,
                  validador: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return (n == null || n <= 0) ? 'Número mayor a 0' : null;
                  }),
              _campo(_interno, 'Número interno'),
              lineasAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('No se pudieron cargar las líneas'),
                data: (lineas) => DropdownButtonFormField<String>(
                  initialValue: _lineaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Línea', border: OutlineInputBorder()),
                  items: lineas
                      .map((LineaResumen l) => DropdownMenuItem(
                            value: l.id,
                            child: Text('${l.numero} — ${l.nombre}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _lineaId = v),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _cargando
                    ? null
                    : () async {
                        final sel = await showDatePicker(
                          context: context,
                          initialDate: _fechaAsig,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (sel != null) setState(() => _fechaAsig = sel);
                      },
                icon: const Icon(Icons.calendar_today),
                label: Text('Asignación: ${_iso(_fechaAsig)}'),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Fotos (${_fotos.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _fotos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(_fotos[i].path),
                                  width: 90, height: 90, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _fotos.removeAt(i)),
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: _cargando ? null : _elegirFotos,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Icon(Icons.add_a_photo),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Registrar microbús'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    TextInputType? tipo,
    String? Function(String?)? validador,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validador ??
            (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
      ),
    );
  }
}
