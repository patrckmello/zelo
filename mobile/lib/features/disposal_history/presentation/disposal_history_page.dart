import 'package:flutter/material.dart';

import '../../../core/formatting/dates.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/scene.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_message.dart';
import '../../medications/presentation/medication_presentation.dart';
import '../application/disposal_store.dart';
import '../domain/disposal.dart';

class DisposalHistoryPage extends StatelessWidget {
  const DisposalHistoryPage({
    required this.store,
    required this.onRegisterDisposal,
    this.highlightId,
    this.revealHighlight = true,
    this.onHighlightShown,
    super.key,
  });

  final DisposalStore store;
  final VoidCallback onRegisterDisposal;

  /// Registro recém-criado, que entra subindo e com destaque.
  final String? highlightId;

  /// Falso enquanto a celebração cobre a tela: o registro espera escondido.
  final bool revealHighlight;
  final VoidCallback? onHighlightShown;

  static const _header = Padding(
    padding: EdgeInsets.fromLTRB(
      ZeloSpace.gutter,
      ZeloSpace.xl,
      ZeloSpace.gutter,
      0,
    ),
    child: PageHeader(
      title: 'Histórico',
      subtitle: 'Registros dos medicamentos que você descartou.',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.isLoading) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header,
                Padding(
                  padding: EdgeInsets.all(ZeloSpace.gutter),
                  child: SkeletonList(count: 2, label: 'Carregando histórico'),
                ),
              ],
            );
          }
          if (store.status == DisposalLoadStatus.failure) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header,
                Expanded(
                  child: CenteredState(
                    child: StateMessage(
                      liveRegion: true,
                      illustration: const HistoryScene(),
                      title: 'Não foi possível carregar o histórico',
                      message:
                          store.errorMessage ?? DisposalStore.loadErrorMessage,
                      action: OutlinedButton.icon(
                        onPressed: store.load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          if (store.records.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header,
                Expanded(
                  child: CenteredState(
                    child: StateMessage(
                      illustration: const HistoryScene(),
                      title: 'Nenhum descarte registrado',
                      message: 'Os descartes registrados aparecerão aqui.',
                      action: OutlinedButton.icon(
                        key: const ValueKey('history-register-button'),
                        onPressed: onRegisterDisposal,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Registrar descarte'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return PageScrollView(
            children: [
              const PageHeader(
                title: 'Histórico',
                subtitle: 'Registros dos medicamentos que você descartou.',
              ),
              const SizedBox(height: ZeloSpace.xl),
              _Summary(records: store.records),
              const SizedBox(height: ZeloSpace.lg),
              for (final record in store.records) ...[
                if (record.id == highlightId)
                  _Arrival(
                    key: ValueKey('disposal-arrival-${record.id}'),
                    revealed: revealHighlight,
                    onShown: onHighlightShown,
                    child: _DisposalCard(record: record),
                  )
                else
                  _DisposalCard(record: record),
                const SizedBox(height: ZeloSpace.sm),
              ],
              const SizedBox(height: ZeloSpace.xs),
              OutlinedButton.icon(
                onPressed: onRegisterDisposal,
                icon: const Icon(Icons.add_task),
                label: const Text('Registrar descarte'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.records});

  final List<DisposalRecord> records;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = records.fold(0, (sum, record) => sum + record.items.length);
    final disposals = records.length == 1
        ? '1 descarte'
        : '${records.length} descartes';
    final medications = items == 1
        ? '1 medicamento devolvido'
        : '$items medicamentos devolvidos';
    return Text(
      '$disposals · $medications para destinação responsável.',
      style: textTheme.bodyMedium,
    );
  }
}

class _DisposalCard extends StatelessWidget {
  const _DisposalCard({required this.record});

  final DisposalRecord record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ZeloSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ZeloColors.validTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check, color: ZeloColors.validInk),
                ),
                const SizedBox(width: ZeloSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatFullDate(record.disposedOn),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        record.pointName ?? 'Local não informado',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZeloSpace.sm),
            const Divider(),
            const SizedBox(height: ZeloSpace.xs),
            for (final item in record.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: textTheme.bodyMedium),
                    ),
                    Text(
                      formatQuantity(item.quantity),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Registro de descarte: um comprovante com o selo de conclusão.
class HistoryScene extends StatelessWidget {
  const HistoryScene({super.key});

  @override
  Widget build(BuildContext context) {
    return ScenePanel(
      semanticLabel: 'Ilustração: registro de descarte',
      aspectRatio: 1.7,
      maxWidth: 280,
      child: Center(
        child: SizedBox(
          width: 150,
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 14,
                top: 0,
                right: 0,
                bottom: 10,
                child: _receipt(opacity: 0.55),
              ),
              Positioned(
                left: 0,
                top: 10,
                right: 14,
                bottom: 0,
                child: _receipt(),
              ),
              const Positioned(
                right: -6,
                bottom: -10,
                child: SceneTile(
                  icon: Icons.check,
                  color: ZeloColors.validInk,
                  background: ZeloColors.validTint,
                  size: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _receipt({double opacity = 1}) => Opacity(
    opacity: opacity,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZeloColors.paper,
        borderRadius: BorderRadius.circular(ZeloRadii.control),
        border: Border.all(color: ZeloColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(56, ZeloColors.petroleumBlue.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          _line(80, ZeloColors.hairline),
          const SizedBox(height: 6),
          _line(64, ZeloColors.hairline),
        ],
      ),
    ),
  );

  static Widget _line(double width, Color color) => Container(
    width: width,
    height: 6,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

/// Entrada do registro novo: sobe de baixo e ganha um contorno verde que se
/// apaga, como os detalhes que aparecem depois da celebração.
class _Arrival extends StatefulWidget {
  const _Arrival({
    required this.revealed,
    required this.child,
    this.onShown,
    super.key,
  });

  final bool revealed;
  final Widget child;
  final VoidCallback? onShown;

  @override
  State<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends State<_Arrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(_Arrival oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStart();
  }

  void _maybeStart() {
    if (!widget.revealed || _controller.isAnimating || _controller.value > 0) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onShown?.call(),
      );
      return;
    }
    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onShown?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final rise = Curves.easeOutCubic.transform((t / 0.4).clamp(0.0, 1.0));
        final ring = t < 0.4 ? rise : 1 - ((t - 0.4) / 0.6).clamp(0.0, 1.0);
        return Opacity(
          opacity: rise,
          child: Transform.translate(
            offset: Offset(0, 120 * (1 - rise)),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ZeloRadii.card),
                border: Border.all(
                  color: ZeloColors.green.withValues(alpha: ring),
                  width: 2,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
