// lib/features/conductor/pantalla_home_conductor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/primary_button.dart';

class PantallaHomeConductor extends ConsumerWidget {
  const PantallaHomeConductor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Mientras se restaura la sesión guardada
    if (auth.estado == AuthEstado.desconocido) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Sin sesión: invitar a iniciarla
    if (auth.estado == AuthEstado.noAutenticado || auth.conductor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Conductor'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus_filled, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                const Text('Portal del Conductor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Inicia sesión para gestionar tus rutas y vehículos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Iniciar Sesión',
                  icon: Icons.login,
                  onPressed: () => context.go('/conductor/login'),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),
        ),
      );
    }

    final c = auth.conductor!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/conductor/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: c.fotoUrl.isNotEmpty ? NetworkImage(c.fotoUrl) : null,
                  child: c.fotoUrl.isEmpty 
                      ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary) 
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(c.email, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Licencia ${c.categoriaLicencia}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AccionDashboard(
                  icono: Icons.directions_bus,
                  titulo: 'Mis Microbuses',
                  color: Colors.blue,
                  delay: 200,
                  onTap: () => context.push('/conductor/microbuses'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AccionDashboard(
                  icono: Icons.play_circle_fill,
                  titulo: 'Iniciar Ruta',
                  color: Colors.green,
                  delay: 300,
                  onTap: () => context.push('/conductor/recorrido'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccionDashboard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _AccionDashboard({
    required this.icono,
    required this.titulo,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 36, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: delay.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOut);
  }
}
