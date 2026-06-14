import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { messagesRepo } from './messages.repository.js';
import { emitToTrip } from '../../realtime/io.js';

const router = Router();

const sendSchema = z.object({
  type: z.enum(['text', 'location', 'image']).default('text'),
  body: z.string().max(1000).optional(),
  lat: z.number().optional(),
  lng: z.number().optional(),
  imageUrl: z.string().url().optional(),
});

// Historial del chat de un viaje
router.get(
  '/:tripId',
  requireAuth,
  asyncHandler(async (req, res) => {
    const tripId = Number(req.params.tripId);
    await messagesRepo.assertParticipant(tripId, req.user);
    await messagesRepo.markRead(tripId, req.user.id);
    res.json({ messages: await messagesRepo.list(tripId) });
  })
);

// Enviar mensaje (tambien disponible por socket)
router.post(
  '/:tripId',
  requireAuth,
  validate(sendSchema),
  asyncHandler(async (req, res) => {
    const tripId = Number(req.params.tripId);
    await messagesRepo.assertParticipant(tripId, req.user);
    const msg = await messagesRepo.create({ tripId, senderId: req.user.id, ...req.body });
    emitToTrip(tripId, 'chat:message', msg);
    res.status(201).json(msg);
  })
);

export default router;
