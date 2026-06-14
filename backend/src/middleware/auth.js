import { verifyToken } from '../utils/security.js';
import { unauthorized, forbidden } from '../utils/errors.js';

/** Exige un JWT valido. Coloca { id, role } en req.user. */
export function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(unauthorized('Falta token de acceso'));
  try {
    const payload = verifyToken(token);
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch {
    next(unauthorized('Token invalido o expirado'));
  }
}

/** Restringe a ciertos roles. Uso: requireRole('admin'), requireRole('driver','admin'). */
export function requireRole(...roles) {
  return (req, _res, next) => {
    if (!req.user) return next(unauthorized());
    if (!roles.includes(req.user.role)) return next(forbidden('Rol no permitido'));
    next();
  };
}
