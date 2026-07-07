// lib/features/usuario/recorrido_linea/pantalla_lista_lineas.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/linea.dart';
import '../../../shared/providers/lineas_provider.dart';
import '../../../shared/widgets/custom_card.dart';

class PantallaListaLineas extends ConsumerStatefulWidget {
  const PantallaListaLineas({super.key});

  @override
  ConsumerState<PantallaListaLineas> createState() => _PantallaListaLineasState();
}

class _PantallaListaLineasState extends ConsumerState<PantallaListaLineas> {
  final _buscadorCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    super.dispose();
  }

  /// Filtra por número / nombre / descripción. El orden numérico ya viene del
  /// lineasProvider, así que acá solo se filtra.
  List<LineaResumen> _filtrar(List<LineaResumen> lineas) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return lineas;
    return lineas.where((l) {
      return l.numero.toLowerCase().contains(q) ||
          l.nombre.toLowerCase().contains(q) ||
          (l.descripcion?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
        data: (lineas) {
          final visibles = _filtrar(lineas);
          return Column(
            children: [
              _buscador(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(lineasProvider.future),
                  child: visibles.isEmpty
                      ? _sinResultados()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          itemCount: visibles.length,
                          itemBuilder: (context, index) =>
                              _tarjetaLinea(visibles[index], index),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _buscadorCtrl,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar línea (número o nombre)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpiar',
                  onPressed: () {
                    _buscadorCtrl.clear();
                    setState(() => _query = '');
                    FocusScope.of(context).unfocus();
                  },
                ),
          filled: true,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _sinResultados() {
    // ListView para que el RefreshIndicator siga funcionando con scroll.
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No hay líneas que coincidan con "$_query"',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaLinea(LineaResumen linea, int index) {
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
          duration: 250.ms,
          // Escalona solo las primeras tarjetas para que al escribir no haya
          // un retardo largo por línea.
          delay: (30 * index.clamp(0, 8)).ms,
        );
  }
}
