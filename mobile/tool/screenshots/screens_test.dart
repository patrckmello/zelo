// Capturas de tela determinísticas das principais telas do Zelo.
//
// Uso (na pasta mobile/):
//   flutter test tool/screenshots/screens_test.dart
// As imagens são gravadas em build/screenshots ou em ZELO_SCREENSHOTS_DIR.
// Os pontos de coleta exibidos são fictícios (fixtures de teste).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/bootstrap/brand_intro_page.dart';
import 'package:zelo/app/zelo_app.dart';
import 'package:zelo/core/network/zelo_api_client.dart';
import 'package:zelo/core/storage/token_store.dart';
import 'package:zelo/core/theme/zelo_theme.dart';
import 'package:zelo/features/authentication/data/simulated_authentication_service.dart';
import 'package:zelo/features/collection_points/domain/collection_point.dart';
import 'package:zelo/features/collection_points/domain/location.dart';
import 'package:zelo/features/medications/application/medication_store.dart';

import '../../test/support/collection_points_fakes.dart';
import '../../test/support/fake_zelo_backend.dart';
import '../../test/support/in_memory_dependencies.dart';
import '../../test/support/reminder_fakes.dart';
import '../../test/support/scan_fakes.dart';
import 'screenshot_support.dart';

void main() {
  final today = DateTime(2026, 10, 2);
  var appCount = 0;

  setUpAll(ScreenshotSupport.loadFonts);

  Widget app({
    bool onboarded = true,
    bool session = true,
    MedicationStore? store,
    CollectionPointsRepository? points,
    InMemoryOnboardingPreferences? preferences,
  }) => ScreenshotSupport.frame(
    ZeloApp(
      key: ValueKey(appCount++),
      showBrandIntro: false,
      medicationStore: store ?? MedicationStore.seeded(clock: () => today),
      onboardingPreferences:
          preferences ?? InMemoryOnboardingPreferences(completed: onboarded),
      authenticationService: SimulatedAuthenticationService(
        sessionStore: InMemorySessionStore(active: session),
      ),
      collectionPointsRepository: points,
      locationProvider: FakeLocationProvider(),
      externalActions: FakeExternalActions(),
    ),
  );

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget widget, {
    Size size = ScreenshotSupport.phone,
    double textScale = 1,
    Future<void> Function()? navigate,
    bool settle = true,
    Future<void> Function()? after,
  }) async {
    ScreenshotSupport.configureView(tester, size: size);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await ScreenshotSupport.withShadows(() async {
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await navigate?.call();
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        // Animações contínuas nunca assentam; captura-se o quadro atual.
        await tester.pump(const Duration(milliseconds: 16));
      }
      await ScreenshotSupport.capture(tester, name);
      await after?.call();
    });
  }

  /// App no modo conectado, com uma API falsa em memória e três medicamentos
  /// fictícios relativos à data atual (o modo conectado usa o relógio real).
  Widget connectedApp({
    LocationProvider? location,
    FakeReminderService? reminders,
  }) {
    final backend = FakeZeloBackend();
    final now = DateTime.now();
    String iso(DateTime date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    for (final (name, days, quantity) in [
      ('Dipirona', 140, 10),
      ('Loratadina', 12, 6),
      ('Soro fisiológico', -5, 1),
    ]) {
      backend.medications.add({
        'id': 'srv-$name',
        'name': name,
        'expiration_date': iso(now.add(Duration(days: days))),
        'quantity': quantity,
        'notes': '',
        'active': true,
      });
    }
    final client = ZeloApiClient(
      baseUrl: Uri.parse('http://api.zelo.test'),
      tokenStore: InMemoryTokenStore(),
      httpClient: backend.client,
    );
    return ScreenshotSupport.frame(
      ZeloApp(
        key: ValueKey(appCount++),
        apiClient: client,
        showBrandIntro: false,
        onboardingPreferences: InMemoryOnboardingPreferences(completed: true),
        locationProvider: location ?? FakeLocationProvider(),
        externalActions: FakeExternalActions(),
        imageCapture: FakeImageCapture(),
        reminderService: reminders ?? FakeReminderService(),
        reminderPreferences: InMemoryReminderPreferences(),
      ),
    );
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      FakeZeloBackend.email,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      FakeZeloBackend.password,
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('01 abertura', (tester) async {
    await shoot(
      tester,
      '01-abertura',
      ScreenshotSupport.frame(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ZeloTheme.light,
          home: BrandIntroPage(onFinished: () {}),
        ),
      ),
    );
  });

  for (final page in [1, 2, 3]) {
    testWidgets('02 onboarding $page', (tester) async {
      await shoot(
        tester,
        '02-onboarding-$page',
        app(onboarded: false, session: false),
        navigate: () async {
          for (var index = 1; index < page; index++) {
            await tester.tap(
              find.byKey(const ValueKey('onboarding-next-button')),
            );
            await tester.pumpAndSettle();
          }
        },
      );
    });
  }

  testWidgets('03 login', (tester) async {
    await shoot(tester, '03-login', app(session: false));
  });

  testWidgets('04 cadastro', (tester) async {
    await shoot(
      tester,
      '04-cadastro',
      app(session: false),
      navigate: () async {
        await tapVisible(tester, find.byKey(const ValueKey('register-link')));
      },
    );
  });

  testWidgets('05 recuperação', (tester) async {
    await shoot(
      tester,
      '05-recuperacao',
      app(session: false),
      navigate: () async {
        await tapVisible(
          tester,
          find.byKey(const ValueKey('recover-password-link')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('recovery-email-field')),
          'pessoa@example.com',
        );
        await tester.tap(find.byKey(const ValueKey('recovery-submit-button')));
      },
    );
  });

  testWidgets('06 início', (tester) async {
    await shoot(tester, '06-inicio', app());
  });

  testWidgets('07 início rolado', (tester) async {
    await shoot(
      tester,
      '07-inicio-acoes',
      app(),
      navigate: () async {
        await tester.ensureVisible(find.text('Ações rápidas'));
      },
    );
  });

  testWidgets('08 início vazio', (tester) async {
    await shoot(
      tester,
      '08-inicio-vazio',
      app(store: MedicationStore(clock: () => today)),
    );
  });

  testWidgets('09 lista', (tester) async {
    await shoot(
      tester,
      '09-lista',
      app(),
      navigate: () async => tester.tap(find.text('Ver todos')),
    );
  });

  testWidgets('10 lista filtrada', (tester) async {
    await shoot(
      tester,
      '10-lista-vencidos',
      app(),
      navigate: () async {
        await tester.tap(find.text('Ver todos'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('medication-filter-expired')),
        );
      },
    );
  });

  for (final (name, slug) in [
    ('Dipirona', 'valido'),
    ('Loratadina', 'proximo'),
    ('Soro fisiológico', 'vencido'),
  ]) {
    testWidgets('11 detalhe $slug', (tester) async {
      await shoot(
        tester,
        '11-detalhe-$slug',
        app(),
        navigate: () async {
          await tester.tap(find.text('Ver todos'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(name));
        },
      );
    });
  }

  testWidgets('12 formulário', (tester) async {
    await shoot(
      tester,
      '12-formulario',
      app(),
      navigate: () async {
        await tapVisible(tester, find.text('Cadastrar medicamento'));
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  });

  testWidgets('13 descartar sem servidor', (tester) async {
    await shoot(
      tester,
      '13-descartar-demo',
      app(),
      navigate: () async => tester.tap(find.text('Descartar')),
    );
  });

  testWidgets('14 descartar busca', (tester) async {
    await shoot(
      tester,
      '14-descartar-busca',
      app(points: FakeCollectionPointsRepository()),
      navigate: () async {
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('points-use-location-button')),
        );
      },
    );
  });

  testWidgets('15 descartar resultados', (tester) async {
    await shoot(
      tester,
      '15-descartar-resultados',
      app(points: FakeCollectionPointsRepository()),
      navigate: () async {
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        await tapVisible(
          tester,
          find.byKey(const ValueKey('points-use-location-button')),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Farmácia Exemplo - Centro'));
      },
    );
  });

  testWidgets('16 detalhe do ponto', (tester) async {
    await shoot(
      tester,
      '16-ponto-detalhe',
      app(points: FakeCollectionPointsRepository()),
      navigate: () async {
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        await tapVisible(
          tester,
          find.byKey(const ValueKey('points-use-location-button')),
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Unidade de Saúde Exemplo'));
      },
    );
  });

  testWidgets('17 histórico', (tester) async {
    await shoot(
      tester,
      '17-historico',
      app(),
      navigate: () async => tester.tap(find.text('Histórico')),
    );
  });

  testWidgets('18 conta', (tester) async {
    await shoot(
      tester,
      '18-conta',
      app(),
      navigate: () async => tester.tap(find.text('Conta')),
    );
  });

  testWidgets('22 registrar descarte', (tester) async {
    await shoot(
      tester,
      '22-registrar-descarte',
      app(),
      navigate: () async {
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        await tapVisible(
          tester,
          find.byKey(const ValueKey('register-disposal-button')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('disposal-place-field')),
          'Farmácia do bairro',
        );
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  });

  testWidgets('23 histórico com registro', (tester) async {
    await shoot(
      tester,
      '23-historico-registro',
      app(),
      navigate: () async {
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        await tapVisible(
          tester,
          find.byKey(const ValueKey('register-disposal-button')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('disposal-place-field')),
          'Farmácia do bairro',
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('confirm-disposal-button')),
        );
        // A celebração segue sozinha para o Histórico.
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('24 recuperação com código (servidor)', (tester) async {
    final backend = FakeZeloBackend();
    final client = ZeloApiClient(
      baseUrl: Uri.parse('http://api.zelo.test'),
      tokenStore: InMemoryTokenStore(),
      httpClient: backend.client,
    );
    await shoot(
      tester,
      '24-recuperacao-codigo',
      ScreenshotSupport.frame(
        ZeloApp(
          key: ValueKey(appCount++),
          apiClient: client,
          showBrandIntro: false,
          onboardingPreferences: InMemoryOnboardingPreferences(completed: true),
          locationProvider: FakeLocationProvider(),
          externalActions: FakeExternalActions(),
        ),
      ),
      navigate: () async {
        await tapVisible(
          tester,
          find.byKey(const ValueKey('recover-password-link')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('recovery-email-field')),
          FakeZeloBackend.email,
        );
        await tester.tap(find.byKey(const ValueKey('recovery-submit-button')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('reset-confirm-button')),
        );
      },
    );
  });

  testWidgets('19 erro de inicialização', (tester) async {
    await shoot(
      tester,
      '19-erro-inicializacao',
      app(
        preferences: InMemoryOnboardingPreferences(
          completed: true,
          failReads: 1,
        ),
      ),
    );
  });

  testWidgets('20 tela pequena com texto ampliado', (tester) async {
    await shoot(
      tester,
      '20-inicio-pequeno-texto-ampliado',
      app(),
      size: ScreenshotSupport.smallPhone,
      textScale: 1.6,
    );
  });

  testWidgets('21 lista com texto ampliado', (tester) async {
    await shoot(
      tester,
      '21-lista-texto-ampliado',
      app(),
      size: ScreenshotSupport.smallPhone,
      textScale: 1.6,
      navigate: () async => tester.tap(find.text('Ver todos')),
    );
  });

  testWidgets('25 início conectado', (tester) async {
    await shoot(
      tester,
      '25-inicio-conectado',
      connectedApp(),
      navigate: () async {
        await signIn(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey('home-scan-action')),
        );
      },
    );
  });

  testWidgets('26 leitura da embalagem', (tester) async {
    await shoot(
      tester,
      '26-leitura-embalagem',
      connectedApp(),
      navigate: () async {
        await signIn(tester);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('home-scan-action')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('scan-source-camera')));
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  });

  testWidgets('27 escolha da foto', (tester) async {
    await shoot(
      tester,
      '27-escolha-da-foto',
      connectedApp(),
      navigate: () async {
        await signIn(tester);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('home-scan-action')),
        );
      },
    );
  });

  testWidgets('28 meu perfil', (tester) async {
    await shoot(
      tester,
      '28-meu-perfil',
      connectedApp(),
      navigate: () async {
        await signIn(tester);
        await tester.tap(find.text('Conta'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('open-profile')));
      },
    );
  });

  testWidgets('29 descartar localizando', (tester) async {
    await shoot(
      tester,
      '29-descartar-localizando',
      connectedApp(location: HangingLocationProvider()),
      settle: false,
      navigate: () async {
        await signIn(tester);
        await tapVisible(tester, find.text('Encontrar ponto de descarte'));
        await tester.pumpAndSettle();
        await tapVisible(
          tester,
          find.byKey(const ValueKey('points-use-location-button')),
        );
        await tester.pump(const Duration(milliseconds: 800));
        await tester.ensureVisible(
          find.byKey(const ValueKey('page-back-button')),
        );
      },
      // Esgota o tempo-limite da localização para não deixar timers.
      after: () => tester.pump(const Duration(seconds: 31)),
    );
  });

  Future<void> registerDisposal(WidgetTester tester) async {
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('register-disposal-button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('disposal-place-field')),
      'Farmácia do bairro',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-disposal-button')),
    );
  }

  testWidgets('30 carimbo do cadastro', (tester) async {
    await shoot(
      tester,
      '30-carimbo-cadastro',
      app(),
      settle: false,
      navigate: () async {
        await tapVisible(tester, find.text('Cadastrar medicamento'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('medication-name-field')),
          'Paracetamol',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tapVisible(
          tester,
          find.byKey(const ValueKey('save-medication-button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 900));
      },
      after: tester.pumpAndSettle,
    );
  });

  for (final (name, elapsed) in [
    ('31-descarte-trajeto', 300),
    ('32-descarte-varredura', 600),
    ('33-descarte-mandou-bem', 2600),
  ]) {
    testWidgets(name, (tester) async {
      await shoot(
        tester,
        name,
        app(),
        settle: false,
        navigate: () async {
          await registerDisposal(tester);
          await tester.pump();
          for (var time = 0; time < elapsed; time += 100) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        },
        after: tester.pumpAndSettle,
      );
    });
  }

  Future<void> openReminders(WidgetTester tester) async {
    await signIn(tester);
    await tester.tap(find.text('Conta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('reminders-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reminders-switch')));
    await tester.pumpAndSettle();
  }

  testWidgets('38 lembretes ligados', (tester) async {
    await shoot(
      tester,
      '38-lembretes-ligados',
      connectedApp(),
      navigate: () async {
        await openReminders(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey('reminders-test')),
        );
      },
    );
  });

  testWidgets('39 lembretes bloqueados', (tester) async {
    await shoot(
      tester,
      '39-lembretes-bloqueados',
      connectedApp(reminders: FakeReminderService(grantOnRequest: false)),
      navigate: () async {
        await openReminders(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey('reminders-open-settings')),
        );
      },
    );
  });
}
