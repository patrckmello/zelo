import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/widgets/scene.dart';

/// Prateleira vazia com o lugar da primeira embalagem.
class EmptyShelfScene extends StatelessWidget {
  const EmptyShelfScene({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScenePanel(
      semanticLabel: 'Ilustração: prateleira vazia',
      aspectRatio: 1.7,
      maxWidth: 280,
      child: SceneShelf(
        children: [
          ScenePackage(stripe: ZeloColors.green, height: 70),
          ScenePackage(
            stripe: ZeloColors.hairline,
            icon: Icons.add,
            height: 92,
            outlined: true,
          ),
          SizedBox(height: 56),
        ],
      ),
    );
  }
}

/// Embalagem e sinal de falha de sincronização.
class LoadFailureScene extends StatelessWidget {
  const LoadFailureScene({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScenePanel(
      semanticLabel: 'Ilustração: falha ao carregar',
      aspectRatio: 1.7,
      maxWidth: 280,
      tint: ZeloColors.expiredTint,
      showSymbol: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ScenePackage(stripe: ZeloColors.hairline, height: 92),
          ),
          SizedBox(width: 16),
          SceneTile(
            icon: Icons.sync_problem_outlined,
            color: ZeloColors.expiredInk,
          ),
        ],
      ),
    );
  }
}
