import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { query } from '../../config/db.js';
import { notFound, forbidden } from '../../utils/errors.js';

const router = Router();

const vehicleSchema = z.object({
  type: z.enum(['particular', 'camioneta', 'camion_pequeno', 'camion_mediano', 'acarreo', 'moto']),
  brand: z.string().max(60).optional(),
  model: z.string().max(60).optional(),
  year: z.coerce.number().int().min(1980).max(2100).optional(),
  plate: z.string().max(20).optional(),
  color: z.string().max(30).optional(),
  capacityKg: z.coerce.number().int().min(0).optional(),
  photoUrl: z.string().optional(),
  servicesOffered: z.array(z.string()).default([]),
  customPerKm: z.coerce.number().min(0).max(999).optional(),
  customBaseFare: z.coerce.number().min(0).max(9999).optional(),
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

// Registrar vehiculo
router.post(
  '/',
  requireAuth,
  requireRole('driver'),
  validate(vehicleSchema),
  asyncHandler(async (req, res) => {
    const v = req.body;
    const { rows } = await query(
      `INSERT INTO vehicles (driver_id, type, brand, model, year, plate, color, capacity_kg,
                             photo_url, services_offered, custom_per_km, custom_base_fare)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
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
        JSON.stringify(v.servicesOffered ?? []),
        v.customPerKm ?? null,
        v.customBaseFare ?? null,
      ]
    );
    res.status(201).json(rows[0]);
  })
);

// Editar vehiculo
router.patch(
  '/:id',
  requireAuth,
  requireRole('driver'),
  validate(vehicleSchema.partial()),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const { rows: existing } = await query(
      'SELECT driver_id FROM vehicles WHERE id = $1',
      [id]
    );
    if (!existing[0]) throw notFound('Vehiculo no encontrado');
    if (existing[0].driver_id !== req.user.id) throw forbidden('No es tu vehiculo');

    const v = req.body;
    const sets = [];
    const params = [id];
    const pushSet = (col, val) => {
      params.push(val);
      sets.push(`${col} = $${params.length}`);
    };
    if (v.type !== undefined) pushSet('type', v.type);
    if (v.brand !== undefined) pushSet('brand', v.brand);
    if (v.model !== undefined) pushSet('model', v.model);
    if (v.year !== undefined) pushSet('year', v.year);
    if (v.plate !== undefined) pushSet('plate', v.plate);
    if (v.color !== undefined) pushSet('color', v.color);
    if (v.capacityKg !== undefined) pushSet('capacity_kg', v.capacityKg);
    if (v.photoUrl !== undefined) pushSet('photo_url', v.photoUrl);
    if (v.servicesOffered !== undefined)
      pushSet('services_offered', JSON.stringify(v.servicesOffered));
    if (v.customPerKm !== undefined) pushSet('custom_per_km', v.customPerKm);
    if (v.customBaseFare !== undefined)
      pushSet('custom_base_fare', v.customBaseFare);

    if (sets.length === 0) {
      const { rows } = await query('SELECT * FROM vehicles WHERE id = $1', [id]);
      return res.json(rows[0]);
    }
    const { rows } = await query(
      `UPDATE vehicles SET ${sets.join(', ')} WHERE id = $1 RETURNING *`,
      params
    );
    res.json(rows[0]);
  })
);

// Eliminar vehiculo
router.delete(
  '/:id',
  requireAuth,
  requireRole('driver'),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const { rows } = await query(
      'SELECT driver_id FROM vehicles WHERE id = $1',
      [id]
    );
    if (!rows[0]) throw notFound('Vehiculo no encontrado');
    if (rows[0].driver_id !== req.user.id) throw forbidden('No es tu vehiculo');
    await query('DELETE FROM vehicles WHERE id = $1', [id]);
    res.json({ ok: true });
  })
);

export default router;
