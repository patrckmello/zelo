import 'package:flutter/material.dart';

import '../../core/theme/zelo_colors.dart';

class BrandIntroPage extends StatefulWidget {
  const BrandIntroPage({
    required this.onFinished,
    this.duration = const Duration(milliseconds: 800),
    super.key,
  });

  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<BrandIntroPage> createState() => _BrandIntroPageState();
}

class _BrandIntroPageState extends State<BrandIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _turns;
  var _started = false;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0.65, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.82, end: 1).animate(curve);
    _turns = Tween<double>(begin: -0.18, end: 0).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }

    _controller.forward().whenComplete(_finish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _turns,
                    child: Image.asset(
                      'assets/branding/zelo-symbol.png',
                      key: const ValueKey('zelo-brand-symbol'),
                      width: 144,
                      height: 144,
                      semanticLabel: 'Símbolo do Zelo',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Zelo',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: ZeloColors.petroleumBlue,
                      fontSize: 38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cuide. Organize. Descarte certo.',
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

  void _finish() {
    if (!mounted || _finished) {
      return;
    }
    _finished = true;
    widget.onFinished();
  }
}
