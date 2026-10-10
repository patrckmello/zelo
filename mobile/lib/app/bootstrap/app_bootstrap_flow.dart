import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/platform/external_actions.dart';
import '../../core/storage/onboarding_preferences.dart';
import '../../core/theme/zelo_colors.dart';
import '../../core/theme/zelo_tokens.dart';
import '../../core/widgets/brand_lockup.dart';
import '../../core/widgets/scene.dart';
import '../../core/widgets/state_message.dart';
import '../../features/account/domain/account_service.dart';
import '../../features/authentication/domain/authentication_service.dart';
import '../../features/authentication/presentation/login_page.dart';
import '../../features/authentication/presentation/password_recovery_page.dart';
import '../../features/authentication/presentation/register_page.dart';
import '../../features/collection_points/domain/collection_point.dart';
import '../../features/collection_points/domain/location.dart';
import '../../features/disposal_history/application/disposal_store.dart';
import '../../features/medications/application/medication_store.dart';
import '../../features/medications/domain/medication_scan.dart';
import '../../features/reminders/application/reminder_controller.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../zelo_shell.dart';
import 'bootstrap_controller.dart';

enum _AuthenticationPage { login, register, recovery }

class AppBootstrapFlow extends StatefulWidget {
  const AppBootstrapFlow({
    required this.onboardingPreferences,
    required this.authenticationService,
    required this.medicationStore,
    required this.disposalStore,
    required this.locationProvider,
    required this.externalActions,
    this.collectionPoints,
    this.accountService,
    this.scanner,
    this.reminders,
    this.storageNotice,
    super.key,
  });

  final OnboardingPreferences onboardingPreferences;
  final AuthenticationService authenticationService;
  final MedicationStore medicationStore;
  final DisposalStore disposalStore;
  final CollectionPointsRepository? collectionPoints;
  final AccountService? accountService;
  final MedicationScanner? scanner;
  final ReminderController? reminders;
  final LocationProvider locationProvider;
  final ExternalActions externalActions;
  final String? storageNotice;

  @override
  State<AppBootstrapFlow> createState() => _AppBootstrapFlowState();
}

class _AppBootstrapFlowState extends State<AppBootstrapFlow> {
  late final BootstrapController _controller;
  late final StreamSubscription<void> _expirations;
  var _authenticationPage = _AuthenticationPage.login;
  var _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = BootstrapController(
      onboardingPreferences: widget.onboardingPreferences,
      authenticationService: widget.authenticationService,
    )..addListener(_refresh);
    _expirations = widget.authenticationService.sessionExpirations.listen(
      (_) => _sessionExpired(),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _expirations.cancel();
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
        disposalStore: widget.disposalStore,
        onLogout: _logout,
        isLoggingOut: _isLoggingOut,
        collectionPoints: widget.collectionPoints,
        locationProvider: widget.locationProvider,
        externalActions: widget.externalActions,
        account:
            widget.authenticationService.currentAccount ??
            const SessionAccount.simulated(),
        storageNotice: widget.storageNotice,
        accountService: widget.accountService,
        onAccountDeleted: _accountDeleted,
        scanner: widget.scanner,
        reminders: widget.reminders,
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

  /// Descarta as cópias locais para não expor dados a outra conta.
  void _clearLocalData() {
    widget.medicationStore.clear();
    widget.disposalStore.clear();
    // Os nomes dos medicamentos não podem continuar em avisos de outra conta.
    unawaited(widget.reminders?.cancelAll() ?? Future<void>.value());
  }

  Future<void> _sessionExpired() async {
    if (_controller.state != BootstrapState.authenticated) {
      return;
    }
    // Fecha telas empilhadas (formulário, detalhes) para o login aparecer.
    Navigator.of(context).popUntil((route) => route.isFirst);
    _clearLocalData();
    _authenticationPage = _AuthenticationPage.login;
    await _controller.load();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Sua sessão expirou. Entre novamente para continuar.',
            ),
          ),
        );
    }
  }

  Future<void> _accountDeleted() async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await widget.authenticationService.signOut();
    _clearLocalData();
    _authenticationPage = _AuthenticationPage.login;
    await _controller.load();
    if (mounted) {
      // Avisos antigos da área autenticada não devem atrasar este.
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Conta excluída. Seus dados foram removidos do Zelo.',
            ),
          ),
        );
    }
  }

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
      _clearLocalData();
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
    // Mesmo quadro final da abertura; só a faixa passa a indicar a espera
    // real da inicialização.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Preparando o Zelo',
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLockup(loading: true),
                  const SizedBox(height: ZeloSpace.md),
                  Text(
                    'Preparando o Zelo…',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: ZeloColors.inkMuted),
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

class _BootstrapErrorPage extends StatelessWidget {
  const _BootstrapErrorPage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CenteredState(
          child: StateMessage(
            liveRegion: true,
            illustration: const ScenePanel(
              semanticLabel: 'Ilustração: falha ao preparar o aplicativo',
              aspectRatio: 1.7,
              maxWidth: 280,
              tint: ZeloColors.expiredTint,
              child: Center(
                child: SceneTile(
                  icon: Icons.sync_problem_outlined,
                  color: ZeloColors.expiredInk,
                ),
              ),
            ),
            title: 'Algo não saiu como esperado',
            message: BootstrapController.safeErrorMessage,
            action: FilledButton.icon(
              key: const ValueKey('bootstrap-retry-button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ),
      ),
    );
  }
}
