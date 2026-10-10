import 'package:flutter/material.dart';

import '../../../../core/theme/zelo_colors.dart';
import '../../../../core/theme/zelo_tokens.dart';
import '../../domain/medication.dart';
import '../medication_presentation.dart';

/// Linha de validade: mostra em que trecho do ciclo o medicamento está hoje.
///
/// O trilho tem três zonas — válido, atenção (janela de [warningDays]) e
/// vencido — e um marcador "Hoje". A posição é ilustrativa; a data exata é
/// sempre apresentada em texto.
class ValidityTrack extends StatelessWidget {
  const ValidityTrack({
    required this.daysUntilExpiration,
    this.warningDays = defaultExpirationWarningDays,
    super.key,
  });

  final int daysUntilExpiration;
  final int warningDays;

  static const _validShare = 0.5;
  static const _warningShare = 0.3;
  static const _expiredShare = 0.2;
  static const _validHorizonDays = 335;
  static const _expiredHorizonDays = 60;

  MedicationStatus get _status => statusForDaysUntilExpiration(
    daysUntilExpiration,
    warningDays: warningDays,
  );

  /// Posição do marcador entre 0 (início) e 1 (fim do trilho).
  double get markerPosition {
    final days = daysUntilExpiration;
    if (days > warningDays) {
      final beyond = (days - warningDays).clamp(0, _validHorizonDays);
      return _validShare * (1 - beyond / _validHorizonDays);
    }
    if (days >= 0) {
      final elapsed = warningDays == 0 ? 1 : (warningDays - days) / warningDays;
      return _validShare + _warningShare * elapsed;
    }
    final overdue = (-days).clamp(0, _expiredHorizonDays);
    return _validShare +
        _warningShare +
        _expiredShare * overdue / _expiredHorizonDays;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelSmall;
    final alignment = Alignment(markerPosition * 2 - 1, 0);

    return Semantics(
      label:
          'Linha de validade: ${status.label.toLowerCase()}, '
          '${expirationDetail(daysUntilExpiration)}. A atenção começa '
          '$warningDays dias antes da validade.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: alignment,
              child: Text(
                'Hoje',
                style: labelStyle?.copyWith(
                  color: status.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 18,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      _zone(MedicationStatus.valid, _validShare, status),
                      const SizedBox(width: 3),
                      _zone(
                        MedicationStatus.expiringSoon,
                        _warningShare,
                        status,
                      ),
                      const SizedBox(width: 3),
                      _zone(MedicationStatus.expired, _expiredShare, status),
                    ],
                  ),
                  Align(
                    alignment: alignment,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: status.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: ZeloColors.paper, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33174C5B),
                            blurRadius: 0,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeloSpace.xs),
            Row(
              children: [
                _caption('Válido', _validShare, labelStyle),
                const SizedBox(width: 3),
                _caption('Atenção', _warningShare, labelStyle),
                const SizedBox(width: 3),
                _caption('Vencido', _expiredShare, labelStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _zone(MedicationStatus zone, double share, MedicationStatus current) {
    return Expanded(
      flex: (share * 100).round(),
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: zone == current
              ? zone.accent
              : zone.accent.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(ZeloRadii.pill),
        ),
      ),
    );
  }

  Widget _caption(String text, double share, TextStyle? style) {
    return Expanded(
      flex: (share * 100).round(),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
