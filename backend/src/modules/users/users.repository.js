import { query } from '../../config/db.js';

const PUBLIC_COLUMNS = `id, role, full_name, phone, email, photo_url, status,
                        rating_avg, rating_count, created_at`;

export const usersRepo = {
  async findByPhone(phone) {
    const { rows } = await query('SELECT * FROM users WHERE phone = $1', [phone]);
    return rows[0] || null;
  },

  async findById(id) {
    const { rows } = await query(`SELECT ${PUBLIC_COLUMNS} FROM users WHERE id = $1`, [id]);
    return rows[0] || null;
  },

  async findByIdWithHash(id) {
    const { rows } = await query('SELECT * FROM users WHERE id = $1', [id]);
    return rows[0] || null;
  },

  async create({ role, fullName, phone, email, passwordHash }) {
    const { rows } = await query(
      `INSERT INTO users (role, full_name, phone, email, password_hash)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING ${PUBLIC_COLUMNS}`,
      [role, fullName, phone, email || null, passwordHash]
    );
    return rows[0];
  },

  async updateProfile(id, { fullName, email, photoUrl }) {
    const { rows } = await query(
      `UPDATE users
         SET full_name = COALESCE($2, full_name),
             email     = COALESCE($3, email),
             photo_url = COALESCE($4, photo_url),
             updated_at = now()
       WHERE id = $1
       RETURNING ${PUBLIC_COLUMNS}`,
      [id, fullName ?? null, email ?? null, photoUrl ?? null]
    );
    return rows[0] || null;
  },

  async setPasswordHash(id, passwordHash) {
    await query('UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1', [
      id,
      passwordHash,
    ]);
  },
};
