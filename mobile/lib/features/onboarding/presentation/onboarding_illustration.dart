import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';

enum OnboardingVisual { organization, wastePrevention, responsibleDisposal }

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    required this.visual,
    required this.pageNumber,
    required this.semanticLabel,
    super.key,
  });

  final OnboardingVisual visual;
  final int pageNumber;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: AspectRatio(
            aspectRatio: 1.45,
            child: DecoratedBox(
              key: ValueKey('onboarding-illustration-$pageNumber'),
              decoration: BoxDecoration(
                color: ZeloColors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.asset(
                          'assets/branding/zelo-symbol.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: switch (visual) {
                        OnboardingVisual.organization =>
                          const _OrganizationScene(),
                        OnboardingVisual.wastePrevention =>
                          const _WastePreventionScene(),
                        OnboardingVisual.responsibleDisposal =>
                          const _DisposalScene(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganizationScene extends StatelessWidget {
  const _OrganizationScene();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _SceneCard(icon: Icons.medication_outlined, height: 112),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _SceneCard(icon: Icons.inventory_2_outlined, height: 76),
          ),
          SizedBox(width: 12),
          Expanded(child: _SceneCard(icon: Icons.event_outlined, height: 96)),
        ],
      ),
    );
  }
}

class _WastePreventionScene extends StatelessWidget {
  const _WastePreventionScene();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: _SceneCard(icon: Icons.calendar_month_outlined, height: 126),
          ),
          SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: _SceneIcon(
              icon: Icons.notifications_active_outlined,
              color: ZeloColors.warningAmber,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisposalScene extends StatelessWidget {
  const _DisposalScene();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          _SceneIcon(icon: Icons.medication_outlined),
          Expanded(child: Divider(thickness: 3)),
          _SceneIcon(icon: Icons.recycling_outlined, color: ZeloColors.green),
          Expanded(child: Divider(thickness: 3)),
          _SceneIcon(icon: Icons.location_on_outlined),
        ],
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.icon, required this.height});

  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ZeloColors.petroleumBlue.withValues(alpha: 0.12),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: ZeloColors.petroleumBlue, size: 28),
    );
  }
}

class _SceneIcon extends StatelessWidget {
  const _SceneIcon({required this.icon, this.color = ZeloColors.petroleumBlue});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 28),
    );
  }
}
