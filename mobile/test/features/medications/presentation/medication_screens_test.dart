import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/theme/zelo_theme.dart';
import 'package:zelo/features/medications/application/medication_store.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/medications/domain/medication_repository.dart';
import 'package:zelo/features/medications/presentation/medication_form_page.dart';
import 'package:zelo/features/medications/presentation/medications_page.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  Widget wrap(Widget child) => MaterialApp(theme: ZeloTheme.light, home: child);

  testWidgets('filtros da lista mostram somente a situação escolhida', (
    tester,
  ) async {
    final store = MedicationStore.seeded(clock: () => today);
    addTearDown(store.dispose);
    await store.load();

    await tester.pumpWidget(wrap(MedicationsPage(store: store)));
    await tester.pumpAndSettle();
    expect(find.text('Dipirona'), findsOneWidget);
    expect(find.text('Soro fisiológico'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('medication-filter-expired')));
    await tester.pumpAndSettle();
    expect(find.text('Soro fisiológico'), findsOneWidget);
    expect(find.text('Dipirona'), findsNothing);
    expect(find.text('Loratadina'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('medication-filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('Dipirona'), findsOneWidget);
  });

  testWidgets('lista abre já filtrada quando solicitado', (tester) async {
    final store = MedicationStore.seeded(clock: () => today);
    addTearDown(store.dispose);
    await store.load();

    await tester.pumpWidget(
      wrap(
        MedicationsPage(
          store: store,
          initialFilter: MedicationStatus.expiringSoon,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Loratadina'), findsOneWidget);
    expect(find.text('Dipirona'), findsNothing);
  });

  testWidgets('formulário antecipa a situação da validade escolhida', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MedicationFormPage(
          referenceDate: today,
          medication: Medication(
            id: 'med-1',
            name: 'Loratadina',
            expirationDate: today.add(const Duration(days: 12)),
            quantity: 6,
          ),
          onSave: (draft) async => throw UnimplementedError(),
        ),
      ),
    );

    expect(
      find.text('Próximo do vencimento · vence em 12 dias'),
      findsOneWidget,
    );
  });

  testWidgets('falha ao salvar mantém o formulário aberto com aviso', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      wrap(
        MedicationFormPage(
          referenceDate: today,
          onSave: (draft) async {
            attempts++;
            throw const MedicationRepositoryException('Servidor indisponível.');
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('medication-name-field')),
      'Dipirona',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-medication-button')));
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(find.byKey(const ValueKey('medication-form-error')), findsOneWidget);
    expect(find.text('Servidor indisponível.'), findsOneWidget);
    expect(find.text('Dipirona'), findsOneWidget);
  });
}
