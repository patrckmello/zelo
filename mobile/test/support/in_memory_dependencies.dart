import 'package:zelo/core/storage/onboarding_preferences.dart';
import 'package:zelo/core/storage/session_store.dart';

class InMemoryOnboardingPreferences implements OnboardingPreferences {
  InMemoryOnboardingPreferences({this.completed = false, this.failReads = 0});

  bool completed;
  int failReads;
  int readCount = 0;
  int writeCount = 0;

  @override
  Future<bool> isCompleted() async {
    readCount++;
    if (failReads > 0) {
      failReads--;
      throw StateError('Falha interna simulada');
    }
    return completed;
  }

  @override
  Future<void> markCompleted() async {
    completed = true;
    writeCount++;
  }
}

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore({this.active = false, this.failReads = 0});

  bool active;
  int failReads;
  int readCount = 0;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<bool> hasActiveSession() async {
    readCount++;
    if (failReads > 0) {
      failReads--;
      throw StateError('Falha interna simulada');
    }
    return active;
  }

  @override
  Future<void> saveActiveSession() async {
    active = true;
    saveCount++;
  }

  @override
  Future<void> clearSession() async {
    active = false;
    clearCount++;
  }
}
