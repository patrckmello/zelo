import 'package:flutter/material.dart';

import '../core/theme/zelo_theme.dart';
import 'zelo_shell.dart';

class ZeloApp extends StatelessWidget {
  const ZeloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zelo',
      debugShowCheckedModeBanner: false,
      theme: ZeloTheme.light,
      home: const ZeloShell(),
    );
  }
}
