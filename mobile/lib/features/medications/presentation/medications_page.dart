import 'package:flutter/material.dart';

import '../application/medication_store.dart';
import '../domain/medication.dart';
import 'medication_detail_page.dart';
import 'medication_form_page.dart';
import 'medication_presentation.dart';

class MedicationsPage extends StatelessWidget {
  const MedicationsPage({required this.store, super.key});

  final MedicationStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final errorMessage = store.errorMessage;
            if (errorMessage != null) {
              return _ErrorState(message: errorMessage, onRetry: store.retry);
            }

            final medications = store.medications;
            if (medications.isEmpty) {
              return _EmptyState(onAdd: () => openMedicationForm(context));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: medications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final medication = medications[index];
                return _MedicationCard(
                  medication: medication,
                  referenceDate: store.today,
                  onTap: () => _openDetails(context, medication.id),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-medication-button'),
        onPressed: () => openMedicationForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
    );
  }

  Future<void> openMedicationForm(BuildContext context) async {
    final draft = await Navigator.of(context).push<MedicationDraft>(
      MaterialPageRoute(builder: (_) => const MedicationFormPage()),
    );

    if (draft == null || !context.mounted) {
      return;
    }

    final medication = store.add(draft);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${medication.name} foi cadastrado.')),
    );
  }

  Future<void> _openDetails(BuildContext context, String medicationId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            MedicationDetailPage(store: store, medicationId: medicationId),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.referenceDate,
    required this.onTap,
  });

  final Medication medication;
  final DateTime referenceDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = medication.statusAt(referenceDate);

    return Card(
      child: InkWell(
        key: ValueKey('medication-card-${medication.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      medication.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              MedicationStatusBadge(status: status),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Metadata(
                    icon: Icons.event_outlined,
                    text: 'Validade: ${formatDate(medication.expirationDate)}',
                  ),
                  _Metadata(
                    icon: Icons.inventory_2_outlined,
                    text: 'Quantidade: ${medication.quantity}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Sua farmácia está vazia',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre o primeiro medicamento para acompanhar sua validade.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar medicamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                'Não foi possível carregar os medicamentos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
