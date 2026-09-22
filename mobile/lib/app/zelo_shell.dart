import 'package:flutter/material.dart';

import '../features/account/presentation/account_page.dart';
import '../features/collection_points/presentation/collection_points_page.dart';
import '../features/disposal_history/presentation/disposal_history_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/medications/application/medication_store.dart';
import '../features/medications/domain/medication.dart';
import '../features/medications/presentation/medication_form_page.dart';
import '../features/medications/presentation/medications_page.dart';

class ZeloShell extends StatefulWidget {
  const ZeloShell({
    required this.medicationStore,
    required this.onLogout,
    this.isLoggingOut = false,
    super.key,
  });

  final MedicationStore medicationStore;
  final Future<void> Function() onLogout;
  final bool isLoggingOut;

  @override
  State<ZeloShell> createState() => _ZeloShellState();
}

class _ZeloShellState extends State<ZeloShell> {
  int _selectedIndex = 0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
            medicationStore: widget.medicationStore,
            onAddMedication: _openMedicationForm,
            onOpenMedications: _openMedications,
            onOpenDisposal: () => _selectDestination(1),
          ),
          const CollectionPointsPage(),
          const DisposalHistoryPage(),
          AccountPage(
            onLogout: widget.onLogout,
            isLoggingOut: widget.isLoggingOut,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: _selectDestination,
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _openMedications() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => MedicationsPage(store: widget.medicationStore),
    ),
  );

  Future<void> _openMedicationForm() async {
    final draft = await Navigator.of(context).push<MedicationDraft>(
      MaterialPageRoute(builder: (_) => const MedicationFormPage()),
    );

    if (draft == null || !mounted) {
      return;
    }

    final medication = widget.medicationStore.add(draft);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${medication.name} foi cadastrado.')),
    );
  }
}
