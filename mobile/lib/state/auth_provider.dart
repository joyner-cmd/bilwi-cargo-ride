import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/di/services.dart';
import '../data/models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._services);
  final Services _services;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null && _services.store.token != null;

  /// Restaura sesion guardada (arranque rapido / offline).
  void bootstrap() {
    final json = _services.store.userJson;
    if (json != null) {
      _user = AppUser.fromJson(jsonDecode(json));
      final token = _services.store.token;
      if (token != null) _services.socket.connect(token);
    }
  }

  Future<void> login(String phone, String password) async {
    final res = await _services.auth.login(phone, password);
    await _persist(res.user, res.token);
  }

  Future<void> register({
    required String role,
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    final res = await _services.auth.register(
      role: role,
      fullName: fullName,
      phone: phone,
      password: password,
      email: email,
    );
    await _persist(res.user, res.token);
  }

  Future<void> logout() async {
    _services.socket.dispose();
    await _services.store.clearSession();
    _services.api.setToken(null);
    _user = null;
    notifyListeners();
  }

  Future<void> _persist(AppUser user, String token) async {
    await _services.store.setToken(token);
    await _services.store.setUserJson(jsonEncode(user.toJson()));
    _services.api.setToken(token);
    _services.socket.connect(token);
    _user = user;
    notifyListeners();
  }
}
