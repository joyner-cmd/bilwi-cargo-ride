# Monetización y despliegue

## Estrategia de monetización
1. **Comisión por viaje (15%)** — se aplica automáticamente al completar el viaje (configurable en `.env` con `PLATFORM_COMMISSION`).
2. **Tarifa nocturna y de hora pico** — 1.2x–1.25x según hora (incluido en `surgeForHour`).
3. **Recargo por carga grande** — 1.2x medium, 1.5x large, 2x xlarge.
4. **Plan conductor PRO** — pago mensual fijo para conductores que prefieren no pagar comisión por viaje (módulo futuro: `subscriptions`).
5. **Publicidad local in-app** — banners de ferreterías y mueblerías en la pantalla de inicio del cliente.
6. **Acuerdos con empresas** — tarifas corporativas para ferreterías y distribuidores ("Comercial").

## Plan de despliegue

### Backend (producción)
1. Servidor VPS (DigitalOcean, Vultr, o similar) con Ubuntu 22.04 — 2 GB RAM suficiente para empezar.
2. Instala Node 18+, PostgreSQL 16, Nginx, certbot.
3. Clona el repo, copia `.env.example` → `.env` con valores reales (cambia `JWT_SECRET`).
4. `npm install --production && npm run db:setup`.
5. Usa **pm2** para mantener el proceso vivo: `pm2 start src/server.js --name bilwi-api`.
6. Nginx como reverse proxy a `localhost:4000`, con HTTPS gratis (Let's Encrypt).
7. Apunta `api.bilwicargo.ni` al servidor.

### App móvil (producción)
1. Cambia `apiHost` en `mobile/lib/core/config/app_config.dart` a `api.bilwicargo.ni`.
2. **Quita** `usesCleartextTraffic="true"` del manifest cuando uses HTTPS.
3. Genera un keystore propio:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
4. Configura `key.properties` en `android/` (Flutter doc oficial).
5. `flutter build appbundle --release` → sube `.aab` a Google Play Console.

### App alternativa: APK directo
Para distribuirla sin Play Store (al inicio):
- `flutter build apk --release --split-per-abi` genera APKs más pequeños (≈9 MB por ABI).
- Sube el APK a una web/CDN propia y comparte el link por WhatsApp.

## Hoja de ruta sugerida (post-MVP)
1. Firebase Cloud Messaging (notificaciones push fuera de la app).
2. Pagos en línea con BAC/Banpro/Lafise.
3. Verificación de documentos por OCR.
4. Panel administrativo web (React/Next) consumiendo `/api/admin/*`.
5. Módulo IA: predicción de demanda y rutas óptimas con OSRM.
