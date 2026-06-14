import { Server } from 'socket.io';
import { verifyToken } from '../utils/security.js';
import { setIo, roomForUser, roomForTrip, emitToTrip } from './io.js';
import { driversRepo } from '../modules/drivers/drivers.repository.js';
import { messagesRepo } from '../modules/messages/messages.repository.js';
import { query } from '../config/db.js';

export function initSocket(httpServer, corsOrigin) {
  const io = new Server(httpServer, {
    cors: { origin: corsOrigin === '*' ? true : corsOrigin.split(','), credentials: true },
  });
  setIo(io);

  // Autenticacion por token en el handshake
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('No autorizado'));
    try {
      const payload = verifyToken(token);
      socket.user = { id: payload.sub, role: payload.role };
      next();
    } catch {
      next(new Error('Token invalido'));
    }
  });

  io.on('connection', (socket) => {
    const { id: userId, role } = socket.user;
    socket.join(roomForUser(userId)); // sala personal para notificaciones directas

    // Unirse a la sala de un viaje (cliente y conductor)
    socket.on('trip:join', (tripId) => socket.join(roomForTrip(tripId)));
    socket.on('trip:leave', (tripId) => socket.leave(roomForTrip(tripId)));

    // Conductor transmite su ubicacion -> se persiste y se reenvia al viaje
    socket.on('driver:location', async ({ lat, lng, tripId }) => {
      if (role !== 'driver') return;
      try {
        await driversRepo.updateLocation(userId, lat, lng);
        if (tripId) {
          await query(
            'INSERT INTO trip_locations (trip_id, lat, lng) VALUES ($1,$2,$3)',
            [tripId, lat, lng]
          );
          emitToTrip(tripId, 'driver:location', { tripId, lat, lng, at: Date.now() });
        }
      } catch (err) {
        socket.emit('error:event', { event: 'driver:location', message: String(err.message) });
      }
    });

    // Chat en tiempo real
    socket.on('chat:send', async ({ tripId, type = 'text', body, lat, lng, imageUrl }, ack) => {
      try {
        await messagesRepo.assertParticipant(tripId, socket.user);
        const msg = await messagesRepo.create({
          tripId,
          senderId: userId,
          type,
          body,
          lat,
          lng,
          imageUrl,
        });
        emitToTrip(tripId, 'chat:message', msg);
        if (typeof ack === 'function') ack({ ok: true, message: msg });
      } catch (err) {
        if (typeof ack === 'function') ack({ ok: false, error: String(err.message) });
      }
    });

    // Indicador de lectura
    socket.on('chat:read', async ({ tripId }) => {
      try {
        await messagesRepo.markRead(tripId, userId);
        emitToTrip(tripId, 'chat:read', { tripId, by: userId });
      } catch {
        /* noop */
      }
    });
  });

  return io;
}
