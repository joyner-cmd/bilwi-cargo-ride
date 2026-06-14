import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/async.js';
import { withTransaction, query } from '../../config/db.js';
import { badRequest, forbidden, notFound, conflict } from '../../utils/errors.js';

const router = Router();

const ratingSchema = z.object({
  tripId: z.coerce.number().int(),
  stars: z.coerce.number().int().min(1).max(5),
  comment: z.string().max(500).optional(),
});

// Calificar al otro participante de un viaje completado
router.post(
  '/',
  requireAuth,
  validate(ratingSchema),
  asyncHandler(async (req, res) => {
    const { tripId, stars, comment } = req.body;
    const { rows } = await query('SELECT * FROM trips WHERE id = $1', [tripId]);
    const trip = rows[0];
    if (!trip) throw notFound('Viaje no encontrado');
    if (trip.status !== 'completed') throw badRequest('Solo se califican viajes completados');

    const raterId = req.user.id;
    let rateeId;
    if (raterId === trip.client_id) rateeId = trip.driver_id;
    else if (raterId === trip.driver_id) rateeId = trip.client_id;
    else throw forbidden('No participaste en este viaje');
    if (!rateeId) throw badRequest('El viaje no tiene contraparte para calificar');

    try {
      const rating = await withTransaction(async (client) => {
        const ins = await client.query(
          `INSERT INTO ratings (trip_id, rater_id, ratee_id, stars, comment)
           VALUES ($1,$2,$3,$4,$5) RETURNING *`,
          [tripId, raterId, rateeId, stars, comment ?? null]
        );
        // Recalcula promedio del calificado
        await client.query(
          `UPDATE users u SET
             rating_count = sub.cnt,
             rating_avg   = sub.avg
           FROM (SELECT count(*) AS cnt, COALESCE(avg(stars),0) AS avg
                   FROM ratings WHERE ratee_id = $1) sub
           WHERE u.id = $1`,
          [rateeId]
        );
        return ins.rows[0];
      });
      res.status(201).json(rating);
    } catch (err) {
      if (err.code === '23505') throw conflict('Ya calificaste este viaje');
      throw err;
    }
  })
);

export default router;
