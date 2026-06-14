# Bilwi Cargo & Ride - API
# Imagen ligera y rapida. Railway usa este Dockerfile automaticamente.
FROM node:20-alpine

WORKDIR /app

# Cache de dependencias
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund

# Copia el resto del codigo
COPY src ./src
COPY sql ./sql

ENV NODE_ENV=production
ENV PORT=4000
EXPOSE 4000

# Railway: AUTO_MIGRATE=true para aplicar schema y seed en el primer arranque
CMD ["node", "src/server.js"]
