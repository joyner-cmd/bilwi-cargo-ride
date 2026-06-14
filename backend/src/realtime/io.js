/**
 * Puente entre la capa REST y Socket.io.
 * socket.js registra la instancia; los servicios emiten sin acoplarse a socket.io.
 */
let io = null;

export const setIo = (instance) => {
  io = instance;
};

export const roomForTrip = (tripId) => `trip:${tripId}`;
export const roomForUser = (userId) => `user:${userId}`;

export function emitToTrip(tripId, event, data) {
  if (io) io.to(roomForTrip(tripId)).emit(event, data);
}

export function emitToUser(userId, event, data) {
  if (io) io.to(roomForUser(userId)).emit(event, data);
}
