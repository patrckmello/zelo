import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/brand_lockup.dart';

enum OnboardingVisual { organization, wastePrevention, responsibleDisposal }

/// Cena animada de cada página do onboarding, feita com as mesmas peças da
/// interface (embalagem com faixa de validade, carimbo VAL, faixa de três
/// segmentos), sem redesenhar a marca (D024, D037).
///
/// A animação toca quando a página fica [active]; com redução de movimento,
/// a cena aparece pronta. [parallax] desloca as peças durante o arraste.
class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({
    required this.visual,
    required this.pageNumber,
    required this.semanticLabel,
    this.active = true,
    this.parallax = 0,
    super.key,
  });

  final OnboardingVisual visual;
  final int pageNumber;
  final String semanticLabel;
  final bool active;
  final double parallax;

  static Color tintFor(OnboardingVisual visual) => switch (visual) {
    OnboardingVisual.organization => ZeloColors.greenTint,
    OnboardingVisual.wastePrevention => ZeloColors.expiringTint,
    OnboardingVisual.responsibleDisposal => ZeloColors.petroleumTint,
  };

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(restart: false);
  }

  @override
  void didUpdateWidget(OnboardingIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _sync(restart: true);
    }
  }

  void _sync({required bool restart}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.active) {
      if (restart || _controller.value == 0) {
        _controller.forward(from: 0);
      }
    } else {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      image: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: ValueKey('onboarding-illustration-${widget.pageNumber}'),
          decoration: BoxDecoration(
            color: OnboardingIllustration.tintFor(widget.visual),
            borderRadius: BorderRadius.circular(32),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            // A cena é decorativa (descrita por [semanticLabel]); seus rótulos
            // não acompanham a escala de texto para não quebrar a composição.
            child: MediaQuery.withNoTextScaling(
              child: LayoutBuilder(
                builder: (context, constraints) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final size = constraints.biggest;
                    final t = _controller.value;
                    return switch (widget.visual) {
                      OnboardingVisual.organization => _ShelfScene(
                        t: t,
                        size: size,
                        parallax: widget.parallax,
                      ),
                      OnboardingVisual.wastePrevention => _TrackScene(
                        t: t,
                        size: size,
                        parallax: widget.parallax,
                      ),
                      OnboardingVisual.responsibleDisposal => _RouteScene(
                        t: t,
                        size: size,
                        parallax: widget.parallax,
                      ),
                    };
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _phase(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) => curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// Página 1: três embalagens pousam na prateleira, recebem o carimbo VAL e a
/// faixa de validade resume a farmácia.
class _ShelfScene extends StatelessWidget {
  const _ShelfScene({
    required this.t,
    required this.size,
    required this.parallax,
  });

  final double t;
  final Size size;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    const packages = [
      (ZeloColors.green, Icons.medication_outlined, 132.0, '03/27'),
      (
        ZeloColors.warningAmber,
        Icons.medication_liquid_outlined,
        104.0,
        '10/26',
      ),
      (ZeloColors.green, Icons.vaccines_outlined, 118.0, '08/27'),
    ];
    final width = math.min(size.width - 48, 300.0);
    final packageWidth = (width - 2 * 14) / 3;
    final shelfY = size.height * 0.68;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Prateleira.
        Positioned(
          left: (size.width - width - 24) / 2,
          width: width + 24,
          top: shelfY,
          height: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ZeloColors.paper.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(ZeloRadii.pill),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14174C5B),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        for (final (index, package) in packages.indexed)
          _placed(
            index: index,
            package: package,
            left: (size.width - width) / 2 + index * (packageWidth + 14),
            width: packageWidth,
            shelfY: shelfY,
          ),
        Positioned(
          left: 0,
          right: 0,
          top: shelfY + 34,
          child: Center(
            child: Opacity(
              opacity: _phase(t, 0.7, 0.85),
              child: ValidityBar(
                drawn: _phase(t, 0.72, 1),
                width: width * 0.66,
              ),
            ),
          ),
        ),
        // Resumo, como o painel da Início.
        Positioned(
          left: 0,
          right: 0,
          top: size.height * 0.1,
          child: Center(
            child: Opacity(
              opacity: _phase(t, 0.82, 1),
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - _phase(t, 0.82, 1))),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ZeloColors.paper,
                    borderRadius: BorderRadius.circular(ZeloRadii.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14174C5B),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(
                          text: '3 ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: 'medicamentos · '),
                        TextSpan(
                          text: '1 vence em breve',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ZeloColors.expiringInk,
                          ),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: ZeloColors.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placed({
    required int index,
    required (Color, IconData, double, String) package,
    required double left,
    required double width,
    required double shelfY,
  }) {
    final (stripe, icon, height, stamp) = package;
    final drop = _phase(
      t,
      0.08 * index,
      0.3 + 0.08 * index,
      Curves.easeOutBack,
    );
    final mark = _phase(t, 0.45 + 0.08 * index, 0.6 + 0.08 * index);
    return Positioned(
      left: left + parallax * (18 + index * 14),
      width: width,
      top: shelfY - height - (1 - drop) * (shelfY + 40),
      height: height,
      child: Opacity(
        opacity: drop.clamp(0.0, 1.0),
        child: _Package(
          stripe: stripe,
          icon: icon,
          stamp: stamp,
          stampIn: mark,
        ),
      ),
    );
  }
}

/// Embalagem da cena com carimbo de validade que "bate" ao aparecer.
class _Package extends StatelessWidget {
  const _Package({
    required this.stripe,
    required this.icon,
    required this.stamp,
    required this.stampIn,
    this.compact = false,
  });

  final Color stripe;
  final IconData icon;
  final String stamp;
  final double stampIn;

  /// Versão pequena, só com o ícone e a faixa.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ZeloColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZeloColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12174C5B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: compact
                ? Center(child: Icon(icon, color: ZeloColors.ink, size: 18))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: ZeloColors.ink, size: 22),
                        const Spacer(),
                        Opacity(
                          opacity: stampIn,
                          child: Transform.rotate(
                            angle: -0.08,
                            child: Transform.scale(
                              scale: 1 + 0.7 * (1 - stampIn),
                              alignment: Alignment.centerLeft,
                              child: _MiniStamp(text: stamp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(height: compact ? 8 : 10, color: stripe),
        ],
      ),
    );
  }
}

class _MiniStamp extends StatelessWidget {
  const _MiniStamp({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: ZeloColors.fieldBorder, width: 1.2),
          borderRadius: BorderRadius.circular(ZeloRadii.stamp),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'VAL ',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: const TextStyle(color: ZeloColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

/// Página 2: o marcador "Hoje" avança pela linha de validade, entra na
/// janela de 30 dias e a embalagem passa de verde a âmbar.
class _TrackScene extends StatelessWidget {
  const _TrackScene({
    required this.t,
    required this.size,
    required this.parallax,
  });

  final double t;
  final Size size;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = math.min(size.width - 56, 290.0);
    final left = (size.width - width) / 2;
    final trackY = size.height * 0.72;
    final move = _phase(t, 0.15, 0.7, Curves.easeInOutCubic);
    final marker = lerpDouble(0.12, 0.66, move)!;
    final warn = _phase(t, 0.5, 0.7);
    final card = _phase(t, 0.68, 0.92, Curves.easeOutBack);
    final stripe = Color.lerp(ZeloColors.green, ZeloColors.warningAmber, warn)!;
    final packageHeight = math.min(size.height * 0.36, 128.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Embalagem acompanhada.
        Positioned(
          left: left + parallax * 20,
          top: trackY - packageHeight - 44,
          width: 108,
          height: packageHeight,
          child: _Package(
            stripe: stripe,
            icon: Icons.medication_outlined,
            stamp: '10/26',
            stampIn: _phase(t, 0.05, 0.25),
          ),
        ),
        // Item de atenção, como na Início.
        Positioned(
          right: left - 4 - parallax * 36,
          top: trackY - packageHeight - 60 + 12 * (1 - card),
          width: math.min(width * 0.6, 176),
          child: Opacity(
            opacity: card.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.9 + 0.1 * card,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                decoration: BoxDecoration(
                  color: ZeloColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A174C5B),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ZeloColors.warningAmber,
                        borderRadius: BorderRadius.circular(ZeloRadii.pill),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Loratadina',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: ZeloColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Vence em 12 dias',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: ZeloColors.expiringInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Linha de validade: válido, janela de 30 dias, vencido.
        Positioned(
          left: left,
          width: width,
          top: trackY,
          height: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 55,
                child: _segment(ZeloColors.green.withValues(alpha: 0.55)),
              ),
              const SizedBox(width: 4),
              Expanded(flex: 28, child: _segment(ZeloColors.warningAmber)),
              const SizedBox(width: 4),
              Expanded(
                flex: 17,
                child: _segment(ZeloColors.expiredRed.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        Positioned(
          left: left + width * 0.55 + 4,
          top: trackY + 18,
          child: Text(
            '30 dias',
            style: textTheme.labelSmall?.copyWith(
              color: ZeloColors.expiringInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Marcador "Hoje".
        Positioned(
          left: left + width * marker - 22,
          top: trackY - 34,
          width: 44,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ZeloColors.ink,
                  borderRadius: BorderRadius.circular(ZeloRadii.pill),
                ),
                child: const Text(
                  'Hoje',
                  style: TextStyle(
                    color: ZeloColors.paper,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(width: 2, height: 10, color: ZeloColors.ink),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: ZeloColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: ZeloColors.ink, width: 4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segment(Color color) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(ZeloRadii.pill),
    ),
  );
}

/// Página 3: a embalagem vencida segue o trajeto até o ponto de coleta, que
/// confirma o descarte.
class _RouteScene extends StatelessWidget {
  const _RouteScene({
    required this.t,
    required this.size,
    required this.parallax,
  });

  final double t;
  final Size size;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final start = Offset(size.width * 0.2, size.height * 0.74);
    final end = Offset(size.width * 0.74, size.height * 0.36);
    final control = Offset(size.width * 0.28, size.height * 0.24);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final metric = path.computeMetrics().first;
    final travel = _phase(t, 0.25, 0.75, Curves.easeInOutCubic);
    final tangent = metric.getTangentForOffset(metric.length * travel)!;
    final arrived = _phase(t, 0.75, 0.95, Curves.easeOutBack);
    final pins = _phase(t, 0, 0.3, Curves.easeOutBack);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _StreetsPainter(shift: parallax * 30)),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _RoutePainter(path: path, progress: travel),
          ),
        ),
        // Origem: a casa da pessoa.
        Positioned(
          left: start.dx - 24,
          top: start.dy - 4,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ZeloColors.paper,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A174C5B),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.home_outlined, color: ZeloColors.ink),
          ),
        ),
        for (final (dx, dy) in [(0.18, 0.3), (0.5, 0.62), (0.86, 0.7)])
          Positioned(
            left: size.width * dx - 12 + parallax * 24,
            top: size.height * dy - 30,
            child: Transform.scale(
              scale: pins,
              alignment: Alignment.bottomCenter,
              child: const Icon(
                Icons.location_on,
                size: 30,
                color: Color(0x66174C5B),
              ),
            ),
          ),
        // Ponto de coleta escolhido.
        Positioned(
          left: end.dx - 28,
          top: end.dy - 64,
          child: Transform.scale(
            scale: pins,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ZeloColors.validInk,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33174C5B),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.recycling,
                color: ZeloColors.paper,
                size: 28,
              ),
            ),
          ),
        ),
        // Embalagem vencida a caminho.
        Positioned(
          left: tangent.position.dx - 22,
          top: tangent.position.dy - 30,
          width: 44,
          height: 56,
          child: Opacity(
            opacity: 1 - _phase(t, 0.7, 0.8),
            child: Transform.rotate(
              angle: -0.15 + 0.3 * travel,
              child: const _Package(
                stripe: ZeloColors.expiredRed,
                icon: Icons.medication_outlined,
                stamp: '',
                stampIn: 0,
                compact: true,
              ),
            ),
          ),
        ),
        // Confirmação.
        Positioned(
          left: end.dx - 80,
          top: end.dy - 108,
          width: 160,
          child: Opacity(
            opacity: arrived.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.7 + 0.3 * arrived,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ZeloColors.paper,
                    borderRadius: BorderRadius.circular(ZeloRadii.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A174C5B),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: ZeloColors.validInk,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Descartado',
                        style: TextStyle(
                          color: ZeloColors.validInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Quarteirões sugeridos por ruas claras, sem imitar um mapa real.
class _StreetsPainter extends CustomPainter {
  _StreetsPainter({required this.shift});

  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZeloColors.paper.withValues(alpha: 0.75)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    for (final y in [0.2, 0.52, 0.86]) {
      canvas.drawLine(
        Offset(-20 + shift, size.height * y),
        Offset(size.width + 20 + shift, size.height * (y + 0.06)),
        paint,
      );
    }
    for (final x in [0.36, 0.64, 0.92]) {
      canvas.drawLine(
        Offset(size.width * x + shift, -20),
        Offset(size.width * (x - 0.08) + shift, size.height + 20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StreetsPainter oldDelegate) => oldDelegate.shift != shift;
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.path, required this.progress});

  final Path path;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZeloColors.validInk
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      final limit = metric.length * progress;
      var distance = 0.0;
      while (distance < limit) {
        final next = math.min(distance + 8, limit);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.path != path;
}
