import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { query } from '../../config/db.js';
import { haversineKm, estimateMinutes } from '../../utils/geo.js';
import { computeFare, surgeForHour, cargoFactorFor } from '../../utils/fares.js';
import { notFound } from '../../utils/errors.js';

const router = Router();

// Catalogo de tipos de servicio activos
router.get(
  '/',
  asyncHandler(async (_req, res) => {
    const { rows } = await query(
      `SELECT id, code, name, description, vehicle_type, base_fare, per_km, per_min,
              min_fare, allows_stops
         FROM service_types WHERE active = true ORDER BY sort_order`
    );
    res.json({ services: rows });
  })
);

const quoteSchema = z.object({
  serviceTypeId: z.coerce.number().int(),
  originLat: z.number(),
  originLng: z.number(),
  destLat: z.number(),
  destLng: z.number(),
  cargoSize: z.enum(['small', 'medium', 'large', 'xlarge']).optional(),
});

// Cotizacion previa de tarifa (sin crear viaje)
router.post(
  '/quote',
  requireAuth,
  validate(quoteSchema),
  asyncHandler(async (req, res) => {
    const b = req.body;
    const { rows } = await query('SELECT * FROM service_types WHERE id = $1', [b.serviceTypeId]);
    const st = rows[0];
    if (!st) throw notFound('Tipo de servicio no encontrado');

    const distanceKm = haversineKm(b.originLat, b.originLng, b.destLat, b.destLng);
    const durationMin = estimateMinutes(distanceKm);
    const surge = surgeForHour(new Date().getHours());
    const cargoFactor = cargoFactorFor(b.cargoSize);

    const fare = computeFare({
      baseFare: Number(st.base_fare),
      perKm: Number(st.per_km),
      perMin: Number(st.per_min),
      minFare: Number(st.min_fare),
      distanceKm,
      durationMin,
      surge,
      cargoFactor,
    });

    res.json({
      serviceType: { id: st.id, code: st.code, name: st.name },
      distanceKm: Number(distanceKm.toFixed(2)),
      durationMin: Math.round(durationMin),
      surge,
      currency: 'NIO',
      fareMin: Number(st.min_fare),
      fareEstimated: fare,
    });
  })
);

export default router;
