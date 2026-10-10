import 'medication.dart';

/// Fonte dos medicamentos do usuário: memória na demonstração e API Zelo
/// quando o backend estiver configurado.
abstract interface class MedicationRepository {
  Future<List<Medication>> fetchAll();

  Future<Medication> create(MedicationDraft draft);

  Future<Medication> update(String id, MedicationDraft draft);

  Future<void> delete(String id);
}

/// Falha com mensagem segura para exibição, sem detalhes internos.
class MedicationRepositoryException implements Exception {
  const MedicationRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'MedicationRepositoryException: $message';
}
