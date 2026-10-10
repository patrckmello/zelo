import 'package:flutter/material.dart';

import '../theme/zelo_tokens.dart';

/// Estado vazio, futuro ou de erro: composição visual, título, explicação e
/// ação opcional. Evita o padrão de ícone isolado no centro da tela.
class StateMessage extends StatelessWidget {
  const StateMessage({
    required this.illustration,
    required this.title,
    required this.message,
    this.action,
    this.liveRegion = false,
    super.key,
  });

  final Widget illustration;
  final String title;
  final String message;
  final Widget? action;

  /// Anuncia o conteúdo a leitores de tela quando ele surge após uma ação.
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: liveRegion,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration,
          const SizedBox(height: ZeloSpace.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: ZeloSpace.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          if (action case final action?) ...[
            const SizedBox(height: ZeloSpace.xl),
            action,
          ],
        ],
      ),
    );
  }
}

/// Centraliza um [StateMessage] na área disponível, mantendo rolagem quando
/// o texto ampliado não couber.
class CenteredState extends StatelessWidget {
  const CenteredState({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeloSpace.xxl,
          vertical: ZeloSpace.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - ZeloSpace.xl * 2).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
