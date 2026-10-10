import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/zelo_app.dart';
import 'package:zelo/features/authentication/data/simulated_authentication_service.dart';
import 'package:zelo/features/disposal_history/application/disposal_store.dart';
import 'package:zelo/features/disposal_history/data/disposal_repositories.dart';
import 'package:zelo/features/disposal_history/domain/disposal.dart';
import 'package:zelo/features/medications/application/medication_store.dart';

import '../../support/collection_points_fakes.dart';
import '../../support/in_memory_dependencies.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  testWidgets(
    'demonstração registra descarte dos vencidos e mostra histórico',
    (tester) async {
      final store = MedicationStore.seeded(clock: () => today);
      addTearDown(store.dispose);
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ZeloApp(
          showBrandIntro: false,
          medicationStore: store,
          onboardingPreferences: InMemoryOnboardingPreferences(completed: true),
          authenticationService: SimulatedAuthenticationService(
            sessionStore: InMemorySessionStore(active: true),
          ),
          locationProvider: FakeLocationProvider(),
          externalActions: FakeExternalActions(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum descarte registrado'), findsOneWidget);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('register-disposal-button')),
      );
      await tester.pumpAndSettle();

      // O vencido vem marcado; a pessoa informa o local livremente.
      expect(find.text('Registrar 1 item'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('disposal-place-field')),
        'Farmácia do bairro',
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('confirm-disposal-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Celebração: dados do próprio registro, sem estimativas inventadas.
      expect(find.text('Mandou bem!'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Descarte registrado. 1 medicamento, 1 unidade.'),
        findsOneWidget,
      );
      final next = find.byKey(const ValueKey('celebration-history-button'));
      await tester.ensureVisible(next);
      await tester.pump();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Mandou bem!'), findsNothing);

      expect(find.text('Farmácia do bairro'), findsOneWidget);
      expect(find.text('Soro fisiológico'), findsOneWidget);
      expect(store.totalCount, 2);
      expect(store.findById('med-3'), isNull);
    },
  );

  test('repositório em memória recusa itens inexistentes', () async {
    final store = MedicationStore.seeded(clock: () => today);
    addTearDown(store.dispose);
    final repository = InMemoryDisposalRepository(
      medications: store.repository,
    );
    final disposals = DisposalStore(repository: repository);
    addTearDown(disposals.dispose);

    await expectLater(
      disposals.register(
        DisposalRequest(
          medicationIds: const ['inexistente'],
          disposedOn: today,
        ),
      ),
      throwsA(isA<DisposalRepositoryException>()),
    );
    await disposals.load();
    expect(disposals.records, isEmpty);
  });
}
