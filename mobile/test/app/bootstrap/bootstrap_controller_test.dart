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
}
