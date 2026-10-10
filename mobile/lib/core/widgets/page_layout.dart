import 'package:flutter/material.dart';

import '../theme/zelo_tokens.dart';

/// Conteúdo rolável com margens, largura máxima e respiro inferior padrão.
class PageScrollView extends StatelessWidget {
  const PageScrollView({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(
      ZeloSpace.gutter,
      ZeloSpace.xl,
      ZeloSpace.gutter,
      ZeloSpace.xxl,
    ),
    this.maxWidth = ZeloSpace.contentMaxWidth,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Título das áreas principais, com descrição opcional.
///
/// Com [onBack], mostra um atalho de volta acima do título, usado quando a
/// área foi aberta a partir de uma ação da Início.
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.backLabel = 'Início',
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack case final back?) ...[
          TextButton.icon(
            key: const ValueKey('page-back-button'),
            onPressed: back,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            ),
            icon: const Icon(Icons.arrow_back),
            label: Text(backLabel),
          ),
          const SizedBox(height: ZeloSpace.xxs),
        ],
        Semantics(
          header: true,
          child: Text(title, style: textTheme.headlineLarge),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: ZeloSpace.xs),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Cabeçalho de seção com ação opcional alinhada à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    // Com texto ampliado, a ação desce para a linha seguinte em vez de
    // espremer o título.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: ZeloSpace.xxs,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (actionLabel case final label?)
          TextButton(key: actionKey, onPressed: onAction, child: Text(label)),
      ],
    );
  }
}
