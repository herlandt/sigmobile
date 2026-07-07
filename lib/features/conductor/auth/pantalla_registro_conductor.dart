// lib/features/conductor/auth/pantalla_registro_conductor.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/providers/auth_provider.dart';

class PantallaRegistroConductor extends ConsumerStatefulWidget {
  const PantallaRegistroConductor({super.key});

  @override
  ConsumerState<PantallaRegistroConductor> createState() =>
      _PantallaRegistroConductorState();
}

class _PantallaRegistroConductorState
    extends ConsumerState<PantallaRegistroConductor> {
  final _formKey = GlobalKey<FormState>();
  final _documento = TextEditingController();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _sexo;
  String? _categoria;
  DateTime? _fechaNac;
  XFile? _foto;
  bool _cargando = false;

  @override
  void dispose() {
    _documento.dispose();
    _nombre.dispose();
    _telefono.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegirFoto() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _foto = img);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final sel = await showDatePicker(
      context: context,
      initialDate: DateTime(hoy.year - 25),
      firstDate: DateTime(1940),
      lastDate: hoy,
    );
    if (sel != null) setState(() => _fechaNac = sel);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sexo == null || _categoria == null || _fechaNac == null || _foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Completá sexo, licencia, fecha de nacimiento y foto')));
      return;
    }
    setState(() => _cargando = true);
    try {
      final api = ref.read(apiServiceConductorProvider);
      await api.registrarConductor(
        documentoIdentidad: _documento.text.trim(),
        nombre: _nombre.text.trim(),
        fechaNacimiento: _iso(_fechaNac!),
        sexo: _sexo!,
        telefono: _telefono.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        categoriaLicencia: _categoria!,
        fotoPath: _foto!.path,
      );
      // Auto-login tras el registro
      final ok = await ref
          .read(authProvider.notifier)
          .login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (ok) {
        context.go('/conductor');
      } else {
        context.go('/conductor/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de conductor'),
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
              GestureDetector(
                onTap: _cargando ? null : _elegirFoto,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue[50],
                  backgroundImage:
                      _foto != null ? FileImage(File(_foto!.path)) : null,
                  child: _foto == null
                      ? const Icon(Icons.add_a_photo, size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Tocá para elegir tu foto')),
              const SizedBox(height: 16),
              _campo(_documento, 'Documento de identidad'),
              _campo(_nombre, 'Nombre completo'),
              _campo(_telefono, 'Teléfono', tipo: TextInputType.phone),
              _campo(_email, 'Email', tipo: TextInputType.emailAddress,
                  validador: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null),
              _campo(_password, 'Contraseña', oculto: true,
                  validador: (v) =>
                      (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _sexo,
                decoration: const InputDecoration(
                    labelText: 'Sexo', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                ],
                onChanged: (v) => setState(() => _sexo = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                    labelText: 'Categoría de licencia',
                    border: OutlineInputBorder()),
                items: const ['A', 'B', 'C', 'P', 'M']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _cargando ? null : _elegirFecha,
                icon: const Icon(Icons.calendar_today),
                label: Text(_fechaNac == null
                    ? 'Fecha de nacimiento'
                    : 'Nacimiento: ${_iso(_fechaNac!)}'),
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
                      : const Text('Registrarme'),
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
    bool oculto = false,
    String? Function(String?)? validador,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        obscureText: oculto,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validador ??
            (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
      ),
    );
  }
}
