import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/bootstrap/brand_intro_page.dart';

void main() {
  testWidgets('exibe somente o símbolo e conclui a animação automaticamente', (
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
    expect(find.text('Zelo'), findsNothing);
    expect(find.text('Cuide. Organize. Descarte certo.'), findsNothing);
    expect(completionCount, 0);

    await tester.pumpAndSettle();

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
}
