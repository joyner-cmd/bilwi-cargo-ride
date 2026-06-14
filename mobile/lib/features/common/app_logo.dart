import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Logo de la app dibujado con widgets (sin necesidad de asset externo):
/// un pin de ubicacion sobre un camion, en colores de marca.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.azulCaribe;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: light
              ? [Colors.white24, Colors.white10]
              : [AppColors.verdeAgua.withValues(alpha: .5), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: light ? Colors.white54 : AppColors.turquesa, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.local_shipping_rounded, size: size * 0.5, color: fg),
          Positioned(
            top: size * 0.14,
            right: size * 0.16,
            child: Icon(Icons.location_on, size: size * 0.3, color: AppColors.turquesa),
          ),
        ],
      ),
    );
  }
}
