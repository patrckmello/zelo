import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/formatting/dates.dart';
import 'package:zelo/features/collection_points/presentation/collection_point_presentation.dart';
import 'package:zelo/features/medications/presentation/medication_presentation.dart';

void main() {
  group('describeExpiration', () {
    test('usa hoje, amanhã e ontem nos limites', () {
      expect(describeExpiration(0), 'Vence hoje');
      expect(describeExpiration(1), 'Vence amanhã');
      expect(describeExpiration(-1), 'Venceu ontem');
    });

    test('conta dias até 60 e aproxima prazos maiores', () {
      expect(describeExpiration(12), 'Vence em 12 dias');
      expect(describeExpiration(60), 'Vence em 60 dias');
      expect(describeExpiration(90), 'Vence em cerca de 3 meses');
      expect(describeExpiration(400), 'Vence em cerca de 1 ano');
      expect(describeExpiration(-5), 'Venceu há 5 dias');
      expect(describeExpiration(-800), 'Venceu há cerca de 2 anos');
    });

    test('complemento curto acompanha o rótulo da situação', () {
      expect(expirationDetail(-5), 'há 5 dias');
      expect(expirationDetail(-1), 'ontem');
      expect(expirationDetail(0), 'vence hoje');
      expect(expirationDetail(12), 'vence em 12 dias');
    });
  });

  test('formata quantidade, datas e distância em português', () {
    expect(formatQuantity(1), '1 unidade');
    expect(formatQuantity(8), '8 unidades');
    expect(formatDate(DateTime(2026, 9, 5)), '05/09/2026');
    expect(formatLongDate(DateTime(2026, 10, 2)), 'sexta-feira, 2 de outubro');
    expect(formatFullDate(DateTime(2026, 10, 2)), '2 de outubro de 2026');
    expect(formatDistance(412), '412 m');
    expect(formatDistance(1840), '1,8 km');
    expect(formatDistance(12400), '12 km');
  });

  test('traduz tipos de resíduo normalizados', () {
    expect(residueLabel('medicamento'), 'Medicamentos');
    expect(residueLabel('seringa'), 'Seringas');
    expect(residueLabel('outro'), 'Outro');
  });
}
