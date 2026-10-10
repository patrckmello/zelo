/// Dados da própria conta, vindos da API Zelo.
class AccountProfile {
  const AccountProfile({
    required this.name,
    required this.email,
    required this.createdAt,
    required this.medicationsCount,
    required this.disposalsCount,
  });

  final String name;
  final String email;
  final DateTime createdAt;
  final int medicationsCount;
  final int disposalsCount;
}

/// Perfil e segurança da conta. Disponível somente no modo conectado.
abstract interface class AccountService {
  Future<AccountProfile> fetchProfile();

  Future<AccountProfile> updateName(String name);

  Future<AccountProfile> changeEmail({
    required String newEmail,
    required String currentPassword,
  });

  /// Troca a senha, encerra as outras sessões e mantém este aparelho conectado.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Exclui a conta e todos os dados; a sessão local é descartada.
  Future<void> deleteAccount({required String currentPassword});
}

/// Falha com mensagem segura para exibição.
class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => 'AccountException: $message';
}
