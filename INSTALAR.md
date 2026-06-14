# Bilwi Cargo & Ride — Instalar y usar

## 🎯 Versión final (cloud)

El APK ya está conectado al servidor en **Railway**. No depende de tu PC, no
hay IP que cambiar, no hay backend que arrancar. Solo instálalo y úsalo.

**APK:** `dist/BilwiCargoRide-v1.0.1-cloud.apk` (~24 MB)
**API pública:** https://bilwi-cargo-ride-production.up.railway.app
**Repo:** https://github.com/joyner-cmd/bilwi-cargo-ride

## 📲 Cómo instalarlo

1. Copia `BilwiCargoRide-v1.0.1-cloud.apk` al teléfono (USB, WhatsApp, Drive).
2. Ábrelo en el teléfono. Android pide permiso "Instalar de fuentes desconocidas" → **Permitir**.
3. Toca **Instalar**.
4. Aparece el ícono **Bilwi Cargo & Ride** → ábrelo.

> Si Play Protect avisa "no se reconoce", toca **Instalar de todos modos**. Es normal porque el APK no pasó por Play Store (puedes subirlo cuando quieras).

## 👤 Cuentas demo

| Rol       | Teléfono       | Contraseña |
|-----------|----------------|------------|
| Cliente   | `+50588880001` | `demo1234` |
| Conductor | `+50588880002` | `demo1234` |
| Admin     | `+50588880000` | `demo1234` |

En la pantalla de login hay 2 chips: **"Cliente"** y **"Conductor"** que rellenan los datos solos.

## 🚀 Probar el flujo

1. Instala el APK en **dos teléfonos** (o en un teléfono + un emulador).
2. En uno, entra como **Conductor** → activa el switch **"Disponible para viajes"**.
3. En el otro, entra como **Cliente**:
   - Toca el mapa para marcar tu **destino**.
   - Elige un servicio (Carrera, Acarreo, Mudanza, etc.).
   - Verás cotización (distancia, tiempo, tarifa C$).
   - Toca **Solicitar**.
4. El **Conductor** recibe la solicitud → la **Acepta**.
5. Avanza: **Llegó → Iniciar → Finalizar**.
6. Chatea durante el viaje, califica al final.

## 🔄 Si quieres recompilar el APK

```powershell
cd "C:\Users\joyne\OneDrive\Escritorio\Proyectos Joy\Jenny\bilwi-cargo-ride\mobile"
flutter build apk --release
```

El nuevo APK queda en `mobile\build\app\outputs\flutter-apk\app-release.apk`.

## 🛠️ Si quieres seguir desarrollando

- Cualquier cambio que hagas en el **backend** + `git push` → Railway redeploya **solo** en ~2 min.
- Cualquier cambio que hagas en la **app** → `flutter build apk --release` y reinstalas el APK.

## 📊 Monitoreo

- **Logs del servidor en vivo:** Railway dashboard → proyecto `dependable-rejoicing` → servicio `bilwi-cargo-ride` → pestaña **"Deployments"** → click en el deploy activo → **"Deploy Logs"**.
- **Base de datos:** Railway dashboard → servicio `Postgres` → pestaña **"Data"** (Railway tiene un editor visual de tablas).
- **Métricas admin:** entra a la app como admin (`+50588880000`) — *(la UI de admin web queda como fase 2; por ahora puedes probar el endpoint con curl: `GET /api/admin/metrics` con header `Authorization: Bearer <token>`)*.

---

## ¿Qué hay en el proyecto?

```
bilwi-cargo-ride/
├── backend/        # API REST + WebSockets (Node + Express + PostgreSQL)
├── mobile/         # App Flutter Material 3 (cliente + conductor)
├── docs/           # Arquitectura, API, manuales, monetización
├── dist/           # APK listo para instalar
└── INSTALAR.md     # Este archivo
```
