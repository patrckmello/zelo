import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/bootstrap/bootstrap_controller.dart';
import 'package:zelo/features/authentication/data/simulated_authentication_service.dart';

import '../../support/in_memory_dependencies.dart';

void main() {
  BootstrapController createController({
    required InMemoryOnboardingPreferences preferences,
    required InMemorySessionStore sessionStore,
  }) => BootstrapController(
    onboardingPreferences: preferences,
    authenticationService: SimulatedAuthenticationService(
      sessionStore: sessionStore,
    ),
  );

  test('primeiro acesso direciona ao onboarding', () async {
    final controller = createController(
      preferences: InMemoryOnboardingPreferences(),
      sessionStore: InMemorySessionStore(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state, BootstrapState.firstAccess);
  });

  test('onboarding concluído sem sessão direciona ao login', () async {
    final controller = createController(
      preferences: InMemoryOnboardingPreferences(completed: true),
      sessionStore: InMemorySessionStore(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state, BootstrapState.unauthenticated);
  });

  test('sessão simulada restaurada direciona à Home', () async {
    final controller = createController(
      preferences: InMemoryOnboardingPreferences(completed: true),
      sessionStore: InMemorySessionStore(active: true),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state, BootstrapState.authenticated);
  });

  test('erro de bootstrap é recuperável em nova tentativa', () async {
    final preferences = InMemoryOnboardingPreferences(
      completed: true,
      failReads: 1,
    );
    final controller = createController(
      preferences: preferences,
      sessionStore: InMemorySessionStore(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state, BootstrapState.recoverableError);

    await controller.load();
    expect(controller.state, BootstrapState.unauthenticated);
    expect(preferences.readCount, 2);
  });

  test(
    'compartilha a leitura enquanto o bootstrap está em andamento',
    () async {
      final completer = Completer<bool>();
      final preferences = DeferredOnboardingPreferences(completer);
      final controller = BootstrapController(
        onboardingPreferences: preferences,
        authenticationService: SimulatedAuthenticationService(
          sessionStore: InMemorySessionStore(),
        ),
      );
      addTearDown(controller.dispose);

      final firstLoad = controller.load();
      final secondLoad = controller.load();

      expect(identical(firstLoad, secondLoad), isTrue);
      expect(preferences.readCount, 1);

      completer.complete(false);
      await firstLoad;
      expect(controller.state, BootstrapState.firstAccess);
    },
  );

  test('ignora conclusão pendente depois do descarte', () async {
    final completer = Completer<bool>();
    final controller = BootstrapController(
      onboardingPreferences: DeferredOnboardingPreferences(completer),
      authenticationService: SimulatedAuthenticationService(
        sessionStore: InMemorySessionStore(),
      ),
    );

    final load = controller.load();
    controller.dispose();
    completer.complete(false);

    await expectLater(load, completes);
  });
}
