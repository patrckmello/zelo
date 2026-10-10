import '../../../core/network/zelo_api_client.dart';
import '../domain/authentication_service.dart';

/// Autenticação real pela API Zelo (M4).
class ApiAuthenticationService implements AuthenticationService {
  ApiAuthenticationService({required this.client});

  final ZeloApiClient client;
  SessionAccount? _account;

  @override
  SessionAccount? get currentAccount => _account;

  @override
  bool get isSimulated => false;

  @override
  Stream<void> get sessionExpirations => client.sessionExpirations;

  @override
  Future<bool> restoreSession() async {
    // Logo após login ou cadastro a sessão já está aberta em memória.
    if (client.hasSession && _account != null) {
      return true;
    }
    final session = await client.restoreSession();
    _account = session == null ? null : _accountFrom(session.user);
    return session != null;
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _authenticate('/v1/auth/login', {
        'email': email.trim(),
        'password': password,
      });

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('/v1/auth/register', {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
  });

  @override
  Future<void> signInAsDemo() async {
    throw const AuthenticationFailure(
      'A entrada de demonstração existe somente no modo sem servidor.',
    );
  }

  @override
  Future<void> requestPasswordReset(String email) => _guard(
    () => client.send(
      'POST',
      '/v1/auth/password-reset/request',
      body: {'email': email.trim()},
      authenticated: false,
    ),
  );

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) => _guard(
    () => client.send(
      'POST',
      '/v1/auth/password-reset/confirm',
      body: {'token': code.trim(), 'new_password': newPassword},
      authenticated: false,
    ),
  );

  @override
  Future<void> signOut() async {
    await client.closeSession();
    _account = null;
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) =>
      _guard(() async {
        final session = await client.openSession(path, body);
        _account = _accountFrom(session.user);
        return null;
      });

  Future<void> _guard(Future<Object?> Function() operation) async {
    try {
      await operation();
    } on ApiException catch (error) {
      throw AuthenticationFailure(error.message);
    }
  }

  static SessionAccount _accountFrom(Map<String, dynamic> user) =>
      SessionAccount(
        name: user['name'] as String?,
        email: user['email'] as String?,
      );
}
