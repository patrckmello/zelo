import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/zelo_app.dart';
import 'package:zelo/features/medications/application/medication_store.dart';
import 'package:zelo/features/medications/domain/medication.dart';

void main() {
  final referenceDate = DateTime(2026, 8, 24);

  testWidgets('exibe resumo dinâmico e navega para os medicamentos', (
    tester,
  ) async {
    final store = MedicationStore.seeded(clock: () => referenceDate);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ZeloApp(medicationStore: store, showBrandIntro: false),
    );

    expect(find.text('Cuide. Organize. Descarte certo.'), findsOneWidget);
    expect(find.text('Sua farmácia doméstica'), findsOneWidget);
    expect(find.text('medicamentos cadastrados'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.medication_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Dipirona'), findsOneWidget);
    expect(find.text('Loratadina'), findsOneWidget);
    expect(find.text('Soro fisiológico'), findsOneWidget);
    expect(find.text('Válido'), findsOneWidget);
    expect(find.text('Próximo do vencimento'), findsOneWidget);
    expect(find.text('Vencido'), findsOneWidget);
  });

  testWidgets('valida e cadastra medicamento manualmente', (tester) async {
    final store = MedicationStore(clock: () => referenceDate);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ZeloApp(medicationStore: store, showBrandIntro: false),
    );
    await tester.tap(find.text('Cadastrar medicamento'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('medication-quantity-field')),
      '0',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-medication-button')));
    await tester.pump();

    expect(find.text('Informe o nome do medicamento.'), findsOneWidget);
    expect(find.text('Informe uma quantidade maior que zero.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('medication-name-field')),
      'Paracetamol',
    );
    await tester.enterText(
      find.byKey(const ValueKey('medication-quantity-field')),
      '4',
    );
    await tester.enterText(
      find.byKey(const ValueKey('medication-notes-field')),
      'Caixa do banheiro',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-medication-button')));
    await tester.pumpAndSettle();

    expect(store.totalCount, 1);
    expect(store.medications.single.name, 'Paracetamol');
    expect(find.text('Paracetamol foi cadastrado.'), findsOneWidget);
  });

  testWidgets('edita e remove medicamento com confirmação', (tester) async {
    final store = MedicationStore(
      clock: () => referenceDate,
      medications: [
        Medication(
          id: 'med-test',
          name: 'Loratadina',
          expirationDate: referenceDate.add(const Duration(days: 10)),
          quantity: 3,
        ),
      ],
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ZeloApp(medicationStore: store, showBrandIntro: false),
    );
    await tester.tap(find.byIcon(Icons.medication_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loratadina'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-medication-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('medication-name-field')),
      'Loratadina infantil',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-medication-button')));
    await tester.pumpAndSettle();

    expect(find.text('Loratadina infantil'), findsOneWidget);
    expect(store.medications.single.name, 'Loratadina infantil');

    await tester.tap(find.byKey(const ValueKey('delete-medication-button')));
    await tester.pumpAndSettle();
    expect(find.text('Remover medicamento?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('confirm-delete-medication-button')),
    );
    await tester.pumpAndSettle();

    expect(store.medications, isEmpty);
    expect(find.text('Sua farmácia está vazia'), findsOneWidget);
  });

  testWidgets('exibe erro simulado e permite tentar novamente', (tester) async {
    final store = MedicationStore(
      clock: () => referenceDate,
      initialError: 'Falha simulada para validar a interface.',
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ZeloApp(medicationStore: store, showBrandIntro: false),
    );
    await tester.tap(find.byIcon(Icons.medication_outlined));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os medicamentos'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Sua farmácia está vazia'), findsOneWidget);
  });
}
