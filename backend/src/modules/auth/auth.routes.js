import { Router } from 'express';
import { z } from 'zod';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { authService } from './auth.service.js';

const router = Router();

const registerSchema = z.object({
  role: z.enum(['client', 'driver']),
  fullName: z.string().min(3).max(120),
  phone: z.string().min(8).max(20),
  email: z.string().email().optional(),
  password: z.string().min(6).max(72),
});

const loginSchema = z.object({
  phone: z.string().min(8).max(20),
  password: z.string().min(1),
});

router.post(
  '/register',
  validate(registerSchema),
  asyncHandler(async (req, res) => {
    const result = await authService.register(req.body);
    res.status(201).json(result);
  })
);

router.post(
  '/login',
  validate(loginSchema),
  asyncHandler(async (req, res) => {
    const result = await authService.login(req.body);
    res.json(result);
  })
);

export default router;
