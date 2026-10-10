import 'package:flutter/material.dart';

import '../theme/zelo_colors.dart';
import '../theme/zelo_tokens.dart';
import 'brand_symbol.dart';

/// Painel das composições ilustrativas: superfície tingida, cantos amplos e o
/// símbolo oficial em marca-d'água, sem redesenhar a marca.
class ScenePanel extends StatelessWidget {
  const ScenePanel({
    required this.child,
    required this.semanticLabel,
    this.aspectRatio = 1.5,
    this.maxWidth = 320,
    this.tint = ZeloColors.greenTint,
    this.showSymbol = true,
    super.key,
  });

  final Widget child;
  final String semanticLabel;
  final double aspectRatio;
  final double maxWidth;
  final Color tint;
  final bool showSymbol;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(ZeloRadii.sheet),
              ),
              child: Stack(
                children: [
                  if (showSymbol)
                    const Positioned(
                      top: 14,
                      right: 14,
                      child: Opacity(
                        opacity: 0.16,
                        child: BrandSymbol(size: 48, decorative: true),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(ZeloSpace.lg),
                      child: child,
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

/// Embalagem de medicamento: cartão de papel com a faixa de validade na base,
/// como a tarja impressa nas caixas.
class ScenePackage extends StatelessWidget {
  const ScenePackage({
    required this.stripe,
    this.icon = Icons.medication_outlined,
    this.height = 96,
    this.width,
    this.outlined = false,
    super.key,
  });

  final Color stripe;
  final IconData icon;
  final double height;
  final double? width;

  /// Desenha somente o contorno, para lugares ainda vazios.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ZeloRadii.control);
    if (outlined) {
      return CustomPaint(
        painter: _DashedRectPainter(color: ZeloColors.fieldBorder),
        child: SizedBox(
          height: height,
          width: width,
          child: Icon(icon, color: ZeloColors.inkMuted, size: 24),
        ),
      );
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: ZeloColors.paper,
        borderRadius: radius,
        border: Border.all(color: ZeloColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: ZeloColors.ink, size: 22),
                  const Spacer(),
                  const _StampLine(width: 34),
                  const SizedBox(height: 4),
                  const _StampLine(width: 22),
                ],
              ),
            ),
          ),
          Container(height: 8, color: stripe),
        ],
      ),
    );
  }
}

/// Selo da cena: superfície tingida com um ícone da ação.
class SceneTile extends StatelessWidget {
  const SceneTile({
    required this.icon,
    this.color = ZeloColors.petroleumBlue,
    this.background,
    this.size = 56,
    super.key,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? ZeloColors.paper,
        borderRadius: BorderRadius.circular(ZeloRadii.control + 2),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// Trajeto tracejado horizontal, usado no caminho até o descarte.
class SceneDashedLine extends StatelessWidget {
  const SceneDashedLine({
    this.color = ZeloColors.petroleumBlue,
    this.thickness = 3,
    super.key,
  });

  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color, thickness: thickness),
        size: Size.infinite,
      ),
    );
  }
}

/// Prateleira: base sobre a qual as embalagens se apoiam.
class SceneShelf extends StatelessWidget {
  const SceneShelf({required this.children, this.spacing = 12, super.key});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZeloSpace.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) SizedBox(width: spacing),
                Expanded(child: children[index]),
              ],
            ],
          ),
        ),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: ZeloColors.petroleumBlue.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(ZeloRadii.pill),
          ),
        ),
      ],
    );
  }
}

class _StampLine extends StatelessWidget {
  const _StampLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: ZeloColors.hairline,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color, required this.thickness});

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 7.0;
    final y = size.height / 2;
    for (var x = thickness / 2; x < size.width; x += dash + gap) {
      final end = (x + dash).clamp(0, size.width - thickness / 2).toDouble();
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.thickness != thickness;
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(ZeloRadii.control),
        ),
      );
    for (final metric in path.computeMetrics()) {
      const dash = 6.0;
      const gap = 5.0;
      for (
        var distance = 0.0;
        distance < metric.length;
        distance += dash + gap
      ) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
