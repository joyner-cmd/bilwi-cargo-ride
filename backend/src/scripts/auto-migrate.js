/**
 * Migracion automatica al arrancar el servidor.
 * Solo corre cuando AUTO_MIGRATE=true o cuando existe DATABASE_URL (Railway/Render).
 * Idempotente: usa CREATE/DROP/INSERT que pueden repetirse.
 */
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from '../config/db.js';
import { hashPassword } from '../utils/security.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const sqlDir = path.resolve(__dirname, '../../sql');

export async function autoMigrate() {
  const enabled = process.env.AUTO_MIGRATE === 'true' || !!process.env.DATABASE_URL;
  if (!enabled) {
    console.log('[migrate] omitido (defina AUTO_MIGRATE=true para forzar).');
    return;
  }

  console.log('[migrate] verificando esquema...');
  const { rows } = await pool.query(
    "SELECT to_regclass('public.users') AS t"
  );
  const exists = rows[0]?.t !== null;
  if (exists) {
    console.log('[migrate] esquema ya presente, omitido.');
    return;
  }

  console.log('[migrate] aplicando schema.sql + seed.sql + cuentas demo...');
  const schema = await fs.readFile(path.join(sqlDir, 'schema.sql'), 'utf8');
  await pool.query(schema);

  const seed = await fs.readFile(path.join(sqlDir, 'seed.sql'), 'utf8');
  await pool.query(seed);

  const pass = await hashPassword('demo1234');
  for (const u of [
    { role: 'admin', name: 'Admin Bilwi', phone: '+50588880000', email: 'admin@bilwicargo.ni' },
    { role: 'client', name: 'Cliente Demo', phone: '+50588880001', email: 'cliente@bilwicargo.ni' },
    { role: 'driver', name: 'Conductor Demo', phone: '+50588880002', email: 'conductor@bilwicargo.ni' },
  ]) {
    await pool.query(
      `INSERT INTO users (role, full_name, phone, email, password_hash, status)
       VALUES ($1,$2,$3,$4,$5,'active')
       ON CONFLICT (phone) DO NOTHING`,
      [u.role, u.name, u.phone, u.email, pass]
    );
  }

  const { rows: drvRows } = await pool.query(
    "SELECT id FROM users WHERE phone = '+50588880002'"
  );
  const driverId = drvRows[0]?.id;
  if (driverId) {
    await pool.query(
      `INSERT INTO drivers (user_id, license_number, license_verified, id_verified, doc_status,
                            is_available, current_lat, current_lng, last_location_at)
       VALUES ($1,'LIC-DEMO-001',true,true,'approved',true,14.0270,-83.3810, now())
       ON CONFLICT (user_id) DO NOTHING`,
      [driverId]
    );
    await pool.query(
      `INSERT INTO vehicles (driver_id, type, brand, model, year, plate, color, capacity_kg, status)
       SELECT $1,'camioneta','Toyota','Hilux',2018,'M-12345','Blanco',800,'approved'
       WHERE NOT EXISTS (SELECT 1 FROM vehicles WHERE driver_id = $1)`,
      [driverId]
    );
  }

  console.log('[migrate] OK. Cuentas demo creadas (clave: demo1234).');
}
