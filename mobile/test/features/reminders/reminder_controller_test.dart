import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/features/medications/application/medication_store.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/reminders/application/reminder_controller.dart';
import 'package:zelo/features/reminders/domain/reminder_service.dart';

import '../../support/reminder_fakes.dart';

void main() {
  final today = DateTime(2026, 10, 2, 10);

  late MedicationStore store;
  late FakeReminderService service;
  late InMemoryReminderPreferences preferences;
  late ReminderController controller;

  Medication med(String id, DateTime expiration) =>
      Medication(id: id, name: id, expirationDate: expiration, quantity: 1);

  Future<void> build({
    bool enabled = false,
    bool loadStore = true,
    FakeReminderService? fake,
    List<Medication> medications = const [],
  }) async {
    store = MedicationStore(medications: medications, clock: () => today);
    service = fake ?? FakeReminderService();
    preferences = InMemoryReminderPreferences(enabled: enabled);
    controller = ReminderController(
      service: service,
      preferences: preferences,
      store: store,
      clock: () => today,
    );
    await controller.load();
    if (loadStore) {
      await store.load();
    }
    await pumpEventQueue();
  }

  tearDown(() async {
    controller.dispose();
    store.dispose();
    await service.close();
  });

  test('começa desligado e sem agendar nada', () async {
    await build(medications: [med('Dipirona', DateTime(2026, 12, 31))]);

    expect(controller.isLoaded, isTrue);
    expect(controller.enabled, isFalse);
    expect(controller.isActive, isFalse);
    expect(service.scheduleCalls, 0);
    expect(service.permissionRequests, 0);
  });

  test('ligar pede a permissão, grava a escolha e agenda', () async {
    await build(medications: [med('Dipirona', DateTime(2026, 12, 31))]);

    final result = await controller.setEnabled(true);
    await pumpEventQueue();

    expect(result, ReminderPermission.granted);
    expect(service.permissionRequests, 1);
    expect(preferences.enabled, isTrue);
    expect(controller.isActive, isTrue);
    expect(service.scheduled.map((r) => r.daysBefore), [30, 7, 0]);
    expect(controller.next?.at, DateTime(2026, 12, 1, 9));
  });

  test('permissão negada mantém desligado e não agenda', () async {
    await build(
      fake: FakeReminderService(grantOnRequest: false),
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );

    final result = await controller.setEnabled(true);
    await pumpEventQueue();

    expect(result, ReminderPermission.denied);
    expect(controller.enabled, isFalse);
    expect(preferences.enabled, isFalse);
    expect(service.scheduleCalls, 0);
  });

  test('desligar cancela tudo e limpa o próximo aviso', () async {
    await build(
      enabled: true,
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );
    expect(service.scheduled, isNotEmpty);

    await controller.setEnabled(false);

    expect(controller.enabled, isFalse);
    expect(preferences.enabled, isFalse);
    expect(service.scheduled, isEmpty);
    expect(controller.next, isNull);
    expect(service.cancelAllCalls, 1);
  });

  test(
    'escolha guardada reagenda ao abrir, mas só com a lista carregada',
    () async {
      await build(
        enabled: true,
        loadStore: false,
        medications: [med('Dipirona', DateTime(2026, 12, 31))],
      );
      // Lista ainda não carregou (ex.: antes do login): não pode apagar avisos.
      expect(service.scheduleCalls, 0);

      await store.load();
      await pumpEventQueue();
      expect(service.scheduled, hasLength(3));
    },
  );

  test('mudanças na lista reagendam os avisos', () async {
    await build(
      enabled: true,
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );
    expect(service.scheduled, hasLength(3));

    await store.add(
      MedicationDraft(
        name: 'Loratadina',
        expirationDate: DateTime(2027, 3, 1),
        quantity: 2,
      ),
    );
    await pumpEventQueue();

    expect(service.scheduled, hasLength(6));
    expect(
      service.scheduled.any((r) => r.medicationNames.contains('Loratadina')),
      isTrue,
    );
  });

  test('várias mudanças seguidas viram poucos agendamentos', () async {
    final gate = Completer<void>();
    await build(
      enabled: true,
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );
    final before = service.scheduleCalls;

    service.scheduleGate = gate;
    for (var i = 0; i < 5; i++) {
      unawaited(store.refresh());
    }
    await pumpEventQueue();
    // Um agendamento em andamento e nenhum outro em paralelo.
    expect(service.scheduleCalls, before + 1);

    gate.complete();
    await pumpEventQueue();
    // Os pedidos que chegaram no meio viram uma única passagem a mais.
    expect(service.scheduleCalls, before + 2);
  });

  test('falha ao agendar não derruba o controlador', () async {
    await build(
      enabled: true,
      fake: FakeReminderService()..failSchedule = StateError('sem alarme'),
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );

    expect(controller.isActive, isTrue);
    expect(controller.next, isNull);

    service.failSchedule = null;
    await store.refresh();
    await pumpEventQueue();
    expect(service.scheduled, hasLength(3));
  });

  test('sair da conta apaga os avisos, mas mantém a escolha', () async {
    await build(
      enabled: true,
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );

    await controller.cancelAll();
    store.clear();
    await pumpEventQueue();

    expect(service.scheduled, isEmpty);
    expect(controller.next, isNull);
    expect(preferences.enabled, isTrue);

    // Ao entrar de novo e carregar, volta a agendar.
    await store.load();
    await pumpEventQueue();
    expect(service.scheduled, hasLength(3));
  });

  test('permissão revogada no sistema bloqueia; devolvida, reagenda', () async {
    await build(
      enabled: true,
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );
    expect(controller.isActive, isTrue);

    service.permissionNow = ReminderPermission.denied;
    await controller.refreshPermission();
    expect(controller.isBlocked, isTrue);
    expect(controller.isActive, isFalse);

    service.scheduled = const [];
    service.permissionNow = ReminderPermission.granted;
    await controller.refreshPermission();
    await pumpEventQueue();
    expect(controller.isActive, isTrue);
    expect(service.scheduled, hasLength(3));
  });

  test('sem suporte, nada é pedido nem agendado', () async {
    await build(
      fake: FakeReminderService(supported: false),
      medications: [med('Dipirona', DateTime(2026, 12, 31))],
    );

    expect(controller.isUnsupported, isTrue);
    expect(await controller.setEnabled(true), ReminderPermission.unsupported);
    expect(service.permissionRequests, 0);
    expect(service.scheduleCalls, 0);
  });

  test('o próximo aviso ignora os que já passaram', () async {
    await build(
      enabled: true,
      medications: [med('Dipirona', DateTime(2026, 10, 22))],
    );
    // De 22/10 sobram 7 dias antes (15/10) e o próprio dia (22/10).
    expect(controller.next?.daysBefore, 7);
    expect(controller.next?.at, DateTime(2026, 10, 15, 9));
  });

  test(
    'aviso de teste, configurações e carga de abertura vão ao serviço',
    () async {
      await build(fake: FakeReminderService()..launch = 'validade');

      await controller.sendTest();
      await controller.openSettings();

      expect(service.testCalls, 1);
      expect(service.settingsCalls, 1);
      expect(await controller.launchPayload(), 'validade');
    },
  );
}
