import 'package:flutter/material.dart';

import '../features/home/presentation/home_page.dart';
import '../features/medications/application/medication_store.dart';
import '../features/medications/domain/medication.dart';
import '../features/medications/presentation/medication_form_page.dart';
import '../features/medications/presentation/medications_page.dart';

class ZeloShell extends StatefulWidget {
  const ZeloShell({required this.medicationStore, super.key});

  final MedicationStore medicationStore;

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
      icon: Icon(Icons.medication_outlined),
      selectedIcon: Icon(Icons.medication),
      label: 'Medicamentos',
    ),
    NavigationDestination(
      icon: Icon(Icons.location_on_outlined),
      selectedIcon: Icon(Icons.location_on),
      label: 'Descarte',
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
            onOpenMedications: () => _selectDestination(1),
            onOpenDisposal: () => _selectDestination(2),
          ),
          MedicationsPage(store: widget.medicationStore),
          const _PlaceholderPage(
            icon: Icons.location_on_outlined,
            title: 'Pontos de descarte',
            message: 'A consulta à EcoMed será integrada em uma etapa futura.',
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

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
