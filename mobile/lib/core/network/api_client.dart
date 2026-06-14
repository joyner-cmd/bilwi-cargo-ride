import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Cliente HTTP central. Inyecta el token y normaliza errores.
class ApiClient {
  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio dio;
  String? _token;

  void setToken(String? token) => _token = token;

  /// Extrae un mensaje legible del error del backend.
  static String messageFrom(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map && data['error']['message'] != null) {
        return data['error']['message'].toString();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Sin conexion con el servidor. Revisa tu internet o la IP del servidor.';
      }
      return 'Error de red (${error.response?.statusCode ?? 'sin codigo'})';
    }
    return error.toString();
  }
}
