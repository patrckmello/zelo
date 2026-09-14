import 'package:flutter/material.dart';

import '../core/theme/zelo_theme.dart';
import '../features/medications/application/medication_store.dart';
import 'bootstrap/brand_intro_page.dart';
import 'zelo_shell.dart';

class ZeloApp extends StatefulWidget {
  const ZeloApp({
    this.medicationStore,
    this.showBrandIntro = true,
    super.key,
  });

  final MedicationStore? medicationStore;
  final bool showBrandIntro;

  @override
  State<ZeloApp> createState() => _ZeloAppState();
}

class _ZeloAppState extends State<ZeloApp> {
  late final MedicationStore _medicationStore;
  late final bool _ownsMedicationStore;
  late bool _showBrandIntro;

  @override
  void initState() {
    super.initState();
    _showBrandIntro = widget.showBrandIntro;
    _ownsMedicationStore = widget.medicationStore == null;
    _medicationStore = widget.medicationStore ?? MedicationStore.seeded();
  }

  @override
  void dispose() {
    if (_ownsMedicationStore) {
      _medicationStore.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zelo',
      debugShowCheckedModeBanner: false,
      theme: ZeloTheme.light,
      home: _showBrandIntro
          ? BrandIntroPage(
              onFinished: () {
                if (mounted) {
                  setState(() => _showBrandIntro = false);
                }
              },
            )
          : ZeloShell(medicationStore: _medicationStore),
    );
  }
}
