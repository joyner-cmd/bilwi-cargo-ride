# API REST — Bilwi Cargo & Ride

Base URL: `http://<host>:4000/api`. JWT en header `Authorization: Bearer <token>`.

## Auth
| Método | Ruta | Cuerpo |
|--------|------|--------|
| POST | `/auth/register` | `{ role:'client'\|'driver', fullName, phone, password, email? }` |
| POST | `/auth/login`    | `{ phone, password }` |

Respuesta: `{ user, token }`.

## Usuarios
| Método | Ruta | Auth |
|--------|------|------|
| GET    | `/users/me` | usuario |
| PATCH  | `/users/me` | usuario |
| POST   | `/users/me/password` | usuario |

## Conductores
| Método | Ruta | Rol |
|--------|------|-----|
| GET   | `/drivers/me` | driver |
| PATCH | `/drivers/me/availability` `{ available:bool }` | driver |
| POST  | `/drivers/me/location` `{ lat, lng }` | driver |
| GET   | `/drivers/nearby?lat=&lng=&vehicleType=&radiusKm=` | cualquiera |

## Vehículos
| Método | Ruta |
|--------|------|
| GET  | `/vehicles/me` |
| POST | `/vehicles` |

## Servicios y cotización
| Método | Ruta |
|--------|------|
| GET  | `/services` |
| POST | `/services/quote` `{ serviceTypeId, originLat, originLng, destLat, destLng, cargoSize? }` |

## Viajes (ciclo de vida)
| Método | Ruta | Rol |
|--------|------|-----|
| POST | `/trips` | cliente — crear |
| GET  | `/trips` | propios |
| GET  | `/trips/:id` | participante |
| POST | `/trips/:id/accept` | driver |
| POST | `/trips/:id/arrived` | driver |
| POST | `/trips/:id/start` | driver |
| POST | `/trips/:id/complete` | driver |
| POST | `/trips/:id/cancel` `{ reason? }` | participante |

## Calificaciones / Chat / Incidentes / Notificaciones
| Método | Ruta |
|--------|------|
| POST | `/ratings` `{ tripId, stars(1-5), comment? }` |
| GET  | `/messages/:tripId` |
| POST | `/messages/:tripId` `{ body }` |
| POST | `/incidents` `{ tripId?, type, description?, lat?, lng? }` |
| GET  | `/incidents` |
| GET  | `/notifications` |

## Admin (rol admin)
| Método | Ruta |
|--------|------|
| GET   | `/admin/metrics` |
| GET   | `/admin/users?role=` |
| PATCH | `/admin/users/:id/status` `{ status:active\|suspended }` |
| GET   | `/admin/vehicles?status=` |
| PATCH | `/admin/vehicles/:id/status` |
| PATCH | `/admin/documents/:id/status` |

## WebSocket (Socket.io)

Conexión: `io(socketUrl, { auth: { token } })`.

| Evento (cliente → servidor) | Datos | Quién |
|-----------------------------|-------|-------|
| `trip:join` | `tripId` | participante |
| `driver:location` | `{ lat, lng, tripId? }` | driver |
| `chat:send` | `{ tripId, body }` | participante |
| `chat:read` | `{ tripId }` | participante |

| Evento (servidor → cliente) | Datos |
|-----------------------------|-------|
| `trip:new` | nueva solicitud cercana (al driver) |
| `trip:accepted` | al cliente |
| `trip:status` | cambios de estado a la sala del viaje |
| `driver:location` | tracking en vivo |
| `chat:message` | mensaje nuevo |
