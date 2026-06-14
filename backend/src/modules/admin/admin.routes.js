import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { query } from '../../config/db.js';

const router = Router();
router.use(requireAuth, requireRole('admin'));

// Metricas rapidas para el dashboard
router.get(
  '/metrics',
  asyncHandler(async (_req, res) => {
    const [{ rows: u }, { rows: t }, { rows: rev }] = await Promise.all([
      query(`SELECT
                count(*) FILTER (WHERE role='client')  AS clients,
                count(*) FILTER (WHERE role='driver')  AS drivers,
                count(*) FILTER (WHERE status='suspended') AS suspended
              FROM users`),
      query(`SELECT
                count(*)                                  AS total,
                count(*) FILTER (WHERE status='completed') AS completed,
                count(*) FILTER (WHERE status='cancelled') AS cancelled,
                count(*) FILTER (WHERE status NOT IN ('completed','cancelled')) AS active
              FROM trips`),
      query(`SELECT COALESCE(sum(amount),0) AS gross, COALESCE(sum(commission),0) AS commission
               FROM payments WHERE status='paid'`),
    ]);
    res.json({ users: u[0], trips: t[0], revenue: rev[0] });
  })
);

// Usuarios
router.get(
  '/users',
  asyncHandler(async (req, res) => {
    const role = req.query.role;
    const { rows } = await query(
      `SELECT id, role, full_name, phone, email, status, rating_avg, created_at
         FROM users
        WHERE ($1::text IS NULL OR role = $1)
        ORDER BY created_at DESC LIMIT 200`,
      [role || null]
    );
    res.json({ users: rows });
  })
);

router.patch(
  '/users/:id/status',
  validate(z.object({ status: z.enum(['active', 'suspended']) })),
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      'UPDATE users SET status = $2 WHERE id = $1 RETURNING id, status',
      [Number(req.params.id), req.body.status]
    );
    res.json(rows[0]);
  })
);

// Vehiculos pendientes / aprobacion
router.get(
  '/vehicles',
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      `SELECT v.*, u.full_name AS driver_name
         FROM vehicles v JOIN users u ON u.id = v.driver_id
        WHERE ($1::text IS NULL OR v.status = $1)
        ORDER BY v.created_at DESC LIMIT 200`,
      [req.query.status || null]
    );
    res.json({ vehicles: rows });
  })
);

router.patch(
  '/vehicles/:id/status',
  validate(z.object({ status: z.enum(['approved', 'rejected', 'pending']) })),
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      'UPDATE vehicles SET status = $2 WHERE id = $1 RETURNING id, status',
      [Number(req.params.id), req.body.status]
    );
    res.json(rows[0]);
  })
);

// Documentos de conductores
router.patch(
  '/documents/:id/status',
  validate(z.object({ status: z.enum(['approved', 'rejected', 'pending']), notes: z.string().optional() })),
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      `UPDATE driver_documents SET status = $2, reviewed_by = $3, notes = $4
        WHERE id = $1 RETURNING *`,
      [Number(req.params.id), req.body.status, req.user.id, req.body.notes ?? null]
    );
    res.json(rows[0]);
  })
);

export default router;
