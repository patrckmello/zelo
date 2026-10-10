import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/features/medications/application/medication_store.dart';
import 'package:zelo/features/medications/data/in_memory_medication_repository.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/medications/domain/medication_repository.dart';

void main() {
  final referenceDate = DateTime(2026, 8, 24);

  test('seed produz um medicamento em cada situação de validade', () async {
    final store = MedicationStore.seeded(clock: () => referenceDate);
    addTearDown(store.dispose);

    expect(store.status, MedicationLoadStatus.idle);
    await store.load();

    expect(store.status, MedicationLoadStatus.ready);
    expect(store.totalCount, 3);
    expect(store.countByStatus(MedicationStatus.valid), 1);
    expect(store.countByStatus(MedicationStatus.expiringSoon), 1);
    expect(store.countByStatus(MedicationStatus.expired), 1);
    expect(store.needingAttention.map((medication) => medication.name), [
      'Soro fisiológico',
      'Loratadina',
    ]);
  });

  test('adiciona, atualiza e remove medicamento normalizando dados', () async {
    final store = MedicationStore(clock: () => referenceDate);
    addTearDown(store.dispose);
    await store.load();
    var notifications = 0;
    store.addListener(() => notifications++);

    final medication = await store.add(
      MedicationDraft(
        name: '  Paracetamol  ',
        expirationDate: DateTime(2027, 1, 10, 22),
        quantity: 10,
        notes: '  Armário principal  ',
      ),
    );

    expect(medication.name, 'Paracetamol');
    expect(medication.expirationDate, DateTime(2027, 1, 10));
    expect(medication.notes, 'Armário principal');

    await store.update(
      medication.id,
      MedicationDraft(
        name: 'Paracetamol infantil',
        expirationDate: DateTime(2027, 2, 15),
        quantity: 4,
      ),
    );

    expect(store.findById(medication.id)?.name, 'Paracetamol infantil');
    expect(store.findById(medication.id)?.quantity, 4);

    await store.remove(medication.id);

    expect(store.medications, isEmpty);
    expect(notifications, 3);
  });

  test('falha de carga é segura e nova tentativa recupera', () async {
    final store = MedicationStore(
      clock: () => referenceDate,
      initialError: 'Falha simulada',
    );
    addTearDown(store.dispose);

    await store.load();
    expect(store.status, MedicationLoadStatus.failure);
    expect(store.errorMessage, 'Falha simulada');

    await store.retry();
    expect(store.status, MedicationLoadStatus.ready);
    expect(store.errorMessage, isNull);
  });

  test('erro inesperado vira mensagem genérica sem detalhes', () async {
    final store = MedicationStore(repository: _ThrowingRepository());
    addTearDown(store.dispose);

    await store.load();
    expect(store.errorMessage, MedicationStore.loadErrorMessage);

    await expectLater(
      store.add(
        MedicationDraft(
          name: 'Dipirona',
          expirationDate: referenceDate,
          quantity: 1,
        ),
      ),
      throwsA(
        isA<MedicationRepositoryException>().having(
          (error) => error.message,
          'message',
          MedicationStore.saveErrorMessage,
        ),
      ),
    );
  });

  test('compartilha a carga em andamento', () async {
    final repository = _DeferredRepository();
    final store = MedicationStore(repository: repository);
    addTearDown(store.dispose);

    final first = store.load();
    final second = store.load();
    expect(identical(first, second), isTrue);
    expect(repository.fetchCount, 1);

    repository.complete(const []);
    await first;
    expect(store.status, MedicationLoadStatus.ready);
  });

  test('clear descarta a carga pendente e os dados locais', () async {
    final repository = _DeferredRepository();
    final store = MedicationStore(repository: repository);
    addTearDown(store.dispose);

    final load = store.load();
    store.clear();
    repository.complete([
      Medication(
        id: 'med-1',
        name: 'Dipirona',
        expirationDate: referenceDate,
        quantity: 1,
      ),
    ]);
    await load;

    expect(store.status, MedicationLoadStatus.idle);
    expect(store.medications, isEmpty);
  });

  test('refresh mantém os dados atuais quando falha', () async {
    final repository = _FlakyRepository();
    final store = MedicationStore(repository: repository);
    addTearDown(store.dispose);
    await store.load();
    expect(store.totalCount, 1);

    repository.failNext = true;
    await expectLater(
      store.refresh(),
      throwsA(isA<MedicationRepositoryException>()),
    );
    expect(store.status, MedicationLoadStatus.ready);
    expect(store.totalCount, 1);
  });

  test('repositório em memória recusa atualizar item inexistente', () async {
    final repository = InMemoryMedicationRepository();
    await expectLater(
      repository.update(
        'inexistente',
        MedicationDraft(name: 'X', expirationDate: referenceDate, quantity: 1),
      ),
      throwsA(isA<MedicationRepositoryException>()),
    );
  });
}

class _ThrowingRepository implements MedicationRepository {
  @override
  Future<Medication> create(MedicationDraft draft) =>
      Future.error(StateError('detalhe interno'));

  @override
  Future<void> delete(String id) => Future.error(StateError('detalhe interno'));

  @override
  Future<List<Medication>> fetchAll() =>
      Future.error(StateError('detalhe interno'));

  @override
  Future<Medication> update(String id, MedicationDraft draft) =>
      Future.error(StateError('detalhe interno'));
}

class _DeferredRepository extends InMemoryMedicationRepository {
  final _completer = Completer<List<Medication>>();
  int fetchCount = 0;

  void complete(List<Medication> medications) =>
      _completer.complete(medications);

  @override
  Future<List<Medication>> fetchAll() {
    fetchCount++;
    return _completer.future;
  }
}

class _FlakyRepository extends InMemoryMedicationRepository {
  _FlakyRepository()
    : super(
        medications: [
          Medication(
            id: 'med-1',
            name: 'Dipirona',
            expirationDate: DateTime(2027),
            quantity: 1,
          ),
        ],
      );

  bool failNext = false;

  @override
  Future<List<Medication>> fetchAll() {
    if (failNext) {
      failNext = false;
      return Future.error(StateError('rede indisponível'));
    }
    return super.fetchAll();
  }
}
