import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

/// Muestra un bottom sheet preguntando si tomar foto o elegir de galeria.
/// Devuelve la opcion elegida o null si se cancela.
Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borde,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text('Agregar foto',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.azulNoche)),
            const SizedBox(height: 12),
            _option(ctx, Icons.photo_camera, 'Tomar foto', ImageSource.camera),
            const SizedBox(height: 8),
            _option(
                ctx, Icons.photo_library, 'Elegir de galeria', ImageSource.gallery),
          ],
        ),
      ),
    ),
  );
}

Widget _option(BuildContext ctx, IconData icon, String text, ImageSource src) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => Navigator.pop(ctx, src),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.arena,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.verdeMenta,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.azulCaribe),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulNoche)),
        ],
      ),
    ),
  );
}
