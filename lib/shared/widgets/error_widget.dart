// lib/shared/widgets/error_widget.dart
import 'package:flutter/material.dart';

class ErrorVista extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const ErrorVista({super.key, required this.mensaje, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            if (onReintentar != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
