// lib/features/usuario/recorrido_linea/pantalla_selector_sentido.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/linea.dart';

class PantallaSelectorSentido extends StatelessWidget {
  final LineaResumen linea;
  const PantallaSelectorSentido({super.key, required this.linea});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Línea ${linea.numero}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(linea.nombre,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            if (linea.descripcion != null) ...[
              const SizedBox(height: 8),
              Text(linea.descripcion!,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 48),
            const Text('¿Qué sentido deseas ver?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            _BotonSentido(
              icono: Icons.arrow_forward,
              texto: 'Ida',
              color: Colors.blue[700]!,
              onTap: () => _ir(context, 'ida'),
            ),
            const SizedBox(height: 12),
            _BotonSentido(
              icono: Icons.arrow_back,
              texto: 'Vuelta',
              color: Colors.orange[700]!,
              onTap: () => _ir(context, 'vuelta'),
            ),
            const SizedBox(height: 12),
            _BotonSentido(
              icono: Icons.compare_arrows,
              texto: 'Ambos sentidos',
              color: Colors.purple[700]!,
              onTap: () => _ir(context, 'ambos'),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.push('/usuario/esperando', extra: linea),
              icon: const Icon(Icons.access_time),
              label: const Text('Esperar microbús en tiempo real'),
            ),
          ],
        ),
      ),
    );
  }

  void _ir(BuildContext context, String sentido) {
    context.push('/usuario/mapa/${linea.id}', extra: {
      'sentido': sentido,
      'nombre': '${linea.numero} — ${linea.nombre}',
    });
  }
}

class _BotonSentido extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  const _BotonSentido({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icono),
      label: Text(texto, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
