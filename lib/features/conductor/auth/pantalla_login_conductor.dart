// lib/features/conductor/auth/pantalla_login_conductor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/auth_provider.dart';

class PantallaLoginConductor extends ConsumerStatefulWidget {
  const PantallaLoginConductor({super.key});

  @override
  ConsumerState<PantallaLoginConductor> createState() =>
      _PantallaLoginConductorState();
}

class _PantallaLoginConductorState
    extends ConsumerState<PantallaLoginConductor> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _verPassword = false;

  // Credenciales de prueba para la demo.
  static const _demoEmail = 'juan.perez@example.com';
  static const _demoPassword = 'conductor123';

  void _rellenarDemo() {
    _email.text = _demoEmail;
    _password.text = _demoPassword;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .login(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      context.go('/conductor');
    } else {
      final error = ref.read(authProvider).error ?? 'No se pudo iniciar sesión';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargando = ref.watch(authProvider).cargando;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conductor — Iniciar sesión'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus, size: 72, color: Colors.blue[800]),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Ingresá un email válido'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: !_verPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _verPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _verPassword = !_verPassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Ingresá tu contraseña'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: cargando ? null : _entrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                    ),
                    child: cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: cargando
                      ? null
                      : () => context.push('/conductor/registro'),
                  child: const Text('¿No tenés cuenta? Registrate'),
                ),
                const SizedBox(height: 8),
                // Acceso rápido para la demo: rellena las credenciales de prueba.
                OutlinedButton.icon(
                  onPressed: cargando
                      ? null
                      : () {
                          _rellenarDemo();
                          _entrar();
                        },
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Acceso rápido (demo)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
