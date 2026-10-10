import 'package:flutter/material.dart';

import '../theme/zelo_colors.dart';
import '../theme/zelo_tokens.dart';

/// Bloco estático de carregamento. Não pisca, para respeitar a redução de
/// movimento sem lógica adicional.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    this.width,
    this.height = 14,
    this.radius = ZeloRadii.stamp,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ZeloColors.shelfDeep,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lista de cartões em carregamento, anunciada uma única vez.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 3, this.label = 'Carregando', super.key});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var index = 0; index < count; index++) ...[
              if (index > 0) const SizedBox(height: ZeloSpace.sm),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(ZeloSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 160, height: 16),
                      SizedBox(height: ZeloSpace.sm),
                      SkeletonBlock(width: 120),
                      SizedBox(height: ZeloSpace.sm),
                      SkeletonBlock(width: 200, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
