import 'package:flutter/material.dart';

import '../core/theme/zelo_theme.dart';
import '../features/medications/application/medication_store.dart';
import 'zelo_shell.dart';

class ZeloApp extends StatefulWidget {
  const ZeloApp({this.medicationStore, super.key});

  final MedicationStore? medicationStore;

  @override
  State<ZeloApp> createState() => _ZeloAppState();
}

class _ZeloAppState extends State<ZeloApp> {
  late final MedicationStore _medicationStore;
  late final bool _ownsMedicationStore;

  @override
  void initState() {
    super.initState();
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
      home: ZeloShell(medicationStore: _medicationStore),
    );
  }
}
