import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/scene.dart';
import '../domain/collection_point.dart';

/// "412 m", "1,2 km" ou "12 km".
String formatDistance(int meters) {
  if (meters < 1000) {
    return '$meters m';
  }
  final kilometers = meters / 1000;
  final text = kilometers < 10
      ? kilometers.toStringAsFixed(1).replaceAll('.', ',')
      : kilometers.round().toString();
  return '$text km';
}

/// Rótulo legível para os tipos de resíduo normalizados pela API Zelo.
String residueLabel(String type) => switch (type) {
  'medicamento' => 'Medicamentos',
  'seringa' => 'Seringas',
  '' => type,
  _ => type[0].toUpperCase() + type.substring(1),
};

/// Selo da origem do ponto: programa LogMed ou confirmação necessária.
class CollectionPointOriginBadge extends StatelessWidget {
  const CollectionPointOriginBadge({required this.point, super.key});

  final CollectionPoint point;

  @override
  Widget build(BuildContext context) {
    final verified = !point.requiresConfirmation;
    final (background, foreground, icon, label) = verified
        ? (
            ZeloColors.validTint,
            ZeloColors.validInk,
            Icons.verified_outlined,
            'Programa LogMed',
          )
        : (
            ZeloColors.expiringTint,
            ZeloColors.expiringInk,
            Icons.call_outlined,
            'Confirme antes de ir',
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ZeloRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 14, color: foreground)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Embalagem a caminho de um ponto de coleta.
class DisposalPathScene extends StatelessWidget {
  const DisposalPathScene({this.maxWidth = 280, super.key});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ScenePanel(
      semanticLabel: 'Ilustração: trajeto até um ponto de coleta',
      aspectRatio: 1.9,
      maxWidth: maxWidth,
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              child: ScenePackage(stripe: ZeloColors.expiredRed, height: 68),
            ),
            SizedBox(width: 8),
            Expanded(child: SceneDashedLine()),
            SizedBox(width: 8),
            SceneTile(
              icon: Icons.recycling,
              color: ZeloColors.validInk,
              size: 48,
            ),
            SizedBox(width: 8),
            Expanded(child: SceneDashedLine(color: ZeloColors.green)),
            SizedBox(width: 8),
            SceneTile(icon: Icons.location_on_outlined, size: 48),
          ],
        ),
      ),
    );
  }
}
