import '../../core/network/api_client.dart';
import '../models/user.dart';

class AuthResult {
  AuthResult(this.user, this.token);
  final AppUser user;
  final String token;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthResult> login(String phone, String password) async {
    final res = await _api.dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return _parse(res.data);
  }

  Future<AuthResult> register({
    required String role,
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    final res = await _api.dio.post('/auth/register', data: {
      'role': role,
      'fullName': fullName,
      'phone': phone,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    return _parse(res.data);
  }

  AuthResult _parse(dynamic data) =>
      AuthResult(AppUser.fromJson(data['user']), data['token'] as String);
}
