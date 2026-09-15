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

  Future<void> signOut();
}

class AuthenticationFailure implements Exception {
  const AuthenticationFailure(this.message);

  final String message;
}
