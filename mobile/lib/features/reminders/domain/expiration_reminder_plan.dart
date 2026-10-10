import '../../medications/domain/medication.dart';

/// Quantos dias antes do vencimento a pessoa é avisada (0 = no próprio dia).
const reminderOffsets = [30, 7, 0];

/// Horário local dos avisos.
const reminderHour = 9;

/// Limite de avisos agendados ao mesmo tempo: sistemas móveis restringem os
/// alarmes pendentes (no iOS são 64), então vale o mais próximo primeiro.
const maxScheduledReminders = 60;

/// Um aviso de validade, que pode reunir vários medicamentos da mesma data.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.daysBefore,
    required this.medicationNames,
  });

  /// Identificador entre os avisos agendados (1, 2, 3…).
  final int id;

  /// Momento do aviso, no horário local do aparelho.
  final DateTime at;
  final int daysBefore;
  final List<String> medicationNames;

  String get title => switch (daysBefore) {
    0 => 'Vence hoje',
    1 => 'Vence amanhã',
    _ => 'Vence em $daysBefore dias',
  };

  /// Nomes dos medicamentos, no máximo três: "A", "A e B", "A, B e C" ou
  /// "A, B e mais 3".
  String get body => formatMedicationNames(medicationNames);

  @override
  String toString() => 'PlannedReminder($id, $at, $title: $body)';
}

String formatMedicationNames(List<String> names) {
  return switch (names.length) {
    0 => '',
    1 => names.first,
    2 => '${names[0]} e ${names[1]}',
    3 => '${names[0]}, ${names[1]} e ${names[2]}',
    _ => '${names[0]}, ${names[1]} e mais ${names.length - 2}',
  };
}

/// Planeja os avisos de validade.
///
/// Cada medicamento gera um aviso por data de [offsets]; medicamentos com o
/// mesmo vencimento e o mesmo antecedente viram um só aviso. Avisos que já
/// passaram são ignorados e ficam só os [limit] mais próximos, em ordem.
List<PlannedReminder> planExpirationReminders(
  Iterable<Medication> medications, {
  required DateTime now,
  List<int> offsets = reminderOffsets,
  int hour = reminderHour,
  int limit = maxScheduledReminders,
}) {
  final groups = <(DateTime, int), List<String>>{};
  for (final medication in medications) {
    final expiration = dateOnly(medication.expirationDate);
    for (final offset in offsets) {
      final at = DateTime(
        expiration.year,
        expiration.month,
        expiration.day - offset,
        hour,
      );
      if (!at.isAfter(now)) {
        continue;
      }
      groups.putIfAbsent((at, offset), () => []).add(medication.name);
    }
  }

  final ordered = groups.entries.toList()
    ..sort((first, second) {
      final byTime = first.key.$1.compareTo(second.key.$1);
      // No mesmo horário, o aviso mais urgente (menos dias) vem primeiro.
      return byTime != 0 ? byTime : first.key.$2.compareTo(second.key.$2);
    });

  return [
    for (final (index, entry) in ordered.take(limit).indexed)
      PlannedReminder(
        id: index + 1,
        at: entry.key.$1,
        daysBefore: entry.key.$2,
        medicationNames: (entry.value..sort()).toList(growable: false),
      ),
  ];
}
