import 'package:flutter/material.dart';

import '../../core/widgets/brand_lockup.dart';

/// Abertura: parte do mesmo quadro da splash nativa (símbolo centralizado) e
/// revela nome, slogan e a faixa de validade (D011, D036). Um toque encerra
/// antes.
class BrandIntroPage extends StatefulWidget {
  const BrandIntroPage({
    required this.onFinished,
    this.duration = defaultDuration,
    super.key,
  });

  static const defaultDuration = Duration(milliseconds: 1300);

  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<BrandIntroPage> createState() => _BrandIntroPageState();
}

class _BrandIntroPageState extends State<BrandIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _started = false;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => BrandLockup(reveal: _controller.value),
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
    _controller.stop();
    widget.onFinished();
  }
}
