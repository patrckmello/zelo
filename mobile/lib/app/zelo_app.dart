import 'package:flutter/material.dart';

import '../core/storage/onboarding_preferences.dart';
import '../core/storage/session_store.dart';
import '../core/theme/zelo_theme.dart';
import '../features/authentication/data/simulated_authentication_service.dart';
import '../features/authentication/domain/authentication_service.dart';
import '../features/medications/application/medication_store.dart';
import 'bootstrap/app_bootstrap_flow.dart';
import 'bootstrap/brand_intro_page.dart';

class ZeloApp extends StatefulWidget {
  const ZeloApp({
    this.medicationStore,
    this.onboardingPreferences,
    this.authenticationService,
    this.showBrandIntro = true,
    super.key,
  });

  final MedicationStore? medicationStore;
  final OnboardingPreferences? onboardingPreferences;
  final AuthenticationService? authenticationService;
  final bool showBrandIntro;

  @override
  State<ZeloApp> createState() => _ZeloAppState();
}

class _ZeloAppState extends State<ZeloApp> {
  late final MedicationStore _medicationStore;
  late final OnboardingPreferences _onboardingPreferences;
  late final AuthenticationService _authenticationService;
  late final bool _ownsMedicationStore;
  late bool _showBrandIntro;

  @override
  void initState() {
    super.initState();
    _showBrandIntro = widget.showBrandIntro;
    _ownsMedicationStore = widget.medicationStore == null;
    _medicationStore = widget.medicationStore ?? MedicationStore.seeded();
    _onboardingPreferences =
        widget.onboardingPreferences ??
        SharedPreferencesOnboardingPreferences();
    _authenticationService =
        widget.authenticationService ??
        SimulatedAuthenticationService(
          sessionStore: SharedPreferencesSessionStore(),
        );
  }

  @override
  void dispose() {
    if (_ownsMedicationStore) {
      _medicationStore.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zelo',
      debugShowCheckedModeBanner: false,
      theme: ZeloTheme.light,
      home: _showBrandIntro
          ? BrandIntroPage(
              onFinished: () {
                if (mounted) {
                  setState(() => _showBrandIntro = false);
                }
              },
            )
          : AppBootstrapFlow(
              onboardingPreferences: _onboardingPreferences,
              authenticationService: _authenticationService,
              medicationStore: _medicationStore,
            ),
    );
  }
}
