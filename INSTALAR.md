# Bilwi Cargo & Ride — Guía rápida para instalarla y usarla

## 1. APK listo

El archivo está aquí:

**`dist/BilwiCargoRide-v1.0.0.apk`** (~24 MB)

## 2. Cómo instalarlo en el teléfono

1. Copia el archivo al teléfono (USB, WhatsApp, Drive, etc.).
2. En el teléfono, ábrelo. Android pedirá permiso "Instalar de fuentes desconocidas" → **Permitir**.
3. Toca **Instalar**. Listo: aparece el ícono **Bilwi Cargo & Ride**.

> Si Play Protect avisa porque no está firmado con cuenta de Google Play, toca **Instalar de todos modos**. (En la fase MVP es normal; al subirlo a Play Store esto desaparece.)

## 3. Arrancar el backend

El backend debe estar corriendo en tu PC para que la app funcione (es el "cerebro").

```powershell
cd bilwi-cargo-ride\backend
npm start
```

El servidor escucha en `http://localhost:4000`. El comando `npm run db:setup` ya se ejecutó: la base de datos y las cuentas demo están listas.

## 4. Decirle a la app dónde está tu backend

La app y el backend tienen que hablar por la **misma red WiFi**. Hay dos casos:

### A. Emulador Android (en tu misma PC)
El código ya viene listo: usa `10.0.2.2:4000` (alias del emulador para "tu PC").

### B. Teléfono físico (WiFi)
1. En tu PC, abre PowerShell y corre `ipconfig`. Busca tu **"Dirección IPv4"** (algo como `192.168.1.10`).
2. Edita `mobile/lib/core/config/app_config.dart` y cambia:
   ```dart
   static const String apiHost = '192.168.1.10';   // <- tu IP
   ```
3. Recompila el APK:
   ```powershell
   cd mobile
   flutter build apk --release
   ```
4. El nuevo APK queda en `mobile/build/app/outputs/flutter-apk/app-release.apk`.

> Necesario: tu PC y tu teléfono en **la misma WiFi**, y el firewall debe permitir el puerto 4000 (Windows lo pregunta la primera vez).

## 5. Cuentas demo (ya creadas)

| Rol       | Teléfono       | Contraseña |
|-----------|----------------|------------|
| Cliente   | `+50588880001` | `demo1234` |
| Conductor | `+50588880002` | `demo1234` |
| Admin     | `+50588880000` | `demo1234` |

En la pantalla de login hay 2 chips: "Cliente" y "Conductor" que rellenan los datos automáticamente.

## 6. Probar el flujo completo (te toma 2 minutos)

1. Entra como **Conductor** en un teléfono/emulador — activa la disponibilidad.
2. En otro dispositivo (o cierra sesión y entra como **Cliente**):
   - Toca el mapa para marcar tu **destino**.
   - Elige un servicio (ride, acarreo, mudanza, etc.).
   - Verás la cotización (distancia, tiempo, tarifa C$).
   - Toca **Solicitar**.
3. El **Conductor** recibe la solicitud en tiempo real → la **Acepta**.
4. Avanza: **Llegó → Iniciar → Finalizar**.
5. El **Cliente** puede chatear durante el viaje y al final califica.

## 7. ¿Qué hay dentro?

- `backend/` — API REST + WebSockets (Node/Express/PostgreSQL). Verificado end-to-end.
- `mobile/` — App Flutter Material 3 (cliente + conductor, mapa OSM, chat, SOS, calificación).
- `dist/` — APK listo para instalar.
- `docs/` — Manuales técnico/usuario, arquitectura, monetización.
