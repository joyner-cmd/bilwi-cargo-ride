import { query } from '../../config/db.js';
import { forbidden, notFound } from '../../utils/errors.js';

export const messagesRepo = {
  /** Verifica que el usuario participe en el viaje. Devuelve el viaje. */
  async assertParticipant(tripId, user) {
    const { rows } = await query(
      'SELECT id, client_id, driver_id FROM trips WHERE id = $1',
      [tripId]
    );
    const trip = rows[0];
    if (!trip) throw notFound('Viaje no encontrado');
    if (user.role !== 'admin' && trip.client_id !== user.id && trip.driver_id !== user.id)
      throw forbidden('No participas en este viaje');
    return trip;
  },

  async create({ tripId, senderId, type = 'text', body, lat, lng, imageUrl }) {
    const { rows } = await query(
      `INSERT INTO messages (trip_id, sender_id, type, body, lat, lng, image_url)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [tripId, senderId, type, body ?? null, lat ?? null, lng ?? null, imageUrl ?? null]
    );
    return rows[0];
  },

  async list(tripId, limit = 100) {
    const { rows } = await query(
      `SELECT m.*, u.full_name AS sender_name
         FROM messages m JOIN users u ON u.id = m.sender_id
        WHERE m.trip_id = $1
        ORDER BY m.created_at ASC
        LIMIT $2`,
      [tripId, limit]
    );
    return rows;
  },

  async markRead(tripId, readerId) {
    await query(
      `UPDATE messages SET read_at = now()
        WHERE trip_id = $1 AND sender_id <> $2 AND read_at IS NULL`,
      [tripId, readerId]
    );
  },
};
