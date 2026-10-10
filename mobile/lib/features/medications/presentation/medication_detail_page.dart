import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/state_message.dart';
import '../application/medication_store.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';
import 'medication_form_page.dart';
import 'medication_presentation.dart';
import 'medication_scenes.dart';
import 'widgets/validity_track.dart';

class MedicationDetailPage extends StatefulWidget {
  const MedicationDetailPage({
    required this.store,
    required this.medicationId,
    super.key,
  });

  final MedicationStore store;
  final String medicationId;

  @override
  State<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  Medication? _lastKnown;
  var _isRemoving = false;

  MedicationStore get _store => widget.store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final found = _store.findById(widget.medicationId);
        // Durante a remoção, mantém o conteúdo até a página fechar.
        final medication = found ?? (_isRemoving ? _lastKnown : null);
        if (medication == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const CenteredState(
              child: StateMessage(
                illustration: EmptyShelfScene(),
                title: 'Medicamento não encontrado',
                message: 'Ele pode ter sido removido da sua farmácia.',
              ),
            ),
          );
        }
        _lastKnown = medication;
        return _buildDetails(context, medication);
      },
    );
  }

  Widget _buildDetails(BuildContext context, Medication medication) {
    final textTheme = Theme.of(context).textTheme;
    final today = _store.today;
    final status = medication.statusAt(today);
    final days = medication.daysUntilExpirationAt(today);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const ValueKey('edit-medication-button'),
            tooltip: 'Editar medicamento',
            onPressed: _isRemoving ? null : () => _edit(medication),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: const ValueKey('delete-medication-button'),
            tooltip: 'Remover medicamento',
            onPressed: _isRemoving ? null : () => _confirmRemoval(medication),
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: ZeloSpace.xxs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PageScrollView(
          padding: const EdgeInsets.fromLTRB(
            ZeloSpace.gutter,
            ZeloSpace.xxs,
            ZeloSpace.gutter,
            ZeloSpace.xxl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(medication.name, style: textTheme.headlineMedium),
            ),
            const SizedBox(height: ZeloSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: MedicationStatusBadge(status: status),
            ),
            const SizedBox(height: ZeloSpace.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(ZeloSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRAZO', style: textTheme.labelSmall),
                    const SizedBox(height: ZeloSpace.xxs),
                    Text(
                      describeExpiration(days),
                      style: textTheme.headlineSmall?.copyWith(
                        color: status.ink,
                      ),
                    ),
                    const SizedBox(height: ZeloSpace.lg),
                    ValidityTrack(daysUntilExpiration: days),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ZeloSpace.sm),
            Card(
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Data de validade',
                    value: formatDate(medication.expirationDate),
                  ),
                  const Divider(indent: 56),
                  _DetailRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Quantidade',
                    value: formatQuantity(medication.quantity),
                  ),
                  const Divider(indent: 56),
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'Observações',
                    value: medication.notes.isEmpty
                        ? 'Nenhuma observação'
                        : medication.notes,
                    isPlaceholder: medication.notes.isEmpty,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeloSpace.md),
            Text(
              'A situação considera a data atual e uma janela inicial de '
              '$defaultExpirationWarningDays dias para proximidade do '
              'vencimento.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(Medication medication) => openMedicationForm(
    context,
    medication: medication,
    onSave: (draft) => _store.update(medication.id, draft),
    referenceDate: _store.today,
  );

  Future<void> _confirmRemoval(Medication medication) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: ZeloColors.expiredRed,
              minimumSize: const Size(96, 48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isRemoving = true);
    try {
      await _store.remove(medication.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on MedicationRepositoryException catch (error) {
      if (mounted) {
        setState(() => _isRemoving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeloSpace.md,
          vertical: ZeloSpace.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: ZeloColors.inkMuted, size: 22),
            ),
            const SizedBox(width: ZeloSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(
                      color: isPlaceholder
                          ? ZeloColors.inkMuted
                          : ZeloColors.ink,
                      fontWeight: isPlaceholder
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
