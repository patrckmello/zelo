import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/features/medications/domain/medication.dart';

void main() {
  group('Medication.statusAt', () {
    final referenceDate = DateTime(2026, 8, 24, 18, 30);

    Medication medicationExpiringOn(DateTime expirationDate) => Medication(
      id: 'med-test',
      name: 'Medicamento de teste',
      expirationDate: expirationDate,
      quantity: 1,
    );

    test('classifica data anterior como vencido', () {
      final medication = medicationExpiringOn(DateTime(2026, 8, 23, 23, 59));

      expect(medication.statusAt(referenceDate), MedicationStatus.expired);
    });

    test('considera o medicamento válido durante o dia da validade', () {
      final medication = medicationExpiringOn(DateTime(2026, 8, 24));

      expect(medication.statusAt(referenceDate), MedicationStatus.expiringSoon);
    });

    test('inclui exatamente 30 dias na janela de proximidade', () {
      final medication = medicationExpiringOn(DateTime(2026, 9, 23));

      expect(medication.statusAt(referenceDate), MedicationStatus.expiringSoon);
    });

    test('classifica acima de 30 dias como válido', () {
      final medication = medicationExpiringOn(DateTime(2026, 9, 24));

      expect(medication.statusAt(referenceDate), MedicationStatus.valid);
    });

    test('aceita uma janela configurável', () {
      final medication = medicationExpiringOn(DateTime(2026, 8, 31));

      expect(
        medication.statusAt(referenceDate, warningDays: 5),
        MedicationStatus.valid,
      );
    });
  });
}
