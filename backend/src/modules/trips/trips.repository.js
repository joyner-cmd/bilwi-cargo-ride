import { query, withTransaction } from '../../config/db.js';

const DETAIL_SELECT = `
  t.*,
  st.code  AS service_code,
  st.name  AS service_name,
  cu.full_name AS client_name, cu.phone AS client_phone, cu.photo_url AS client_photo,
  cu.rating_avg AS client_rating,
  du.full_name AS driver_name, du.phone AS driver_phone, du.photo_url AS driver_photo,
  du.rating_avg AS driver_rating,
  v.type AS vehicle_type, v.brand AS vehicle_brand, v.model AS vehicle_model,
  v.plate AS vehicle_plate, v.color AS vehicle_color
`;

const DETAIL_FROM = `
  FROM trips t
  JOIN service_types st ON st.id = t.service_type_id
  JOIN users cu ON cu.id = t.client_id
  LEFT JOIN users du ON du.id = t.driver_id
  LEFT JOIN vehicles v ON v.id = t.vehicle_id
`;

export const tripsRepo = {
  async create(data, stops = []) {
    return withTransaction(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO trips
           (client_id, service_type_id, status, origin_lat, origin_lng, origin_address,
            dest_lat, dest_lng, dest_address, distance_km, duration_min, cargo_size,
            notes, fare_estimated, payment_method)
         VALUES ($1,$2,'requested',$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
         RETURNING id`,
        [
          data.clientId,
          data.serviceTypeId,
          data.originLat,
          data.originLng,
          data.originAddress ?? null,
          data.destLat,
          data.destLng,
          data.destAddress ?? null,
          data.distanceKm,
          data.durationMin,
          data.cargoSize ?? null,
          data.notes ?? null,
          data.fareEstimated,
          data.paymentMethod ?? 'cash',
        ]
      );
      const tripId = rows[0].id;

      for (let i = 0; i < stops.length; i++) {
        const s = stops[i];
        await client.query(
          `INSERT INTO trip_stops (trip_id, seq, lat, lng, address) VALUES ($1,$2,$3,$4,$5)`,
          [tripId, i + 1, s.lat, s.lng, s.address ?? null]
        );
      }
      return tripId;
    });
  },

  async findDetailById(id) {
    const { rows } = await query(`SELECT ${DETAIL_SELECT} ${DETAIL_FROM} WHERE t.id = $1`, [id]);
    return rows[0] || null;
  },

  async listForUser({ userId, role, status, limit = 30 }) {
    const col = role === 'driver' ? 't.driver_id' : 't.client_id';
    const params = [userId, limit];
    let where = `${col} = $1`;
    if (status) {
      params.splice(1, 0, status);
      where += ` AND t.status = $2`;
    }
    const limitParam = `$${params.length}`;
    const { rows } = await query(
      `SELECT ${DETAIL_SELECT} ${DETAIL_FROM}
        WHERE ${where}
        ORDER BY t.requested_at DESC
        LIMIT ${limitParam}`,
      params
    );
    return rows;
  },

  async getStops(tripId) {
    const { rows } = await query(
      'SELECT seq, lat, lng, address FROM trip_stops WHERE trip_id = $1 ORDER BY seq',
      [tripId]
    );
    return rows;
  },

  /** Acepta el viaje de forma atomica solo si sigue 'requested' (evita doble asignacion). */
  async accept(tripId, driverId, vehicleId) {
    const { rows } = await query(
      `UPDATE trips
          SET driver_id = $2, vehicle_id = $3, status = 'accepted', accepted_at = now()
        WHERE id = $1 AND status = 'requested'
        RETURNING id`,
      [tripId, driverId, vehicleId]
    );
    return rows[0] || null;
  },

  async setStatus(tripId, status, extra = {}) {
    const stampCol = {
      arrived: 'arrived_at',
      in_progress: 'started_at',
      completed: 'completed_at',
      cancelled: 'cancelled_at',
    }[status];
    const sets = [`status = $2`];
    const params = [tripId, status];
    if (stampCol) sets.push(`${stampCol} = now()`);
    if (extra.fareFinal !== undefined) {
      params.push(extra.fareFinal);
      sets.push(`fare_final = $${params.length}`);
    }
    if (extra.cancelReason !== undefined) {
      params.push(extra.cancelReason);
      sets.push(`cancel_reason = $${params.length}`);
    }
    if (extra.cancelledBy !== undefined) {
      params.push(extra.cancelledBy);
      sets.push(`cancelled_by = $${params.length}`);
    }
    const { rows } = await query(
      `UPDATE trips SET ${sets.join(', ')} WHERE id = $1 RETURNING id`,
      params
    );
    return rows[0] || null;
  },

  async recordPayment(tripId, amount, commission, method) {
    await query(
      `INSERT INTO payments (trip_id, amount, commission, method, status)
       VALUES ($1,$2,$3,$4,'paid')`,
      [tripId, amount, commission, method]
    );
  },
};
