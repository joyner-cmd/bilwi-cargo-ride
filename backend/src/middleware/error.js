import { AppError } from '../utils/errors.js';
import { isProd } from '../config/env.js';

export function notFoundHandler(_req, res) {
  res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ruta no encontrada' } });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, _req, res, _next) {
  if (err instanceof AppError) {
    return res.status(err.status).json({ error: { code: err.code, message: err.message } });
  }
  // Violacion de unicidad de Postgres
  if (err && err.code === '23505') {
    return res.status(409).json({ error: { code: 'CONFLICT', message: 'El registro ya existe' } });
  }
  console.error('[error]', err);
  res.status(500).json({
    error: {
      code: 'INTERNAL',
      message: 'Error interno del servidor',
      ...(isProd ? {} : { detail: String(err.message || err) }),
    },
  });
}
