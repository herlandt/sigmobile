// lib/features/conductor/microbus/pantalla_mis_microbuses.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/microbus_provider.dart';

class PantallaMisMicrobuses extends ConsumerWidget {
  const PantallaMisMicrobuses({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(misMicrobusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis microbuses'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
        onPressed: () async {
          await context.push('/conductor/microbuses/nuevo');
          ref.invalidate(misMicrobusesProvider);
        },
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No se pudieron cargar los microbuses'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(misMicrobusesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No tenés microbuses registrados.\nTocá "Registrar" para agregar uno.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(misMicrobusesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = lista[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    backgroundImage: m.primeraFotoUrl != null
                        ? NetworkImage(m.primeraFotoUrl!)
                        : null,
                    child: m.primeraFotoUrl == null
                        ? const Icon(Icons.directions_bus)
                        : null,
                  ),
                  title: Text('${m.placa} · ${m.modelo}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Interno ${m.numeroInterno} · ${m.cantidadAsientos} asientos'),
                  trailing: Chip(
                    label: Text(m.activo ? 'Activo' : 'Baja',
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: m.activo ? Colors.green : Colors.grey,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
