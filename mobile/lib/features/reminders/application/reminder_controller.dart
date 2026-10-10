import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../medications/application/medication_store.dart';
import '../data/reminder_preferences.dart';
import '../domain/expiration_reminder_plan.dart';
import '../domain/reminder_service.dart';

/// Lembretes de validade (RF06): liga e desliga, pede a permissão e mantém os
/// avisos agendados em dia com a lista de medicamentos.
///
/// Todo o agendamento acontece no aparelho. Quando a lista muda (cadastro,
/// edição, remoção, descarte ou nova carga), os avisos são recalculados e
/// substituídos; pedidos que chegam durante um agendamento são reunidos em
/// uma única nova passagem.
class ReminderController extends ChangeNotifier {
  ReminderController({
    required this._service,
    required this._preferences,
    required this._store,
    Clock? clock,
  }) : _clock = clock ?? DateTime.now {
    _store.addListener(_onStoreChanged);
  }

  final ReminderService _service;
  final ReminderPreferences _preferences;
  final MedicationStore _store;
  final Clock _clock;

  var _loaded = false;
  var _enabled = false;
  var _busy = false;
  var _disposed = false;
  ReminderPermission? _permission;
  var _plan = const <PlannedReminder>[];
  Future<void>? _syncing;
  var _syncAgain = false;

  /// Falso até a primeira leitura da escolha e da permissão terminar.
  bool get isLoaded => _loaded;

  /// A pessoa quer receber os lembretes.
  bool get enabled => _enabled;

  /// Pedindo permissão ou gravando a escolha.
  bool get isBusy => _busy;

  /// Nulo antes da primeira leitura.
  ReminderPermission? get permission => _permission;

  bool get isUnsupported => _permission == ReminderPermission.unsupported;

  /// Ligado e permitido pelo sistema: os avisos estão valendo.
  bool get isActive => _enabled && _permission == ReminderPermission.granted;

  /// Ligado, mas o sistema bloqueou as notificações do aplicativo.
  bool get isBlocked => _enabled && _permission == ReminderPermission.denied;

  Stream<String> get taps => _service.taps;

  /// Próximo aviso ainda por vir; nulo quando não há nenhum agendado.
  PlannedReminder? get next {
    final now = _clock();
    for (final reminder in _plan) {
      if (reminder.at.isAfter(now)) {
        return reminder;
      }
    }
    return null;
  }

  /// Lê a escolha e a permissão; chamado ao abrir o aplicativo.
  Future<void> load() async {
    try {
      _enabled = await _preferences.isEnabled();
      _permission = await _service.permission();
    } on Object catch (error) {
      // Sem o plugin (ex.: testes ou aparelho sem suporte), os lembretes
      // simplesmente não existem; o resto do aplicativo segue.
      debugPrint('Lembretes indisponíveis: $error');
      _permission = ReminderPermission.unsupported;
    }
    _loaded = true;
    _notify();
    _syncIfReady();
  }

  /// Relê a permissão do sistema (ela pode ter mudado fora do aplicativo).
  Future<void> refreshPermission() async {
    if (isUnsupported || !_loaded) {
      return;
    }
    final before = _permission;
    try {
      _permission = await _service.permission();
    } on Object catch (error) {
      debugPrint('Permissão de notificações indisponível: $error');
      return;
    }
    if (before != _permission) {
      _notify();
    }
    if (before != ReminderPermission.granted) {
      _syncIfReady();
    }
  }

  /// Liga ou desliga. Ao ligar, pede a permissão; devolve o resultado dela.
  Future<ReminderPermission> setEnabled(bool value) async {
    if (isUnsupported) {
      return ReminderPermission.unsupported;
    }
    _busy = true;
    _notify();
    try {
      if (value) {
        final permission = await _service.requestPermission();
        _permission = permission;
        if (permission != ReminderPermission.granted) {
          // Fica desligado: sem permissão não há o que agendar.
          _enabled = false;
          await _preferences.setEnabled(false);
          return permission;
        }
        _enabled = true;
        await _preferences.setEnabled(true);
        _syncIfReady();
        return permission;
      }
      _enabled = false;
      await _preferences.setEnabled(false);
      _plan = const [];
      await _service.cancelAll();
      return _permission ?? ReminderPermission.granted;
    } on Object catch (error) {
      debugPrint('Falha ao alterar os lembretes: $error');
      return _permission ?? ReminderPermission.denied;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> sendTest() async {
    try {
      await _service.showTest();
    } on Object catch (error) {
      debugPrint('Falha ao enviar o aviso de teste: $error');
    }
  }

  Future<void> openSettings() async {
    try {
      await _service.openSettings();
    } on Object catch (error) {
      debugPrint('Falha ao abrir as configurações: $error');
    }
  }

  /// Carga do aviso que abriu o aplicativo, se foi isso que o abriu.
  Future<String?> launchPayload() async {
    try {
      return await _service.launchPayload();
    } on Object catch (error) {
      debugPrint('Falha ao ler o aviso de abertura: $error');
      return null;
    }
  }

  /// Apaga os avisos agendados e os já mostrados, como ao sair da conta: os
  /// nomes dos medicamentos não podem ficar para outra pessoa. A escolha de
  /// receber lembretes continua; ao entrar de novo, tudo é reagendado.
  Future<void> cancelAll() async {
    _plan = const [];
    _notify();
    try {
      await _service.cancelAll();
    } on Object catch (error) {
      debugPrint('Falha ao cancelar os lembretes: $error');
    }
  }

  void _onStoreChanged() => _syncIfReady();

  /// Só reagenda com a lista carregada: antes disso (ou sem a conta aberta) a
  /// lista vazia apagaria avisos que ainda valem.
  void _syncIfReady() {
    if (isActive && _store.status == MedicationLoadStatus.ready) {
      _requestSync();
    }
  }

  void _requestSync() {
    if (_syncing != null) {
      _syncAgain = true;
      return;
    }
    late final Future<void> operation;
    operation = _sync().whenComplete(() {
      if (identical(_syncing, operation)) {
        _syncing = null;
      }
      if (_syncAgain && !_disposed) {
        _syncAgain = false;
        _requestSync();
      }
    });
    _syncing = operation;
  }

  Future<void> _sync() async {
    final plan = planExpirationReminders(_store.medications, now: _clock());
    try {
      await _service.schedule(plan);
      _plan = plan;
    } on Object catch (error) {
      debugPrint('Falha ao agendar os lembretes: $error');
      return;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
