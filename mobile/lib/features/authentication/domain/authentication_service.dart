abstract interface class AuthenticationService {
  Future<bool> restoreSession();

  Future<void> signIn({required String email, required String password});

  Future<void> signInAsDemo();

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  /// Conclui a recuperação com o código recebido por e-mail.
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  });

  Future<void> signOut();

  /// Conta da sessão atual, conhecida após autenticar ou restaurar a sessão.
  SessionAccount? get currentAccount;

  /// Verdadeiro na simulação local: oferece entrada de demonstração e não
  /// envia e-mails nem protege contas reais.
  bool get isSimulated;

  /// Emite quando a sessão expira durante o uso e exige novo login.
  Stream<void> get sessionExpirations;
}

/// Identificação mínima da sessão, sem dados inventados.
class SessionAccount {
  const SessionAccount({required this.name, required this.email})
    : simulated = false;

  const SessionAccount.simulated()
    : simulated = true,
      name = null,
      email = null;

  final bool simulated;
  final String? name;
  final String? email;
}

class AuthenticationFailure implements Exception {
  const AuthenticationFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthenticationFailure: $message';
}
