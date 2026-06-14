import '../network/api_client.dart';
import '../network/socket_service.dart';
import '../storage/local_store.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/trips_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/messages_repository.dart';

/// Contenedor simple de dependencias (DI manual, sin frameworks).
class Services {
  Services._(this.api, this.store, this.socket)
      : auth = AuthRepository(api),
        catalog = CatalogRepository(api, store),
        trips = TripsRepository(api),
        driver = DriverRepository(api),
        messages = MessagesRepository(api);

  final ApiClient api;
  final LocalStore store;
  final SocketService socket;

  final AuthRepository auth;
  final CatalogRepository catalog;
  final TripsRepository trips;
  final DriverRepository driver;
  final MessagesRepository messages;

  static Future<Services> init() async {
    final api = ApiClient();
    final store = await LocalStore.create();
    api.setToken(store.token);
    return Services._(api, store, SocketService());
  }
}
