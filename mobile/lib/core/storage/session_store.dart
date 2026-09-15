import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SessionStore {
  Future<bool> hasActiveSession();

  Future<void> saveActiveSession();

  Future<void> clearSession();
}

class SharedPreferencesSessionStore implements SessionStore {
  SharedPreferencesSessionStore({SharedPreferencesAsync? storage})
    : _storage = storage ?? SharedPreferencesAsync();

  static const key = 'simulated_session_active';

  final SharedPreferencesAsync _storage;

  @override
  Future<bool> hasActiveSession() async => await _storage.getBool(key) ?? false;

  @override
  Future<void> saveActiveSession() => _storage.setBool(key, true);

  @override
  Future<void> clearSession() => _storage.remove(key);
}
