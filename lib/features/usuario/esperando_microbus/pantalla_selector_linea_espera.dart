// lib/features/usuario/esperando_microbus/pantalla_selector_linea_espera.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/lineas_provider.dart';

class PantallaSelectorLineaEspera extends ConsumerWidget {
  const PantallaSelectorLineaEspera({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineasAsync = ref.watch(lineasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Esperando Microbús'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: lineasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lineas) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '¿Qué línea estás esperando?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: lineas.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final linea = lineas[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[800],
                      child: Text(linea.numero,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(linea.nombre),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/usuario/esperando/${linea.id}',
                      extra: linea,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
