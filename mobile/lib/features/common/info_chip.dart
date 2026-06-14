import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Chip de informacion (icono + valor + etiqueta) estilo "5 asientos / Gasolina".
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = tint ?? AppColors.azulCaribe;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.arena,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulNoche,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(color: AppColors.grisSuave, fontSize: 11)),
        ],
      ),
    );
  }
}
