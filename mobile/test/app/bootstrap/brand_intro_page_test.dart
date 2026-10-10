import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/bootstrap/brand_intro_page.dart';

void main() {
  testWidgets('revela símbolo, nome e slogan e conclui automaticamente', (
    tester,
  ) async {
    var completionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BrandIntroPage(
          duration: const Duration(milliseconds: 400),
          onFinished: () => completionCount++,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('zelo-brand-symbol')), findsOneWidget);
    // O primeiro quadro é o da splash nativa: só o símbolo, centralizado.
    final symbolCenter = tester.getCenter(
      find.byKey(const ValueKey('zelo-brand-symbol')),
    );
    expect(
      symbolCenter.dy,
      closeTo(
        tester.view.physicalSize.height / tester.view.devicePixelRatio / 2,
        2,
      ),
    );
    expect(completionCount, 0);

    await tester.pumpAndSettle();
    expect(find.text('Zelo'), findsOneWidget);
    expect(find.text('Descarte certo.'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Zelo. Cuide. Organize. Descarte certo.'),
      findsOneWidget,
    );

    expect(completionCount, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completionCount, 1);
  });

  testWidgets('não anima quando a redução de movimento está ativa', (
    tester,
  ) async {
    var completionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: BrandIntroPage(onFinished: () => completionCount++),
        ),
      ),
    );

    expect(completionCount, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completionCount, 1);
  });

  testWidgets('um toque encerra a abertura antes do fim', (tester) async {
    var completionCount = 0;
    await tester.pumpWidget(
      MaterialApp(home: BrandIntroPage(onFinished: () => completionCount++)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(BrandIntroPage));
    await tester.pump();

    expect(completionCount, 1);
    await tester.pumpAndSettle();
    expect(completionCount, 1);
  });
}
