import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/theme/zelo_theme.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/medications/domain/medication_scan.dart';
import 'package:zelo/features/medications/presentation/medication_form_page.dart';

import '../../../support/scan_fakes.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  Future<List<MedicationDraft>> pumpForm(
    WidgetTester tester, {
    required MedicationScanner? scanner,
    bool startWithScan = false,
    Medication? medication,
  }) async {
    final saved = <MedicationDraft>[];
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ZeloTheme.light,
        home: MedicationFormPage(
          referenceDate: today,
          medication: medication,
          scanner: scanner,
          startWithScan: startWithScan,
          onSave: (draft) async {
            saved.add(draft);
            return Medication(
              id: 'med-${saved.length}',
              name: draft.name,
              expirationDate: draft.expirationDate,
              quantity: draft.quantity,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return saved;
  }

  String fieldText(WidgetTester tester, String key) =>
      tester.widget<TextFormField>(find.byKey(ValueKey(key))).controller!.text;

  Future<void> scanFromGallery(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('scan-package-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-source-gallery')));
    await tester.pumpAndSettle();
  }

  testWidgets('sem a API Zelo o cadastro não oferece leitura', (tester) async {
    await pumpForm(tester, scanner: null);
    expect(find.byKey(const ValueKey('scan-package-button')), findsNothing);
  });

  testWidgets('edição não oferece leitura da embalagem', (tester) async {
    await pumpForm(
      tester,
      scanner: MedicationScanner(
        capture: FakeImageCapture(),
        service: FakeScanService(),
      ),
      medication: Medication(
        id: 'med-1',
        name: 'Loratadina',
        expirationDate: DateTime(2027, 1, 10),
        quantity: 6,
      ),
    );
    expect(find.byKey(const ValueKey('scan-package-button')), findsNothing);
  });

  testWidgets('leitura preenche os campos e só salva após confirmação', (
    tester,
  ) async {
    final capture = FakeImageCapture();
    final service = FakeScanService(
      result: MedicationScanResult(
        nameCandidates: const ['Loratadina', 'Claritin'],
        expirationDate: DateTime(2027, 8, 31),
        expirationText: 'VAL AGO/2027',
        quantity: 12,
      ),
    )..gate = Completer<void>();
    final saved = await pumpForm(
      tester,
      scanner: MedicationScanner(capture: capture, service: service),
    );

    await tester.tap(find.byKey(const ValueKey('scan-package-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-source-gallery')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('scan-progress')), findsOneWidget);

    service.gate!.complete();
    await tester.pumpAndSettle();
    expect(capture.sources, [ImageSourceKind.gallery]);
    expect(find.byKey(const ValueKey('scan-result')), findsOneWidget);
    expect(find.textContaining('VAL AGO/2027'), findsOneWidget);
    expect(find.textContaining('último dia do mês'), findsOneWidget);
    expect(fieldText(tester, 'medication-name-field'), 'Loratadina');
    expect(fieldText(tester, 'medication-expiration-field'), '31/08/2027');
    expect(fieldText(tester, 'medication-quantity-field'), '12');
    expect(saved, isEmpty);

    await tester.tap(find.byKey(const ValueKey('scan-name-option-0')));
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'medication-name-field'), 'Claritin');

    await tester.ensureVisible(
      find.byKey(const ValueKey('save-medication-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-medication-button')));
    await tester.pumpAndSettle();
    expect(saved.single.name, 'Claritin');
    expect(saved.single.expirationDate, DateTime(2027, 8, 31));
    expect(saved.single.quantity, 12);
  });

  testWidgets('nome digitado pela pessoa não é substituído pela leitura', (
    tester,
  ) async {
    await pumpForm(
      tester,
      scanner: MedicationScanner(
        capture: FakeImageCapture(),
        service: FakeScanService(
          result: MedicationScanResult(
            nameCandidates: const ['Dipirona'],
            expirationDate: DateTime(2027, 3, 31),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('medication-name-field')),
      'Novalgina gotas',
    );

    await scanFromGallery(tester);
    expect(fieldText(tester, 'medication-name-field'), 'Novalgina gotas');
    expect(fieldText(tester, 'medication-expiration-field'), '31/03/2027');
    expect(find.byKey(const ValueKey('scan-name-option-0')), findsOneWidget);
  });

  testWidgets('foto sem texto reconhecível orienta a pessoa', (tester) async {
    await pumpForm(
      tester,
      scanner: MedicationScanner(
        capture: FakeImageCapture(),
        service: FakeScanService(),
      ),
    );
    await scanFromGallery(tester);
    expect(find.byKey(const ValueKey('scan-empty')), findsOneWidget);
    expect(fieldText(tester, 'medication-name-field'), isEmpty);
  });

  testWidgets('falha na leitura mostra a mensagem e mantém o formulário', (
    tester,
  ) async {
    await pumpForm(
      tester,
      scanner: MedicationScanner(
        capture: FakeImageCapture(),
        service: FakeScanService(
          error: const MedicationScanException(
            'A leitura de embalagens está indisponível no momento.',
          ),
        ),
      ),
    );
    await scanFromGallery(tester);
    expect(
      find.text('A leitura de embalagens está indisponível no momento.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('save-medication-button')),
      findsOneWidget,
    );
  });

  testWidgets('desistir da foto não altera nada', (tester) async {
    final service = FakeScanService();
    await pumpForm(
      tester,
      startWithScan: true,
      scanner: MedicationScanner(
        capture: FakeImageCapture(cancel: true),
        service: service,
      ),
    );
    // A escolha da origem abre sozinha quando o cadastro vem do atalho.
    expect(find.byKey(const ValueKey('scan-source-camera')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scan-source-camera')));
    await tester.pumpAndSettle();
    expect(service.calls, 0);
    expect(find.byKey(const ValueKey('scan-result')), findsNothing);
    expect(find.byKey(const ValueKey('scan-package-button')), findsOneWidget);
  });
}
