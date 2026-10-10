import 'dart:async';

import 'package:zelo/features/reminders/data/reminder_preferences.dart';
import 'package:zelo/features/reminders/domain/expiration_reminder_plan.dart';
import 'package:zelo/features/reminders/domain/reminder_service.dart';

/// Serviço de avisos em memória: guarda o que foi agendado e permite simular
/// permissão, toques e falhas.
class FakeReminderService implements ReminderService {
  FakeReminderService({
    this.supported = true,
    this._permission = ReminderPermission.granted,
    this.grantOnRequest = true,
  });

  final bool supported;

  /// Resposta ao pedido de permissão.
  bool grantOnRequest;

  ReminderPermission _permission;

  /// Último conjunto agendado (substitui o anterior a cada chamada).
  List<PlannedReminder> scheduled = const [];
  var scheduleCalls = 0;
  var cancelAllCalls = 0;
  var testCalls = 0;
  var settingsCalls = 0;
  var permissionRequests = 0;
  String? launch;
  Object? failSchedule;
  Completer<void>? scheduleGate;

  final _taps = StreamController<String>.broadcast();

  set permissionNow(ReminderPermission value) => _permission = value;

  void tap([String payload = expirationReminderPayload]) => _taps.add(payload);

  @override
  bool get isSupported => supported;

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<ReminderPermission> permission() async =>
      supported ? _permission : ReminderPermission.unsupported;

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequests++;
    if (!supported) {
      return ReminderPermission.unsupported;
    }
    _permission = grantOnRequest
        ? ReminderPermission.granted
        : ReminderPermission.denied;
    return _permission;
  }

  @override
  Future<void> openSettings() async => settingsCalls++;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    scheduleCalls++;
    await scheduleGate?.future;
    if (failSchedule case final error?) {
      throw error;
    }
    scheduled = List.of(reminders);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled = const [];
  }

  @override
  Future<void> showTest() async => testCalls++;

  @override
  Future<String?> launchPayload() async => launch;

  Future<void> close() => _taps.close();
}

class InMemoryReminderPreferences implements ReminderPreferences {
  InMemoryReminderPreferences({this.enabled = false});

  bool enabled;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
}
