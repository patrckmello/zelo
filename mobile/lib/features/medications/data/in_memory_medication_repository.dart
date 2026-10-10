import '../domain/medication.dart';
import '../domain/medication_repository.dart';

/// Repositório em memória usado na demonstração sem backend e nos testes.
/// Os dados são reiniciados quando o aplicativo é encerrado.
class InMemoryMedicationRepository implements MedicationRepository {
  InMemoryMedicationRepository({
    Iterable<Medication> medications = const [],
    this._failNextFetch,
  }) : _medications = List.of(medications),
       _nextId = medications.length + 1;

  /// Dados fictícios de demonstração, um em cada situação de validade.
  factory InMemoryMedicationRepository.seeded({required DateTime today}) {
    final reference = dateOnly(today);
    return InMemoryMedicationRepository(
      medications: [
        Medication(
          id: 'med-1',
          name: 'Dipirona',
          expirationDate: reference.add(const Duration(days: 90)),
          quantity: 8,
          notes: 'Comprimidos guardados no armário da cozinha.',
        ),
        Medication(
          id: 'med-2',
          name: 'Loratadina',
          expirationDate: reference.add(const Duration(days: 12)),
          quantity: 6,
        ),
        Medication(
          id: 'med-3',
          name: 'Soro fisiológico',
          expirationDate: reference.subtract(const Duration(days: 5)),
          quantity: 1,
          notes: 'Separado para descarte responsável.',
        ),
      ],
    );
  }

  static const notFoundMessage = 'Medicamento não encontrado.';

  final List<Medication> _medications;
  String? _failNextFetch;
  int _nextId;

  @override
  Future<List<Medication>> fetchAll() async {
    final failure = _failNextFetch;
    if (failure != null) {
      _failNextFetch = null;
      throw MedicationRepositoryException(failure);
    }
    return List.unmodifiable(_medications);
  }

  @override
  Future<Medication> create(MedicationDraft draft) async {
    final medication = Medication(
      id: _newId(),
      name: draft.name,
      expirationDate: draft.expirationDate,
      quantity: draft.quantity,
      notes: draft.notes,
    );
    _medications.add(medication);
    return medication;
  }

  @override
  Future<Medication> update(String id, MedicationDraft draft) async {
    final index = _medications.indexWhere((medication) => medication.id == id);
    if (index == -1) {
      throw const MedicationRepositoryException(notFoundMessage);
    }
    final updated = _medications[index].copyWith(
      name: draft.name,
      expirationDate: draft.expirationDate,
      quantity: draft.quantity,
      notes: draft.notes,
    );
    _medications[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _medications.removeWhere((medication) => medication.id == id);
  }

  String _newId() {
    while (_medications.any((medication) => medication.id == 'med-$_nextId')) {
      _nextId++;
    }
    return 'med-${_nextId++}';
  }
}
