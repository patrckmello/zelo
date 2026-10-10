import '../../../core/network/zelo_api_client.dart';
import '../../medications/data/api_medication_repository.dart';
import '../../medications/domain/medication.dart';
import '../../medications/domain/medication_repository.dart';
import '../domain/disposal.dart';

/// Descartes em memória para a demonstração sem servidor. Os itens saem do
/// mesmo repositório de medicamentos usado pela farmácia.
class InMemoryDisposalRepository implements DisposalRepository {
  InMemoryDisposalRepository({required this.medications});

  final MedicationRepository medications;
  final _records = <DisposalRecord>[];
  var _nextId = 1;

  @override
  Future<List<DisposalRecord>> fetchAll() async => List.unmodifiable(
    List.of(_records)..sort((a, b) => b.disposedOn.compareTo(a.disposedOn)),
  );

  @override
  Future<DisposalRecord> register(DisposalRequest request) async {
    final available = {
      for (final medication in await medications.fetchAll())
        medication.id: medication,
    };
    final ids = request.medicationIds.toSet().toList();
    if (ids.isEmpty || ids.any((id) => !available.containsKey(id))) {
      throw const DisposalRepositoryException(
        'Um ou mais medicamentos não foram encontrados.',
      );
    }
    for (final id in ids) {
      await medications.delete(id);
    }
    final record = DisposalRecord(
      id: 'descarte-${_nextId++}',
      disposedOn: dateOnly(request.disposedOn),
      pointName: request.point?.name,
      pointAddress: request.point?.address,
      notes: request.notes,
      items: [
        for (final id in ids)
          DisposalItem(
            name: available[id]!.name,
            quantity: available[id]!.quantity,
            expirationDate: available[id]!.expirationDate,
          ),
      ],
    );
    _records.add(record);
    return record;
  }
}

/// Descartes persistidos na API Zelo.
class ApiDisposalRepository implements DisposalRepository {
  ApiDisposalRepository(this.client);

  final ZeloApiClient client;

  @override
  Future<List<DisposalRecord>> fetchAll() => _guard(() async {
    final json = await client.send('GET', '/v1/disposals') as List<dynamic>;
    return [for (final item in json) _fromJson(item as Map<String, dynamic>)];
  });

  @override
  Future<DisposalRecord> register(DisposalRequest request) => _guard(() async {
    final point = request.point;
    final json = await client.send(
      'POST',
      '/v1/disposals',
      body: {
        'medication_ids': request.medicationIds,
        'disposed_on': formatIsoDate(request.disposedOn),
        'notes': request.notes,
        if (point != null)
          'point': {
            'name': point.name,
            'external_id': point.externalId,
            'address': point.address,
          },
      },
    ) as Map<String, dynamic>;
    return _fromJson(json);
  });

  static DisposalRecord _fromJson(Map<String, dynamic> json) => DisposalRecord(
    id: json['id'] as String,
    disposedOn: parseIsoDate(json['disposed_on'] as String),
    pointName: json['point_name'] as String?,
    pointAddress: json['point_address'] as String?,
    notes: json['notes'] as String? ?? '',
    items: [
      for (final item in json['items'] as List<dynamic>)
        DisposalItem(
          name: (item as Map<String, dynamic>)['medication_name'] as String,
          quantity: item['quantity'] as int,
          expirationDate: parseIsoDate(item['expiration_date'] as String),
        ),
    ],
  );

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      throw DisposalRepositoryException(error.message);
    }
  }
}
