# Aplicativo móvel

Aplicativo Flutter do Zelo, inicialmente direcionado ao Android. A versão atual
contém tema Material 3 e um fluxo manual de medicamentos validado com dados em
memória:

- resumo dinâmico da farmácia doméstica;
- listagem ordenada por validade;
- cadastro, edição, detalhes e remoção;
- estados vazio e erro simulado com nova tentativa;
- classificação como válido, próximo do vencimento ou vencido.

A janela padrão de proximidade é de 30 dias. A comparação usa somente a data, e
o medicamento que vence hoje ainda não é classificado como vencido.

O armazenamento não é persistente: os dados voltam ao estado inicial quando o
aplicativo é reiniciado. Persistência e integração com a API Zelo pertencem ao
marco do backend.

A identidade de abertura está em validação. O código contém uma splash Android
com fundo monocromático, seguida por animação curta do símbolo em Flutter. A
animação é ignorada quando a redução de movimento está ativa. Onboarding e
autenticação ainda não foram implementados.

## Validação atual

- `dart format`: aprovado;
- `flutter analyze`: sem problemas;
- `flutter test`: 12 testes do M3 aprovados em 24/08/2026;
- `flutter build web`: aprovado.

Dois testes de abertura foram adicionados, totalizando 14 testes no código, mas
a suíte atualizada ainda não foi executada. No clone inspecionado em 14/09/2026,
o SDK Flutter portátil descrito no README da raiz e o Android SDK não estavam
disponíveis. A splash nativa precisa ser validada em Android real ou emulador.
