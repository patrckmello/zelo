import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_message.dart';
import '../application/medication_store.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';
import '../domain/medication_scan.dart';
import 'medication_detail_page.dart';
import 'medication_form_page.dart';
import 'medication_scenes.dart';
import 'widgets/medication_tile.dart';

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({
    required this.store,
    this.initialFilter,
    this.scanner,
    super.key,
  });

  final MedicationStore store;
  final MedicationStatus? initialFilter;
  final MedicationScanner? scanner;

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  late MedicationStatus? _filter = widget.initialFilter;

  MedicationStore get _store => widget.store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(listenable: _store, builder: _buildBody),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-medication-button'),
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Widget? _) {
    if (_store.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          ZeloSpace.gutter,
          ZeloSpace.xs,
          ZeloSpace.gutter,
          0,
        ),
        child: SkeletonList(label: 'Carregando medicamentos'),
      );
    }

    if (_store.status == MedicationLoadStatus.failure) {
      return CenteredState(
        child: StateMessage(
          liveRegion: true,
          illustration: const LoadFailureScene(),
          title: 'Não foi possível carregar os medicamentos',
          message: _store.errorMessage ?? MedicationStore.loadErrorMessage,
          action: OutlinedButton.icon(
            onPressed: _store.retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
      );
    }

    final medications = _store.medications;
    if (medications.isEmpty) {
      return CenteredState(
        child: StateMessage(
          illustration: const EmptyShelfScene(),
          title: 'Sua farmácia está vazia',
          message:
              'Cadastre o primeiro medicamento para acompanhar sua validade.',
          action: FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar medicamento'),
          ),
        ),
      );
    }

    final today = _store.today;
    final visible = _filter == null
        ? medications
        : _store.medicationsWithStatus(_filter!);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          ZeloSpace.gutter,
          ZeloSpace.xxs,
          ZeloSpace.gutter,
          96,
        ),
        children: [
          _FilterBar(
            selected: _filter,
            total: medications.length,
            countOf: _store.countByStatus,
            onSelected: (status) => setState(() => _filter = status),
          ),
          const SizedBox(height: ZeloSpace.md),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ZeloSpace.xl),
              child: Text(
                'Nenhum medicamento nesta situação.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: ZeloColors.inkMuted),
              ),
            ),
          for (final medication in visible) ...[
            MedicationTile(
              medication: medication,
              referenceDate: today,
              onTap: () => _openDetails(medication.id),
            ),
            const SizedBox(height: ZeloSpace.sm),
          ],
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    try {
      await _store.refresh();
    } on MedicationRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _add() => openMedicationForm(
    context,
    onSave: _store.add,
    referenceDate: _store.today,
    scanner: widget.scanner,
  );

  Future<void> _openDetails(String medicationId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            MedicationDetailPage(store: _store, medicationId: medicationId),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.total,
    required this.countOf,
    required this.onSelected,
  });

  final MedicationStatus? selected;
  final int total;
  final int Function(MedicationStatus status) countOf;
  final ValueChanged<MedicationStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <(MedicationStatus?, String, int)>[
      (null, 'Todos', total),
      (MedicationStatus.expired, 'Vencidos', countOf(MedicationStatus.expired)),
      (
        MedicationStatus.expiringSoon,
        'Próximos',
        countOf(MedicationStatus.expiringSoon),
      ),
      (MedicationStatus.valid, 'Válidos', countOf(MedicationStatus.valid)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (status, label, count) in options) ...[
            ChoiceChip(
              key: ValueKey('medication-filter-${status?.name ?? 'all'}'),
              selected: selected == status,
              onSelected: (_) => onSelected(status),
              label: Text('$label  $count'),
            ),
            const SizedBox(width: ZeloSpace.xs),
          ],
        ],
      ),
    );
  }
}
