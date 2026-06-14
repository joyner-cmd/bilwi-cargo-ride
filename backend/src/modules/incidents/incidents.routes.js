import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { query } from '../../config/db.js';

const router = Router();

const incidentSchema = z.object({
  tripId: z.coerce.number().int().optional(),
  type: z.enum(['sos', 'accident', 'harassment', 'fraud', 'other']),
  description: z.string().max(1000).optional(),
  lat: z.number().optional(),
  lng: z.number().optional(),
});

// Reportar incidente / boton SOS
router.post(
  '/',
  requireAuth,
  validate(incidentSchema),
  asyncHandler(async (req, res) => {
    const b = req.body;
    const { rows } = await query(
      `INSERT INTO incidents (trip_id, reporter_id, type, description, lat, lng)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [b.tripId ?? null, req.user.id, b.type, b.description ?? null, b.lat ?? null, b.lng ?? null]
    );
    res.status(201).json(rows[0]);
  })
);

// Mis reportes (o todos si admin)
router.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    if (req.user.role === 'admin') {
      const { rows } = await query('SELECT * FROM incidents ORDER BY created_at DESC LIMIT 100');
      return res.json({ incidents: rows });
    }
    const { rows } = await query(
      'SELECT * FROM incidents WHERE reporter_id = $1 ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json({ incidents: rows });
  })
);

// Cambiar estado (admin)
router.patch(
  '/:id',
  requireAuth,
  requireRole('admin'),
  validate(z.object({ status: z.enum(['open', 'reviewing', 'resolved']) })),
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      'UPDATE incidents SET status = $2 WHERE id = $1 RETURNING *',
      [Number(req.params.id), req.body.status]
    );
    res.json(rows[0]);
  })
);

export default router;
