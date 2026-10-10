import 'package:flutter/material.dart';

import '../../../../core/formatting/dates.dart';
import '../../../../core/theme/zelo_colors.dart';
import '../../../../core/theme/zelo_tokens.dart';
import '../../domain/medication.dart';
import '../medication_presentation.dart';

/// Composição da farmácia doméstica: total, barra proporcional por situação e
/// contagens exatas. A barra nunca é a única fonte da informação.
class PharmacyOverview extends StatelessWidget {
  const PharmacyOverview({
    required this.referenceDate,
    required this.validCount,
    required this.expiringCount,
    required this.expiredCount,
    super.key,
  });

  /// Data em que a situação foi calculada.
  final DateTime referenceDate;
  final int validCount;
  final int expiringCount;
  final int expiredCount;

  int get total => validCount + expiringCount + expiredCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final counts = {
      MedicationStatus.valid: validCount,
      MedicationStatus.expiringSoon: expiringCount,
      MedicationStatus.expired: expiredCount,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ZeloSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOJE, ${formatFullDate(referenceDate).toUpperCase()}',
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: ZeloSpace.xs),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: ZeloSpace.sm,
              children: [
                Text('$total', style: textTheme.displaySmall),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    total == 1
                        ? 'medicamento cadastrado'
                        : 'medicamentos cadastrados',
                    style: textTheme.bodyMedium?.copyWith(
                      color: ZeloColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZeloSpace.md),
            ExcludeSemantics(child: _CompositionBar(counts: counts)),
            const SizedBox(height: ZeloSpace.md),
            for (final entry in counts.entries)
              _LegendRow(status: entry.key, count: entry.value),
          ],
        ),
      ),
    );
  }
}

class _CompositionBar extends StatelessWidget {
  const _CompositionBar({required this.counts});

  final Map<MedicationStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final present = counts.entries.where((entry) => entry.value > 0).toList();
    if (present.isEmpty) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: ZeloColors.shelfDeep,
          borderRadius: BorderRadius.circular(ZeloRadii.pill),
        ),
      );
    }

    return SizedBox(
      height: 10,
      child: Row(
        children: [
          for (var index = 0; index < present.length; index++) ...[
            if (index > 0) const SizedBox(width: 3),
            Expanded(
              flex: present[index].value,
              child: Container(
                decoration: BoxDecoration(
                  color: present[index].key.accent,
                  borderRadius: BorderRadius.circular(ZeloRadii.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.status, required this.count});

  final MedicationStatus status;
  final int count;

  String get _label => switch (status) {
    MedicationStatus.valid => count == 1 ? 'Válido' : 'Válidos',
    MedicationStatus.expiringSoon =>
      count == 1 ? 'Próximo do vencimento' : 'Próximos do vencimento',
    MedicationStatus.expired => count == 1 ? 'Vencido' : 'Vencidos',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$count ${_label.toLowerCase()}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: status.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: ZeloSpace.sm),
            Expanded(child: Text(_label, style: textTheme.bodyMedium)),
            Text(
              '$count',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: count > 0 && status != MedicationStatus.valid
                    ? status.ink
                    : ZeloColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
