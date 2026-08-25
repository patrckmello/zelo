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

## Validação atual

- `dart format`: aprovado;
- `flutter analyze`: sem problemas;
- `flutter test`: 12 testes aprovados;
- `flutter build web`: aprovado.

O Android SDK ainda não está disponível nesta máquina. Enquanto isso, o app
pode ser executado e validado no Chrome por meio do Flutter portátil descrito
no README da raiz.
