import '../../../core/network/zelo_api_client.dart';
import '../domain/account_service.dart';

class ApiAccountService implements AccountService {
  ApiAccountService(this.client);

  final ZeloApiClient client;

  @override
  Future<AccountProfile> fetchProfile() =>
      _profile(() => client.send('GET', '/v1/account'));

  @override
  Future<AccountProfile> updateName(String name) => _profile(
    () => client.send('PATCH', '/v1/account', body: {'name': name.trim()}),
  );

  @override
  Future<AccountProfile> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) => _profile(
    () => client.send(
      'POST',
      '/v1/account/email',
      body: {'new_email': newEmail.trim(), 'current_password': currentPassword},
    ),
  );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    final json = await client.send(
      'POST',
      '/v1/account/password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
    await client.adoptSession(json as Map<String, dynamic>);
  });

  @override
  Future<void> deleteAccount({required String currentPassword}) =>
      _guard(() async {
        await client.send(
          'POST',
          '/v1/account/delete',
          body: {'current_password': currentPassword},
        );
        await client.discardSession();
      });

  Future<AccountProfile> _profile(Future<Object?> Function() request) =>
      _guard(() async {
        final json = await request() as Map<String, dynamic>;
        return AccountProfile(
          name: json['name'] as String,
          email: json['email'] as String,
          createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
          medicationsCount: json['medications_count'] as int,
          disposalsCount: json['disposals_count'] as int,
        );
      });

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      throw AccountException(error.message);
    }
  }
}
