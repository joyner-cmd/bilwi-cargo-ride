import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { driversRepo } from './drivers.repository.js';

const router = Router();

const availabilitySchema = z.object({ available: z.boolean() });
const locationSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});
const nearbyQuerySchema = z.object({
  lat: z.coerce.number(),
  lng: z.coerce.number(),
  vehicleType: z.string().optional(),
  radiusKm: z.coerce.number().optional(),
});

// Estado del propio conductor
router.get(
  '/me',
  requireAuth,
  requireRole('driver'),
  asyncHandler(async (req, res) => {
    const profile = await driversRepo.getProfile(req.user.id);
    res.json(profile);
  })
);

// Activar / desactivar disponibilidad
router.patch(
  '/me/availability',
  requireAuth,
  requireRole('driver'),
  validate(availabilitySchema),
  asyncHandler(async (req, res) => {
    const profile = await driversRepo.setAvailability(req.user.id, req.body.available);
    res.json(profile);
  })
);

// Actualizar ubicacion (tambien se hace por socket; este es respaldo REST)
router.post(
  '/me/location',
  requireAuth,
  requireRole('driver'),
  validate(locationSchema),
  asyncHandler(async (req, res) => {
    await driversRepo.updateLocation(req.user.id, req.body.lat, req.body.lng);
    res.json({ ok: true });
  })
);

// Conductores cercanos (cliente)
router.get(
  '/nearby',
  requireAuth,
  validate(nearbyQuerySchema, 'query'),
  asyncHandler(async (req, res) => {
    const drivers = await driversRepo.findNearby(req.query);
    res.json({ drivers });
  })
);

export default router;
