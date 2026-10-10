import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/zelo_app.dart';
import 'package:zelo/core/network/zelo_api_client.dart';
import 'package:zelo/core/storage/token_store.dart';
import 'package:zelo/features/authentication/data/simulated_authentication_service.dart';
import 'package:zelo/features/medications/domain/medication_scan.dart';

import '../support/collection_points_fakes.dart';
import '../support/fake_zelo_backend.dart';
import '../support/in_memory_dependencies.dart';
import '../support/reminder_fakes.dart';
import '../support/scan_fakes.dart';

void main() {
  Future<FakeZeloBackend> pumpConnectedApp(
    WidgetTester tester, {
    TokenStore? tokenStore,
    FakeZeloBackend? backend,
    ImageCapture? imageCapture,
    FakeReminderService? reminders,
    InMemoryReminderPreferences? reminderPreferences,
  }) async {
    final server = backend ?? FakeZeloBackend();
    final client = ZeloApiClient(
      baseUrl: Uri.parse('http://api.zelo.test'),
      tokenStore: tokenStore ?? InMemoryTokenStore(),
      httpClient: server.client,
    );
    addTearDown(client.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ZeloApp(
        apiClient: client,
        showBrandIntro: false,
        onboardingPreferences: InMemoryOnboardingPreferences(completed: true),
        locationProvider: FakeLocationProvider(),
        externalActions: FakeExternalActions(),
        imageCapture: imageCapture ?? FakeImageCapture(),
        reminderService: reminders ?? FakeReminderService(),
        reminderPreferences:
            reminderPreferences ?? InMemoryReminderPreferences(),
      ),
    );
    await tester.pumpAndSettle();
    return server;
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      FakeZeloBackend.email,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      FakeZeloBackend.password,
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('modo conectado não oferece demonstração e mostra a conta', (
    tester,
  ) async {
    await pumpConnectedApp(tester);

    expect(find.byKey(const ValueKey('demo-login-button')), findsNothing);
    await signIn(tester);
    expect(find.text('Sua farmácia doméstica'), findsOneWidget);
    expect(find.textContaining('somente na memória'), findsNothing);

    await tester.tap(find.text('Conta'));
    await tester.pumpAndSettle();
    expect(find.text('Pessoa de Teste'), findsOneWidget);
    expect(find.text(FakeZeloBackend.email), findsOneWidget);
    expect(find.text('Sessão simulada'), findsNothing);
  });

  testWidgets('cadastra no servidor, consulta pontos e registra descarte', (
    tester,
  ) async {
    final server = await pumpConnectedApp(tester);
    await signIn(tester);

    await tapVisible(tester, find.text('Cadastrar medicamento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('medication-name-field')),
      'Xarope',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xarope foi cadastrado.'), findsOneWidget);
    expect(server.medications.single['name'], 'Xarope');

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('points-use-location-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Farmácia Exemplo - Centro'), findsOneWidget);
    final nearby = server.requests.lastWhere(
      (request) => request.url.path == '/v1/collection-points/nearby',
    );
    expect(nearby.url.queryParameters['latitude'], '-30.035');

    await tapVisible(tester, find.text('Farmácia Exemplo - Centro'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('register-disposal-here-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xarope'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-disposal-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Celebração com o que saiu de casa; depois, sozinha, o histórico.
    expect(find.text('Mandou bem!'), findsOneWidget);
    expect(
      find.text('Seu primeiro descarte registrado no Zelo.'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.text('Mandou bem!'), findsNothing);
    expect(find.text('Farmácia Exemplo - Centro'), findsOneWidget);
    expect(server.disposals.single['point_external_id'], 'logmed-001234');
    expect(server.medications.single['active'], isFalse);
  });

  testWidgets('escaneia a embalagem pela Início e salva após conferência', (
    tester,
  ) async {
    final capture = FakeImageCapture();
    final server = await pumpConnectedApp(tester, imageCapture: capture);
    await signIn(tester);

    await tapVisible(tester, find.byKey(const ValueKey('home-scan-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-source-camera')));
    await tester.pumpAndSettle();

    expect(capture.sources, [ImageSourceKind.camera]);
    expect(server.ocrUploads, 1);
    final upload = server.requests.lastWhere(
      (request) => request.url.path == '/v1/ocr/medication',
    );
    expect(upload.headers['Authorization'], startsWith('Bearer '));
    expect(find.byKey(const ValueKey('scan-result')), findsOneWidget);
    expect(find.textContaining('VAL 03/2027'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.pumpAndSettle();
    final saved = server.medications.single;
    expect(saved['name'], 'Dipirona Monoidratada');
    expect(saved['expiration_date'], '2027-03-31');
    expect(saved['quantity'], 20);
  });

  testWidgets('demonstração não oferece a leitura da embalagem', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ZeloApp(
        showBrandIntro: false,
        onboardingPreferences: InMemoryOnboardingPreferences(completed: true),
        authenticationService: SimulatedAuthenticationService(
          sessionStore: InMemorySessionStore(active: true),
        ),
        locationProvider: FakeLocationProvider(),
        externalActions: FakeExternalActions(),
        imageCapture: FakeImageCapture(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sua farmácia doméstica'), findsOneWidget);
    expect(find.text('Cadastrar medicamento'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-scan-action')), findsNothing);
  });

  testWidgets('sessão expirada durante o uso volta ao login', (tester) async {
    final server = await pumpConnectedApp(tester);
    await signIn(tester);

    server
      ..expireAccessTokenOnce = true
      ..failRefresh = true;
    await tapVisible(tester, find.text('Cadastrar medicamento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('medication-name-field')),
      'Xarope',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Novo medicamento'), findsNothing);
    expect(find.text('Entre no Zelo'), findsOneWidget);
    expect(
      find.text('Sua sessão expirou. Entre novamente para continuar.'),
      findsOneWidget,
    );
  });

  testWidgets('servidor sem chave EcoMed informa a configuração pendente', (
    tester,
  ) async {
    await pumpConnectedApp(
      tester,
      backend: FakeZeloBackend(pointsConfigured: false),
    );
    await signIn(tester);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('points-choose-region-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('region-Canoas')));
    await tester.pumpAndSettle();

    expect(
      find.text('A consulta de pontos ainda não foi configurada no servidor.'),
      findsOneWidget,
    );
  });

  testWidgets('recuperação conectada conclui a troca de senha com código', (
    tester,
  ) async {
    await pumpConnectedApp(tester);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('recover-password-link')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email-field')),
      FakeZeloBackend.email,
    );
    await tester.tap(find.byKey(const ValueKey('recovery-submit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Verifique seu e-mail'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('reset-code-field')),
      'codigo-valido-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-password-field')),
      'nova-senha-456',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('reset-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reset-completed-message')),
      findsOneWidget,
    );
  });

  testWidgets('perfil edita nome, troca senha e exclui a conta', (
    tester,
  ) async {
    final server = await pumpConnectedApp(tester);
    await signIn(tester);
    expect(find.text('Olá, Pessoa'), findsOneWidget);

    await tester.tap(find.text('Conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Meu perfil'), findsWidgets);
    expect(
      find.text('0 medicamentos ativos · 0 descartes registrados'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('profile-name-tile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-field-name')),
      'Ana Souza',
    );
    await tester.tap(find.byKey(const ValueKey('account-form-submit')));
    await tester.pumpAndSettle();
    expect(server.accountName, 'Ana Souza');
    expect(find.text('Nome atualizado.'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('profile-password-tile')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-field-current')),
      'errada-000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-field-new')),
      'nova-senha-456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-field-confirmation')),
      'nova-senha-456',
    );
    await tester.tap(find.byKey(const ValueKey('account-form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Senha atual incorreta.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('account-field-current')),
      FakeZeloBackend.password,
    );
    await tester.tap(find.byKey(const ValueKey('account-form-submit')));
    await tester.pumpAndSettle();
    expect(server.accountPassword, 'nova-senha-456');

    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-account-button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-field-password')),
      'nova-senha-456',
    );
    await tester.tap(find.byKey(const ValueKey('account-form-submit')));
    await tester.pumpAndSettle();

    expect(server.accountDeleted, isTrue);
    expect(find.text('Entre no Zelo'), findsOneWidget);
    expect(
      find.text('Conta excluída. Seus dados foram removidos do Zelo.'),
      findsOneWidget,
    );
  });

  testWidgets('demonstração explica que o perfil exige conta Zelo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ZeloApp(
        showBrandIntro: false,
        onboardingPreferences: InMemoryOnboardingPreferences(completed: true),
        authenticationService: SimulatedAuthenticationService(
          sessionStore: InMemorySessionStore(active: true),
        ),
        locationProvider: FakeLocationProvider(),
        externalActions: FakeExternalActions(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zelo'), findsOneWidget);

    await tester.tap(find.text('Conta'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Meu perfil fica disponível ao entrar'),
      findsOneWidget,
    );
  });
}
