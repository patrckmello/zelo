import 'dart:async';

import 'package:zelo/core/platform/external_actions.dart';
import 'package:zelo/features/collection_points/domain/collection_point.dart';
import 'package:zelo/features/collection_points/domain/location.dart';

/// Atribuição usada nos testes, igual à exigida pela documentação do projeto.
const testAttribution =
    'Dados: EcoMed — fontes CNES/DATASUS (Ministério da Saúde) e '
    'LogMed/Sindusfarma.';

/// Pontos fictícios. O primeiro reproduz o exemplo publicado na documentação
/// pública da API EcoMed; nenhum representa um local real.
const fixturePoints = <CollectionPoint>[
  CollectionPoint(
    id: 'logmed-001234',
    name: 'Farmácia Exemplo - Centro',
    address: 'Rua das Flores, 100',
    city: 'São Paulo',
    state: 'SP',
    latitude: -23.5489,
    longitude: -46.6388,
    phone: '(11) 3333-4444',
    residueTypes: ['medicamento'],
    distanceMeters: 412,
    origin: CollectionPointOrigin.logmed,
  ),
  CollectionPoint(
    id: 'logmed-009876',
    name: 'Farmácia Exemplo - Bairro',
    address: 'Avenida Exemplo, 2000',
    city: 'São Paulo',
    state: 'SP',
    latitude: -23.5521,
    longitude: -46.6301,
    residueTypes: ['medicamento', 'seringa'],
    distanceMeters: 1840,
    origin: CollectionPointOrigin.logmed,
  ),
  CollectionPoint(
    id: 'exemplo-ubs-1',
    name: 'Unidade de Saúde Exemplo',
    address: 'Rua Fictícia, 45',
    city: 'São Paulo',
    state: 'SP',
    latitude: -23.5602,
    longitude: -46.6455,
    phone: '(11) 3000-0000',
    residueTypes: ['medicamento'],
    distanceMeters: 3100,
    origin: CollectionPointOrigin.other,
  ),
];

class FakeCollectionPointsRepository implements CollectionPointsRepository {
  FakeCollectionPointsRepository({
    this.points = fixturePoints,
    this.failure,
    this.completer,
  });

  final List<CollectionPoint> points;
  CollectionPointsException? failure;
  Completer<NearbyCollectionPoints>? completer;
  final requests = <GeoPosition>[];

  @override
  Future<NearbyCollectionPoints> findNearby(
    GeoPosition position, {
    int radiusMeters = 5000,
  }) {
    requests.add(position);
    final pending = completer;
    if (pending != null) {
      return pending.future;
    }
    final error = failure;
    if (error != null) {
      failure = null;
      return Future.error(error);
    }
    return Future.value(
      NearbyCollectionPoints(
        points: points,
        attribution: testAttribution,
        radiusMeters: radiusMeters,
      ),
    );
  }
}

class FakeLocationProvider implements LocationProvider {
  FakeLocationProvider({
    this.position = const GeoPosition(-30.0346123, -51.2177456),
    this.failure,
  });

  final GeoPosition position;
  LocationException? failure;
  int requests = 0;

  @override
  Future<GeoPosition> currentPosition() async {
    requests++;
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
    return position;
  }
}

class FakeExternalActions implements ExternalActions {
  final openedMaps = <String>[];
  final dialed = <String>[];
  bool result = true;

  @override
  Future<bool> dial(String phone) async {
    dialed.add(phone);
    return result;
  }

  @override
  Future<bool> openInMaps({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    openedMaps.add(label);
    return result;
  }
}

/// Localização que nunca responde, como um computador sem Wi-Fi nem GPS.
class HangingLocationProvider implements LocationProvider {
  int requests = 0;

  @override
  Future<GeoPosition> currentPosition() {
    requests++;
    return Completer<GeoPosition>().future;
  }
}
