import { query } from '../../config/db.js';
import { env } from '../../config/env.js';

export const driversRepo = {
  async ensureProfile(userId) {
    await query(
      `INSERT INTO drivers (user_id) VALUES ($1)
       ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );
  },

  async getProfile(userId) {
    const { rows } = await query('SELECT * FROM drivers WHERE user_id = $1', [userId]);
    return rows[0] || null;
  },

  async setAvailability(userId, isAvailable) {
    const { rows } = await query(
      `UPDATE drivers SET is_available = $2 WHERE user_id = $1 RETURNING *`,
      [userId, isAvailable]
    );
    return rows[0] || null;
  },

  async updateLocation(userId, lat, lng) {
    await query(
      `UPDATE drivers
         SET current_lat = $2, current_lng = $3, last_location_at = now()
       WHERE user_id = $1`,
      [userId, lat, lng]
    );
  },

  /**
   * Conductores disponibles dentro del radio, ordenados por cercania.
   * Filtra por tipo de vehiculo si se indica. Usa Haversine en SQL.
   */
  async findNearby({ lat, lng, vehicleType, radiusKm = env.business.nearbyRadiusKm, limit = 20 }) {
    const { rows } = await query(
      `SELECT * FROM (
         SELECT u.id, u.full_name, u.photo_url, u.rating_avg, u.rating_count,
                d.current_lat, d.current_lng, d.last_location_at,
                v.id AS vehicle_id, v.type AS vehicle_type, v.brand, v.model,
                v.plate, v.color, v.capacity_kg,
                (6371 * acos(
                   least(1, greatest(-1,
                     cos(radians($1)) * cos(radians(d.current_lat)) *
                     cos(radians(d.current_lng) - radians($2)) +
                     sin(radians($1)) * sin(radians(d.current_lat))
                   ))
                )) AS distance_km
           FROM drivers d
           JOIN users u ON u.id = d.user_id AND u.status = 'active'
           JOIN vehicles v ON v.driver_id = d.user_id AND v.status = 'approved'
          WHERE d.is_available = true
            AND d.current_lat IS NOT NULL
            AND ($3::text IS NULL OR v.type = $3)
       ) t
       WHERE t.distance_km <= $4
       ORDER BY t.distance_km ASC
       LIMIT $5`,
      [lat, lng, vehicleType || null, radiusKm, limit]
    );
    return rows;
  },

  async incrementTrips(userId) {
    await query('UPDATE drivers SET total_trips = total_trips + 1 WHERE user_id = $1', [userId]);
  },
};
