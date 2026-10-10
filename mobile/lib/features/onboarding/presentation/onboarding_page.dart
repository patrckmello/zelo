import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/storage/onboarding_preferences.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import 'onboarding_illustration.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.preferences,
    required this.onCompleted,
    super.key,
  });

  final OnboardingPreferences preferences;
  final VoidCallback onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _items = <_OnboardingItem>[
    _OnboardingItem(
      visual: OnboardingVisual.organization,
      eyebrow: 'Organize',
      title: 'Sua farmácia de casa, em ordem',
      description:
          'Cadastre o que você guarda e veja tudo organizado pela data de '
          'validade.',
      illustration: 'Embalagens na prateleira, cada uma com a validade.',
    ),
    _OnboardingItem(
      visual: OnboardingVisual.wastePrevention,
      eyebrow: 'Cuide',
      title: 'Saiba o que vence antes de vencer',
      description:
          'O Zelo destaca o que vence nos próximos 30 dias, para você usar a '
          'tempo e evitar desperdício.',
      illustration: 'Linha de validade entrando na janela de 30 dias.',
    ),
    _OnboardingItem(
      visual: OnboardingVisual.responsibleDisposal,
      eyebrow: 'Descarte certo',
      title: 'Leve ao ponto de coleta mais perto',
      description:
          'Encontre pontos de coleta perto de você e registre cada descarte '
          'no seu histórico.',
      illustration: 'Embalagem vencida seguindo até um ponto de coleta.',
      note:
          'Nenhuma permissão é pedida agora. A localização só é usada quando '
          'você buscar um ponto.',
    ),
  ];

  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  bool get _isLast => _currentPage == _items.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSaving) {
          _goBack();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  _TopBar(
                    showBack: _currentPage > 0,
                    showSkip: !_isLast,
                    enabled: !_isSaving,
                    onBack: _goBack,
                    onSkip: _complete,
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('onboarding-pages'),
                      controller: _pageController,
                      itemCount: _items.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) => AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, _) => _OnboardingContent(
                          item: _items[index],
                          pageNumber: index + 1,
                          active: index == _currentPage,
                          offset: _offsetOf(index),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ZeloSpace.xl,
                      ZeloSpace.sm,
                      ZeloSpace.xl,
                      ZeloSpace.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Progress(current: _currentPage, total: _items.length),
                        const SizedBox(height: ZeloSpace.lg),
                        FilledButton(
                          key: ValueKey(
                            _isLast
                                ? 'onboarding-start-button'
                                : 'onboarding-next-button',
                          ),
                          onPressed: _isSaving ? null : _goForward,
                          child: _isSaving
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _isLast ? 'Começar' : 'Continuar',
                                      ),
                                    ),
                                    const SizedBox(width: ZeloSpace.xs),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
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
    );
  }

  /// Distância da página [index] até a posição atual do arraste (-1 a 1).
  double _offsetOf(int index) {
    if (!_pageController.hasClients ||
        !_pageController.position.hasContentDimensions) {
      return (index - _currentPage).toDouble().clamp(-1.0, 1.0);
    }
    final page = _pageController.page ?? _currentPage.toDouble();
    return (index - page).clamp(-1.0, 1.0);
  }

  void _goBack() {
    if (_currentPage == 0) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_currentPage - 1);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: ZeloMotion.easeOut,
    );
  }

  void _goForward() {
    if (_isLast) {
      _complete();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_currentPage + 1);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: ZeloMotion.easeOut,
    );
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);
    try {
      await widget.preferences.markCompleted();
      if (mounted) {
        widget.onCompleted();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar sua escolha. Tente novamente.',
          ),
        ),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.showSkip,
    required this.enabled,
    required this.onBack,
    required this.onSkip,
  });

  final bool showBack;
  final bool showSkip;
  final bool enabled;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                key: const ValueKey('onboarding-back-button'),
                onPressed: enabled ? onBack : null,
                tooltip: 'Voltar para a página anterior',
                icon: const Icon(Icons.arrow_back),
              )
            else
              const SizedBox(width: 48),
            const Spacer(),
            if (showSkip)
              TextButton(
                key: const ValueKey('onboarding-skip-button'),
                onPressed: enabled ? onSkip : null,
                child: const Text('Pular'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({
    required this.item,
    required this.pageNumber,
    required this.active,
    required this.offset,
  });

  final _OnboardingItem item;
  final int pageNumber;
  final bool active;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // O texto chega um pouco depois do palco durante o arraste.
    final textShift = offset * 48;
    final textOpacity = 1 - math.min(offset.abs() * 1.4, 1).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageHeight = (constraints.maxHeight * 0.58).clamp(220.0, 440.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ZeloSpace.md,
            ZeloSpace.xs,
            ZeloSpace.md,
            ZeloSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: stageHeight,
                child: OnboardingIllustration(
                  visual: item.visual,
                  pageNumber: pageNumber,
                  semanticLabel: 'Ilustração: ${item.illustration}',
                  active: active,
                  parallax: offset,
                ),
              ),
              const SizedBox(height: ZeloSpace.xl),
              Opacity(
                opacity: textOpacity,
                child: Transform.translate(
                  offset: Offset(textShift, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ZeloSpace.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pageNumber.toString().padLeft(2, '0')} · '
                          '${item.eyebrow.toUpperCase()}',
                          style: textTheme.labelMedium?.copyWith(
                            color: ZeloColors.validInk,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: ZeloSpace.xs),
                        Text(
                          item.title,
                          key: ValueKey('onboarding-title-$pageNumber'),
                          style: textTheme.headlineMedium?.copyWith(
                            letterSpacing: -0.6,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: ZeloSpace.sm),
                        Text(
                          item.description,
                          style: textTheme.bodyLarge?.copyWith(
                            color: ZeloColors.inkMuted,
                          ),
                        ),
                        if (item.note case final note?) ...[
                          const SizedBox(height: ZeloSpace.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: ZeloColors.inkMuted,
                              ),
                              const SizedBox(width: ZeloSpace.xs),
                              Expanded(
                                child: Text(
                                  note,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: ZeloColors.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Progresso em segmentos; o atual se alonga e preenche.
class _Progress extends StatelessWidget {
  const _Progress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Página ${current + 1} de $total',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < total; index++)
              AnimatedContainer(
                duration: ZeloMotion.of(context, ZeloMotion.standard),
                curve: ZeloMotion.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == current ? 32 : 12,
                height: 6,
                decoration: BoxDecoration(
                  color: index <= current
                      ? ZeloColors.petroleumBlue
                      : ZeloColors.petroleumBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(ZeloRadii.pill),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.visual,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.illustration,
    this.note,
  });

  final OnboardingVisual visual;
  final String eyebrow;
  final String title;
  final String description;
  final String illustration;
  final String? note;
}
