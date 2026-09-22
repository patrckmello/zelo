import 'package:flutter/material.dart';

import 'brand_intro_page.dart';

class AppLaunchFlow extends StatefulWidget {
  const AppLaunchFlow({
    required this.child,
    this.showBrandIntro = true,
    super.key,
  });

  final Widget child;
  final bool showBrandIntro;

  @override
  State<AppLaunchFlow> createState() => _AppLaunchFlowState();
}

class _AppLaunchFlowState extends State<AppLaunchFlow> {
  late bool _showBrandIntro;

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
        Offstage(offstage: _showBrandIntro, child: widget.child),
        if (_showBrandIntro)
          BrandIntroPage(
            onFinished: () {
              if (mounted) {
                setState(() => _showBrandIntro = false);
              }
            },
          ),
      ],
    );
  }
}
