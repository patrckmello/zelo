import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/zelo_app.dart';
import 'package:zelo/features/authentication/data/simulated_authentication_service.dart';
import 'package:zelo/features/medications/application/medication_store.dart';

import '../../support/in_memory_dependencies.dart';

void main() {
  ZeloApp buildApp({
    required InMemoryOnboardingPreferences preferences,
    required InMemorySessionStore sessionStore,
  }) => ZeloApp(
    showBrandIntro: false,
    medicationStore: MedicationStore(),
    onboardingPreferences: preferences,
    authenticationService: SimulatedAuthenticationService(
      sessionStore: sessionStore,
    ),
  );

  testWidgets('primeiro acesso exibe onboarding e pular leva ao login', (
    tester,
  ) async {
    final preferences = InMemoryOnboardingPreferences();
    final sessionStore = InMemorySessionStore();

    await tester.pumpWidget(
      buildApp(preferences: preferences, sessionStore: sessionStore),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cuide dos seus medicamentos'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip-button')));
    await tester.pumpAndSettle();
    expect(find.text('Entre no Zelo'), findsOneWidget);
    expect(preferences.completed, isTrue);
  });

  testWidgets('onboarding concluído não reaparece na nova abertura', (
    tester,
  ) async {
    final preferences = InMemoryOnboardingPreferences(completed: true);
    final sessionStore = InMemorySessionStore();

    await tester.pumpWidget(
      buildApp(preferences: preferences, sessionStore: sessionStore),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entre no Zelo'), findsOneWidget);
    expect(find.text('Cuide dos seus medicamentos'), findsNothing);
  });

  testWidgets('sessão restaurada abre a Home e a navegação inferior', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        preferences: InMemoryOnboardingPreferences(completed: true),
        sessionStore: InMemorySessionStore(active: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sua farmácia doméstica'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('erro de bootstrap mostra mensagem segura e permite tentar', (
    tester,
  ) async {
    final preferences = InMemoryOnboardingPreferences(
      completed: true,
      failReads: 1,
    );
    await tester.pumpWidget(
      buildApp(preferences: preferences, sessionStore: InMemorySessionStore()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível preparar o aplicativo. Tente novamente.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('bootstrap-retry-button')));
    await tester.pumpAndSettle();
    expect(find.text('Entre no Zelo'), findsOneWidget);
  });

  testWidgets(
    'login demonstração substitui o fluxo e voltar não reabre login',
    (tester) async {
      final sessionStore = InMemorySessionStore();
      await tester.pumpWidget(
        buildApp(
          preferences: InMemoryOnboardingPreferences(completed: true),
          sessionStore: sessionStore,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-login-button')));
      await tester.pumpAndSettle();

      expect(find.text('Sua farmácia doméstica'), findsOneWidget);
      expect(find.text('Entre no Zelo'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sua farmácia doméstica'), findsOneWidget);
      expect(find.text('Entre no Zelo'), findsNothing);
    },
  );

  testWidgets('logout limpa sessão e substitui a Home pelo login', (
    tester,
  ) async {
    final sessionStore = InMemorySessionStore(active: true);
    await tester.pumpWidget(
      buildApp(
        preferences: InMemoryOnboardingPreferences(completed: true),
        sessionStore: sessionStore,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('logout-button')));
    await tester.pumpAndSettle();

    expect(sessionStore.active, isFalse);
    expect(sessionStore.clearCount, 1);
    expect(find.text('Entre no Zelo'), findsOneWidget);
    expect(find.text('Sua farmácia doméstica'), findsNothing);
  });

  testWidgets('cadastro e recuperação permitem voltar ao login', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        preferences: InMemoryOnboardingPreferences(completed: true),
        sessionStore: InMemorySessionStore(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('register-link')));
    await tester.pumpAndSettle();
    expect(find.text('Crie sua conta'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Entre no Zelo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recover-password-link')));
    await tester.pumpAndSettle();
    expect(find.text('Recupere seu acesso'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Entre no Zelo'), findsOneWidget);
  });
}
