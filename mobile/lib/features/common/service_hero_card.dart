import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/service_type.dart';

/// Tarjeta grande con foto del vehiculo (estilo AVIS). Para el carrusel
/// horizontal de seleccion de servicio.
class ServiceHeroCard extends StatelessWidget {
  const ServiceHeroCard({
    super.key,
    required this.service,
    required this.selected,
    required this.fromPrice,
    required this.onTap,
  });

  final ServiceType service;
  final bool selected;
  final String fromPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.azulCaribe : AppColors.borde,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.tarjeta : AppShadows.sutil,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.arenaSuave,
                          AppColors.verdeMenta.withValues(alpha: .5)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      service.assetImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_shipping,
                          size: 42,
                          color: AppColors.azulCaribe),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.azulCaribe,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.azulNoche,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('desde $fromPrice',
                      style: const TextStyle(
                          color: AppColors.grisSuave, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
