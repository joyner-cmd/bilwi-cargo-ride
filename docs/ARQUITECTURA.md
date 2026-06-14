# Arquitectura — Bilwi Cargo & Ride

## Visión general

```
┌──────────────────┐      HTTPS/REST + WebSocket      ┌────────────────────┐
│  App Flutter     │  ─────────────────────────────▶  │  Node.js + Express │
│  (cliente +      │                                  │  + Socket.io        │
│   conductor)     │  ◀─────  WS realtime  ─────────  │                    │
└──────────────────┘                                  └─────────┬──────────┘
       │  cache local                                           │
       │  (SharedPreferences)                                   │ pg pool
       ▼                                                        ▼
   [Modo bajo consumo]                                ┌────────────────────┐
                                                     │   PostgreSQL 16    │
                                                     │  (esquema completo)│
                                                     └────────────────────┘
```

## Capas

### Backend (`backend/src`)
- `config/`     — entorno y pool de Postgres.
- `middleware/` — JWT auth, validación Zod, errores.
- `modules/`    — Cada dominio sigue **Repository Pattern**:
  - `auth/`        registro, login.
  - `users/`       perfil.
  - `drivers/`     disponibilidad, ubicación, cercanos.
  - `vehicles/`    registro y aprobación.
  - `services/`    catálogo + cotización.
  - `trips/`       ciclo de vida completo.
  - `messages/`    chat por viaje.
  - `ratings/`     1–5 estrellas mutuas.
  - `incidents/`   SOS / reportes.
  - `notifications/` historial in-app.
  - `admin/`       métricas + aprobaciones.
- `realtime/`   — Socket.io (tracking + chat + estado).
- `utils/`      — Haversine, tarifas (surge + carga), seguridad.

### App (`mobile/lib`)
- `core/config`   — base URL del API.
- `core/network`  — `ApiClient` (Dio) + `SocketService`.
- `core/storage`  — `LocalStore` (sesión + cache catálogo).
- `core/theme`    — Material 3 (Azul Caribe + Turquesa).
- `core/utils`    — GPS, formato.
- `data/models`   — DTOs tipados.
- `data/repositories` — Repositorios (auth, catálogo, viajes, chat).
- `state`         — `AuthProvider` (Provider).
- `features/`     — Pantallas por feature (splash, auth, client, driver, trip, chat, history, profile).

## Principios aplicados (SOLID)

- **S** Cada repositorio/servicio tiene una responsabilidad.
- **O** El cálculo de tarifa parametriza factores (carga, surge) sin tocar el cálculo base.
- **L** Repositorios implementan contratos consistentes (ej. `Trip.fromJson`).
- **I** El cliente HTTP expone solo lo necesario (`dio` + `setToken`).
- **D** La UI depende del repositorio, no del cliente HTTP directamente.

## Modo bajo consumo (Bilwi)

1. **Compresión gzip** activa en el backend.
2. **Caché local de catálogo** de servicios (`SharedPreferences`).
3. **Sesión persistida** (arranque inmediato).
4. **WebSocket sobre `websocket` transport** (sin polling).
5. **Imágenes locales** para los servicios (no se descargan en cada uso).
6. **Tiles OpenStreetMap** cacheados por la librería `flutter_map`.

## Seguridad

- Contraseñas con bcrypt (10 rondas).
- JWT firmado HS256, expiración 30 días.
- Rate limit en `/api/auth` (50 intentos por 15 min).
- Validación Zod en cada endpoint.
- Tracking solo dentro de viajes; ubicación se borra al cerrar sesión.
- Botón **SOS** crea incidentes con coordenadas.

## Pasarelas de pago

El MVP soporta `cash | transfer | mobile | card` como métodos. La integración real con **BAC / Banpro / Lafise** se conecta en `payments` (servicio aislado) cuando obtengas los accesos del banco.
