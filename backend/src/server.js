import http from 'node:http';
import { createApp } from './app.js';
import { initSocket } from './realtime/socket.js';
import { env } from './config/env.js';
import { pool } from './config/db.js';
import { autoMigrate } from './scripts/auto-migrate.js';

async function bootstrap() {
  try {
    await autoMigrate();
  } catch (err) {
    console.error('[boot] error en migracion automatica:', err);
    // No detenemos el arranque: la migracion puede fallar si ya esta aplicada
  }

  const app = createApp();
  const server = http.createServer(app);
  initSocket(server, env.corsOrigin);

  server.listen(env.port, '0.0.0.0', () => {
    console.log(`\n  Bilwi Cargo & Ride API`);
    console.log(`  -> http://localhost:${env.port}/api/health`);
    console.log(`  -> entorno: ${env.nodeEnv}\n`);
  });

  const shutdown = async (signal) => {
    console.log(`\n[${signal}] cerrando servidor...`);
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

bootstrap();
