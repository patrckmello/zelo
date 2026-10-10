import 'dart:async';

import 'package:flutter/material.dart';

import '../core/platform/external_actions.dart';
import '../core/theme/zelo_colors.dart';
import '../features/account/domain/account_service.dart';
import '../features/account/presentation/account_page.dart';
import '../features/account/presentation/profile_page.dart';
import '../features/authentication/domain/authentication_service.dart';
import '../features/collection_points/application/collection_points_controller.dart';
import '../features/collection_points/domain/collection_point.dart';
import '../features/collection_points/domain/location.dart';
import '../features/collection_points/presentation/collection_points_page.dart';
import '../features/disposal_history/application/disposal_store.dart';
import '../features/disposal_history/domain/disposal.dart';
import '../features/disposal_history/presentation/disposal_celebration.dart';
import '../features/disposal_history/presentation/disposal_history_page.dart';
import '../features/disposal_history/presentation/register_disposal_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/medications/application/medication_store.dart';
import '../features/medications/domain/medication.dart';
import '../features/medications/domain/medication_scan.dart';
import '../features/medications/presentation/medication_detail_page.dart';
import '../features/medications/presentation/medication_form_page.dart';
import '../features/medications/presentation/medications_page.dart';
import '../features/reminders/application/reminder_controller.dart';

/// Área autenticada: Início, Descartar, Histórico e Conta (D023).
class ZeloShell extends StatefulWidget {
  const ZeloShell({
    required this.medicationStore,
    required this.disposalStore,
    required this.onLogout,
    required this.locationProvider,
    required this.externalActions,
    this.collectionPoints,
    this.account = const SessionAccount.simulated(),
    this.accountService,
    this.onAccountDeleted,
    this.scanner,
    this.reminders,
    this.storageNotice,
    this.isLoggingOut = false,
    super.key,
  });

  final MedicationStore medicationStore;
  final DisposalStore disposalStore;
  final Future<void> Function() onLogout;
  final bool isLoggingOut;

  /// Ausente quando a API Zelo não está configurada nesta execução.
  final CollectionPointsRepository? collectionPoints;
  final LocationProvider locationProvider;
  final ExternalActions externalActions;
  final SessionAccount account;

  /// Perfil da conta; ausente no modo demonstração.
  final AccountService? accountService;
  final Future<void> Function()? onAccountDeleted;

  /// Leitura da embalagem; ausente sem a API Zelo.
  final MedicationScanner? scanner;

  /// Lembretes de validade; ausentes sem a API Zelo.
  final ReminderController? reminders;
  final String? storageNotice;

  @override
  State<ZeloShell> createState() => _ZeloShellState();
}

class _ZeloShellState extends State<ZeloShell> {
  int _selectedIndex = 0;

  /// Verdadeiro quando a área atual foi aberta por um atalho da Início.
  var _openedFromHome = false;
  CollectionPointsController? _pointsController;

  /// Celebração do descarte em andamento e o registro a destacar depois.
  OverlayEntry? _celebration;
  String? _highlightDisposalId;
  var _revealDisposal = true;
  StreamSubscription<String>? _reminderTaps;
  late SessionAccount _account = widget.account;

  MedicationStore get _store => widget.medicationStore;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Início',
    ),
    NavigationDestination(
      icon: Icon(Icons.recycling_outlined),
      selectedIcon: Icon(Icons.recycling),
      label: 'Descartar',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Histórico',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_circle_outlined),
      selectedIcon: Icon(Icons.account_circle),
      label: 'Conta',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.collectionPoints case final repository?) {
      _pointsController = CollectionPointsController(
        repository: repository,
        locationProvider: widget.locationProvider,
      );
    }
    // Tocar num aviso de validade abre os medicamentos que pedem atenção.
    _reminderTaps = widget.reminders?.taps.listen(
      (_) => _openExpiringMedications(),
    );
    // Carrega após o primeiro quadro para não notificar durante o build.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      // Se foi um aviso que abriu o aplicativo, vai direto à lista.
      if (await widget.reminders?.launchPayload() != null && mounted) {
        _openExpiringMedications();
      }
      if (!mounted) {
        return;
      }
      if (_store.status == MedicationLoadStatus.idle) {
        _store.load();
      }
      if (widget.disposalStore.status == DisposalLoadStatus.idle) {
        widget.disposalStore.load();
      }
    });
  }

  @override
  void dispose() {
    unawaited(_reminderTaps?.cancel());
    _celebration?.remove();
    _pointsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Voltar (Android ou navegador) em outra área leva ao Início antes de
    // sair do aplicativo.
    return PopScope<Object?>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _selectDestination(0);
        }
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
            medicationStore: _store,
            onAddMedication: _openMedicationForm,
            onOpenMedications: _openMedications,
            onOpenMedication: _openMedication,
            onOpenDisposal: () => _selectDestination(1, fromHome: true),
            storageNotice: widget.storageNotice,
            greetingName: _account.simulated ? null : _account.name,
            onScanPackage: widget.scanner == null
                ? null
                : () => _openMedicationForm(startWithScan: true),
          ),
          CollectionPointsPage(
            medicationStore: _store,
            controller: _pointsController,
            externalActions: widget.externalActions,
            onOpenMedication: _openMedication,
            onOpenExpired: () =>
                _openMedications(filter: MedicationStatus.expired),
            onRegisterDisposal: _openRegisterDisposal,
            onBackToHome: _openedFromHome ? () => _selectDestination(0) : null,
          ),
          DisposalHistoryPage(
            store: widget.disposalStore,
            onRegisterDisposal: () => _openRegisterDisposal(null),
            highlightId: _highlightDisposalId,
            revealHighlight: _revealDisposal,
            onHighlightShown: () => setState(() => _highlightDisposalId = null),
          ),
          AccountPage(
            onLogout: widget.onLogout,
            account: _account,
            isLoggingOut: widget.isLoggingOut,
            onOpenProfile: widget.accountService == null ? null : _openProfile,
            reminders: widget.reminders,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ZeloColors.hairline)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          destinations: _destinations,
          onDestinationSelected: (index) => _selectDestination(index),
        ),
      ),
    );
  }

  void _selectDestination(int index, {bool fromHome = false}) {
    setState(() {
      _selectedIndex = index;
      _openedFromHome = fromHome && index != 0;
    });
  }

  void _openExpiringMedications() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _selectDestination(0);
    _openMedications(filter: MedicationStatus.expiringSoon);
  }

  Future<void> _openMedications({MedicationStatus? filter}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => MedicationsPage(
            store: _store,
            initialFilter: filter,
            scanner: widget.scanner,
          ),
        ),
      );

  Future<void> _openMedication(String medicationId) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              MedicationDetailPage(store: _store, medicationId: medicationId),
        ),
      );

  Future<void> _openRegisterDisposal(CollectionPoint? point) =>
      Navigator.of(context).push<DisposalRecord>(
        MaterialPageRoute(
          builder: (_) => RegisterDisposalPage(
            medicationStore: _store,
            disposalStore: widget.disposalStore,
            onRegistered: _celebrate,
            point: point == null
                ? null
                : DisposalPoint(
                    name: point.name,
                    externalId: point.id,
                    address: [
                      point.address,
                      point.locality,
                    ].where((part) => part.isNotEmpty).join(' · '),
                  ),
          ),
        ),
      );

  /// Celebração numa camada acima do app (D038). Enquanto ela cobre a tela,
  /// as rotas de registro saem e o Histórico fica por baixo; quando a camada
  /// se dissolve, o registro novo sobe em destaque.
  void _celebrate(DisposalRecord record, Offset? origin) {
    _celebration?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final start = origin == null || overlayBox == null
        ? null
        : overlayBox.globalToLocal(origin);
    final entry = OverlayEntry(
      builder: (_) => DisposalCelebration(
        record: record,
        origin: start,
        disposalCount: widget.disposalStore.records.length,
        remainingExpired: _store.countByStatus(MedicationStatus.expired),
        onCovered: () {
          if (!mounted) {
            return;
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
          setState(() {
            _highlightDisposalId = record.id;
            _revealDisposal = false;
          });
          _selectDestination(2);
        },
        onFinished: () {
          _celebration?.remove();
          _celebration = null;
          if (mounted) {
            setState(() => _revealDisposal = true);
          }
        },
      ),
    );
    _celebration = entry;
    overlay.insert(entry);
  }

  Future<void> _openProfile() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ProfilePage(
        service: widget.accountService!,
        onProfileChanged: (profile) => setState(
          () => _account = SessionAccount(
            name: profile.name,
            email: profile.email,
          ),
        ),
        onAccountDeleted: widget.onAccountDeleted ?? widget.onLogout,
      ),
    ),
  );

  Future<void> _openMedicationForm({bool startWithScan = false}) =>
      openMedicationForm(
        context,
        onSave: _store.add,
        referenceDate: _store.today,
        scanner: widget.scanner,
        startWithScan: startWithScan,
      );
}
