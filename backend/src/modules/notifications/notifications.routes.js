import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { asyncHandler } from '../../utils/async.js';
import { notificationsRepo } from './notifications.repository.js';

const router = Router();

router.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    res.json({ notifications: await notificationsRepo.listForUser(req.user.id) });
  })
);

router.post(
  '/:id/read',
  requireAuth,
  asyncHandler(async (req, res) => {
    await notificationsRepo.markRead(Number(req.params.id), req.user.id);
    res.json({ ok: true });
  })
);

export default router;
