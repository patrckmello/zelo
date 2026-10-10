import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/theme/zelo_theme.dart';
import 'package:zelo/features/home/presentation/home_page.dart';
import 'package:zelo/features/medications/application/medication_store.dart';
import 'package:zelo/features/medications/domain/medication.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  Medication medication(String id, int days) => Medication(
    id: id,
    name: 'Medicamento $id',
    expirationDate: today.add(Duration(days: days)),
    quantity: 1,
  );

  Future<MedicationStore> pumpHome(
    WidgetTester tester,
    List<Medication> medications, {
    ValueChanged<String>? onOpenMedication,
  }) async {
    final store = MedicationStore(clock: () => today, medications: medications);
    addTearDown(store.dispose);
    await store.load();
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ZeloTheme.light,
        home: Scaffold(
          body: HomePage(
            medicationStore: store,
            onAddMedication: () {},
            onOpenMedications: () {},
            onOpenMedication: onOpenMedication ?? (_) {},
            onOpenDisposal: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('resume a farmácia com contagens exatas por situação', (
    tester,
  ) async {
    await pumpHome(tester, [
      medication('a', 90),
      medication('b', 120),
      medication('c', 10),
      medication('d', -3),
    ]);

    expect(find.text('4'), findsOneWidget);
    expect(find.text('medicamentos cadastrados'), findsOneWidget);
    expect(find.bySemanticsLabel('2 válidos'), findsOneWidget);
    expect(find.bySemanticsLabel('1 próximo do vencimento'), findsOneWidget);
    expect(find.bySemanticsLabel('1 vencido'), findsOneWidget);
    expect(find.textContaining('HOJE, 2 DE OUTUBRO'), findsOneWidget);
  });

  testWidgets('lista primeiro os itens que precisam de atenção', (
    tester,
  ) async {
    String? opened;
    await pumpHome(tester, [
      medication('valido', 90),
      medication('vencendo', 10),
      medication('vencido', -3),
    ], onOpenMedication: (id) => opened = id);

    expect(find.text('Precisa de atenção'), findsOneWidget);
    expect(find.text('Medicamento vencido'), findsOneWidget);
    expect(find.text('Medicamento vencendo'), findsOneWidget);
    expect(find.text('Medicamento valido'), findsNothing);

    await tester.tap(find.text('Medicamento vencido'));
    expect(opened, 'vencido');
  });

  testWidgets('mostra estado tranquilo quando nada vence em breve', (
    tester,
  ) async {
    await pumpHome(tester, [medication('a', 90)]);

    expect(find.text('Tudo em dia'), findsOneWidget);
  });

  testWidgets('limita a prévia e indica os demais itens', (tester) async {
    await pumpHome(tester, [
      for (var index = 0; index < 5; index++) medication('$index', -index - 1),
    ]);

    expect(find.text('Mais 2 itens precisam de atenção'), findsOneWidget);
  });
}
