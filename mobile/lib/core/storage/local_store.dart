import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia ligera (token, usuario y cache de catalogos).
/// Sirve para arranque rapido y modo bajo consumo.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kServices = 'cache_services';

  static Future<LocalStore> create() async =>
      LocalStore(await SharedPreferences.getInstance());

  String? get token => _prefs.getString(_kToken);
  Future<void> setToken(String? v) async =>
      v == null ? _prefs.remove(_kToken) : _prefs.setString(_kToken, v);

  String? get userJson => _prefs.getString(_kUser);
  Future<void> setUserJson(String? v) async =>
      v == null ? _prefs.remove(_kUser) : _prefs.setString(_kUser, v);

  String? get servicesCache => _prefs.getString(_kServices);
  Future<void> setServicesCache(String v) async =>
      _prefs.setString(_kServices, v);

  Future<void> clearSession() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kUser);
  }
}
