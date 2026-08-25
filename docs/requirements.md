# Requisitos

## Legenda

- **Confirmado:** aprovado para o produto.
- **Implementado:** existe em código e foi verificado.
- **Planejado:** pertence a um marco futuro.
- **Pendente:** depende de decisão ou insumo.

A fundação visual e a navegação mínima já existem. Os requisitos funcionais
abaixo permanecem planejados enquanto não houver implementação e validação
específicas.

## Funcionais do MVP

| ID | Requisito | Estado |
|---|---|---|
| RF01 | Cadastrar conta com nome, e-mail e senha | Planejado |
| RF02 | Cadastrar medicamento com nome, validade, quantidade e observações | Planejado |
| RF03 | Listar medicamentos | Planejado |
| RF04 | Editar e remover medicamentos | Planejado |
| RF05 | Classificar como válido, próximo do vencimento ou vencido | Planejado |
| RF06 | Notificar proximidade do vencimento | Planejado |
| RF07 | Consultar pontos próximos por meio da API Zelo | Planejado |
| RF08 | Exibir pontos em lista e posteriormente em mapa | Planejado |
| RF09 | Exibir informações disponíveis e confiabilidade do ponto | Planejado |
| RF10 | Abrir rota em aplicativo externo | Planejado |
| RF11 | Registrar descarte simples | Planejado |
| RF12 | Consultar histórico de descartes | Planejado |
| RF13 | Autenticar usuário por e-mail e senha | Planejado |
| RF14 | Solicitar recuperação de senha | Planejado |
| RF15 | Restaurar uma sessão válida ao reabrir o aplicativo | Planejado |
| RF16 | Encerrar a sessão do usuário | Planejado |
| RF17 | Exibir splash nativa com fundo monocromático e logo do Zelo | Planejado |
| RF18 | Exibir animação curta da marca após a inicialização do Flutter | Planejado |
| RF19 | Apresentar onboarding no primeiro acesso | Planejado |
| RF20 | Permitir pular o onboarding e não repeti-lo após sua conclusão | Planejado |

## Critérios do fluxo inicial

- A splash nativa deve aparecer sem tela branca intermediária.
- A animação deve representar a seta circular de devolução e terminar
  automaticamente, sem impedir a inicialização.
- O onboarding deve ter três páginas: organização de medicamentos, prevenção de
  desperdício e descarte responsável.
- O onboarding deve possuir Pular, Próximo e Começar.
- Câmera e localização não devem ser solicitadas no onboarding.
- No retorno ao aplicativo, uma sessão válida direciona o usuário à página
  inicial; sessão ausente ou inválida direciona ao login.
- A Mostra deverá possuir credencial de demonstração previamente validada.

## Não funcionais

| ID | Requisito | Estado |
|---|---|---|
| RNF01 | Funcionar em smartphones Android | Confirmado |
| RNF02 | Ter interface responsiva, legível e com contraste adequado | Confirmado |
| RNF03 | Não bloquear a interface durante operações externas | Confirmado |
| RNF04 | Tratar falhas de rede sem travamento ou dados fabricados | Confirmado |
| RNF05 | Usar HTTPS fora do ambiente local | Confirmado |
| RNF06 | Proteger senhas, tokens e credenciais | Confirmado |
| RNF07 | Solicitar e explicar permissões apenas quando necessárias | Confirmado |
| RNF08 | Manter a chave EcoMed somente no backend | Confirmado |
| RNF09 | Não registrar segredos, dados pessoais ou coordenadas precisas | Confirmado |
| RNF10 | Ter testes para regras críticas e execução local documentada | Confirmado |
| RNF11 | Evitar atraso artificial durante splash e animação inicial | Confirmado |
| RNF12 | Respeitar a preferência de redução de movimento do sistema | Confirmado |
| RNF13 | Armazenar tokens de sessão em mecanismo seguro do dispositivo | Confirmado |

## Fora do MVP

- aconselhamento, diagnóstico, dose ou recomendação de medicamentos;
- substituição ou interrupção de tratamento;
- prontuários, marketplace, venda, doação ou chat médico;
- garantia de atendimento por qualquer unidade pública;
- login social;
- iOS como prioridade;
- OCR antes da estabilidade do fluxo manual.

## Critério do fluxo vertical inicial

Com dados simulados, o usuário deve concluir o fluxo de entrada, visualizar o
resumo da farmácia doméstica, abrir a lista de medicamentos e acessar uma tela
de cadastro manual. A regra de validade deve possuir testes determinísticos
antes da persistência real.
