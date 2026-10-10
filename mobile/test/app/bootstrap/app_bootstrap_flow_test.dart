import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/bootstrap/app_launch_flow.dart';
import 'package:zelo/app/bootstrap/brand_intro_page.dart';
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
    expect(find.text('Sua farmácia de casa, em ordem'), findsOneWidget);

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
    expect(find.text('Sua farmácia de casa, em ordem'), findsNothing);
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
      await tapVisible(tester, find.byKey(const ValueKey('demo-login-button')));
      await tester.pumpAndSettle();

      expect(find.text('Sua farmácia doméstica'), findsOneWidget);
      expect(find.text('Entre no Zelo'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sua farmácia doméstica'), findsOneWidget);
      expect(find.text('Entre no Zelo'), findsNothing);
    },
  );

  testWidgets('logout existe somente na Conta e identifica sessão simulada', (
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

    expect(find.byKey(const ValueKey('logout-button')), findsNothing);
    expect(find.text('Sessão simulada'), findsNothing);

    await tester.tap(find.text('Conta'));
    await tester.pumpAndSettle();

    expect(find.text('Sessão simulada'), findsOneWidget);
    expect(find.text(SimulatedAuthenticationService.demoEmail), findsNothing);
    expect(find.byKey(const ValueKey('logout-button')), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('logout-button')));
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

    await tapVisible(tester, find.byKey(const ValueKey('register-link')));
    await tester.pumpAndSettle();
    expect(find.text('Crie sua conta'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Entre no Zelo'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('recover-password-link')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recupere seu acesso'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Entre no Zelo'), findsOneWidget);
  });

  testWidgets('bootstrap inicia enquanto a animação permanece visível', (
    tester,
  ) async {
    final completer = Completer<bool>();
    final preferences = DeferredOnboardingPreferences(completer);
    final store = MedicationStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ZeloApp(
        medicationStore: store,
        onboardingPreferences: preferences,
        authenticationService: SimulatedAuthenticationService(
          sessionStore: InMemorySessionStore(),
        ),
      ),
    );

    expect(preferences.readCount, 1);
    expect(find.byKey(const ValueKey('zelo-brand-symbol')), findsOneWidget);

    completer.complete(false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('zelo-brand-symbol')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Sua farmácia de casa, em ordem'), findsOneWidget);
  });

  testWidgets('mostra espera real quando a animação termina primeiro', (
    tester,
  ) async {
    final completer = Completer<bool>();
    final preferences = DeferredOnboardingPreferences(completer);
    final store = MedicationStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ZeloApp(
        medicationStore: store,
        onboardingPreferences: preferences,
        authenticationService: SimulatedAuthenticationService(
          sessionStore: InMemorySessionStore(),
        ),
      ),
    );
    // A faixa de carregamento repete enquanto a inicialização não termina,
    // então avança-se o relógio até a abertura sair.
    final limit =
        BrandIntroPage.defaultDuration + AppLaunchFlow.fadeDuration * 3;
    var elapsed = Duration.zero;
    while (find.byType(BrandIntroPage).evaluate().isNotEmpty &&
        elapsed < limit) {
      await tester.pump(const Duration(milliseconds: 100));
      elapsed += const Duration(milliseconds: 100);
    }

    // Mesma assinatura da abertura, agora com a faixa indicando a espera.
    expect(find.text('Preparando o Zelo…'), findsOneWidget);
    expect(find.text('Zelo'), findsOneWidget);

    completer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Entre no Zelo'), findsOneWidget);
  });
}
