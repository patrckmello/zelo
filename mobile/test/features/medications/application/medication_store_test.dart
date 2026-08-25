import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/features/medications/application/medication_store.dart';
import 'package:zelo/features/medications/domain/medication.dart';

void main() {
  final referenceDate = DateTime(2026, 8, 24);

  test('seed produz um medicamento em cada situação de validade', () {
    final store = MedicationStore.seeded(clock: () => referenceDate);
    addTearDown(store.dispose);

    expect(store.totalCount, 3);
    expect(store.countByStatus(MedicationStatus.valid), 1);
    expect(store.countByStatus(MedicationStatus.expiringSoon), 1);
    expect(store.countByStatus(MedicationStatus.expired), 1);
  });

  test('adiciona, atualiza e remove medicamento em memória', () {
    final store = MedicationStore(clock: () => referenceDate);
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);

    final medication = store.add(
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

    store.update(
      medication.id,
      MedicationDraft(
        name: 'Paracetamol infantil',
        expirationDate: DateTime(2027, 2, 15),
        quantity: 4,
      ),
    );

    expect(store.findById(medication.id)?.name, 'Paracetamol infantil');
    expect(store.findById(medication.id)?.quantity, 4);

    store.remove(medication.id);

    expect(store.medications, isEmpty);
    expect(notifications, 3);
  });

  test('limpa erro simulado ao tentar novamente', () {
    final store = MedicationStore(
      clock: () => referenceDate,
      initialError: 'Falha simulada',
    );
    addTearDown(store.dispose);

    expect(store.errorMessage, isNotNull);

    store.retry();

    expect(store.errorMessage, isNull);
  });
}
