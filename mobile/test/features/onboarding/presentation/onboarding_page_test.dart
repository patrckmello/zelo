import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/features/onboarding/presentation/onboarding_page.dart';

import '../../../support/in_memory_dependencies.dart';

void main() {
  testWidgets('permite avançar e voltar pelas páginas', (tester) async {
    final preferences = InMemoryOnboardingPreferences();

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(preferences: preferences, onCompleted: () {}),
      ),
    );

    expect(find.text('Cuide dos seus medicamentos'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('Evite desperdícios'), findsOneWidget);
    expect(find.text('Página 2 de 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-back-button')));
    await tester.pumpAndSettle();
    expect(find.text('Cuide dos seus medicamentos'), findsOneWidget);
  });

  testWidgets('pular persiste a conclusão do onboarding', (tester) async {
    final preferences = InMemoryOnboardingPreferences();
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          preferences: preferences,
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-skip-button')));
    await tester.pump();

    expect(preferences.completed, isTrue);
    expect(preferences.writeCount, 1);
    expect(completed, isTrue);
  });

  testWidgets('Começar conclui a terceira página', (tester) async {
    final preferences = InMemoryOnboardingPreferences();
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          preferences: preferences,
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Descarte com responsabilidade'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-start-button')));
    await tester.pump();

    expect(preferences.completed, isTrue);
    expect(completed, isTrue);
  });

  testWidgets('layout suporta 390x844 e texto ampliado sem overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: OnboardingPage(
            preferences: InMemoryOnboardingPreferences(),
            onCompleted: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cuide dos seus medicamentos'), findsOneWidget);
    expect(find.text('Página 1 de 3'), findsOneWidget);
  });
}
