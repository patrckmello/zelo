import '../../../core/network/zelo_api_client.dart';
import '../domain/collection_point.dart';

/// Pontos de coleta pela API Zelo, que protege a chave EcoMed (D003).
class ApiCollectionPointsRepository implements CollectionPointsRepository {
  ApiCollectionPointsRepository(this.client);

  final ZeloApiClient client;

  @override
  Future<NearbyCollectionPoints> findNearby(
    GeoPosition position, {
    int radiusMeters = 5000,
  }) async {
    try {
      final json = await client.send(
        'GET',
        '/v1/collection-points/nearby',
        query: {
          'latitude': '${position.latitude}',
          'longitude': '${position.longitude}',
          'radius_m': '$radiusMeters',
        },
      ) as Map<String, dynamic>;
      return NearbyCollectionPoints(
        points: [
          for (final item in json['points'] as List<dynamic>)
            _pointFromJson(item as Map<String, dynamic>),
        ],
        attribution: json['attribution'] as String,
        radiusMeters: json['radius_m'] as int,
      );
    } on ApiException catch (error) {
      throw CollectionPointsException(_failureOf(error), error.message);
    }
  }

  static CollectionPointsFailure _failureOf(ApiException error) {
    if (error.isNetwork) {
      return CollectionPointsFailure.network;
    }
    return switch (error.code) {
      'collection_points_not_configured' =>
        CollectionPointsFailure.notConfigured,
      'collection_points_rate_limited' => CollectionPointsFailure.rateLimited,
      'not_authenticated' => CollectionPointsFailure.unauthorized,
      _ => CollectionPointsFailure.unavailable,
    };
  }

  static CollectionPoint _pointFromJson(Map<String, dynamic> json) =>
      CollectionPoint(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phone: json['phone'] as String?,
        residueTypes: [
          for (final type in json['residue_types'] as List<dynamic>? ?? [])
            type as String,
        ],
        distanceMeters: json['distance_m'] as int?,
        origin: json['origin'] == 'logmed'
            ? CollectionPointOrigin.logmed
            : CollectionPointOrigin.other,
      );
}
