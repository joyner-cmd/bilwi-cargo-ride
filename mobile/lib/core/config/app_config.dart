/// Configuracion central de la app.
///
/// IMPORTANTE: para probar en un telefono fisico, cambia [apiHost] por la IP
/// local de tu PC (ej. 192.168.1.10). En el emulador de Android usa 10.0.2.2.
/// Averigua tu IP con `ipconfig` (Windows) -> "Direccion IPv4".
class AppConfig {
  // Cambia esto a la IP de tu PC para pruebas reales en celular.
  static const String apiHost = '10.0.2.2';
  static const int apiPort = 4000;

  static const String apiBaseUrl = 'http://$apiHost:$apiPort/api';
  static const String socketUrl = 'http://$apiHost:$apiPort';

  // Centro aproximado de Bilwi (Puerto Cabezas).
  static const double bilwiLat = 14.0270;
  static const double bilwiLng = -83.3810;

  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapUserAgent = 'ni.bilwicargo.bilwi_cargo';

  static const String currency = 'C\$';
}
