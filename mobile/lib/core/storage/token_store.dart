import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda somente o token de renovação; o token de acesso, de curta duração,
/// permanece em memória (RNF13).
abstract interface class TokenStore {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  Future<void> clear();
}

/// Armazenamento protegido do sistema (Keystore no Android).
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'zelo_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRefreshToken() => _storage.read(key: key);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: key);
}

class InMemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
