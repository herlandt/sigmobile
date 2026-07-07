// lib/features/usuario/recorrido_linea/pantalla_lista_lineas.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/providers/lineas_provider.dart';
import '../../../shared/widgets/custom_card.dart';

class PantallaListaLineas extends ConsumerWidget {
  const PantallaListaLineas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineasAsync = ref.watch(lineasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas de Microbús'),
        actions: [
          IconButton(
            icon: const Icon(Icons.near_me),
            tooltip: 'Líneas cercanas',
            onPressed: () => context.push('/usuario/lineas-cercanas'),
          ),
          IconButton(
            icon: const Icon(Icons.alt_route),
            tooltip: 'Ruta óptima',
            onPressed: () => context.push('/usuario/ruta-optima'),
          ),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Soy conductor',
            onPressed: () => context.push('/conductor/login'),
          ),
        ],
      ),
      body: lineasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No se pudo cargar las líneas'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(lineasProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (lineas) => RefreshIndicator(
          onRefresh: () => ref.refresh(lineasProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: lineas.length,
            itemBuilder: (context, index) {
              final linea = lineas[index];
              return CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                onTap: () => context.push(
                  '/usuario/recorrido/${linea.id}',
                  extra: linea,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          linea.numero,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            linea.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (linea.descripcion != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              linea.descripcion!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ).animate().fadeIn(
                duration: 300.ms,
                delay: (50 * index).ms,
              ).slideX(
                begin: 0.05,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOut,
              );
            },
          ),
        ),
      ),
    );
  }
}
