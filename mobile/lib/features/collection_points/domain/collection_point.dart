/// Coordenada geográfica em graus decimais.
class GeoPosition {
  const GeoPosition(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Arredonda para três casas (~110 m), minimizando a localização enviada.
  GeoPosition rounded() => GeoPosition(
    double.parse(latitude.toStringAsFixed(3)),
    double.parse(longitude.toStringAsFixed(3)),
  );
}

/// Origem declarada do ponto. Apenas IDs `logmed-*` são farmácias do
/// programa LogMed; os demais podem incluir unidades públicas (CNES/DATASUS)
/// que nem sempre recebem medicamentos trazidos pela população.
enum CollectionPointOrigin { logmed, other }

class CollectionPoint {
  const CollectionPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.origin,
    this.phone,
    this.residueTypes = const [],
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final CollectionPointOrigin origin;
  final String? phone;
  final List<String> residueTypes;
  final int? distanceMeters;

  bool get requiresConfirmation => origin != CollectionPointOrigin.logmed;

  String get locality =>
      [city, state].where((part) => part.isNotEmpty).join(' – ');
}

class NearbyCollectionPoints {
  const NearbyCollectionPoints({
    required this.points,
    required this.attribution,
    required this.radiusMeters,
  });

  final List<CollectionPoint> points;
  final String attribution;
  final int radiusMeters;

  List<CollectionPoint> get pharmacies => points
      .where((point) => point.origin == CollectionPointOrigin.logmed)
      .toList(growable: false);

  List<CollectionPoint> get others => points
      .where((point) => point.origin != CollectionPointOrigin.logmed)
      .toList(growable: false);
}

/// Consulta de pontos sempre feita pela API Zelo, nunca direto na EcoMed.
abstract interface class CollectionPointsRepository {
  Future<NearbyCollectionPoints> findNearby(
    GeoPosition position, {
    int radiusMeters,
  });
}

enum CollectionPointsFailure {
  notConfigured,
  unavailable,
  rateLimited,
  network,
  unauthorized,
}

class CollectionPointsException implements Exception {
  const CollectionPointsException(this.failure, this.message);

  final CollectionPointsFailure failure;
  final String message;

  @override
  String toString() => 'CollectionPointsException(${failure.name}): $message';
}
