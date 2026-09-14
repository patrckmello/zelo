import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/bootstrap/brand_intro_page.dart';

void main() {
  testWidgets('exibe a marca e conclui a animação automaticamente', (
    tester,
  ) async {
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BrandIntroPage(
          duration: const Duration(milliseconds: 400),
          onFinished: () => finished = true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('zelo-brand-symbol')), findsOneWidget);
    expect(find.text('Cuide. Organize. Descarte certo.'), findsOneWidget);
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 400));

    expect(finished, isTrue);
  });

  testWidgets('não anima quando a redução de movimento está ativa', (
    tester,
  ) async {
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: BrandIntroPage(onFinished: () => finished = true),
        ),
      ),
    );

    expect(finished, isTrue);
  });
}
