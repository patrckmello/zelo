import 'package:flutter/material.dart';

import '../../../core/storage/onboarding_preferences.dart';

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
      icon: Icons.medication_outlined,
      title: 'Cuide dos seus medicamentos',
      description:
          'Cadastre seus medicamentos e acompanhe suas datas de validade.',
    ),
    _OnboardingItem(
      icon: Icons.notifications_active_outlined,
      title: 'Evite desperdícios',
      description: 'Receba alertas antes que seus medicamentos vençam.',
    ),
    _OnboardingItem(
      icon: Icons.recycling_outlined,
      title: 'Descarte com responsabilidade',
      description: 'Encontre locais próximos para realizar o descarte correto.',
    ),
  ];

  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      IconButton(
                        key: const ValueKey('onboarding-back-button'),
                        onPressed: _isSaving ? null : _goBack,
                        tooltip: 'Voltar para a página anterior',
                        icon: const Icon(Icons.arrow_back),
                      )
                    else
                      const SizedBox(width: 48, height: 48),
                    const Spacer(),
                    TextButton(
                      key: const ValueKey('onboarding-skip-button'),
                      onPressed: _isSaving ? null : _complete,
                      child: const Text('Pular'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const ValueKey('onboarding-pages'),
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => _OnboardingContent(
                    item: _items[index],
                    pageNumber: index + 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Página ${_currentPage + 1} de ${_items.length}',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var index = 0; index < _items.length; index++)
                            _PageIndicatorDot(
                              index: index,
                              isCurrent: index == _currentPage,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Página ${_currentPage + 1} de ${_items.length}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: ValueKey(
                        _currentPage == _items.length - 1
                            ? 'onboarding-start-button'
                            : 'onboarding-next-button',
                      ),
                      onPressed: _isSaving ? null : _goForward,
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _currentPage == _items.length - 1
                                  ? 'Começar'
                                  : 'Próximo',
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_currentPage - 1);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goForward() {
    if (_currentPage == _items.length - 1) {
      _complete();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_currentPage + 1);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
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

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.item, required this.pageNumber});

  final _OnboardingItem item;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Ilustração: ${item.title}',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Icon(
                          item.icon,
                          size: 76,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    item.title,
                    key: ValueKey('onboarding-title-$pageNumber'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
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

class _PageIndicatorDot extends StatelessWidget {
  const _PageIndicatorDot({required this.index, required this.isCurrent});

  final int index;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isCurrent ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isCurrent
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
