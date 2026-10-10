import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/theme/zelo_theme.dart';
import 'package:zelo/features/collection_points/application/collection_points_controller.dart';
import 'package:zelo/features/collection_points/domain/collection_point.dart';
import 'package:zelo/features/collection_points/domain/location.dart';
import 'package:zelo/features/collection_points/presentation/collection_points_page.dart';
import 'package:zelo/features/medications/application/medication_store.dart';

import '../../support/collection_points_fakes.dart';
import '../../support/in_memory_dependencies.dart';

void main() {
  group('CollectionPointsController', () {
    test('arredonda a localização antes de consultar a API Zelo', () async {
      final repository = FakeCollectionPointsRepository();
      final controller = CollectionPointsController(
        repository: repository,
        locationProvider: FakeLocationProvider(
          position: const GeoPosition(-30.0346123, -51.2177456),
        ),
      );
      addTearDown(controller.dispose);

      await controller.searchNearMe();

      expect(controller.phase, CollectionPointsPhase.loaded);
      expect(repository.requests.single.latitude, -30.035);
      expect(repository.requests.single.longitude, -51.218);
      expect(controller.queryLabel, 'Perto de você');
    });

    test('região de referência dispensa a localização do aparelho', () async {
      final location = FakeLocationProvider();
      final repository = FakeCollectionPointsRepository();
      final controller = CollectionPointsController(
        repository: repository,
        locationProvider: location,
      );
      addTearDown(controller.dispose);

      await controller.searchRegion(referenceRegions.first);

      expect(location.requests, 0);
      expect(controller.queryLabel, 'Porto Alegre');
      expect(controller.result!.points, hasLength(3));
    });

    test('permissão negada mostra mensagem e permite tentar de novo', () async {
      final location = FakeLocationProvider(
        failure: const LocationException(
          LocationFailure.permissionDenied,
          'Sem permissão de localização.',
        ),
      );
      final controller = CollectionPointsController(
        repository: FakeCollectionPointsRepository(),
        locationProvider: location,
      );
      addTearDown(controller.dispose);

      await controller.searchNearMe();
      expect(controller.phase, CollectionPointsPhase.failure);
      expect(controller.failureMessage, 'Sem permissão de localização.');

      await controller.retry();
      expect(controller.phase, CollectionPointsPhase.loaded);
      expect(location.requests, 2);
    });

    test('falha da API exibe a mensagem segura recebida', () async {
      final controller = CollectionPointsController(
        repository: FakeCollectionPointsRepository(
          failure: const CollectionPointsException(
            CollectionPointsFailure.rateLimited,
            'Muitas consultas agora. Tente em instantes.',
          ),
        ),
        locationProvider: FakeLocationProvider(),
      );
      addTearDown(controller.dispose);

      await controller.searchRegion(referenceRegions.first);
      expect(
        controller.failureMessage,
        'Muitas consultas agora. Tente em instantes.',
      );

      await controller.retry();
      expect(controller.phase, CollectionPointsPhase.loaded);
    });

    test('localização sem resposta vira falha com saída, sem travar', () async {
      final location = HangingLocationProvider();
      final repository = FakeCollectionPointsRepository();
      final controller = CollectionPointsController(
        repository: repository,
        locationProvider: location,
        locationTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(controller.dispose);

      await controller.searchNearMe();

      expect(controller.phase, CollectionPointsPhase.failure);
      expect(
        controller.failureMessage,
        CollectionPointsController.locationTimeoutMessage,
      );
      expect(repository.requests, isEmpty);

      await controller.searchRegion(referenceRegions.first);
      expect(controller.phase, CollectionPointsPhase.loaded);
    });

    test('ignora resposta que chega depois de uma nova busca', () async {
      final pending = Completer<NearbyCollectionPoints>();
      final repository = FakeCollectionPointsRepository(completer: pending);
      final controller = CollectionPointsController(
        repository: repository,
        locationProvider: FakeLocationProvider(),
      );
      addTearDown(controller.dispose);

      final search = controller.searchRegion(referenceRegions.first);
      controller.reset();
      pending.complete(
        const NearbyCollectionPoints(
          points: fixturePoints,
          attribution: testAttribution,
          radiusMeters: 5000,
        ),
      );
      await search;

      expect(controller.phase, CollectionPointsPhase.idle);
      expect(controller.result, isNull);
    });
  });

  group('CollectionPointsPage', () {
    final today = DateTime(2026, 10, 2);

    Future<FakeExternalActions> pumpPage(
      WidgetTester tester, {
      CollectionPointsController? controller,
    }) async {
      final store = MedicationStore.seeded(clock: () => today);
      addTearDown(store.dispose);
      await store.load();
      final actions = FakeExternalActions();
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ZeloTheme.light,
          home: Scaffold(
            body: CollectionPointsPage(
              medicationStore: store,
              controller: controller,
              externalActions: actions,
              onOpenMedication: (_) {},
              onOpenExpired: () {},
              onRegisterDisposal: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return actions;
    }

    testWidgets('sem servidor, informa a dependência sem fabricar pontos', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Soro fisiológico'), findsOneWidget);
      expect(find.text('Pontos de descarte'), findsOneWidget);
      expect(find.textContaining('EcoMed'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('points-use-location-button')),
        findsNothing,
      );
    });

    testWidgets('agrupa farmácias LogMed, alerta outros pontos e atribui', (
      tester,
    ) async {
      final controller = CollectionPointsController(
        repository: FakeCollectionPointsRepository(),
        locationProvider: FakeLocationProvider(),
      );
      addTearDown(controller.dispose);
      final actions = await pumpPage(tester, controller: controller);

      expect(find.text('Encontre onde descartar'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('points-use-location-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farmácias do programa LogMed · 2'), findsOneWidget);
      expect(find.text('Outros pontos · 1'), findsOneWidget);
      expect(find.textContaining('Confirme por telefone'), findsOneWidget);
      expect(find.byKey(const ValueKey('points-attribution')), findsOneWidget);

      await tapVisible(tester, find.text('Unidade de Saúde Exemplo'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('não pertence ao programa LogMed'),
        findsOneWidget,
      );
      expect(find.text(testAttribution), findsOneWidget);

      await tapVisible(tester, find.byKey(const ValueKey('open-map-button')));
      await tester.pumpAndSettle();
      expect(actions.openedMaps, ['Unidade de Saúde Exemplo']);

      await tapVisible(tester, find.byKey(const ValueKey('call-point-button')));
      await tester.pumpAndSettle();
      expect(actions.dialed, ['(11) 3000-0000']);
    });

    testWidgets('enquanto localiza, oferece escolher uma região', (
      tester,
    ) async {
      final repository = FakeCollectionPointsRepository();
      final controller = CollectionPointsController(
        repository: repository,
        locationProvider: HangingLocationProvider(),
      );
      addTearDown(controller.dispose);
      await pumpPage(tester, controller: controller);

      await tapVisible(
        tester,
        find.byKey(const ValueKey('points-use-location-button')),
      );
      await tester.pump();
      expect(find.text('Obtendo sua localização…'), findsOneWidget);

      // Sem pumpAndSettle: o indicador gira enquanto a localização não chega.
      final regionButton = find.byKey(
        const ValueKey('points-locating-region-button'),
      );
      await tester.ensureVisible(regionButton);
      await tester.pump();
      await tester.tap(regionButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('region-Esteio')));
      await tester.pumpAndSettle();

      expect(controller.phase, CollectionPointsPhase.loaded);
      expect(repository.requests.single.latitude, -29.861);
      expect(find.textContaining('Esteio · raio de'), findsOneWidget);

      // O limite da localização abandonada expira depois e é ignorado.
      await tester.pump(const Duration(seconds: 31));
      expect(controller.phase, CollectionPointsPhase.loaded);
    });

    testWidgets('busca por região a partir da lista de municípios', (
      tester,
    ) async {
      final repository = FakeCollectionPointsRepository();
      final controller = CollectionPointsController(
        repository: repository,
        locationProvider: FakeLocationProvider(),
      );
      addTearDown(controller.dispose);
      await pumpPage(tester, controller: controller);

      await tapVisible(
        tester,
        find.byKey(const ValueKey('points-choose-region-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('region-Canoas')));
      await tester.pumpAndSettle();

      expect(repository.requests.single.latitude, -29.92);
      expect(find.textContaining('Canoas · raio de'), findsOneWidget);
    });
  });
}
