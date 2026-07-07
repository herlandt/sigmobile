import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (!isLoading) Text(text),
      ],
    );

    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: expand
          ? SizedBox(width: double.infinity, child: Center(child: content))
          : content,
    );

    // Animamos ligeramente el botón de entrada para darle un toque vivo
    return button.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
