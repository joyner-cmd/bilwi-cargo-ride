import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { tripsService } from './trips.service.js';

const router = Router();

const stopSchema = z.object({
  lat: z.number(),
  lng: z.number(),
  address: z.string().optional(),
});

const requestSchema = z.object({
  serviceTypeId: z.coerce.number().int(),
  originLat: z.number(),
  originLng: z.number(),
  originAddress: z.string().optional(),
  destLat: z.number(),
  destLng: z.number(),
  destAddress: z.string().optional(),
  cargoSize: z.enum(['small', 'medium', 'large', 'xlarge']).optional(),
  notes: z.string().max(500).optional(),
  paymentMethod: z.enum(['cash', 'transfer', 'mobile', 'card']).optional(),
  stops: z.array(stopSchema).max(5).optional(),
});

const cancelSchema = z.object({ reason: z.string().max(300).optional() });

// Crear solicitud (cliente)
router.post(
  '/',
  requireAuth,
  requireRole('client'),
  validate(requestSchema),
  asyncHandler(async (req, res) => {
    const result = await tripsService.requestTrip(req.user.id, req.body);
    res.status(201).json(result);
  })
);

// Historial / lista
router.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const trips = await tripsService.list(req.user, req.query.status);
    res.json({ trips });
  })
);

// Detalle
router.get(
  '/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    const trip = await tripsService.getDetail(Number(req.params.id), req.user);
    res.json(trip);
  })
);

// Transiciones del conductor
router.post(
  '/:id/accept',
  requireAuth,
  requireRole('driver'),
  asyncHandler(async (req, res) => {
    res.json(await tripsService.accept(Number(req.params.id), req.user.id));
  })
);

router.post(
  '/:id/arrived',
  requireAuth,
  requireRole('driver'),
  asyncHandler(async (req, res) => {
    res.json(await tripsService.markArrived(Number(req.params.id), req.user.id));
  })
);

router.post(
  '/:id/start',
  requireAuth,
  requireRole('driver'),
  asyncHandler(async (req, res) => {
    res.json(await tripsService.start(Number(req.params.id), req.user.id));
  })
);

router.post(
  '/:id/complete',
  requireAuth,
  requireRole('driver'),
  asyncHandler(async (req, res) => {
    res.json(await tripsService.complete(Number(req.params.id), req.user.id));
  })
);

// Cancelar (cliente o conductor)
router.post(
  '/:id/cancel',
  requireAuth,
  validate(cancelSchema),
  asyncHandler(async (req, res) => {
    res.json(await tripsService.cancel(Number(req.params.id), req.user, req.body.reason));
  })
);

export default router;
