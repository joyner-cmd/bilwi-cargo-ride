import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { query } from '../../config/db.js';
import { badRequest, notFound } from '../../utils/errors.js';

const router = Router();

const uploadSchema = z.object({
  mimeType: z
    .string()
    .regex(/^image\/(jpeg|jpg|png|webp)$/i, 'Solo imagenes (jpeg, png, webp)'),
  base64: z.string().min(100),
});

// Subir imagen (base64). Devuelve un id + url relativa para guardar como photo_url.
router.post(
  '/',
  requireAuth,
  validate(uploadSchema),
  asyncHandler(async (req, res) => {
    const { mimeType, base64 } = req.body;

    // Acepta data URLs ("data:image/jpeg;base64,...") y base64 puro.
    const cleaned = base64.includes(',') ? base64.split(',', 2)[1] : base64;
    let buffer;
    try {
      buffer = Buffer.from(cleaned, 'base64');
    } catch {
      throw badRequest('Base64 invalido');
    }
    const max = 3 * 1024 * 1024;
    if (buffer.length === 0) throw badRequest('Imagen vacia');
    if (buffer.length > max) throw badRequest('Imagen muy grande (max 3 MB)');

    const { rows } = await query(
      `INSERT INTO uploads (uploader_id, mime_type, data, size_bytes)
       VALUES ($1, $2, $3, $4) RETURNING id`,
      [req.user.id, mimeType.toLowerCase(), buffer, buffer.length]
    );
    const id = rows[0].id;
    res.status(201).json({
      id,
      url: `/api/uploads/${id}`,
      size: buffer.length,
    });
  })
);

// Servir imagen binaria. No requiere auth (las URLs son largas e impredecibles).
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      'SELECT mime_type, data FROM uploads WHERE id = $1',
      [Number(req.params.id)]
    );
    if (!rows[0]) throw notFound('Imagen no encontrada');
    res.setHeader('Content-Type', rows[0].mime_type);
    res.setHeader('Cache-Control', 'public, max-age=86400, immutable');
    res.send(rows[0].data);
  })
);

export default router;
