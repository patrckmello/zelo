import 'package:flutter/material.dart';

import '../core/network/zelo_api_client.dart';
import '../core/platform/external_actions.dart';
import '../core/storage/onboarding_preferences.dart';
import '../core/storage/session_store.dart';
import '../core/storage/token_store.dart';
import '../core/theme/zelo_theme.dart';
import '../features/account/data/api_account_service.dart';
import '../features/account/domain/account_service.dart';
import '../features/authentication/data/api_authentication_service.dart';
import '../features/authentication/data/simulated_authentication_service.dart';
import '../features/authentication/domain/authentication_service.dart';
import '../features/collection_points/data/api_collection_points_repository.dart';
import '../features/collection_points/data/geolocator_location_provider.dart';
import '../features/collection_points/domain/collection_point.dart';
import '../features/collection_points/domain/location.dart';
import '../features/disposal_history/application/disposal_store.dart';
import '../features/disposal_history/data/disposal_repositories.dart';
import '../features/medications/application/medication_store.dart';
import '../features/medications/data/api_medication_repository.dart';
import '../features/medications/data/medication_scan_services.dart';
import '../features/medications/domain/medication_scan.dart';
import '../features/reminders/application/reminder_controller.dart';
import '../features/reminders/data/local_reminder_service.dart';
import '../features/reminders/data/reminder_preferences.dart';
import '../features/reminders/domain/reminder_service.dart';
import 'app_config.dart';
import 'bootstrap/app_bootstrap_flow.dart';
import 'bootstrap/app_launch_flow.dart';

/// Raiz de composição: cria uma única instância de cada dependência.
///
/// Sem [AppConfig.apiBaseUrl], usa a demonstração local (autenticação
/// simulada e dados em memória). Com a URL, usa a API Zelo, guarda o token de
/// renovação no armazenamento seguro e consulta pontos reais.
class ZeloApp extends StatefulWidget {
  const ZeloApp({
    this.config = const AppConfig(),
    this.medicationStore,
    this.disposalStore,
    this.onboardingPreferences,
    this.authenticationService,
    this.collectionPointsRepository,
    this.locationProvider,
    this.externalActions,
    this.apiClient,
    this.imageCapture,
    this.reminderService,
    this.reminderPreferences,
    this.showBrandIntro = true,
    super.key,
  });

  static const demoStorageNotice =
      'Os medicamentos desta versão ficam somente na memória e são apagados '
      'quando o aplicativo é encerrado.';

  final AppConfig config;
  final MedicationStore? medicationStore;
  final DisposalStore? disposalStore;
  final OnboardingPreferences? onboardingPreferences;
  final AuthenticationService? authenticationService;
  final CollectionPointsRepository? collectionPointsRepository;
  final LocationProvider? locationProvider;
  final ExternalActions? externalActions;

  /// Cliente da API usado no modo conectado; criado a partir da
  /// configuração quando ausente.
  final ZeloApiClient? apiClient;

  /// Origem das fotos da embalagem; o padrão é câmera e galeria.
  final ImageCapture? imageCapture;

  /// Avisos locais de validade; o padrão usa as notificações do Android.
  final ReminderService? reminderService;
  final ReminderPreferences? reminderPreferences;
  final bool showBrandIntro;

  @override
  State<ZeloApp> createState() => _ZeloAppState();
}

class _ZeloAppState extends State<ZeloApp> {
  late final MedicationStore _medicationStore;
  late final DisposalStore _disposalStore;
  late final OnboardingPreferences _onboardingPreferences;
  late final AuthenticationService _authenticationService;
  late final CollectionPointsRepository? _collectionPoints;
  late final LocationProvider _locationProvider;
  late final ExternalActions _externalActions;
  late final String? _storageNotice;
  AccountService? _accountService;
  MedicationScanner? _scanner;
  ReminderController? _reminders;
  ZeloApiClient? _apiClient;

  @override
  void initState() {
    super.initState();
    _onboardingPreferences =
        widget.onboardingPreferences ??
        SharedPreferencesOnboardingPreferences();
    _locationProvider =
        widget.locationProvider ?? const GeolocatorLocationProvider();
    _externalActions =
        widget.externalActions ?? const UrlLauncherExternalActions();

    final baseUrl = widget.config.apiBaseUrl;
    if (widget.apiClient != null || baseUrl != null) {
      final client =
          widget.apiClient ??
          (_apiClient = ZeloApiClient(
            baseUrl: baseUrl!,
            tokenStore: SecureTokenStore(),
          ));
      _authenticationService =
          widget.authenticationService ??
          ApiAuthenticationService(client: client);
      _medicationStore =
          widget.medicationStore ??
          MedicationStore(repository: ApiMedicationRepository(client));
      _disposalStore =
          widget.disposalStore ??
          DisposalStore(repository: ApiDisposalRepository(client));
      _collectionPoints =
          widget.collectionPointsRepository ??
          ApiCollectionPointsRepository(client);
      _accountService = ApiAccountService(client);
      _scanner = MedicationScanner(
        capture: widget.imageCapture ?? ImagePickerCapture(),
        service: ApiMedicationScanService(client),
      );
      _reminders = ReminderController(
        service: widget.reminderService ?? LocalReminderService(),
        preferences:
            widget.reminderPreferences ??
            SharedPreferencesReminderPreferences(),
        store: _medicationStore,
      )..load();
      _storageNotice = null;
    } else {
      _authenticationService =
          widget.authenticationService ??
          SimulatedAuthenticationService(
            sessionStore: SharedPreferencesSessionStore(),
          );
      _medicationStore = widget.medicationStore ?? MedicationStore.seeded();
      _disposalStore =
          widget.disposalStore ??
          DisposalStore(
            repository: InMemoryDisposalRepository(
              medications: _medicationStore.repository,
            ),
          );
      _collectionPoints = widget.collectionPointsRepository;
      _storageNotice = ZeloApp.demoStorageNotice;
    }
  }

  @override
  void dispose() {
    if (widget.medicationStore == null) {
      _medicationStore.dispose();
    }
    if (widget.disposalStore == null) {
      _disposalStore.dispose();
    }
    _reminders?.dispose();
    _apiClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zelo',
      debugShowCheckedModeBanner: false,
      theme: ZeloTheme.light,
      home: AppLaunchFlow(
        showBrandIntro: widget.showBrandIntro,
        child: AppBootstrapFlow(
          onboardingPreferences: _onboardingPreferences,
          authenticationService: _authenticationService,
          medicationStore: _medicationStore,
          disposalStore: _disposalStore,
          collectionPoints: _collectionPoints,
          accountService: _accountService,
          scanner: _scanner,
          reminders: _reminders,
          locationProvider: _locationProvider,
          externalActions: _externalActions,
          storageNotice: _storageNotice,
        ),
      ),
    );
  }
}
