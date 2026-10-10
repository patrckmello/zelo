import 'package:shared_preferences/shared_preferences.dart';

/// Escolha da pessoa de receber (ou não) os lembretes de validade.
abstract interface class ReminderPreferences {
  Future<bool> isEnabled();

  Future<void> setEnabled(bool enabled);
}

/// Guarda só um booleano não sensível (D005).
class SharedPreferencesReminderPreferences implements ReminderPreferences {
  SharedPreferencesReminderPreferences({SharedPreferencesAsync? storage})
    : _provided = storage;

  static const key = 'expiration_reminders_enabled';

  final SharedPreferencesAsync? _provided;

  // Criado só no primeiro uso: construir o objeto não toca na plataforma.
  late final SharedPreferencesAsync _storage =
      _provided ?? SharedPreferencesAsync();

  @override
  Future<bool> isEnabled() async => await _storage.getBool(key) ?? false;

  @override
  Future<void> setEnabled(bool enabled) => _storage.setBool(key, enabled);
}
