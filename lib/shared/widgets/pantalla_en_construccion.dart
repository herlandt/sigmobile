// lib/shared/widgets/pantalla_en_construccion.dart
import 'package:flutter/material.dart';

/// Placeholder temporal para pantallas que se implementan en bloques posteriores.
class PantallaEnConstruccion extends StatelessWidget {
  final String titulo;
  const PantallaEnConstruccion({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '🚧 En construcción — disponible en el próximo bloque de la Fase 4b.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
