import pg from 'pg';
import { env } from './env.js';

/**
 * Pool unico reutilizado en toda la app.
 *
 * - En produccion (Railway/Render/Heroku) toma `DATABASE_URL` y habilita SSL.
 * - En desarrollo usa PGHOST/PGUSER/etc. del .env local.
 */
const usingUrl = !!process.env.DATABASE_URL;

export const pool = new pg.Pool(
  usingUrl
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
        max: 10,
        idleTimeoutMillis: 30000,
      }
    : {
        host: env.db.host,
        port: env.db.port,
        user: env.db.user,
        password: env.db.password,
        database: env.db.database,
        max: 10,
        idleTimeoutMillis: 30000,
      }
);

pool.on('error', (err) => {
  console.error('[db] error inesperado en cliente idle', err);
});

/** Ejecuta una consulta y devuelve filas. */
export const query = (text, params) => pool.query(text, params);

/** Ejecuta un callback dentro de una transaccion. */
export async function withTransaction(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
