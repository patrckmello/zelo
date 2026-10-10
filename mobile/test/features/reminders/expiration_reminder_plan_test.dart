import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/reminders/domain/expiration_reminder_plan.dart';

void main() {
  // Sexta-feira, 2 de outubro de 2026, 10h.
  final now = DateTime(2026, 10, 2, 10);

  Medication med(String name, DateTime expiration) =>
      Medication(id: name, name: name, expirationDate: expiration, quantity: 1);

  test('gera aviso 30 dias antes, 7 dias antes e no dia, às 9h', () {
    final plan = planExpirationReminders([
      med('Dipirona', DateTime(2026, 12, 31)),
    ], now: now);

    expect(plan.map((reminder) => reminder.at), [
      DateTime(2026, 12, 1, 9),
      DateTime(2026, 12, 24, 9),
      DateTime(2026, 12, 31, 9),
    ]);
    expect(plan.map((reminder) => reminder.daysBefore), [30, 7, 0]);
    expect(plan.map((reminder) => reminder.id), [1, 2, 3]);
  });

  test('ignora avisos cujo horário já passou', () {
    // Vence em 20 dias: o aviso de 30 dias já ficou para trás.
    final plan = planExpirationReminders([
      med('Loratadina', DateTime(2026, 10, 22)),
    ], now: now);
    expect(plan.map((reminder) => reminder.daysBefore), [7, 0]);

    // Vence hoje, depois das 9h: não sobra nada para avisar.
    expect(
      planExpirationReminders([med('Hoje', DateTime(2026, 10, 2))], now: now),
      isEmpty,
    );
    // Já vencido: nada.
    expect(
      planExpirationReminders([med('Velho', DateTime(2026, 9, 1))], now: now),
      isEmpty,
    );
  });

  test('antes das 9h, o aviso do próprio dia ainda vale', () {
    final plan = planExpirationReminders([
      med('Hoje', DateTime(2026, 10, 2)),
    ], now: DateTime(2026, 10, 2, 8, 30));
    expect(plan.single.at, DateTime(2026, 10, 2, 9));
    expect(plan.single.title, 'Vence hoje');
  });

  test('reúne medicamentos com o mesmo vencimento em um só aviso', () {
    final plan = planExpirationReminders([
      med('Soro', DateTime(2026, 11, 15)),
      med('Dipirona', DateTime(2026, 11, 15)),
      med('Loratadina', DateTime(2026, 11, 16)),
    ], now: now);

    final sameDay = plan.where((r) => r.at == DateTime(2026, 11, 15, 9));
    expect(sameDay.single.daysBefore, 0);
    expect(sameDay.single.medicationNames, ['Dipirona', 'Soro']);
    expect(sameDay.single.body, 'Dipirona e Soro');
    // 3 datas distintas por antecedente: 2 vencimentos x 3 antecedentes.
    expect(plan, hasLength(6));
  });

  test('ordena do mais próximo ao mais distante e numera os avisos', () {
    final plan = planExpirationReminders([
      med('Longe', DateTime(2027, 6, 1)),
      med('Perto', DateTime(2026, 10, 20)),
    ], now: now);
    final times = plan.map((reminder) => reminder.at).toList();
    expect([...times]..sort(), times);
    expect(plan.first.medicationNames, ['Perto']);
    expect(plan.map((r) => r.id), [for (var i = 1; i <= plan.length; i++) i]);
  });

  test('mantém só os avisos mais próximos quando passa do limite', () {
    final medications = [
      for (var i = 0; i < 40; i++)
        med('Remédio $i', DateTime(2027, 1, 1).add(Duration(days: i * 2))),
    ];
    final plan = planExpirationReminders(medications, now: now);
    expect(plan, hasLength(maxScheduledReminders));
    expect(plan.last.id, maxScheduledReminders);
    final all = planExpirationReminders(medications, now: now, limit: 1000);
    expect(
      plan.map((r) => r.at),
      all.take(maxScheduledReminders).map((r) => r.at),
    );
  });

  test('títulos e lista de nomes em português', () {
    PlannedReminder reminder(int days, List<String> names) => PlannedReminder(
      id: 1,
      at: now,
      daysBefore: days,
      medicationNames: names,
    );

    expect(reminder(0, ['A']).title, 'Vence hoje');
    expect(reminder(1, ['A']).title, 'Vence amanhã');
    expect(reminder(7, ['A']).title, 'Vence em 7 dias');
    expect(reminder(30, ['A']).title, 'Vence em 30 dias');
    expect(reminder(7, ['A']).body, 'A');
    expect(reminder(7, ['A', 'B']).body, 'A e B');
    expect(reminder(7, ['A', 'B', 'C']).body, 'A, B e C');
    expect(reminder(7, ['A', 'B', 'C', 'D', 'E']).body, 'A, B e mais 3');
  });

  test('lista vazia não gera nada', () {
    expect(planExpirationReminders(const [], now: now), isEmpty);
  });

  test('antecedentes personalizados e virada de mês', () {
    final plan = planExpirationReminders(
      [med('Soro', DateTime(2026, 11, 3))],
      now: now,
      offsets: const [5],
    );
    expect(plan.single.at, DateTime(2026, 10, 29, 9));
  });
}
