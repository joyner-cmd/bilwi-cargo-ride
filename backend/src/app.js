import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';

import { env, isProd } from './config/env.js';
import { notFoundHandler, errorHandler } from './middleware/error.js';

import authRoutes from './modules/auth/auth.routes.js';
import usersRoutes from './modules/users/users.routes.js';
import driversRoutes from './modules/drivers/drivers.routes.js';
import vehiclesRoutes from './modules/vehicles/vehicles.routes.js';
import servicesRoutes from './modules/services/services.routes.js';
import tripsRoutes from './modules/trips/trips.routes.js';
import ratingsRoutes from './modules/ratings/ratings.routes.js';
import messagesRoutes from './modules/messages/messages.routes.js';
import incidentsRoutes from './modules/incidents/incidents.routes.js';
import notificationsRoutes from './modules/notifications/notifications.routes.js';
import adminRoutes from './modules/admin/admin.routes.js';
import uploadsRoutes from './modules/uploads/uploads.routes.js';

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(compression()); // menor consumo de datos (clave para Bilwi)
  app.use(
    cors({
      origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(','),
      credentials: true,
    })
  );
  app.use(express.json({ limit: '6mb' })); // las imagenes en base64 pesan
  app.use(morgan(isProd ? 'combined' : 'dev'));

  // Rate limit basico en auth para frenar fuerza bruta
  app.use('/api/auth', rateLimit({ windowMs: 15 * 60 * 1000, max: 50 }));

  app.get('/api/health', (_req, res) =>
    res.json({ status: 'ok', service: 'bilwi-cargo-ride', time: new Date().toISOString() })
  );

  app.use('/api/auth', authRoutes);
  app.use('/api/users', usersRoutes);
  app.use('/api/drivers', driversRoutes);
  app.use('/api/vehicles', vehiclesRoutes);
  app.use('/api/services', servicesRoutes);
  app.use('/api/trips', tripsRoutes);
  app.use('/api/ratings', ratingsRoutes);
  app.use('/api/messages', messagesRoutes);
  app.use('/api/incidents', incidentsRoutes);
  app.use('/api/notifications', notificationsRoutes);
  app.use('/api/admin', adminRoutes);
  app.use('/api/uploads', uploadsRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
