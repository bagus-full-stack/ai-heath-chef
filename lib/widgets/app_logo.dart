import 'package:flutter/material.dart';

/// Logo Fodli (obturateur) : l'icône de l'app, aux coins arrondis.
class AppLogo extends StatelessWidget {
  final double size;
  final double radius;

  const AppLogo({super.key, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/icon/icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Fodli',
      ),
    );
  }
}
