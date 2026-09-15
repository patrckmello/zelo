import 'package:flutter/foundation.dart';

import '../../core/storage/onboarding_preferences.dart';
import '../../features/authentication/domain/authentication_service.dart';

enum BootstrapState {
  initializing,
  firstAccess,
  unauthenticated,
  authenticated,
  recoverableError,
}

class BootstrapController extends ChangeNotifier {
  BootstrapController({
    required this.onboardingPreferences,
    required this.authenticationService,
  });

  static const safeErrorMessage =
      'Não foi possível preparar o aplicativo. Tente novamente.';

  final OnboardingPreferences onboardingPreferences;
  final AuthenticationService authenticationService;

  BootstrapState _state = BootstrapState.initializing;
  BootstrapState get state => _state;

  Future<void> load() async {
    _setState(BootstrapState.initializing);
    try {
      final onboardingCompleted = await onboardingPreferences.isCompleted();
      if (!onboardingCompleted) {
        _setState(BootstrapState.firstAccess);
        return;
      }

      final hasSession = await authenticationService.restoreSession();
      _setState(
        hasSession
            ? BootstrapState.authenticated
            : BootstrapState.unauthenticated,
      );
    } catch (_) {
      _setState(BootstrapState.recoverableError);
    }
  }

  void _setState(BootstrapState value) {
    _state = value;
    notifyListeners();
  }
}
