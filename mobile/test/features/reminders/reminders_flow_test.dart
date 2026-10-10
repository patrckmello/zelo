import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/zelo_app.dart';
import 'package:zelo/core/network/zelo_api_client.dart';
import 'package:zelo/core/storage/token_store.dart';
import 'package:zelo/features/medications/application/medication_store.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/reminders/application/reminder_controller.dart';
import 'package:zelo/features/reminders/domain/reminder_service.dart';
import 'package:zelo/features/reminders/presentation/reminders_section.dart';

import '../../support/collection_points_fakes.dart';
import '../../support/fake_zelo_backend.dart';
import '../../support/in_memory_dependencies.dart';
import '../../support/reminder_fakes.dart';

void main() {
  final today = DateTime(2026, 10, 2, 10);

  group('seção Lembretes', () {
    late MedicationStore store;
    late FakeReminderService service;
    late InMemoryReminderPreferences preferences;
    late ReminderController controller;

    Future<void> pumpSection(
      WidgetTester tester, {
      FakeReminderService? fake,
      bool enabled = false,
    }) async {
      store = MedicationStore(
        medications: [
          Medication(
            id: 'm1',
            name: 'Dipirona',
            expirationDate: DateTime(2026, 12, 31),
            quantity: 1,
          ),
        ],
        clock: () => today,
      );
      service = fake ?? FakeReminderService();
      preferences = InMemoryReminderPreferences(enabled: enabled);
      controller = ReminderController(
        service: service,
        preferences: preferences,
        store: store,
        clock: () => today,
      );
      addTearDown(() async {
        controller.dispose();
        store.dispose();
        await service.close();
      });
      await controller.load();
      await store.load();
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemindersSection(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final toggle = find.byKey(const ValueKey('reminders-switch'));

    testWidgets('desligada mostra o que os avisos farão, sem agendar', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.text('Lembretes'), findsOneWidget);
      expect(find.text(RemindersSection.offDescription), findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(find.byKey(const ValueKey('reminders-next')), findsNothing);
      expect(find.byKey(const ValueKey('reminders-test')), findsNothing);
      expect(service.permissionRequests, 0);
    });

    testWidgets('ligar agenda e mostra o próximo aviso', (tester) async {
      await pumpSection(tester);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(find.text(RemindersSection.onDescription), findsOneWidget);
      expect(
        find.textContaining('terça-feira, 1 de dezembro, às 9h'),
        findsOneWidget,
      );
      expect(find.textContaining('vence em 30 dias: Dipirona'), findsOneWidget);
      expect(service.scheduled, hasLength(3));
      expect(preferences.enabled, isTrue);
    });

    testWidgets('sem medicamentos com validade futura, explica a espera', (
      tester,
    ) async {
      await pumpSection(tester, enabled: true);
      await store.remove('m1');
      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhum aviso agendado'), findsOneWidget);
    });

    testWidgets('aviso de teste chega ao serviço', (tester) async {
      await pumpSection(tester, enabled: true);

      await tester.tap(find.byKey(const ValueKey('reminders-test')));
      await tester.pump();

      expect(service.testCalls, 1);
    });

    testWidgets('permissão negada explica e leva às configurações', (
      tester,
    ) async {
      await pumpSection(
        tester,
        fake: FakeReminderService(grantOnRequest: false),
      );

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(find.byKey(const ValueKey('reminders-blocked')), findsOneWidget);
      expect(find.text(RemindersSection.blockedMessage), findsOneWidget);
      expect(service.scheduled, isEmpty);

      await tester.tap(find.byKey(const ValueKey('reminders-open-settings')));
      expect(service.settingsCalls, 1);
    });

    testWidgets('ligada, mas bloqueada pelo sistema, mostra o aviso', (
      tester,
    ) async {
      await pumpSection(
        tester,
        enabled: true,
        fake: FakeReminderService(permission: ReminderPermission.denied),
      );

      expect(find.byKey(const ValueKey('reminders-blocked')), findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(find.byKey(const ValueKey('reminders-test')), findsNothing);
    });

    testWidgets('sem suporte (navegador), informa onde funciona', (
      tester,
    ) async {
      await pumpSection(tester, fake: FakeReminderService(supported: false));

      expect(
        find.byKey(const ValueKey('reminders-unsupported')),
        findsOneWidget,
      );
      expect(
        find.text(RemindersSection.unsupportedDescription),
        findsOneWidget,
      );
      expect(toggle, findsNothing);
    });

    testWidgets('desligar cancela os avisos', (tester) async {
      await pumpSection(tester, enabled: true);
      expect(service.scheduled, isNotEmpty);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(service.scheduled, isEmpty);
      expect(preferences.enabled, isFalse);
    });
  });

  group('no aplicativo conectado', () {
    Future<(FakeZeloBackend, FakeReminderService)> pumpApp(
      WidgetTester tester, {
      FakeReminderService? reminders,
      bool enabled = false,
    }) async {
      final server = FakeZeloBackend();
      final soon = DateTime.now().add(const Duration(days: 100));
      server.medications.add({
        'id': 'srv-1',
        'name': 'Dipirona',
        'expiration_date':
            '${soon.year}-${soon.month.toString().padLeft(2, '0')}-'
            '${soon.day.toString().padLeft(2, '0')}',
        'quantity': 10,
        'notes': '',
        'active': true,
      });
      final client = ZeloApiClient(
        baseUrl: Uri.parse('http://api.zelo.test'),
        tokenStore: InMemoryTokenStore(),
        httpClient: server.client,
      );
      addTearDown(client.dispose);
      final service = reminders ?? FakeReminderService();
      addTearDown(service.close);
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ZeloApp(
          apiClient: client,
          showBrandIntro: false,
          onboardingPreferences: InMemoryOnboardingPreferences(completed: true),
          locationProvider: FakeLocationProvider(),
          externalActions: FakeExternalActions(),
          reminderService: service,
          reminderPreferences: InMemoryReminderPreferences(enabled: enabled),
        ),
      );
      await tester.pumpAndSettle();
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
      return (server, service);
    }

    testWidgets('liga em Conta, agenda e o toque no aviso abre a lista', (
      tester,
    ) async {
      final (_, service) = await pumpApp(tester);

      await tester.tap(find.text('Conta'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('reminders-switch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reminders-switch')));
      await tester.pumpAndSettle();

      expect(service.permissionRequests, 1);
      expect(service.scheduled.map((r) => r.daysBefore), [30, 7, 0]);
      expect(service.scheduled.first.medicationNames, ['Dipirona']);

      // Tocar num aviso leva aos medicamentos que pedem atenção.
      service.tap();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('medication-filter-expiringSoon')),
        findsOneWidget,
      );
    });

    testWidgets('a escolha guardada reagenda ao entrar', (tester) async {
      final (_, service) = await pumpApp(tester, enabled: true);

      expect(service.scheduled, hasLength(3));
    });

    testWidgets('aviso que abriu o aplicativo leva direto à lista', (
      tester,
    ) async {
      await pumpApp(
        tester,
        reminders: FakeReminderService()..launch = 'validade',
      );

      expect(
        find.byKey(const ValueKey('medication-filter-expiringSoon')),
        findsOneWidget,
      );
    });

    testWidgets('sair da conta apaga os avisos', (tester) async {
      final (_, service) = await pumpApp(tester, enabled: true);
      expect(service.scheduled, isNotEmpty);

      await tester.tap(find.text('Conta'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('logout-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('logout-button')));
      await tester.pumpAndSettle();

      expect(service.cancelAllCalls, greaterThanOrEqualTo(1));
      expect(service.scheduled, isEmpty);
    });
  });
}
