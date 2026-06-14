/// Configuracion central de la app.
///
/// El backend vive en Railway (sin dependencia de PC o IP local).
/// La app funciona en cualquier red, cualquier telefono.
class AppConfig {
  static const String apiBaseUrl =
      'https://bilwi-cargo-ride-production.up.railway.app/api';
  static const String socketUrl =
      'https://bilwi-cargo-ride-production.up.railway.app';

  // Centro aproximado de Bilwi (Puerto Cabezas).
  static const double bilwiLat = 14.0270;
  static const double bilwiLng = -83.3810;

  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapUserAgent = 'ni.bilwicargo.bilwi_cargo';

  static const String currency = 'C\$';
}
