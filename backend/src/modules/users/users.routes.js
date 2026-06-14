import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { usersRepo } from './users.repository.js';
import { hashPassword, verifyPassword } from '../../utils/security.js';
import { badRequest, notFound } from '../../utils/errors.js';

const router = Router();

const updateSchema = z.object({
  fullName: z.string().min(3).max(120).optional(),
  email: z.string().email().optional(),
  photoUrl: z.string().url().optional(),
});

const passwordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6).max(72),
});

router.get(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const user = await usersRepo.findById(req.user.id);
    if (!user) throw notFound('Usuario no encontrado');
    res.json(user);
  })
);

router.patch(
  '/me',
  requireAuth,
  validate(updateSchema),
  asyncHandler(async (req, res) => {
    const user = await usersRepo.updateProfile(req.user.id, req.body);
    res.json(user);
  })
);

router.post(
  '/me/password',
  requireAuth,
  validate(passwordSchema),
  asyncHandler(async (req, res) => {
    const record = await usersRepo.findByIdWithHash(req.user.id);
    const ok = await verifyPassword(req.body.currentPassword, record.password_hash);
    if (!ok) throw badRequest('Contrasena actual incorrecta');
    await usersRepo.setPasswordHash(req.user.id, await hashPassword(req.body.newPassword));
    res.json({ ok: true });
  })
);

export default router;
