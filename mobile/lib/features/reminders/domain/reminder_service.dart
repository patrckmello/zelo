import 'expiration_reminder_plan.dart';

/// Situação da permissão para exibir notificações.
enum ReminderPermission { granted, denied, unsupported }

/// Avisos locais agendados no próprio aparelho: nada passa pelo servidor.
abstract interface class ReminderService {
  /// Falso onde não há notificações locais agendadas (ex.: navegador).
  bool get isSupported;

  /// Situação atual, sem abrir nenhum pedido ao usuário.
  Future<ReminderPermission> permission();

  /// Pede a permissão (no Android 13+, abre o diálogo do sistema).
  Future<ReminderPermission> requestPermission();

  /// Abre as configurações de notificação do aplicativo no sistema.
  Future<void> openSettings();

  /// Substitui todos os avisos pendentes por [reminders].
  Future<void> schedule(List<PlannedReminder> reminders);

  /// Remove avisos pendentes e os que já estão na bandeja.
  Future<void> cancelAll();

  /// Mostra agora um aviso de exemplo, para conferir se tudo funciona.
  Future<void> showTest();

  /// Toques em avisos com o aplicativo aberto ou em segundo plano.
  Stream<String> get taps;

  /// Carga do aviso que abriu o aplicativo, se foi isso que o abriu.
  Future<String?> launchPayload();
}

/// Carga dos avisos de validade, para abrir a lista de medicamentos.
const expirationReminderPayload = 'validade';
