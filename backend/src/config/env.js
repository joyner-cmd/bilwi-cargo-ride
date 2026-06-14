import dotenv from 'dotenv';
dotenv.config();

const num = (v, def) => (v === undefined ? def : Number(v));

export const env = {
  port: num(process.env.PORT, 4000),
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || '*',

  db: {
    host: process.env.PGHOST || 'localhost',
    port: num(process.env.PGPORT, 5432),
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || 'postgres',
    database: process.env.PGDATABASE || 'bilwi_cargo',
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  },

  business: {
    nearbyRadiusKm: num(process.env.NEARBY_RADIUS_KM, 8),
    platformCommission: num(process.env.PLATFORM_COMMISSION, 0.15),
  },
};

export const isProd = env.nodeEnv === 'production';
