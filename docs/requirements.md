# Requisitos

## Legenda

- **Confirmado:** aprovado para o produto.
- **Implementado:** existe em código e foi verificado.
- **Planejado:** pertence a um marco futuro.
- **Pendente:** depende de decisão ou insumo.

Nesta versão, todos os requisitos funcionais estao confirmados ou planejados;
nenhum esta implementado em código.

## Funcionais do MVP

| ID | Requisito | Estado |
|---|---|---|
| RF01 | Cadastrar e acessar conta | Planejado |
| RF02 | Cadastrar medicamento com nome, validade, quantidade e observações | Planejado |
| RF03 | Listar medicamentos | Planejado |
| RF04 | Editar e remover medicamentos | Planejado |
| RF05 | Classificar como valido, próximo do vencimento ou vencido | Planejado |
| RF06 | Notificar proximidade do vencimento | Planejado |
| RF07 | Consultar pontos próximos por meio da API Zelo | Planejado |
| RF08 | Exibir pontos em lista e posteriormente em mapa | Planejado |
| RF09 | Exibir informações disponíveis e confiabilidade do ponto | Planejado |
| RF10 | Abrir rota em aplicativo externo | Planejado |
| RF11 | Registrar descarte simples | Planejado |
| RF12 | Consultar histórico de descartes | Planejado |

## Não funcionais

| ID | Requisito | Estado |
|---|---|---|
| RNF01 | Funcionar em smartphones Android | Confirmado |
| RNF02 | Interface responsiva, legivel e com contraste adequado | Confirmado |
| RNF03 | não bloquear a interface durante operações externas | Confirmado |
| RNF04 | Tratar falhas de rede sem travamento ou dados fabricados | Confirmado |
| RNF05 | Usar HTTPS fora do ambiente local | Confirmado |
| RNF06 | Proteger senhas e credenciais | Confirmado |
| RNF07 | Solicitar e explicar permissões apenas quando necessárias | Confirmado |
| RNF08 | Manter a chave EcoMed somente no backend | Confirmado |
| RNF09 | não registrar segredos, dados pessoais ou coordenadas precisas | Confirmado |
| RNF10 | Ter testes para regras críticas e execucao local documentada | Confirmado |

## Fora do MVP

- aconselhamento, diagnóstico, dose ou recomendação de medicamentos;
- substituicao ou interrupcao de tratamento;
- prontuarios, marketplace, venda, doacao ou chat médico;
- garantia de atendimento por qualquer unidade pública;
- iOS como prioridade;
- OCR antes da estabilidade do fluxo manual.

## Critério do fluxo vertical inicial

Com dados simulados, o usuário deve visualizar o resumo da farmácia doméstica,
abrir a lista de medicamentos e acessar uma tela de cadastro manual. A regra de
validade deve possuir testes determinísticos antes da persistência real.
