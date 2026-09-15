import '../../../core/storage/session_store.dart';
import '../domain/authentication_service.dart';

class SimulatedAuthenticationService implements AuthenticationService {
  SimulatedAuthenticationService({required this.sessionStore});

  /// Credencial pública e fictícia usada somente para validar a demonstração.
  static const demoEmail = 'demo@zelo.app';
  static const demoPassword = 'ZeloDemo123!';

  final SessionStore sessionStore;

  @override
  Future<bool> restoreSession() => sessionStore.hasActiveSession();

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (email.trim().toLowerCase() != demoEmail || password != demoPassword) {
      throw const AuthenticationFailure(
        'E-mail ou senha inválidos. Confira os dados e tente novamente.',
      );
    }
    await sessionStore.saveActiveSession();
  }

  @override
  Future<void> signInAsDemo() => sessionStore.saveActiveSession();

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // A simulação valida a interface, mas não persiste dados pessoais ou senha.
    await sessionStore.saveActiveSession();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    // Nenhuma conta é consultada e nenhum e-mail real é enviado nesta etapa.
  }

  @override
  Future<void> signOut() => sessionStore.clearSession();
}
