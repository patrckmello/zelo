import 'collection_point.dart';

/// Localização do aparelho, pedida somente quando a pessoa inicia a busca.
abstract interface class LocationProvider {
  Future<GeoPosition> currentPosition();
}

enum LocationFailure { serviceDisabled, permissionDenied, unavailable }

class LocationException implements Exception {
  const LocationException(this.failure, this.message);

  final LocationFailure failure;
  final String message;

  @override
  String toString() => 'LocationException(${failure.name}): $message';
}

/// Região de referência para buscar sem compartilhar a localização.
class ReferenceRegion {
  const ReferenceRegion(this.name, this.position);

  final String name;
  final GeoPosition position;
}

/// Sedes dos municípios da Região Metropolitana de Porto Alegre, recorte
/// inicial do projeto. Coordenadas do Wikidata/Wikipédia (consulta em
/// 02/10/2026), arredondadas a três casas.
const referenceRegions = <ReferenceRegion>[
  ReferenceRegion('Porto Alegre', GeoPosition(-30.033, -51.230)),
  ReferenceRegion('Alvorada', GeoPosition(-29.990, -51.084)),
  ReferenceRegion('Cachoeirinha', GeoPosition(-29.951, -51.094)),
  ReferenceRegion('Canoas', GeoPosition(-29.920, -51.180)),
  ReferenceRegion('Eldorado do Sul', GeoPosition(-29.997, -51.308)),
  ReferenceRegion('Esteio', GeoPosition(-29.861, -51.179)),
  ReferenceRegion('Gravataí', GeoPosition(-29.943, -50.994)),
  ReferenceRegion('Guaíba', GeoPosition(-30.114, -51.325)),
  ReferenceRegion('Novo Hamburgo', GeoPosition(-29.678, -51.131)),
  ReferenceRegion('São Leopoldo', GeoPosition(-29.760, -51.147)),
  ReferenceRegion('Sapucaia do Sul', GeoPosition(-29.839, -51.144)),
  ReferenceRegion('Viamão', GeoPosition(-30.081, -51.023)),
];
