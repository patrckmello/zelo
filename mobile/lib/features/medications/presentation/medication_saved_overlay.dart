import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../domain/medication.dart';
import 'medication_presentation.dart';

/// Confirmação curta do cadastro: a embalagem recebe o carimbo de validade,
/// como na farmácia (D038). Fecha sozinha ou com um toque.
///
/// Com redução de movimento não é exibida; o aviso do cadastro já confirma.
Future<void> showMedicationSaved(
  BuildContext context, {
  required Medication medication,
  required DateTime referenceDate,
}) async {
  if (MediaQuery.disableAnimationsOf(context)) {
    return;
  }
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: const Color(0x8C0B2027),
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => MedicationSavedOverlay(
        medication: medication,
        referenceDate: referenceDate,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class MedicationSavedOverlay extends StatefulWidget {
  const MedicationSavedOverlay({
    required this.medication,
    required this.referenceDate,
    super.key,
  });

  static const duration = Duration(milliseconds: 1800);

  final Medication medication;
  final DateTime referenceDate;

  @override
  State<MedicationSavedOverlay> createState() => _MedicationSavedOverlayState();
}

class _MedicationSavedOverlayState extends State<MedicationSavedOverlay>
    with SingleTickerProviderStateMixin {
  // A duração inclui o tempo de leitura; o controlador mantém quadros até o
  // fim para que a página feche sozinha.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MedicationSavedOverlay.duration,
  );
  var _impact = false;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    _controller
      ..addListener(_onTick)
      ..forward().whenComplete(_close);
  }

  void _onTick() {
    if (!_impact && _controller.value >= 0.42) {
      _impact = true;
      HapticFeedback.lightImpact();
    }
  }

  void _close() {
    if (_closed || !mounted) {
      return;
    }
    _closed = true;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medication = widget.medication;
    final status = medication.statusAt(widget.referenceDate);
    final days = medication.daysUntilExpirationAt(widget.referenceDate);
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: Center(
        child: Semantics(
          liveRegion: true,
          label:
              '${medication.name} guardado na sua farmácia. ${status.label}, '
              '${expirationDetail(days)}.',
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                double phase(
                  double begin,
                  double end, [
                  Curve curve = Curves.easeOutCubic,
                ]) => curve.transform(
                  ((t - begin) / (end - begin)).clamp(0.0, 1.0),
                );
                final cardIn = phase(0, 0.2, Curves.easeOutBack);
                // O carimbo desce rápido e "bate" em 42% do tempo.
                final stamp = phase(0.22, 0.42, Curves.easeInCubic);
                final settle = phase(0.42, 0.56, Curves.easeOutBack);
                final ring = phase(0.42, 0.7);
                final text = phase(0.5, 0.7);
                final squash = t >= 0.42 && t < 0.5 ? 0.04 : 0.0;

                return Transform.scale(
                  scale: 0.92 + 0.08 * cardIn,
                  child: Opacity(
                    opacity: cardIn.clamp(0.0, 1.0),
                    child: Material(
                      key: const ValueKey('medication-saved-overlay'),
                      color: ZeloColors.paper,
                      borderRadius: BorderRadius.circular(ZeloRadii.sheet),
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.fromLTRB(
                          ZeloSpace.xl,
                          ZeloSpace.xl,
                          ZeloSpace.xl,
                          ZeloSpace.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 168,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Transform(
                                    alignment: Alignment.bottomCenter,
                                    transform: Matrix4.diagonal3Values(
                                      1 + squash / 2,
                                      1 - squash,
                                      1,
                                    ),
                                    child: _Package(stripe: status.accent),
                                  ),
                                  // Tinta que se espalha no impacto.
                                  Positioned(
                                    bottom: 46,
                                    child: Opacity(
                                      opacity:
                                          (1 - ring) * (stamp >= 1 ? 0.5 : 0),
                                      child: Container(
                                        width: 80 + 60 * ring,
                                        height: 30 + 22 * ring,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            ZeloRadii.pill,
                                          ),
                                          border: Border.all(
                                            color: status.accent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 50,
                                    child: Opacity(
                                      opacity: stamp,
                                      child: Transform.rotate(
                                        angle: -0.1,
                                        child: Transform.scale(
                                          scale: stamp < 1
                                              ? 2.6 - 1.6 * stamp
                                              : 1.06 - 0.06 * settle,
                                          child: Transform.scale(
                                            scale: 1.25,
                                            child: ValidityStamp(
                                              date: medication.expirationDate,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: ZeloSpace.md),
                            Opacity(
                              opacity: text,
                              child: Transform.translate(
                                offset: Offset(0, 8 * (1 - text)),
                                child: Column(
                                  children: [
                                    Text(
                                      'Guardado na sua farmácia',
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelMedium?.copyWith(
                                        color: ZeloColors.validInk,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: ZeloSpace.xxs),
                                    Text(
                                      medication.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: ZeloSpace.sm),
                                    MedicationStatusBadge(status: status),
                                    const SizedBox(height: ZeloSpace.xxs),
                                    Text(
                                      expirationDetail(days),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: ZeloColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ),
      ),
    );
  }
}

/// Embalagem grande da confirmação, com a faixa da situação.
class _Package extends StatelessWidget {
  const _Package({required this.stripe});

  final Color stripe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 160,
      decoration: BoxDecoration(
        color: ZeloColors.shelf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZeloColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.topLeft,
                child: Icon(
                  Icons.medication_outlined,
                  color: ZeloColors.ink,
                  size: 28,
                ),
              ),
            ),
          ),
          Container(height: 14, color: stripe),
        ],
      ),
    );
  }
}
