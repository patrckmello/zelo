import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/features/authentication/data/simulated_authentication_service.dart';
import 'package:zelo/features/authentication/presentation/login_page.dart';
import 'package:zelo/features/authentication/presentation/password_recovery_page.dart';
import 'package:zelo/features/authentication/presentation/register_page.dart';

import '../../../support/in_memory_dependencies.dart';

void main() {
  testWidgets('login valida campos e preserva credenciais inválidas', (
    tester,
  ) async {
    final service = SimulatedAuthenticationService(
      sessionStore: InMemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authenticationService: service,
          onAuthenticated: () {},
          onRegister: () {},
          onRecoverPassword: () {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pump();
    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'email-invalido',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'senha-incorreta',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pump();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'pessoa@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'senha-incorreta',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('E-mail ou senha inválidos'), findsOneWidget);
    expect(find.text('pessoa@example.com'), findsOneWidget);
    expect(find.text('senha-incorreta'), findsOneWidget);
  });

  testWidgets('login válido cria a sessão simulada', (tester) async {
    final sessionStore = InMemorySessionStore();
    final service = SimulatedAuthenticationService(sessionStore: sessionStore);
    var authenticated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authenticationService: service,
          onAuthenticated: () => authenticated = true,
          onRegister: () {},
          onRecoverPassword: () {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      SimulatedAuthenticationService.demoEmail,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      SimulatedAuthenticationService.demoPassword,
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    expect(authenticated, isTrue);
    expect(sessionStore.active, isTrue);
    expect(sessionStore.saveCount, 1);
  });

  testWidgets('cadastro valida obrigatoriedade e tamanho mínimo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          authenticationService: SimulatedAuthenticationService(
            sessionStore: InMemorySessionStore(),
          ),
          onAuthenticated: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('register-submit-button')));
    await tester.pump();

    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
    expect(find.text('Confirme a senha.'), findsOneWidget);
    expect(find.text('O aceite é obrigatório para continuar.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('register-email-field')),
      'email-invalido',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password-field')),
      'curta',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('register-submit-button')));
    await tester.pump();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 8 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('cadastro rejeita confirmação de senha divergente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          authenticationService: SimulatedAuthenticationService(
            sessionStore: InMemorySessionStore(),
          ),
          onAuthenticated: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-name-field')),
      'Pessoa de Teste',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email-field')),
      'teste@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password-field')),
      'senha-segura',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirmation-field')),
      'senha-diferente',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('register-submit-button')));
    await tester.pump();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
  });

  testWidgets('cadastro exige aceite e não persiste dados pessoais', (
    tester,
  ) async {
    final sessionStore = InMemorySessionStore();
    var authenticated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          authenticationService: SimulatedAuthenticationService(
            sessionStore: sessionStore,
          ),
          onAuthenticated: () => authenticated = true,
          onBack: () {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-name-field')),
      'Pessoa de Teste',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email-field')),
      'teste@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password-field')),
      'senha-segura',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirmation-field')),
      'senha-segura',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-terms-checkbox')),
    );
    await tester.tap(find.byKey(const ValueKey('register-terms-checkbox')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('register-submit-button')));
    await tester.pumpAndSettle();

    expect(authenticated, isTrue);
    expect(sessionStore.active, isTrue);
  });

  testWidgets('recuperação rejeita e-mail inválido', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordRecoveryPage(
          authenticationService: SimulatedAuthenticationService(
            sessionStore: InMemorySessionStore(),
          ),
          onBack: () {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email-field')),
      'email-invalido',
    );
    await tester.tap(find.byKey(const ValueKey('recovery-submit-button')));
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recovery-success-message')),
      findsNothing,
    );
  });

  testWidgets('recuperação válida exibe confirmação genérica', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordRecoveryPage(
          authenticationService: SimulatedAuthenticationService(
            sessionStore: InMemorySessionStore(),
          ),
          onBack: () {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email-field')),
      'qualquer@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('recovery-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('recovery-success-message')),
      findsOneWidget,
    );
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
  });

  testWidgets('login permanece responsivo com teclado em 390x844', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authenticationService: SimulatedAuthenticationService(
            sessionStore: InMemorySessionStore(),
          ),
          onAuthenticated: () {},
          onRegister: () {},
          onRecoverPassword: () {},
        ),
      ),
    );

    await tester.showKeyboard(
      find.byKey(const ValueKey('login-password-field')),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('login-submit-button')),
    );

    expect(tester.takeException(), isNull);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(find.byKey(const ValueKey('login-submit-button')), findsOneWidget);
  });
}
