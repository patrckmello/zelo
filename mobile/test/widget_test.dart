import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/app/zelo_app.dart';

void main() {
  testWidgets('exibe a página inicial e seus dados simulados', (tester) async {
    await tester.pumpWidget(const ZeloApp());

    expect(find.text('Cuide. Organize. Descarte certo.'), findsOneWidget);
    expect(find.text('Sua farmácia doméstica'), findsOneWidget);
    expect(find.text('Cadastrar medicamento'), findsOneWidget);
    expect(find.text('medicamento vencido'), findsOneWidget);
  });

  testWidgets('navega para a área de medicamentos', (tester) async {
    await tester.pumpWidget(const ZeloApp());

    await tester.tap(find.byIcon(Icons.medication_outlined));
    await tester.pumpAndSettle();

    expect(
      find.text('Seu fluxo de cadastro manual será construído aqui.'),
      findsOneWidget,
    );
  });
}
