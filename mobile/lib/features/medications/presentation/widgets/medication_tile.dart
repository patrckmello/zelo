import 'package:flutter/material.dart';

import '../../../../core/theme/zelo_colors.dart';
import '../../../../core/theme/zelo_tokens.dart';
import '../../domain/medication.dart';
import '../medication_presentation.dart';

/// Cartão de medicamento: faixa de situação, nome, prazo e carimbo VAL.
class MedicationTile extends StatelessWidget {
  const MedicationTile({
    required this.medication,
    required this.referenceDate,
    required this.onTap,
    super.key,
  });

  final Medication medication;
  final DateTime referenceDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = medication.statusAt(referenceDate);
    final days = medication.daysUntilExpirationAt(referenceDate);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        key: ValueKey('medication-card-${medication.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ZeloSpace.sm,
            ZeloSpace.sm,
            ZeloSpace.xs,
            ZeloSpace.sm,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusStripe(status: status),
                const SizedBox(width: ZeloSpace.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: ZeloSpace.xxs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: status.label,
                                style: TextStyle(
                                  color: status.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' · ${expirationDetail(days)}'),
                            ],
                          ),
                          style: textTheme.bodyMedium?.copyWith(
                            color: ZeloColors.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: ZeloSpace.xs),
                        Wrap(
                          spacing: ZeloSpace.sm,
                          runSpacing: ZeloSpace.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ValidityStamp(date: medication.expirationDate),
                            Text(
                              formatQuantity(medication.quantity),
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.only(left: ZeloSpace.xxs),
                    child: Icon(
                      Icons.chevron_right,
                      color: ZeloColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
