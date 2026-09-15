import 'package:flutter/material.dart';

import '../../core/storage/onboarding_preferences.dart';
import '../../features/authentication/domain/authentication_service.dart';
import '../../features/authentication/presentation/login_page.dart';
import '../../features/authentication/presentation/password_recovery_page.dart';
import '../../features/authentication/presentation/register_page.dart';
import '../../features/medications/application/medication_store.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../zelo_shell.dart';
import 'bootstrap_controller.dart';

enum _AuthenticationPage { login, register, recovery }

class AppBootstrapFlow extends StatefulWidget {
  const AppBootstrapFlow({
    required this.onboardingPreferences,
    required this.authenticationService,
    required this.medicationStore,
    super.key,
  });

  final OnboardingPreferences onboardingPreferences;
  final AuthenticationService authenticationService;
  final MedicationStore medicationStore;

  @override
  State<AppBootstrapFlow> createState() => _AppBootstrapFlowState();
}

class _AppBootstrapFlowState extends State<AppBootstrapFlow> {
  late final BootstrapController _controller;
  var _authenticationPage = _AuthenticationPage.login;
  var _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = BootstrapController(
      onboardingPreferences: widget.onboardingPreferences,
      authenticationService: widget.authenticationService,
    )..addListener(_refresh);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_controller.state) {
      BootstrapState.initializing => const _BootstrapLoadingPage(),
      BootstrapState.firstAccess => OnboardingPage(
        preferences: widget.onboardingPreferences,
        onCompleted: _controller.load,
      ),
      BootstrapState.unauthenticated => _buildAuthenticationPage(),
      BootstrapState.authenticated => ZeloShell(
        medicationStore: widget.medicationStore,
        onLogout: _logout,
        isLoggingOut: _isLoggingOut,
      ),
      BootstrapState.recoverableError => _BootstrapErrorPage(
        onRetry: _controller.load,
      ),
    };
  }

  Widget _buildAuthenticationPage() => switch (_authenticationPage) {
    _AuthenticationPage.login => LoginPage(
      authenticationService: widget.authenticationService,
      onAuthenticated: _authenticated,
      onRegister: () => _showAuthenticationPage(_AuthenticationPage.register),
      onRecoverPassword: () =>
          _showAuthenticationPage(_AuthenticationPage.recovery),
    ),
    _AuthenticationPage.register => RegisterPage(
      authenticationService: widget.authenticationService,
      onAuthenticated: _authenticated,
      onBack: () => _showAuthenticationPage(_AuthenticationPage.login),
    ),
    _AuthenticationPage.recovery => PasswordRecoveryPage(
      authenticationService: widget.authenticationService,
      onBack: () => _showAuthenticationPage(_AuthenticationPage.login),
    ),
  };

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showAuthenticationPage(_AuthenticationPage page) {
    setState(() => _authenticationPage = page);
  }

  void _authenticated() {
    _authenticationPage = _AuthenticationPage.login;
    _controller.load();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await widget.authenticationService.signOut();
      _authenticationPage = _AuthenticationPage.login;
      await _controller.load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível sair agora. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }
}

class _BootstrapLoadingPage extends StatelessWidget {
  const _BootstrapLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Inicializando o Zelo',
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparando o Zelo…'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapErrorPage extends StatelessWidget {
  const _BootstrapErrorPage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_problem_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Algo não saiu como esperado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    BootstrapController.safeErrorMessage,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('bootstrap-retry-button'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
