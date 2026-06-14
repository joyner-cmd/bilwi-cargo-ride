# Deploy a Railway en 3 minutos (gratis)

Una vez que el código esté en GitHub (lo hace Claude por ti), sigue estos pasos
para tener tu API pública en internet, **sin tu PC encendida**.

## 1. Crea tu cuenta en Railway
1. Abre **https://railway.com** y dale a **"Login"**.
2. Elige **"Login with GitHub"** y autoriza.
3. Confirma tu correo si Railway lo pide.

Railway regala **$5 USD/mes de crédito gratis** sin tarjeta. Esta API consume
~$1/mes, así que es 100% gratis indefinidamente para tu uso.

## 2. Crea el proyecto desde tu repo
1. Click en **"+ New Project"** en el dashboard.
2. Elige **"Deploy from GitHub repo"**.
3. Si te pide permiso para acceder a tus repos, autoriza.
4. Selecciona el repositorio **`bilwi-cargo-ride`**.
5. Railway detecta el `Dockerfile` y empieza a construir solo.

## 3. Añade la base de datos PostgreSQL
1. Dentro del proyecto, click en **"+ Create"** → **"Database"** → **"PostgreSQL"**.
2. Espera ~30 segundos a que aparezca el servicio `Postgres`.
3. Click en tu servicio del backend → pestaña **"Variables"** → **"+ New Variable"** →
   selecciona **"Add Reference"** → escoge `Postgres` → la variable `DATABASE_URL`.
4. Click **"Add"**. El backend se reinicia y aplica el schema + datos demo solo.

## 4. Añade el resto de variables (1 minuto)
En la pestaña **Variables** del servicio backend, agrega:

| Variable | Valor |
|----------|-------|
| `NODE_ENV` | `production` |
| `JWT_SECRET` | `cualquier-frase-larga-y-aleatoria-aqui-cambia-esto` |
| `JWT_EXPIRES_IN` | `30d` |
| `CORS_ORIGIN` | `*` |
| `NEARBY_RADIUS_KM` | `8` |
| `PLATFORM_COMMISSION` | `0.15` |
| `AUTO_MIGRATE` | `true` |

> **Importante:** cambia el `JWT_SECRET` por una frase única (al menos 32 caracteres,
> letras y números). Es la "llave maestra" de tus sesiones.

## 5. Genera la URL pública
1. En el servicio backend, pestaña **"Settings"** → **"Networking"** → **"Generate Domain"**.
2. Railway te da una URL tipo `https://bilwi-cargo-ride-production.up.railway.app`.
3. **Copia esa URL** — la necesitas para el siguiente paso.

## 6. Verifica que responde
Abre en tu navegador:
```
https://tu-url-de-railway.up.railway.app/api/health
```
Debe responder:
```json
{"status":"ok","service":"bilwi-cargo-ride","time":"..."}
```

## 7. Compila el APK con la nueva URL
En tu PC:
```powershell
cd "C:\Users\joyne\OneDrive\Escritorio\Proyectos Joy\Jenny\bilwi-cargo-ride\mobile"
```

Edita `lib/core/config/app_config.dart`:
```dart
// Cambia las dos primeras lineas:
static const String apiBaseUrl = 'https://tu-url-de-railway.up.railway.app/api';
static const String socketUrl  = 'https://tu-url-de-railway.up.railway.app';
```

Luego:
```powershell
flutter build apk --release
```

El nuevo APK estará en `mobile/build/app/outputs/flutter-apk/app-release.apk`.
**Ese es el APK que pasas al teléfono** — y desde ese momento, la app funciona
en cualquier red, sin tu PC, sin IPs, sin nada que configurar.

## 8. Reinstala en el teléfono
1. Desinstala el APK viejo (Ajustes → Apps → Bilwi Cargo & Ride → Desinstalar).
2. Instala el nuevo APK (el del paso 7).
3. Abre la app y prueba con la cuenta cliente (`+50588880001` / `demo1234`).

¡Listo! Ya no dependes de tu PC.
