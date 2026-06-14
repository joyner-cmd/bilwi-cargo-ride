# Bilwi Cargo & Ride

Plataforma de transporte particular y acarreos para Bilwi (Puerto Cabezas), Nicaragua.
Tipo "Uber + Mudanzas" optimizada para conexiones lentas.

- **Backend:** Node.js + Express + PostgreSQL + Socket.io (auth JWT propia)
- **Móvil:** Flutter (Material 3) + OpenStreetMap (flutter_map)
- **Mapas:** OpenStreetMap (sin llaves de pago). Google Maps queda "enchufable" después.

## Estructura

```
bilwi-cargo-ride/
├── backend/        # API REST + WebSockets (Node/Express/PostgreSQL)
├── mobile/         # App Flutter (cliente + conductor)
└── docs/           # Arquitectura, ERD, manuales
```

## Arranque rápido

### 1. Backend
```bash
cd backend
cp .env.example .env          # ajusta usuario/clave de Postgres
npm install
npm run db:setup              # crea tablas + datos demo
npm run dev                   # API en http://localhost:4000
```

### 2. App móvil (Flutter)
```bash
cd mobile
flutter pub get
# Edita lib/core/config/app_config.dart -> apiBaseUrl con la IP de tu PC
flutter run                   # o: flutter build apk --release
```

> Para probar en un teléfono físico, usa la IP local de tu PC (ej. `http://192.168.1.10:4000`),
> no `localhost`. Ver `docs/MANUAL_TECNICO.md`.

## Cuentas demo (tras `npm run db:setup`)

| Rol      | Teléfono     | Contraseña |
|----------|--------------|------------|
| Cliente  | `+50588880001` | `demo1234` |
| Conductor| `+50588880002` | `demo1234` |
| Admin    | `+50588880000` | `demo1234` |
