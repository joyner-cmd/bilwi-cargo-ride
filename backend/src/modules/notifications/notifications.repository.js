import { query } from '../../config/db.js';

export const notificationsRepo = {
  async create(userId, title, body, data = null) {
    const { rows } = await query(
      `INSERT INTO notifications (user_id, title, body, data)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [userId, title, body, data ? JSON.stringify(data) : null]
    );
    return rows[0];
  },

  async listForUser(userId, limit = 30) {
    const { rows } = await query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2',
      [userId, limit]
    );
    return rows;
  },

  async markRead(id, userId) {
    await query('UPDATE notifications SET read_at = now() WHERE id = $1 AND user_id = $2', [
      id,
      userId,
    ]);
  },
};
