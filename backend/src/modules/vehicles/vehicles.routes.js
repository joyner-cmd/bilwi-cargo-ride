import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { query } from '../../config/db.js';

const router = Router();

const vehicleSchema = z.object({
  type: z.enum(['particular', 'camioneta', 'camion_pequeno', 'camion_mediano', 'acarreo', 'moto']),
  brand: z.string().max(60).optional(),
  model: z.string().max(60).optional(),
  year: z.number().int().min(1980).max(2100).optional(),
  plate: z.string().max(20).optional(),
  color: z.string().max(30).optional(),
  capacityKg: z.number().int().min(0).optional(),
  photoUrl: z.string().url().optional(),
});

// Listar mis vehiculos (conductor)
router.get(
  '/me',
  requireAuth,
  requireRole('driver'),
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      'SELECT * FROM vehicles WHERE driver_id = $1 ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json({ vehicles: rows });
  })
);

// Registrar vehiculo (queda 'pending' hasta aprobacion admin)
router.post(
  '/',
  requireAuth,
  requireRole('driver'),
  validate(vehicleSchema),
  asyncHandler(async (req, res) => {
    const v = req.body;
    const { rows } = await query(
      `INSERT INTO vehicles (driver_id, type, brand, model, year, plate, color, capacity_kg, photo_url)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [
        req.user.id,
        v.type,
        v.brand ?? null,
        v.model ?? null,
        v.year ?? null,
        v.plate ?? null,
        v.color ?? null,
        v.capacityKg ?? null,
        v.photoUrl ?? null,
      ]
    );
    res.status(201).json(rows[0]);
  })
);

export default router;
