import 'package:flutter/material.dart';

import '../../../core/formatting/dates.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../domain/medication.dart';

export '../../../core/formatting/dates.dart' show formatDate;

extension MedicationStatusPresentation on MedicationStatus {
  String get label => switch (this) {
    MedicationStatus.valid => 'Válido',
    MedicationStatus.expiringSoon => 'Próximo do vencimento',
    MedicationStatus.expired => 'Vencido',
  };

  /// Cor da faixa e de elementos gráficos, sempre acompanhada de texto.
  Color get accent => switch (this) {
    MedicationStatus.valid => ZeloColors.green,
    MedicationStatus.expiringSoon => ZeloColors.warningAmber,
    MedicationStatus.expired => ZeloColors.expiredRed,
  };

  /// Fundo suave dos selos de situação.
  Color get tint => switch (this) {
    MedicationStatus.valid => ZeloColors.validTint,
    MedicationStatus.expiringSoon => ZeloColors.expiringTint,
    MedicationStatus.expired => ZeloColors.expiredTint,
  };

  /// Texto e ícones sobre o fundo ou sobre papel, com contraste AA.
  Color get ink => switch (this) {
    MedicationStatus.valid => ZeloColors.validInk,
    MedicationStatus.expiringSoon => ZeloColors.expiringInk,
    MedicationStatus.expired => ZeloColors.expiredInk,
  };

  IconData get icon => switch (this) {
    MedicationStatus.valid => Icons.check_circle_outline,
    MedicationStatus.expiringSoon => Icons.schedule,
    MedicationStatus.expired => Icons.error_outline,
  };
}

/// Frase completa sobre o prazo: "Vence em 12 dias", "Venceu há 5 dias".
String describeExpiration(int daysUntilExpiration) {
  final days = daysUntilExpiration;
  if (days == 0) {
    return 'Vence hoje';
  }
  if (days == 1) {
    return 'Vence amanhã';
  }
  if (days == -1) {
    return 'Venceu ontem';
  }
  return days > 1 ? 'Vence em ${_span(days)}' : 'Venceu há ${_span(-days)}';
}

/// Complemento curto da situação: "vence em 12 dias", "há 5 dias".
String expirationDetail(int daysUntilExpiration) {
  final days = daysUntilExpiration;
  if (days == -1) {
    return 'ontem';
  }
  if (days < -1) {
    return 'há ${_span(-days)}';
  }
  return describeExpiration(days).toLowerCase();
}

String formatQuantity(int quantity) =>
    quantity == 1 ? '1 unidade' : '$quantity unidades';

String _span(int days) {
  if (days <= 60) {
    return '$days dias';
  }
  if (days < 365) {
    return 'cerca de ${(days / 30).round()} meses';
  }
  final years = (days / 365).round();
  return years == 1 ? 'cerca de 1 ano' : 'cerca de $years anos';
}

/// Selo de situação com fundo suave e texto em tom escuro (contraste AA).
class MedicationStatusBadge extends StatelessWidget {
  const MedicationStatusBadge({required this.status, super.key});

  final MedicationStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(ZeloRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(status.icon, size: 16, color: status.ink),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: status.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carimbo de validade, como o "VAL" impresso nas embalagens.
class ValidityStamp extends StatelessWidget {
  const ValidityStamp({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: 'Validade ${formatDate(date)}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC9D4D2)),
          borderRadius: BorderRadius.circular(ZeloRadii.stamp),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VAL',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                formatDate(date),
                style: textTheme.labelMedium?.copyWith(
                  color: ZeloColors.inkSoft,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa vertical de situação, a "tarja" dos cartões de medicamento.
class StatusStripe extends StatelessWidget {
  const StatusStripe({required this.status, super.key});

  final MedicationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: status.accent,
        borderRadius: BorderRadius.circular(ZeloRadii.pill),
      ),
    );
  }
}
