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
  }) => statusForDaysUntilExpiration(
    daysUntilExpirationAt(referenceDate),
    warningDays: warningDays,
  );

  /// Dias civis entre [referenceDate] e a validade; negativo após o
  /// vencimento. Horários são ignorados.
  int daysUntilExpirationAt(DateTime referenceDate) =>
      civilDaysBetween(referenceDate, expirationDate);

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

  /// Remove espaços nas bordas e descarta o horário da validade.
  MedicationDraft normalized() => MedicationDraft(
    name: name.trim(),
    expirationDate: dateOnly(expirationDate),
    quantity: quantity,
    notes: notes.trim(),
  );
}

/// Regra única de validade (D009): antes da data de referência está vencido;
/// de hoje até [warningDays], inclusive, está próximo; depois, válido.
MedicationStatus statusForDaysUntilExpiration(
  int daysUntilExpiration, {
  int warningDays = defaultExpirationWarningDays,
}) {
  assert(warningDays >= 0, 'warningDays não pode ser negativo.');
  if (daysUntilExpiration < 0) {
    return MedicationStatus.expired;
  }
  if (daysUntilExpiration <= warningDays) {
    return MedicationStatus.expiringSoon;
  }
  return MedicationStatus.valid;
}

/// Diferença em dias civis de [from] até [to], ignorando horários e fusos.
int civilDaysBetween(DateTime from, DateTime to) =>
    _dateOnlyUtc(to).difference(_dateOnlyUtc(from)).inDays;

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _dateOnlyUtc(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
