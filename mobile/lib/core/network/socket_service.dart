import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

/// Conexion WebSocket para tracking, estado de viaje y chat.
class SocketService {
  io.Socket? _socket;

  bool get connected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null) return;
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
  }

  void on(String event, void Function(dynamic) handler) =>
      _socket?.on(event, handler);

  void off(String event) => _socket?.off(event);

  void emit(String event, dynamic data) => _socket?.emit(event, data);

  void joinTrip(int tripId) => emit('trip:join', tripId);
  void leaveTrip(int tripId) => emit('trip:leave', tripId);

  void sendLocation(double lat, double lng, {int? tripId}) =>
      emit('driver:location', {'lat': lat, 'lng': lng, 'tripId': tripId});

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
