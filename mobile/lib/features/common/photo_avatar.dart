import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

/// Avatar circular con foto remota (cacheada) y placeholder con inicial.
class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar({
    super.key,
    required this.photoUrl,
    required this.fallbackInitial,
    this.size = 56,
    this.background,
    this.foreground,
  });

  final String? photoUrl;
  final String fallbackInitial;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.fullUrl(photoUrl);
    final bg = background ?? AppColors.verdeAgua;
    final fg = foreground ?? AppColors.azulProfundo;
    if (url == null) return _fallback(bg, fg);
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(bg, fg),
        errorWidget: (_, __, ___) => _fallback(bg, fg),
      ),
    );
  }

  Widget _fallback(Color bg, Color fg) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Text(
        fallbackInitial.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// Imagen rectangular cacheada (para fotos de vehiculos).
class PhotoImage extends StatelessWidget {
  const PhotoImage({
    super.key,
    required this.photoUrl,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.fit = BoxFit.cover,
  });

  final String? photoUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.fullUrl(photoUrl);
    if (url == null) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.arena,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.directions_car,
            color: AppColors.grisSuave, size: 32),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: AppColors.arena,
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppColors.arena,
          alignment: Alignment.center,
          child:
              const Icon(Icons.broken_image, color: AppColors.grisSuave),
        ),
      ),
    );
  }
}
