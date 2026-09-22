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

  testWidgets('usa uma composição visual em cada página', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          preferences: InMemoryOnboardingPreferences(),
          onCompleted: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('onboarding-illustration-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-illustration-2')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-illustration-3')),
      findsOneWidget,
    );
  });

  testWidgets('redução de movimento troca página sem transição', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: OnboardingPage(
            preferences: InMemoryOnboardingPreferences(),
            onCompleted: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pump();

    expect(find.text('Evite desperdícios'), findsOneWidget);
    expect(find.text('Página 2 de 3'), findsOneWidget);
  });

  testWidgets('layout suporta tela pequena com texto ampliado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: OnboardingPage(
            preferences: InMemoryOnboardingPreferences(),
            onCompleted: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('onboarding-next-button')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('onboarding-next-button')))
          .height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('controles de navegação mantêm áreas de toque adequadas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          preferences: InMemoryOnboardingPreferences(),
          onCompleted: () {},
        ),
      ),
    );

    final skip = find.byKey(const ValueKey('onboarding-skip-button'));
    final next = find.byKey(const ValueKey('onboarding-next-button'));
    expect(tester.getSize(skip).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(next).height, greaterThanOrEqualTo(48));

    await tester.tap(next);
    await tester.pumpAndSettle();

    final back = find.byKey(const ValueKey('onboarding-back-button'));
    expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(back).width, greaterThanOrEqualTo(48));
  });
}
