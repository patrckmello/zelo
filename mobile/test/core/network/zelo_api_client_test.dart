import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zelo/core/network/zelo_api_client.dart';
import 'package:zelo/core/storage/token_store.dart';

import '../../support/fake_zelo_backend.dart';

void main() {
  final baseUrl = Uri.parse('http://api.zelo.test');

  ZeloApiClient clientFor(FakeZeloBackend backend, TokenStore store) =>
      ZeloApiClient(
        baseUrl: baseUrl,
        tokenStore: store,
        httpClient: backend.client,
      );

  test('login guarda somente o token de renovação', () async {
    final backend = FakeZeloBackend();
    final store = InMemoryTokenStore();
    final client = clientFor(backend, store);

    final session = await client.openSession('/v1/auth/login', {
      'email': FakeZeloBackend.email,
      'password': FakeZeloBackend.password,
    });

    expect(session.user['email'], FakeZeloBackend.email);
    expect(await store.readRefreshToken(), startsWith('refresh-'));
    expect(client.hasSession, isTrue);
  });

  test('renova a sessão após 401 e repete a chamada uma vez', () async {
    final backend = FakeZeloBackend();
    final client = clientFor(backend, InMemoryTokenStore());
    await client.openSession('/v1/auth/login', {
      'email': FakeZeloBackend.email,
      'password': FakeZeloBackend.password,
    });

    backend.expireAccessTokenOnce = true;
    final medications = await client.send('GET', '/v1/medications');

    expect(medications, isEmpty);
    expect(
      backend.requests.map((request) => request.url.path),
      containsAllInOrder([
        '/v1/medications',
        '/v1/auth/refresh',
        '/v1/medications',
      ]),
    );
  });

  test('envio da foto é multipart e também renova a sessão após 401', () async {
    final backend = FakeZeloBackend();
    final client = clientFor(backend, InMemoryTokenStore());
    await client.openSession('/v1/auth/login', {
      'email': FakeZeloBackend.email,
      'password': FakeZeloBackend.password,
    });

    backend.expireAccessTokenOnce = true;
    final scan = await client.upload(
      '/v1/ocr/medication',
      field: 'image',
      bytes: const [0xff, 0xd8, 0xff, 0xe0],
      filename: 'embalagem.jpg',
      contentType: 'image/jpeg',
    );

    expect(scan['expiration_date'], '2027-03-31');
    expect(backend.ocrUploads, 1);
    expect(
      backend.requests.map((request) => request.url.path),
      containsAllInOrder([
        '/v1/ocr/medication',
        '/v1/auth/refresh',
        '/v1/ocr/medication',
      ]),
    );
    expect(
      backend.requests.last.headers['content-type'],
      startsWith('multipart/form-data'),
    );
  });

  test('renovação recusada encerra a sessão e avisa o aplicativo', () async {
    final backend = FakeZeloBackend();
    final store = InMemoryTokenStore();
    final client = clientFor(backend, store);
    await client.openSession('/v1/auth/login', {
      'email': FakeZeloBackend.email,
      'password': FakeZeloBackend.password,
    });
    final expirations = <void>[];
    client.sessionExpirations.listen(expirations.add);

    backend
      ..expireAccessTokenOnce = true
      ..failRefresh = true;
    await expectLater(
      client.send('GET', '/v1/medications'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    await pumpEventQueue();

    expect(expirations, hasLength(1));
    expect(await store.readRefreshToken(), isNull);
    expect(client.hasSession, isFalse);
  });

  test('restaura a sessão a partir do token guardado', () async {
    final backend = FakeZeloBackend();
    final store = InMemoryTokenStore();
    final first = clientFor(backend, store);
    await first.openSession('/v1/auth/login', {
      'email': FakeZeloBackend.email,
      'password': FakeZeloBackend.password,
    });

    final restored = await clientFor(backend, store).restoreSession();
    expect(restored?.user['name'], 'Pessoa de Teste');

    await store.writeRefreshToken('token-desconhecido');
    expect(await clientFor(backend, store).restoreSession(), isNull);
    expect(await store.readRefreshToken(), isNull);
  });

  test('erros da API e de rede viram mensagens seguras', () async {
    final backend = FakeZeloBackend();
    final client = clientFor(backend, InMemoryTokenStore());
    await expectLater(
      client.openSession('/v1/auth/login', {
        'email': FakeZeloBackend.email,
        'password': 'errada',
      }),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'invalid_credentials')
            .having((e) => e.message, 'message', 'E-mail ou senha inválidos.'),
      ),
    );

    final offline = ZeloApiClient(
      baseUrl: baseUrl,
      tokenStore: InMemoryTokenStore(),
      httpClient: MockClient(
        (request) async => throw http.ClientException('sem rede'),
      ),
    );
    await expectLater(
      offline.send('GET', '/health', authenticated: false),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'rede', isTrue)),
    );
  });

  test('logout revoga no servidor e limpa o armazenamento', () async {
    final backend = FakeZeloBackend();
    final store = InMemoryTokenStore();
    final client = clientFor(backend, store);
    await client.openSession('/v1/auth/login', {
      'email': FakeZeloBackend.email,
      'password': FakeZeloBackend.password,
    });

    await client.closeSession();

    expect(await store.readRefreshToken(), isNull);
    expect(backend.requests.last.url.path, '/v1/auth/logout');
  });
}
