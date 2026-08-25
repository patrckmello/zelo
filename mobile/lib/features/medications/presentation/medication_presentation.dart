import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../domain/medication.dart';

extension MedicationStatusPresentation on MedicationStatus {
  String get label => switch (this) {
    MedicationStatus.valid => 'Válido',
    MedicationStatus.expiringSoon => 'Próximo do vencimento',
    MedicationStatus.expired => 'Vencido',
  };

  Color get color => switch (this) {
    MedicationStatus.valid => ZeloColors.green,
    MedicationStatus.expiringSoon => ZeloColors.warningAmber,
    MedicationStatus.expired => ZeloColors.expiredRed,
  };

  IconData get icon => switch (this) {
    MedicationStatus.valid => Icons.check_circle_outline,
    MedicationStatus.expiringSoon => Icons.schedule,
    MedicationStatus.expired => Icons.error_outline,
  };
}

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class MedicationStatusBadge extends StatelessWidget {
  const MedicationStatusBadge({required this.status, super.key});

  final MedicationStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 16, color: status.color),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: status.color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
