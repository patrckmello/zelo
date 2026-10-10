import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatting/dates.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../domain/disposal.dart';
import 'disposal_route.dart';

/// Celebração do descarte, inspirada no "salvar atividade" do Strava (D038):
/// o trajeto nasce no botão, cresce até varrer a tela e fica animado ao fundo
/// do "Mandou bem!"; em seguida a tela se dissolve no Histórico.
///
/// É exibida numa camada acima do app. [onCovered] avisa quando a tela está
/// coberta (o app pode trocar o que está por baixo sem ser visto) e
/// [onFinished], quando a camada terminou de sumir.
///
/// Mostra somente dados do próprio registro e do histórico; não estima
/// impacto ambiental.
class DisposalCelebration extends StatefulWidget {
  const DisposalCelebration({
    required this.record,
    required this.disposalCount,
    required this.onCovered,
    required this.onFinished,
    this.remainingExpired = 0,
    this.origin,
    super.key,
  });

  /// Tempo da abertura (traço, varredura e entrada do conteúdo).
  static const introDuration = Duration(milliseconds: 1900);

  /// Tempo de leitura antes de seguir sozinho para o Histórico.
  static const holdDuration = Duration(milliseconds: 3200);

  static const fadeDuration = Duration(milliseconds: 420);

  final DisposalRecord record;

  /// Quantos descartes a pessoa tem, contando este.
  final int disposalCount;

  /// Vencidos que continuam na farmácia depois deste descarte.
  final int remainingExpired;

  /// Ponto de partida do traço (o botão de confirmar), nas coordenadas da
  /// camada.
  final Offset? origin;

  final VoidCallback onCovered;
  final VoidCallback onFinished;

  @override
  State<DisposalCelebration> createState() => _DisposalCelebrationState();
}

class _DisposalCelebrationState extends State<DisposalCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: DisposalCelebration.introDuration,
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: DisposalCelebration.holdDuration,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: DisposalCelebration.fadeDuration,
  );
  var _started = false;
  var _covered = false;
  var _leaving = false;

  /// Fração da abertura em que a tela fica totalmente coberta.
  static const _coveredAt = 0.38;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final calm = MediaQuery.disableAnimationsOf(context);
    if (calm) {
      _intro.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _markCovered());
      return;
    }
    HapticFeedback.mediumImpact();
    _intro
      ..addListener(() {
        if (_intro.value >= _coveredAt) {
          _markCovered();
        }
      })
      ..forward().whenComplete(_startHold);
  }

  void _markCovered() {
    if (_covered || !mounted) {
      return;
    }
    _covered = true;
    widget.onCovered();
  }

  void _startHold() {
    if (!mounted || _leaving) {
      return;
    }
    _loop.repeat();
    // Com leitor de tela ativo, a pessoa segue quando quiser.
    if (!MediaQuery.accessibleNavigationOf(context)) {
      _hold.forward().whenComplete(_leave);
    }
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) {
      return;
    }
    _leaving = true;
    _markCovered();
    _hold.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = 1;
    } else {
      await _fade.forward();
    }
    _loop.stop();
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    _hold.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _loop, _hold, _fade]),
          builder: (context, _) {
            final t = _intro.value;
            double phase(double begin, double end, [Curve? curve]) =>
                (curve ?? Curves.easeOutCubic).transform(
                  ((t - begin) / (end - begin)).clamp(0.0, 1.0),
                );
            final covered = t >= _coveredAt;

            return Opacity(
              opacity: 1 - Curves.easeOut.transform(_fade.value),
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: t >= 0.6 ? _leave : null,
                  child: ColoredBox(
                    color: covered
                        ? ZeloColors.petroleumBlue
                        : Colors.transparent,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          key: const ValueKey('celebration-route'),
                          painter: DisposalRoutePainter(
                            origin: widget.origin,
                            draw: phase(0, 0.18, Curves.easeInOutCubic),
                            sweep: phase(0.16, _coveredAt, Curves.linear),
                            rest: covered ? phase(0.4, 0.75) : 0,
                            head: _loop.isAnimating ? _loop.value : null,
                          ),
                        ),
                        if (covered)
                          _Content(
                            record: widget.record,
                            disposalCount: widget.disposalCount,
                            remainingExpired: widget.remainingExpired,
                            reveal: phase,
                            hold: _hold.value,
                            onContinue: _leave,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

typedef _Phase = double Function(double begin, double end, [Curve? curve]);

class _Content extends StatelessWidget {
  const _Content({
    required this.record,
    required this.disposalCount,
    required this.remainingExpired,
    required this.reveal,
    required this.hold,
    required this.onContinue,
  });

  final DisposalRecord record;
  final int disposalCount;
  final int remainingExpired;
  final _Phase reveal;
  final double hold;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final medications = record.items.length;
    final units = record.totalUnits;
    final count = reveal(0.62, 0.9);
    int counted(int value) => (value * count).round();
    final milestone = disposalCount <= 1
        ? 'Seu primeiro descarte registrado no Zelo.'
        : 'Você já registrou $disposalCount descartes no Zelo.';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ZeloSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rise(
                  value: reveal(0.44, 0.6),
                  child: Semantics(
                    liveRegion: true,
                    label:
                        'Descarte registrado. '
                        '${_plural(medications, 'medicamento', 'medicamentos')}, '
                        '${_plural(units, 'unidade', 'unidades')}.',
                    child: ExcludeSemantics(
                      child: Text(
                        'DESCARTE REGISTRADO',
                        style: textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF8FD8BC),
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ZeloSpace.xs),
                _Rise(
                  value: reveal(0.48, 0.66),
                  child: Text(
                    'Mandou bem!',
                    key: const ValueKey('celebration-title'),
                    style: textTheme.displayMedium?.copyWith(
                      color: ZeloColors.paper,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.2,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: ZeloSpace.sm),
                _Rise(
                  value: reveal(0.54, 0.72),
                  child: Text(
                    medications == 1
                        ? 'Este medicamento saiu de casa do jeito certo.'
                        : 'Esses medicamentos saíram de casa do jeito certo.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: ZeloColors.paper.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: ZeloSpace.xxl),
                _Rise(
                  value: reveal(0.6, 0.8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stat(
                        value: '${counted(medications)}',
                        label: medications == 1
                            ? 'medicamento'
                            : 'medicamentos',
                      ),
                      _Stat(
                        value: '${counted(units)}',
                        label: units == 1 ? 'unidade' : 'unidades',
                      ),
                      _Stat(
                        value: '${counted(disposalCount)}º',
                        label: 'descarte',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ZeloSpace.xl),
                _Rise(
                  value: reveal(0.7, 0.88),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Line(
                        icon: Icons.place_outlined,
                        text:
                            '${record.pointName ?? 'Local não informado'} · '
                            '${formatFullDate(record.disposedOn)}',
                      ),
                      const SizedBox(height: ZeloSpace.xs),
                      _Line(icon: Icons.emoji_events_outlined, text: milestone),
                      if (remainingExpired > 0) ...[
                        const SizedBox(height: ZeloSpace.xs),
                        _Line(
                          icon: Icons.info_outline,
                          text: remainingExpired == 1
                              ? 'Ainda há 1 medicamento vencido em casa.'
                              : 'Ainda há $remainingExpired medicamentos '
                                    'vencidos em casa.',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: ZeloSpace.xxl),
                _Rise(
                  value: reveal(0.78, 0.96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        key: const ValueKey('celebration-history-button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ZeloColors.paper,
                          foregroundColor: ZeloColors.petroleumBlue,
                        ),
                        onPressed: onContinue,
                        child: const Text('Ver no histórico'),
                      ),
                      const SizedBox(height: ZeloSpace.sm),
                      // Quanto falta para seguir sozinho.
                      ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ZeloRadii.pill),
                          child: LinearProgressIndicator(
                            value: hold,
                            minHeight: 3,
                            color: ZeloColors.paper.withValues(alpha: 0.7),
                            backgroundColor: ZeloColors.paper.withValues(
                              alpha: 0.12,
                            ),
                          ),
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
    );
  }
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.displaySmall?.copyWith(
                color: ZeloColors.paper,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: ZeloColors.paper.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8FD8BC)),
        const SizedBox(width: ZeloSpace.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: ZeloColors.paper.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: value,
    child: Transform.translate(
      offset: Offset(0, 18 * (1 - value)),
      child: child,
    ),
  );
}
