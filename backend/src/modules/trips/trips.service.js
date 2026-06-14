import { query } from '../../config/db.js';
import { env } from '../../config/env.js';
import { tripsRepo } from './trips.repository.js';
import { driversRepo } from '../drivers/drivers.repository.js';
import { notificationsRepo } from '../notifications/notifications.repository.js';
import { haversineKm, estimateMinutes } from '../../utils/geo.js';
import { computeFare, surgeForHour, cargoFactorFor } from '../../utils/fares.js';
import { emitToTrip, emitToUser } from '../../realtime/io.js';
import { badRequest, forbidden, notFound, conflict } from '../../utils/errors.js';

async function getServiceType(id) {
  const { rows } = await query('SELECT * FROM service_types WHERE id = $1 AND active = true', [id]);
  if (!rows[0]) throw notFound('Tipo de servicio no disponible');
  return rows[0];
}

export const tripsService = {
  async requestTrip(clientId, body) {
    const st = await getServiceType(body.serviceTypeId);

    const distanceKm = haversineKm(body.originLat, body.originLng, body.destLat, body.destLng);
    const durationMin = estimateMinutes(distanceKm);
    const fareEstimated = computeFare({
      baseFare: Number(st.base_fare),
      perKm: Number(st.per_km),
      perMin: Number(st.per_min),
      minFare: Number(st.min_fare),
      distanceKm,
      durationMin,
      surge: surgeForHour(new Date().getHours()),
      cargoFactor: cargoFactorFor(body.cargoSize),
    });

    const stops = st.allows_stops ? body.stops || [] : [];
    const tripId = await tripsRepo.create(
      {
        clientId,
        serviceTypeId: st.id,
        originLat: body.originLat,
        originLng: body.originLng,
        originAddress: body.originAddress,
        destLat: body.destLat,
        destLng: body.destLng,
        destAddress: body.destAddress,
        distanceKm: Number(distanceKm.toFixed(2)),
        durationMin: Math.round(durationMin),
        cargoSize: body.cargoSize,
        notes: body.notes,
        fareEstimated,
        paymentMethod: body.paymentMethod,
      },
      stops
    );

    const trip = await tripsRepo.findDetailById(tripId);

    // Avisa a conductores cercanos compatibles con el tipo de vehiculo.
    const nearby = await driversRepo.findNearby({
      lat: body.originLat,
      lng: body.originLng,
      vehicleType: st.vehicle_type,
    });
    for (const d of nearby) {
      emitToUser(d.id, 'trip:new', {
        tripId,
        service: st.name,
        origin: body.originAddress,
        dest: body.destAddress,
        distanceKm: trip.distance_km,
        fareEstimated,
        currency: 'NIO',
      });
    }

    return { trip, notifiedDrivers: nearby.length };
  },

  async getDetail(tripId, user) {
    const trip = await tripsRepo.findDetailById(tripId);
    if (!trip) throw notFound('Viaje no encontrado');
    this.assertParticipant(trip, user);
    trip.stops = await tripsRepo.getStops(tripId);
    return trip;
  },

  async accept(tripId, driverId) {
    const trip = await tripsRepo.findDetailById(tripId);
    if (!trip) throw notFound('Viaje no encontrado');
    if (trip.status !== 'requested') throw conflict('El viaje ya fue tomado o cancelado');

    // Vehiculo aprobado del conductor (preferir el tipo del servicio).
    const { rows } = await query(
      `SELECT id FROM vehicles
        WHERE driver_id = $1 AND status = 'approved'
        ORDER BY (type = (SELECT vehicle_type FROM service_types WHERE id = $2)) DESC, created_at
        LIMIT 1`,
      [driverId, trip.service_type_id]
    );
    if (!rows[0]) throw badRequest('No tienes un vehiculo aprobado para aceptar viajes');

    const accepted = await tripsRepo.accept(tripId, driverId, rows[0].id);
    if (!accepted) throw conflict('El viaje ya fue tomado por otro conductor');

    const detail = await tripsRepo.findDetailById(tripId);
    emitToTrip(tripId, 'trip:status', { tripId, status: 'accepted', trip: detail });
    emitToUser(trip.client_id, 'trip:accepted', { tripId, trip: detail });
    await notificationsRepo.create(
      trip.client_id,
      'Conductor en camino',
      `${detail.driver_name} acepto tu solicitud.`,
      { tripId }
    );
    return detail;
  },

  async markArrived(tripId, driverId) {
    const trip = await this.assertAssignedDriver(tripId, driverId, ['accepted']);
    await tripsRepo.setStatus(tripId, 'arrived');
    const detail = await tripsRepo.findDetailById(tripId);
    emitToTrip(tripId, 'trip:status', { tripId, status: 'arrived', trip: detail });
    await notificationsRepo.create(trip.client_id, 'Tu conductor llego', 'El conductor te espera.', {
      tripId,
    });
    return detail;
  },

  async start(tripId, driverId) {
    await this.assertAssignedDriver(tripId, driverId, ['accepted', 'arrived']);
    await tripsRepo.setStatus(tripId, 'in_progress');
    const detail = await tripsRepo.findDetailById(tripId);
    emitToTrip(tripId, 'trip:status', { tripId, status: 'in_progress', trip: detail });
    return detail;
  },

  async complete(tripId, driverId) {
    const trip = await this.assertAssignedDriver(tripId, driverId, ['in_progress', 'arrived']);
    const fareFinal = Number(trip.fare_estimated);
    const commission = Math.round(fareFinal * env.business.platformCommission);

    await tripsRepo.setStatus(tripId, 'completed', { fareFinal });
    await tripsRepo.recordPayment(tripId, fareFinal, commission, trip.payment_method);
    await driversRepo.incrementTrips(driverId);

    const detail = await tripsRepo.findDetailById(tripId);
    emitToTrip(tripId, 'trip:status', { tripId, status: 'completed', trip: detail });
    await notificationsRepo.create(
      trip.client_id,
      'Viaje finalizado',
      `Total: C$${fareFinal}. No olvides calificar.`,
      { tripId }
    );
    return detail;
  },

  async cancel(tripId, user, reason) {
    const trip = await tripsRepo.findDetailById(tripId);
    if (!trip) throw notFound('Viaje no encontrado');
    this.assertParticipant(trip, user);
    if (['completed', 'cancelled'].includes(trip.status))
      throw conflict('El viaje ya finalizo o fue cancelado');

    await tripsRepo.setStatus(tripId, 'cancelled', {
      cancelReason: reason ?? null,
      cancelledBy: user.id,
    });
    const detail = await tripsRepo.findDetailById(tripId);
    emitToTrip(tripId, 'trip:status', { tripId, status: 'cancelled', trip: detail });

    const other = user.id === trip.client_id ? trip.driver_id : trip.client_id;
    if (other) {
      emitToUser(other, 'trip:cancelled', { tripId });
      await notificationsRepo.create(other, 'Viaje cancelado', reason || 'El viaje fue cancelado.', {
        tripId,
      });
    }
    return detail;
  },

  async list(user, status) {
    return tripsRepo.listForUser({ userId: user.id, role: user.role, status });
  },

  // ---- Helpers de autorizacion ----
  assertParticipant(trip, user) {
    if (user.role === 'admin') return;
    if (trip.client_id !== user.id && trip.driver_id !== user.id)
      throw forbidden('No participas en este viaje');
  },

  async assertAssignedDriver(tripId, driverId, allowedStatuses) {
    const trip = await tripsRepo.findDetailById(tripId);
    if (!trip) throw notFound('Viaje no encontrado');
    if (trip.driver_id !== driverId) throw forbidden('No eres el conductor de este viaje');
    if (allowedStatuses && !allowedStatuses.includes(trip.status))
      throw conflict(`Accion no valida en estado "${trip.status}"`);
    return trip;
  },
};
