const defaultExpirationWarningDays = 30;

enum MedicationStatus { valid, expiringSoon, expired }

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.expirationDate,
    required this.quantity,
    this.notes = '',
  });

  final String id;
  final String name;
  final DateTime expirationDate;
  final int quantity;
  final String notes;

  MedicationStatus statusAt(
    DateTime referenceDate, {
    int warningDays = defaultExpirationWarningDays,
  }) {
    assert(warningDays >= 0, 'warningDays não pode ser negativo.');

    final expiration = _dateOnlyUtc(expirationDate);
    final reference = _dateOnlyUtc(referenceDate);

    if (expiration.isBefore(reference)) {
      return MedicationStatus.expired;
    }

    final daysUntilExpiration = expiration.difference(reference).inDays;
    if (daysUntilExpiration <= warningDays) {
      return MedicationStatus.expiringSoon;
    }

    return MedicationStatus.valid;
  }

  Medication copyWith({
    String? name,
    DateTime? expirationDate,
    int? quantity,
    String? notes,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      expirationDate: expirationDate ?? this.expirationDate,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

class MedicationDraft {
  const MedicationDraft({
    required this.name,
    required this.expirationDate,
    required this.quantity,
    this.notes = '',
  });

  final String name;
  final DateTime expirationDate;
  final int quantity;
  final String notes;
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _dateOnlyUtc(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
