import 'package:flutter/material.dart';

import '../application/medication_store.dart';
import '../domain/medication.dart';
import 'medication_form_page.dart';
import 'medication_presentation.dart';

class MedicationDetailPage extends StatelessWidget {
  const MedicationDetailPage({
    required this.store,
    required this.medicationId,
    super.key,
  });

  final MedicationStore store;
  final String medicationId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final medication = store.findById(medicationId);
        if (medication == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Medicamento')),
            body: const Center(child: Text('Medicamento não encontrado.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes'),
            actions: [
              IconButton(
                key: const ValueKey('edit-medication-button'),
                tooltip: 'Editar medicamento',
                onPressed: () => _edit(context, medication),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: const ValueKey('delete-medication-button'),
                tooltip: 'Remover medicamento',
                onPressed: () => _confirmRemoval(context, medication),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: MedicationStatusBadge(
                          status: medication.statusAt(store.today),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.event_outlined,
                                label: 'Data de validade',
                                value: formatDate(medication.expirationDate),
                              ),
                              const Divider(height: 28),
                              _DetailRow(
                                icon: Icons.inventory_2_outlined,
                                label: 'Quantidade',
                                value: medication.quantity.toString(),
                              ),
                              const Divider(height: 28),
                              _DetailRow(
                                icon: Icons.notes_outlined,
                                label: 'Observações',
                                value: medication.notes.isEmpty
                                    ? 'Nenhuma observação'
                                    : medication.notes,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A situação considera a data atual e uma janela inicial '
                        'de $defaultExpirationWarningDays dias para proximidade '
                        'do vencimento.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, Medication medication) async {
    final draft = await Navigator.of(context).push<MedicationDraft>(
      MaterialPageRoute(
        builder: (_) => MedicationFormPage(medication: medication),
      ),
    );

    if (draft == null || !context.mounted) {
      return;
    }

    store.update(medication.id, draft);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Medicamento atualizado.')));
  }

  Future<void> _confirmRemoval(
    BuildContext context,
    Medication medication,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover medicamento?'),
        content: Text(
          '${medication.name} será removido da sua farmácia doméstica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-medication-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    store.remove(medication.id);
    Navigator.of(context).pop();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
