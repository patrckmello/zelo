# Correção e reconciliação do M2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir incrementalmente navegação, abertura e onboarding do M2 sem regredir o fluxo manual de medicamentos nem declarar o marco concluído.

**Architecture:** Manter `ZeloApp`, `AppBootstrapFlow`, `BootstrapController`, `ZeloShell` e o `MedicationStore` existentes. Montar o bootstrap por baixo da abertura para iniciar as leituras em paralelo, tornar o controlador idempotente enquanto uma carga estiver em andamento e transformar Medicamentos em rota aberta pela Home. As quatro áreas principais permanecem no mesmo `IndexedStack` e compartilham uma única `NavigationBar`.

**Tech Stack:** Flutter 3.47.1, Dart 3.13.1, Material 3, `shared_preferences`, `flutter_test`.

**Restrição operacional:** Não criar commit, push ou PR. Os checkpoints são revisões locais; ao final, sugerir commits semânticos sem executá-los.

---

## Estrutura de arquivos

Novos arquivos:

- `mobile/lib/app/bootstrap/app_launch_flow.dart`: mantém o bootstrap montado sob a abertura.
- `mobile/lib/features/collection_points/presentation/collection_points_page.dart`: estado futuro de Descartar.
- `mobile/lib/features/disposal_history/presentation/disposal_history_page.dart`: estado vazio do Histórico.
- `mobile/lib/features/account/presentation/account_page.dart`: sessão simulada e logout.
- `mobile/lib/features/onboarding/presentation/onboarding_illustration.dart`: composições do onboarding.

Arquivos principais modificados:

- `mobile/lib/app/zelo_app.dart`, `mobile/lib/app/zelo_shell.dart` e `mobile/lib/app/bootstrap/*.dart`.
- `mobile/lib/features/home/presentation/home_page.dart` e `mobile/lib/features/onboarding/presentation/onboarding_page.dart`.
- testes em `mobile/test/app/bootstrap/`, `mobile/test/features/onboarding/` e `mobile/test/widget_test.dart`.
- `README.md`, documentos vivos em `docs/` e `mobile/README.md`.

---

### Task 1: Restabelecer a linha de base verificável

**Files:**

- Inspect: `.gitignore`
- Inspect: `mobile/pubspec.yaml`
- Inspect: `mobile/pubspec.lock`
- No tracked files changed

- [ ] **Step 1: Confirmar a árvore de trabalho**

```powershell
git status --short --branch
git diff --check
```

Expected: `main` em `579814d`, apenas especificação/plano não versionados e nenhum código alterado.

- [ ] **Step 2: Localizar ou restaurar o Flutter 3.47.1**

```powershell
if (Test-Path -LiteralPath '.tools/flutter/bin/flutter.bat') {
  & '.tools/flutter/bin/flutter.bat' --version
} elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
  flutter --version
} else {
  New-Item -ItemType Directory -Path '.tools' -Force | Out-Null
  git clone --depth 1 --branch 3.47.1 https://github.com/flutter/flutter.git '.tools/flutter'
  & '.tools/flutter/bin/flutter.bat' --version
}
```

Expected: Flutter 3.47.1/Dart 3.13.1; `.tools/` continua ignorado.

- [ ] **Step 3: Executar a linha de base em `mobile/`**

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```

Expected: formatação, análise, 37 testes e build aprovados. Se falhar antes de alterações, aplicar `superpowers:systematic-debugging` e separar ambiente de regressão preexistente.

---

### Task 2: Iniciar bootstrap em paralelo e tornar a carga segura

**Files:**

- Create: `mobile/lib/app/bootstrap/app_launch_flow.dart`
- Modify: `mobile/lib/app/zelo_app.dart:12`
- Modify: `mobile/lib/app/bootstrap/bootstrap_controller.dart:14`
- Modify: `mobile/test/support/in_memory_dependencies.dart:1`
- Modify: `mobile/test/app/bootstrap/bootstrap_controller_test.dart:1`
- Modify: `mobile/test/app/bootstrap/app_bootstrap_flow_test.dart:1`

- [ ] **Step 1: Criar dependência controlável de teste**

Add `import 'dart:async';` and this class to `in_memory_dependencies.dart`:

```dart
class DeferredOnboardingPreferences implements OnboardingPreferences {
  DeferredOnboardingPreferences(this.completer);

  final Completer<bool> completer;
  int readCount = 0;

  @override
  Future<bool> isCompleted() {
    readCount++;
    return completer.future;
  }

  @override
  Future<void> markCompleted() async {}
}
```

- [ ] **Step 2: Escrever testes falhos de deduplicação e descarte**

Add `dart:async` to `bootstrap_controller_test.dart` and append:

```dart
test('compartilha a leitura enquanto o bootstrap está em andamento', () async {
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
});

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
```

- [ ] **Step 3: Verificar RED**

```powershell
flutter test test/app/bootstrap/bootstrap_controller_test.dart
```

Expected: FAIL por operações distintas e/ou notificação após `dispose()`.

- [ ] **Step 4: Implementar uma carga compartilhada**

Refactor `BootstrapController` to use:

```dart
Future<void>? _loadInFlight;
bool _disposed = false;

Future<void> load() {
  final activeLoad = _loadInFlight;
  if (activeLoad != null) return activeLoad;

  late final Future<void> operation;
  operation = _performLoad().whenComplete(() {
    if (identical(_loadInFlight, operation)) _loadInFlight = null;
  });
  _loadInFlight = operation;
  return operation;
}

Future<void> _performLoad() async {
  _setState(BootstrapState.initializing);
  try {
    final onboardingCompleted = await onboardingPreferences.isCompleted();
    if (!onboardingCompleted) {
      _setState(BootstrapState.firstAccess);
      return;
    }
    final hasSession = await authenticationService.restoreSession();
    _setState(
      hasSession
          ? BootstrapState.authenticated
          : BootstrapState.unauthenticated,
    );
  } catch (_) {
    _setState(BootstrapState.recoverableError);
  }
}

void _setState(BootstrapState value) {
  if (_disposed) return;
  _state = value;
  notifyListeners();
}

@override
void dispose() {
  _disposed = true;
  super.dispose();
}
```

- [ ] **Step 5: Verificar GREEN do controlador**

```powershell
flutter test test/app/bootstrap/bootstrap_controller_test.dart
```

Expected: todos os testes do controlador passam.

- [ ] **Step 6: Escrever testes falhos das duas ordens de conclusão**

Add `dart:async` to `app_bootstrap_flow_test.dart` and append:

```dart
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
  expect(find.text('Cuide dos seus medicamentos'), findsOneWidget);
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
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();

  expect(find.text('Preparando o Zelo…'), findsOneWidget);

  completer.complete(true);
  await tester.pumpAndSettle();
  expect(find.text('Entre no Zelo'), findsOneWidget);
});
```

- [ ] **Step 7: Verificar RED do paralelismo**

```powershell
flutter test test/app/bootstrap/app_bootstrap_flow_test.dart
```

Expected: FAIL porque o bootstrap atual só monta após a animação.

- [ ] **Step 8: Criar `AppLaunchFlow`**

```dart
import 'package:flutter/material.dart';

import 'brand_intro_page.dart';

class AppLaunchFlow extends StatefulWidget {
  const AppLaunchFlow({
    required this.child,
    this.showBrandIntro = true,
    super.key,
  });

  final Widget child;
  final bool showBrandIntro;

  @override
  State<AppLaunchFlow> createState() => _AppLaunchFlowState();
}

class _AppLaunchFlowState extends State<AppLaunchFlow> {
  late bool _showBrandIntro;

  @override
  void initState() {
    super.initState();
    _showBrandIntro = widget.showBrandIntro;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: _showBrandIntro, child: widget.child),
        if (_showBrandIntro)
          BrandIntroPage(
            onFinished: () {
              if (mounted) setState(() => _showBrandIntro = false);
            },
          ),
      ],
    );
  }
}
```

- [ ] **Step 9: Usar o coordenador em `ZeloApp`**

Remove `_showBrandIntro` state and set:

```dart
home: AppLaunchFlow(
  showBrandIntro: widget.showBrandIntro,
  child: AppBootstrapFlow(
    onboardingPreferences: _onboardingPreferences,
    authenticationService: _authenticationService,
    medicationStore: _medicationStore,
  ),
),
```

- [ ] **Step 10: Verificar GREEN do bootstrap**

```powershell
flutter test test/app/bootstrap/bootstrap_controller_test.dart test/app/bootstrap/app_bootstrap_flow_test.dart
git diff --check
```

Expected: testes passam, uma leitura inicial e nenhuma espera artificial.

---

### Task 3: Reduzir a abertura ao símbolo oficial

**Files:**

- Modify: `mobile/lib/app/bootstrap/brand_intro_page.dart:72`
- Modify: `mobile/test/app/bootstrap/brand_intro_page_test.dart:6`

- [ ] **Step 1: Tornar o teste estrito sobre textos ausentes**

```dart
expect(find.byKey(const ValueKey('zelo-brand-symbol')), findsOneWidget);
expect(find.text('Zelo'), findsNothing);
expect(find.text('Cuide. Organize. Descarte certo.'), findsNothing);
expect(completionCount, 0);
```

Keep the assertions for one completion and reduced motion.

- [ ] **Step 2: Verificar RED**

```powershell
flutter test test/app/bootstrap/brand_intro_page_test.dart
```

Expected: FAIL porque nome e slogan ainda aparecem.

- [ ] **Step 3: Manter somente o ativo oficial**

Replace the `Column` inside `ScaleTransition` with:

```dart
RotationTransition(
  turns: _turns,
  child: Image.asset(
    'assets/branding/zelo-symbol.png',
    key: const ValueKey('zelo-brand-symbol'),
    width: 144,
    height: 144,
    semanticLabel: 'Símbolo do Zelo',
  ),
),
```

Remove the unused color import. Preserve 800 ms, motion curves, `_finished` and `disableAnimations`.

- [ ] **Step 4: Verificar GREEN**

```powershell
flutter test test/app/bootstrap/brand_intro_page_test.dart
```

Expected: all opening tests pass.

---

### Task 4: Substituir a navegação e mover o logout para Conta

**Files:**

- Create: `mobile/lib/features/collection_points/presentation/collection_points_page.dart`
- Create: `mobile/lib/features/disposal_history/presentation/disposal_history_page.dart`
- Create: `mobile/lib/features/account/presentation/account_page.dart`
- Modify: `mobile/lib/app/zelo_shell.dart:9`
- Modify: `mobile/lib/features/home/presentation/home_page.dart:7`
- Modify: `mobile/test/widget_test.dart:25`
- Modify: `mobile/test/app/bootstrap/app_bootstrap_flow_test.dart:55`

- [ ] **Step 1: Escrever testes falhos dos quatro destinos**

Add to `widget_test.dart`:

```dart
testWidgets('exibe quatro destinos sem aba de medicamentos', (tester) async {
  final store = MedicationStore.seeded(clock: () => referenceDate);
  addTearDown(store.dispose);
  await tester.pumpWidget(authenticatedApp(store));
  await tester.pumpAndSettle();

  final navigation = find.byType(NavigationBar);
  for (final label in ['Início', 'Descartar', 'Histórico', 'Conta']) {
    expect(
      find.descendant(of: navigation, matching: find.text(label)),
      findsOneWidget,
    );
  }
  expect(
    find.descendant(of: navigation, matching: find.text('Medicamentos')),
    findsNothing,
  );
});

testWidgets('abre medicamentos por Ver todos', (tester) async {
  final store = MedicationStore.seeded(clock: () => referenceDate);
  addTearDown(store.dispose);
  await tester.pumpWidget(authenticatedApp(store));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ver todos'));
  await tester.pumpAndSettle();

  expect(find.widgetWithText(AppBar, 'Medicamentos'), findsOneWidget);
  expect(find.text('Dipirona'), findsOneWidget);
  expect(find.text('Loratadina'), findsOneWidget);
  expect(find.text('Soro fisiológico'), findsOneWidget);
});

testWidgets('Descartar é futuro e Histórico inicia vazio', (tester) async {
  final store = MedicationStore(clock: () => referenceDate);
  addTearDown(store.dispose);
  await tester.pumpWidget(authenticatedApp(store));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Descartar'));
  await tester.pumpAndSettle();
  expect(find.text('Pontos de descarte'), findsOneWidget);
  expect(find.textContaining('EcoMed'), findsOneWidget);

  await tester.tap(find.text('Histórico'));
  await tester.pumpAndSettle();
  expect(find.text('Nenhum descarte registrado'), findsOneWidget);
  expect(
    find.text('Os descartes registrados aparecerão aqui.'),
    findsOneWidget,
  );
});
```

In the existing summary, edit/remove and error tests, replace:

```dart
await tester.tap(find.byIcon(Icons.medication_outlined));
```

with:

```dart
await tester.tap(find.text('Ver todos'));
```

- [ ] **Step 2: Escrever o teste falho de logout exclusivo**

Replace the logout test in `app_bootstrap_flow_test.dart` with:

```dart
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
  await tester.tap(find.text('Conta'));
  await tester.pumpAndSettle();
  expect(find.text('Sessão simulada'), findsOneWidget);
  expect(find.byKey(const ValueKey('logout-button')), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('logout-button')));
  await tester.pumpAndSettle();
  expect(sessionStore.active, isFalse);
  expect(sessionStore.clearCount, 1);
  expect(find.text('Entre no Zelo'), findsOneWidget);
});
```

- [ ] **Step 3: Verificar RED**

```powershell
flutter test test/widget_test.dart test/app/bootstrap/app_bootstrap_flow_test.dart
```

Expected: FAIL por rótulos, rotas e Conta ainda ausentes.

- [ ] **Step 4: Criar Descartar**

Create `collection_points_page.dart`:

```dart
import 'package:flutter/material.dart';

class CollectionPointsPage extends StatelessWidget {
  const CollectionPointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_searching,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Pontos de descarte',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'A consulta de pontos será disponibilizada quando a '
                  'integração com a EcoMed estiver pronta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Criar o Histórico vazio**

Create `disposal_history_page.dart`:

```dart
import 'package:flutter/material.dart';

class DisposalHistoryPage extends StatelessWidget {
  const DisposalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Nenhum descarte registrado',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Os descartes registrados aparecerão aqui.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

Do not add records, dates or persistence.

- [ ] **Step 6: Criar Conta sem dados pessoais**

Create `account_page.dart`:

```dart
import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    required this.onLogout,
    this.isLoggingOut = false,
    super.key,
  });

  final Future<void> Function() onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Conta', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sessão simulada',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esta versão demonstra a navegação e não representa '
                          'uma conta real. Nenhum dado pessoal é exibido aqui.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const ValueKey('logout-button'),
                  onPressed: isLoggingOut ? null : onLogout,
                  icon: isLoggingOut
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Atualizar `ZeloShell`**

Use these destinations:

```dart
static const _destinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Início',
  ),
  NavigationDestination(
    icon: Icon(Icons.recycling_outlined),
    selectedIcon: Icon(Icons.recycling),
    label: 'Descartar',
  ),
  NavigationDestination(
    icon: Icon(Icons.history_outlined),
    selectedIcon: Icon(Icons.history),
    label: 'Histórico',
  ),
  NavigationDestination(
    icon: Icon(Icons.account_circle_outlined),
    selectedIcon: Icon(Icons.account_circle),
    label: 'Conta',
  ),
];
```

Import the three new pages and replace the `IndexedStack` children with:

```dart
children: [
  HomePage(
    medicationStore: widget.medicationStore,
    onAddMedication: _openMedicationForm,
    onOpenMedications: _openMedications,
    onOpenDisposal: () => _selectDestination(1),
  ),
  const CollectionPointsPage(),
  const DisposalHistoryPage(),
  AccountPage(
    onLogout: widget.onLogout,
    isLoggingOut: widget.isLoggingOut,
  ),
],
```

Open medications with:

```dart
Future<void> _openMedications() => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => MedicationsPage(store: widget.medicationStore),
  ),
);
```

Delete `_PlaceholderPage`.

- [ ] **Step 8: Remover logout da Home**

Delete `onLogout` and `isLoggingOut` from `HomePage`. Replace the title/logout row with:

```dart
Text('Zelo', style: Theme.of(context).textTheme.headlineLarge),
```

Keep summary, `Ver todos`, both quick actions and the memory notice unchanged.

- [ ] **Step 9: Verificar GREEN e regressão de medicamentos**

```powershell
flutter test test/widget_test.dart test/app/bootstrap/app_bootstrap_flow_test.dart
```

Expected: four destinations, medication route, empty history, future disposal state and account-only logout pass; existing add/edit/delete/error medication scenarios remain green.

---

### Task 5: Reconciliar visualmente o onboarding

**Files:**

- Create: `mobile/lib/features/onboarding/presentation/onboarding_illustration.dart`
- Modify: `mobile/lib/features/onboarding/presentation/onboarding_page.dart:23`
- Modify: `mobile/test/features/onboarding/presentation/onboarding_page_test.dart:8`

- [ ] **Step 1: Escrever testes falhos das composições e responsividade**

Add to `onboarding_page_test.dart`:

```dart
testWidgets('usa composição visual identificada em cada página', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OnboardingPage(
        preferences: InMemoryOnboardingPreferences(),
        onCompleted: () {},
      ),
    ),
  );
  expect(find.byKey(const ValueKey('onboarding-illustration-1')), findsOneWidget);
});

testWidgets('redução de movimento troca página sem transição', (tester) async {
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
  expect(find.byKey(const ValueKey('onboarding-next-button')), findsOneWidget);
});
```

Keep the existing 390 × 844/text scale 2 coverage.

- [ ] **Step 2: Verificar RED**

```powershell
flutter test test/features/onboarding/presentation/onboarding_page_test.dart
```

Expected: FAIL because composed illustrations do not exist.

- [ ] **Step 3: Criar o componente visual**

Create `onboarding_illustration.dart` with the public contract:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';

enum OnboardingVisual { organization, wastePrevention, responsibleDisposal }

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    required this.visual,
    required this.pageNumber,
    required this.semanticLabel,
    super.key,
  });

  final OnboardingVisual visual;
  final int pageNumber;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: AspectRatio(
            aspectRatio: 1.45,
            child: DecoratedBox(
              key: ValueKey('onboarding-illustration-$pageNumber'),
              decoration: BoxDecoration(
                color: ZeloColors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Opacity(
                      opacity: 0.20,
                      child: Image.asset(
                        'assets/branding/zelo-symbol.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: switch (visual) {
                        OnboardingVisual.organization =>
                          const _OrganizationScene(),
                        OnboardingVisual.wastePrevention =>
                          const _WastePreventionScene(),
                        OnboardingVisual.responsibleDisposal =>
                          const _DisposalScene(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar as três cenas simples**

In the same file, implement:

```dart
class _OrganizationScene extends StatelessWidget {
  const _OrganizationScene();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.bottomLeft,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _SceneCard(icon: Icons.medication_outlined, height: 112)),
        SizedBox(width: 12),
        Expanded(child: _SceneCard(icon: Icons.inventory_2_outlined, height: 76)),
        SizedBox(width: 12),
        Expanded(child: _SceneCard(icon: Icons.event_outlined, height: 96)),
      ],
    ),
  );
}

class _WastePreventionScene extends StatelessWidget {
  const _WastePreventionScene();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.bottomLeft,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: _SceneCard(icon: Icons.calendar_month_outlined, height: 126),
        ),
        SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: _SceneIcon(
            icon: Icons.notifications_active_outlined,
            color: ZeloColors.warningAmber,
          ),
        ),
      ],
    ),
  );
}

class _DisposalScene extends StatelessWidget {
  const _DisposalScene();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.bottomCenter,
    child: Row(
      children: [
        _SceneIcon(icon: Icons.medication_outlined),
        Expanded(child: Divider(thickness: 3)),
        _SceneIcon(icon: Icons.recycling_outlined),
        Expanded(child: Divider(thickness: 3)),
        _SceneIcon(icon: Icons.location_on_outlined),
      ],
    ),
  );
}
```

Complete the same file with reusable rounded-rectangle primitives:

```dart
class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.icon, required this.height});

  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ZeloColors.petroleumBlue.withValues(alpha: 0.12),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: ZeloColors.petroleumBlue, size: 28),
    );
  }
}

class _SceneIcon extends StatelessWidget {
  const _SceneIcon({
    required this.icon,
    this.color = ZeloColors.petroleumBlue,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 28),
    );
  }
}
```

Use only existing colors, radii 16/28 and 4 px spacing multiples.

- [ ] **Step 5: Integrar ao onboarding**

Replace item icons with `OnboardingVisual.organization`, `wastePrevention` and `responsibleDisposal`. Replace the circular icon block with:

```dart
OnboardingIllustration(
  visual: item.visual,
  pageNumber: pageNumber,
  semanticLabel: 'Ilustração: ${item.title}',
),
```

Keep messages, order, scroll, max width, persistence, Pular/Próximo/Voltar/Começar and motion branches unchanged.

- [ ] **Step 6: Verificar GREEN**

```powershell
dart format lib/features/onboarding test/features/onboarding
flutter test test/features/onboarding/presentation/onboarding_page_test.dart
```

Expected: all onboarding tests pass at requested sizes/scales.

---

### Task 6: Atualizar a documentação viva

**Files:**

- Modify: `README.md`
- Modify: `docs/backlog.md`
- Modify: `docs/requirements.md`
- Modify: `docs/decisions.md`
- Modify: `docs/architecture.md`
- Modify: `docs/testing-plan.md`
- Modify: `mobile/README.md`
- Conditional modify: `docs/scientific-evidence.md`

- [ ] **Step 1: Registrar requisitos e decisão**

Add to `docs/requirements.md`:

```markdown
- A navegação autenticada possui Início, Descartar, Histórico e Conta.
- Medicamentos permanece acessível pela Home e não possui aba inferior.
- O logout existe somente em Conta, que identifica a sessão como simulada.
- Histórico apresenta estado vazio e permanece sem persistência real.
- O bootstrap inicia em paralelo à animação e não adiciona espera artificial.
```

Add D023 to `docs/decisions.md` covering the four destinations, medication route, account-only logout, simulated-session wording, parallel bootstrap and absence of fabricated records/points.

- [ ] **Step 2: Atualizar arquitetura**

Use this opening flow in `docs/architecture.md`:

```text
Splash nativa estática
→ primeira renderização Flutter
  ├─ animação curta do símbolo
  └─ bootstrap em paralelo
       ├─ primeiro acesso → OnboardingPage
       ├─ sem sessão → LoginPage
       ├─ sessão simulada → ZeloShell
       └─ falha → erro recuperável
```

Document `Início | Descartar | Histórico | Conta`, medication route from Home and shared `MedicationStore`.

- [ ] **Step 3: Atualizar backlog e READMEs**

Record navigation, logout, empty/future states, parallel bootstrap and onboarding visual changes only after tests pass. Keep M2 `em andamento` and Android, Figma and legal copy unresolved. Describe the same state in both READMEs.

- [ ] **Step 4: Registrar testes realmente executados**

In `docs/testing-plan.md`, record exact commands, date, versions, final test total, Web build and failures observed. Do not retain 37 as the current total after adding tests. Modify `docs/scientific-evidence.md` only for genuinely observed technical evidence, never as usability or impact evidence.

- [ ] **Step 5: Auditar linguagem**

```powershell
rg -n "M2|concluí|Android|Figma|juríd|Histórico|EcoMed|37 testes" README.md docs mobile/README.md
```

Expected: no false completion claim for M2, Android, Figma, legal texts, history persistence or EcoMed.

---

### Task 7: Verificação final e entrega

**Files:**

- Verify all modified files
- Update actual results in `README.md`, `docs/backlog.md`, `docs/testing-plan.md`, `mobile/README.md`

- [ ] **Step 1: Executar os quatro comandos obrigatórios em `mobile/`**

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```

Expected: exit code 0 for all; exact test count captured; medication regression remains green.

- [ ] **Step 2: Inspecionar visualmente**

```powershell
flutter run -d chrome --web-port 7357
```

Inspect opening, three onboarding pages, four main areas, medication route, empty history and account at 390 × 844. Confirm no overflow, clipping, duplicate navigation or unreachable action. Stop the server after inspection.

- [ ] **Step 3: Auditar Android/JDK sem fabricar validação**

```powershell
flutter doctor -v
java -version
Get-Command adb,sdkmanager -ErrorAction SilentlyContinue
flutter devices
```

If Android SDK, JDK 17 and device/emulator exist, run `flutter build apk --debug` and `flutter run -d <android-device-id>`, then inspect native splash, white-frame absence, symbol crop and transition, including Android 12+ when available. Otherwise record the exact missing prerequisite and do not claim Android validation.

- [ ] **Step 4: Apply verification-before-completion**

Invoke `superpowers:verification-before-completion`, then run fresh:

```powershell
git diff --check
git status --short
git diff --stat
git diff -- README.md docs mobile/lib mobile/test mobile/README.md
```

Expected: only scoped implementation, tests and docs; no secrets, toolchain, builds or unrelated files.

- [ ] **Step 5: Entregar sem commit**

Report initial diagnosis, changes, modified files, commands, observed results, limitations and suggested semantic commits. Do not execute `git add`, `git commit`, `git push` or create a PR.
