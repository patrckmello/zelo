import 'package:flutter/material.dart';

import '../../core/theme/zelo_tokens.dart';
import 'brand_intro_page.dart';

class AppLaunchFlow extends StatefulWidget {
  const AppLaunchFlow({
    required this.child,
    this.showBrandIntro = true,
    super.key,
  });

  /// Dissolução da abertura sobre a tela seguinte.
  static const fadeDuration = Duration(milliseconds: 260);

  final Widget child;
  final bool showBrandIntro;

  @override
  State<AppLaunchFlow> createState() => _AppLaunchFlowState();
}

class _AppLaunchFlowState extends State<AppLaunchFlow> {
  late bool _showBrandIntro;
  var _fading = false;

  @override
  void initState() {
    super.initState();
    _showBrandIntro = widget.showBrandIntro;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: _showBrandIntro && !_fading, child: widget.child),
        if (_showBrandIntro)
          IgnorePointer(
            ignoring: _fading,
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: ZeloMotion.of(context, AppLaunchFlow.fadeDuration),
              curve: Curves.easeOut,
              onEnd: _remove,
              child: BrandIntroPage(onFinished: _startFade),
            ),
          ),
      ],
    );
  }

  void _startFade() {
    if (!mounted) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _remove();
      return;
    }
    setState(() => _fading = true);
  }

  void _remove() {
    if (mounted && _showBrandIntro) {
      setState(() => _showBrandIntro = false);
    }
  }
}
