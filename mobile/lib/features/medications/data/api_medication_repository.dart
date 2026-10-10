import '../../../core/network/zelo_api_client.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';

/// Medicamentos persistidos na API Zelo e isolados por conta.
class ApiMedicationRepository implements MedicationRepository {
  ApiMedicationRepository(this.client);

  final ZeloApiClient client;

  @override
  Future<List<Medication>> fetchAll() => _guard(() async {
    final json = await client.send('GET', '/v1/medications') as List<dynamic>;
    return [for (final item in json) _fromJson(item as Map<String, dynamic>)];
  });

  @override
  Future<Medication> create(MedicationDraft draft) => _guard(
    () async => _fromJson(
      await client.send('POST', '/v1/medications', body: _toJson(draft))
          as Map<String, dynamic>,
    ),
  );

  @override
  Future<Medication> update(String id, MedicationDraft draft) => _guard(
    () async => _fromJson(
      await client.send('PUT', '/v1/medications/$id', body: _toJson(draft))
          as Map<String, dynamic>,
    ),
  );

  @override
  Future<void> delete(String id) =>
      _guard(() => client.send('DELETE', '/v1/medications/$id'));

  static Map<String, dynamic> _toJson(MedicationDraft draft) => {
    'name': draft.name,
    'expiration_date': formatIsoDate(draft.expirationDate),
    'quantity': draft.quantity,
    'notes': draft.notes,
  };

  static Medication _fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] as String,
    name: json['name'] as String,
    expirationDate: parseIsoDate(json['expiration_date'] as String),
    quantity: json['quantity'] as int,
    notes: json['notes'] as String? ?? '',
  );

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      throw MedicationRepositoryException(error.message);
    }
  }
}

/// "2026-10-02" a partir de uma data civil local.
String formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Data civil local a partir de "AAAA-MM-DD", sem conversão de fuso.
DateTime parseIsoDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}
