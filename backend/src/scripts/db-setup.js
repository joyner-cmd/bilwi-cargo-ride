/**
 * Aplica schema.sql + seed.sql y crea cuentas demo con contrasenas hasheadas.
 *
 *   npm run db:setup
 *
 * Funciona en dos modos:
 *  - LOCAL: usa PGHOST/PGUSER/etc y crea la BD si no existe.
 *  - PRODUCCION: usa DATABASE_URL (Railway/Render). La BD ya existe.
 */
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { env } from '../config/env.js';
import { hashPassword } from '../utils/security.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const sqlDir = path.resolve(__dirname, '../../sql');

const usingUrl = !!process.env.DATABASE_URL;

function makeClient(databaseOverride) {
  if (usingUrl) {
    return new pg.Client({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });
  }
  return new pg.Client({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    database: databaseOverride || env.db.database,
  });
}

async function ensureDatabaseLocal() {
  if (usingUrl) return; // Railway / Render ya entregan la BD lista
  const admin = makeClient('postgres');
  await admin.connect();
  const { rowCount } = await admin.query(
    'SELECT 1 FROM pg_database WHERE datname = $1',
    [env.db.database]
  );
  if (rowCount === 0) {
    await admin.query(`CREATE DATABASE "${env.db.database}"`);
    console.log(`[db] Base de datos "${env.db.database}" creada.`);
  } else {
    console.log(`[db] Base de datos "${env.db.database}" ya existe.`);
  }
  await admin.end();
}

async function run() {
  await ensureDatabaseLocal();

  const db = makeClient();
  await db.connect();

  const schema = await fs.readFile(path.join(sqlDir, 'schema.sql'), 'utf8');
  await db.query(schema);
  console.log('[db] Esquema aplicado.');

  const seed = await fs.readFile(path.join(sqlDir, 'seed.sql'), 'utf8');
  await db.query(seed);
  console.log('[db] Tipos de servicio insertados.');

  const pass = await hashPassword('demo1234');

  const admin = await upsertUser(db, {
    role: 'admin',
    full_name: 'Admin Bilwi',
    phone: '+50588880000',
    email: 'admin@bilwicargo.ni',
    password_hash: pass,
  });

  const client = await upsertUser(db, {
    role: 'client',
    full_name: 'Cliente Demo',
    phone: '+50588880001',
    email: 'cliente@bilwicargo.ni',
    password_hash: pass,
  });

  const driver = await upsertUser(db, {
    role: 'driver',
    full_name: 'Conductor Demo',
    phone: '+50588880002',
    email: 'conductor@bilwicargo.ni',
    password_hash: pass,
  });

  await db.query(
    `INSERT INTO drivers (user_id, license_number, license_verified, id_verified, doc_status,
                          is_available, current_lat, current_lng, last_location_at)
     VALUES ($1,'LIC-DEMO-001',true,true,'approved',true,14.0270,-83.3810, now())
     ON CONFLICT (user_id) DO UPDATE SET is_available = EXCLUDED.is_available`,
    [driver.id]
  );

  await db.query(
    `INSERT INTO vehicles (driver_id, type, brand, model, year, plate, color, capacity_kg, status)
     SELECT $1,'camioneta','Toyota','Hilux',2018,'M-12345','Blanco',800,'approved'
     WHERE NOT EXISTS (SELECT 1 FROM vehicles WHERE driver_id = $1)`,
    [driver.id]
  );

  console.log('\n[db] Listo. Cuentas demo (contrasena: demo1234):');
  console.table([
    { rol: 'admin', telefono: '+50588880000' },
    { rol: 'cliente', telefono: '+50588880001' },
    { rol: 'conductor', telefono: '+50588880002' },
  ]);
  // Evita variables sin usar
  void admin;
  void client;

  await db.end();
}

async function upsertUser(db, u) {
  const { rows } = await db.query(
    `INSERT INTO users (role, full_name, phone, email, password_hash, status)
     VALUES ($1,$2,$3,$4,$5,'active')
     ON CONFLICT (phone) DO UPDATE SET full_name = EXCLUDED.full_name
     RETURNING id`,
    [u.role, u.full_name, u.phone, u.email, u.password_hash]
  );
  return rows[0];
}

run().catch((err) => {
  console.error('[db] Error en setup:', err);
  process.exit(1);
});
