import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zelo_colors.dart';
import '../theme/zelo_tokens.dart';
import 'brand_symbol.dart';

/// Assinatura da abertura: símbolo oficial, nome, slogan e a faixa de
/// validade (verde, âmbar, vermelho) que resume o que o app acompanha.
///
/// [reveal] vai de 0 (só o símbolo, como na splash nativa) a 1 (assinatura
/// completa). A abertura anima esse valor; o carregamento usa 1 e, com
/// [loading], percorre a faixa enquanto a inicialização real não termina.
class BrandLockup extends StatelessWidget {
  const BrandLockup({this.reveal = 1, this.loading = false, super.key});

  final double reveal;
  final bool loading;

  static const startSymbolSize = 144.0;
  static const endSymbolSize = 104.0;
  static const tagline = ['Cuide.', 'Organize.', 'Descarte certo.'];

  @override
  Widget build(BuildContext context) {
    double phase(
      double begin,
      double end, [
      Curve curve = Curves.easeOutCubic,
    ]) => curve.transform(((reveal - begin) / (end - begin)).clamp(0.0, 1.0));

    final symbolIn = phase(0, 0.4);
    final settle = phase(0.3, 0.65);
    final textTheme = Theme.of(context).textTheme;
    final symbolSize =
        startSymbolSize + (endSymbolSize - startSymbolSize) * settle;

    return Semantics(
      container: true,
      label: 'Zelo. ${tagline.join(' ')}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.65 + 0.35 * symbolIn,
              child: Transform.rotate(
                angle: -0.18 * 2 * math.pi * (1 - symbolIn),
                child: Transform.scale(
                  scale: 0.82 + 0.18 * symbolIn,
                  child: SizedBox.square(
                    dimension: symbolSize,
                    child: Image.asset(
                      BrandSymbol.assetPath,
                      key: const ValueKey('zelo-brand-symbol'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            // O bloco de texto cresce a partir de zero para que o símbolo
            // comece exatamente no centro, como na splash nativa.
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: settle,
                child: Padding(
                  padding: const EdgeInsets.only(top: ZeloSpace.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Rise(
                        value: phase(0.35, 0.7),
                        child: Text(
                          'Zelo',
                          style: textTheme.displaySmall?.copyWith(
                            color: ZeloColors.ink,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: ZeloSpace.xs),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        children: [
                          for (final (index, word) in tagline.indexed)
                            _Rise(
                              value: phase(
                                0.5 + index * 0.1,
                                0.72 + index * 0.1,
                              ),
                              child: Text(
                                word,
                                style: textTheme.titleSmall?.copyWith(
                                  color: index == tagline.length - 1
                                      ? ZeloColors.validInk
                                      : ZeloColors.inkSoft,
                                  fontWeight: index == tagline.length - 1
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: ZeloSpace.lg),
                      ValidityBar(
                        drawn: phase(0.72, 1, Curves.easeInOutCubic),
                        loading: loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrada curta de baixo para cima com opacidade.
class _Rise extends StatelessWidget {
  const _Rise({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - value)),
        child: child,
      ),
    );
  }
}

/// Faixa em três segmentos (válido, próximo, vencido). [drawn] desenha a
/// faixa da esquerda para a direita; [loading] passa um brilho por ela.
class ValidityBar extends StatefulWidget {
  const ValidityBar({
    this.drawn = 1,
    this.loading = false,
    this.width = 132,
    super.key,
  });

  final double drawn;
  final bool loading;
  final double width;

  @override
  State<ValidityBar> createState() => _ValidityBarState();
}

class _ValidityBarState extends State<ValidityBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ValidityBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.loading && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_sweep.isAnimating) {
      _sweep.repeat();
    } else if (!animate && _sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 6,
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) => CustomPaint(
          painter: _ValidityBarPainter(
            drawn: widget.drawn,
            sweep: _sweep.isAnimating ? _sweep.value : null,
          ),
        ),
      ),
    );
  }
}

class _ValidityBarPainter extends CustomPainter {
  _ValidityBarPainter({required this.drawn, required this.sweep});

  final double drawn;
  final double? sweep;

  static const _segments = [
    (ZeloColors.green, 0.5),
    (ZeloColors.warningAmber, 0.3),
    (ZeloColors.expiredRed, 0.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 4.0;
    final usable = size.width - gap * (_segments.length - 1);
    final limit = size.width * drawn;
    var x = 0.0;
    for (final (color, share) in _segments) {
      final width = usable * share;
      final visible = (limit - x).clamp(0.0, width);
      if (visible > 0) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, visible, size.height),
          Radius.circular(size.height / 2),
        );
        canvas.drawRRect(rect, Paint()..color = color);
      }
      x += width + gap;
    }

    if (sweep case final value?) {
      // Brilho que atravessa a faixa enquanto a inicialização continua.
      final center = -0.25 + 1.5 * value;
      final shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0),
        ],
        stops: [
          (center - 0.18).clamp(0.0, 1.0),
          center.clamp(0.0, 1.0),
          (center + 0.18).clamp(0.0, 1.0),
        ],
      ).createShader(Offset.zero & size);
      canvas.saveLayer(Offset.zero & size, Paint());
      x = 0;
      for (final (_, share) in _segments) {
        final width = usable * share;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 0, width, size.height),
            Radius.circular(size.height / 2),
          ),
          Paint()..shader = shader,
        );
        x += width + gap;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ValidityBarPainter oldDelegate) =>
      oldDelegate.drawn != drawn || oldDelegate.sweep != sweep;
}
