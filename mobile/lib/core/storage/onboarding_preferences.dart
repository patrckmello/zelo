import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingPreferences {
  Future<bool> isCompleted();

  Future<void> markCompleted();
}

class SharedPreferencesOnboardingPreferences implements OnboardingPreferences {
  SharedPreferencesOnboardingPreferences({SharedPreferencesAsync? storage})
    : _storage = storage ?? SharedPreferencesAsync();

  static const key = 'onboarding_completed';

  final SharedPreferencesAsync _storage;

  @override
  Future<bool> isCompleted() async => await _storage.getBool(key) ?? false;

  @override
  Future<void> markCompleted() => _storage.setBool(key, true);
}
