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
  Future<void>? _loadInFlight;
  bool _disposed = false;

  BootstrapState get state => _state;

  Future<void> load() {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) {
      return activeLoad;
    }

    late final Future<void> operation;
    operation = _performLoad().whenComplete(() {
      if (identical(_loadInFlight, operation)) {
        _loadInFlight = null;
      }
    });
    _loadInFlight = operation;
    return operation;
  }

  Future<void> _performLoad() async {
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
    if (_disposed) {
      return;
    }
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
