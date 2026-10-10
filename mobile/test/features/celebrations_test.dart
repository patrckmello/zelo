import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/theme/zelo_theme.dart';
import 'package:zelo/features/disposal_history/domain/disposal.dart';
import 'package:zelo/features/disposal_history/presentation/disposal_celebration.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/medications/presentation/medication_form_page.dart';
import 'package:zelo/features/medications/presentation/medication_saved_overlay.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  group('carimbo do cadastro', () {
    Future<List<MedicationDraft>> pumpLauncher(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      final saved = <MedicationDraft>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ZeloTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => openMedicationForm(
                    context,
                    referenceDate: today,
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
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      return saved;
    }

    Future<void> fillAndSave(WidgetTester tester, String name) async {
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('medication-name-field')),
        name,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-medication-button')),
      );
      await tester.tap(find.byKey(const ValueKey('save-medication-button')));
    }

    testWidgets('carimba, fecha sozinho e oferece cadastrar outro', (
      tester,
    ) async {
      final saved = await pumpLauncher(tester);
      await fillAndSave(tester, 'Dipirona');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(
        find.byKey(const ValueKey('medication-saved-overlay')),
        findsOneWidget,
      );
      expect(find.text('Guardado na sua farmácia'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('medication-saved-overlay')),
        findsNothing,
      );
      expect(find.text('Dipirona foi cadastrado.'), findsOneWidget);

      await tester.tap(find.text('Cadastrar outro'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('medication-name-field')),
        findsOneWidget,
      );
      expect(saved.single.name, 'Dipirona');
    });

    testWidgets('o aviso de cadastro some sozinho', (tester) async {
      await pumpLauncher(tester);
      await fillAndSave(tester, 'Ibuprofeno');
      await tester.pumpAndSettle();
      expect(find.text('Ibuprofeno foi cadastrado.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Ibuprofeno foi cadastrado.'), findsNothing);
    });

    testWidgets('um toque fecha o carimbo antes do tempo', (tester) async {
      await pumpLauncher(tester);
      await fillAndSave(tester, 'Loratadina');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey('medication-saved-overlay')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey('medication-saved-overlay')),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(find.text('Loratadina foi cadastrado.'), findsOneWidget);
    });

    testWidgets('com redução de movimento confirma só pelo aviso', (
      tester,
    ) async {
      await pumpLauncher(tester, reduceMotion: true);
      await fillAndSave(tester, 'Soro');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey('medication-saved-overlay')),
        findsNothing,
      );
      expect(find.text('Soro foi cadastrado.'), findsOneWidget);
    });
  });

  group('celebração do descarte', () {
    final record = DisposalRecord(
      id: 'd-1',
      disposedOn: today,
      pointName: 'Farmácia do bairro',
      items: [
        DisposalItem(name: 'Soro', quantity: 1, expirationDate: today),
        DisposalItem(name: 'Dipirona', quantity: 10, expirationDate: today),
      ],
    );

    late List<String> events;

    Future<void> pumpCelebration(
      WidgetTester tester, {
      int disposalCount = 1,
      int remainingExpired = 0,
      bool reduceMotion = false,
      bool screenReader = false,
    }) async {
      events = [];
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ZeloTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
              accessibleNavigation: screenReader,
            ),
            child: child!,
          ),
          home: Stack(
            children: [
              const Scaffold(body: Center(child: Text('fundo'))),
              DisposalCelebration(
                record: record,
                disposalCount: disposalCount,
                remainingExpired: remainingExpired,
                origin: const Offset(195, 780),
                onCovered: () => events.add('coberta'),
                onFinished: () => events.add('concluída'),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> finishIntro(WidgetTester tester) async {
      await tester.pump(DisposalCelebration.introDuration);
      await tester.pump(const Duration(milliseconds: 16));
    }

    Future<void> finishFade(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(DisposalCelebration.fadeDuration);
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('o trajeto cobre a tela antes do conteúdo aparecer', (
      tester,
    ) async {
      await pumpCelebration(tester);
      await tester.pump(const Duration(milliseconds: 200));
      expect(events, isEmpty);
      expect(find.text('Mandou bem!'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      expect(events, ['coberta']);
      await finishIntro(tester);
      expect(find.text('Mandou bem!'), findsOneWidget);
    });

    testWidgets('mostra o que saiu de casa e segue sozinho', (tester) async {
      await pumpCelebration(tester, disposalCount: 3, remainingExpired: 1);
      await finishIntro(tester);

      expect(find.text('11'), findsOneWidget);
      expect(find.text('3º'), findsOneWidget);
      expect(
        find.text('Você já registrou 3 descartes no Zelo.'),
        findsOneWidget,
      );
      expect(
        find.text('Ainda há 1 medicamento vencido em casa.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Descarte registrado. 2 medicamentos, 11 unidades.',
        ),
        findsOneWidget,
      );

      // A barra mostra quanto falta para seguir sozinho.
      final bar = find.byType(LinearProgressIndicator);
      await tester.pump(DisposalCelebration.holdDuration ~/ 2);
      expect(
        tester.widget<LinearProgressIndicator>(bar).value,
        closeTo(0.5, 0.05),
      );
      await tester.pump(DisposalCelebration.holdDuration ~/ 2);
      await tester.pump(const Duration(milliseconds: 100));
      await finishFade(tester);
      expect(events, ['coberta', 'concluída']);
    });

    testWidgets('Ver no histórico segue antes do tempo', (tester) async {
      await pumpCelebration(tester);
      await finishIntro(tester);

      await tester.tap(
        find.byKey(const ValueKey('celebration-history-button')),
      );
      await finishFade(tester);
      expect(events, ['coberta', 'concluída']);
    });

    testWidgets('com leitor de tela, espera a pessoa seguir', (tester) async {
      await pumpCelebration(tester, screenReader: true);
      await finishIntro(tester);
      await tester.pump(DisposalCelebration.holdDuration * 2);
      expect(events, ['coberta']);

      await tester.tap(
        find.byKey(const ValueKey('celebration-history-button')),
      );
      await finishFade(tester);
      expect(events, ['coberta', 'concluída']);
    });

    testWidgets('com redução de movimento aparece pronta e não segue só', (
      tester,
    ) async {
      await pumpCelebration(tester, reduceMotion: true);
      await tester.pump();

      expect(events, ['coberta']);
      expect(find.text('Mandou bem!'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      await tester.pump(DisposalCelebration.holdDuration * 2);
      expect(events, ['coberta']);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  test('o carimbo dura menos de dois segundos', () {
    expect(
      MedicationSavedOverlay.duration,
      lessThan(const Duration(seconds: 2)),
    );
  });
}
