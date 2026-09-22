# Requisitos

## Legenda

- **Confirmado:** aprovado para o produto.
- **Implementado:** existe em código e foi verificado.
- **Planejado:** pertence a um marco futuro.
- **Pendente:** depende de decisão ou insumo.

A fundação visual, a navegação mínima e o fluxo manual de medicamentos em
memória já existem. Cada requisito abaixo registra separadamente o estado
verificado nesta versão.

## Funcionais do MVP

| ID | Requisito | Estado |
|---|---|---|
| RF01 | Cadastrar conta com nome, e-mail e senha | Implementado apenas como simulação local |
| RF02 | Cadastrar medicamento com nome, validade, quantidade e observações | Implementado em memória |
| RF03 | Listar medicamentos | Implementado em memória |
| RF04 | Editar e remover medicamentos | Implementado em memória |
| RF05 | Classificar como válido, próximo do vencimento ou vencido | Implementado e testado |
| RF06 | Notificar proximidade do vencimento | Planejado |
| RF07 | Consultar pontos próximos por meio da API Zelo | Planejado |
| RF08 | Exibir pontos em lista e posteriormente em mapa | Planejado |
| RF09 | Exibir informações disponíveis e confiabilidade do ponto | Planejado |
| RF10 | Abrir rota em aplicativo externo | Planejado |
| RF11 | Registrar descarte simples | Planejado |
| RF12 | Consultar histórico de descartes | Planejado |
| RF13 | Autenticar usuário por e-mail e senha | Implementado apenas como simulação local |
| RF14 | Solicitar recuperação de senha | Implementado apenas como confirmação simulada |
| RF15 | Restaurar uma sessão válida ao reabrir o aplicativo | Implementado com marcador simulado não sensível |
| RF16 | Encerrar a sessão do usuário | Implementado para a sessão simulada, exclusivamente pela Conta |
| RF17 | Exibir splash nativa com fundo monocromático e logo do Zelo | Pendente de verificação em Android |
| RF18 | Exibir animação curta da marca após a inicialização do Flutter | Implementado com somente o símbolo e testado em paralelo ao bootstrap; transição Android pendente |
| RF19 | Apresentar onboarding no primeiro acesso | Implementado e testado |
| RF20 | Permitir pular o onboarding e não repeti-lo após sua conclusão | Implementado e testado |

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
- Erros de preferências devem exibir mensagem segura e permitir nova tentativa.
- Login e logout devem substituir o fluxo raiz, sem retorno às páginas de
  entrada pelo botão Voltar depois da autenticação.
- A leitura do onboarding e da sessão deve iniciar em paralelo à animação,
  sem atraso artificial, chamadas duplicadas ou atualização após descarte.
- A abertura Flutter deve exibir somente o símbolo oficial, sem nome ou slogan.

## Critérios da navegação autenticada

- A barra inferior deve conter Início, Descartar, Histórico e Conta.
- Medicamentos deve permanecer acessível por “Ver todos” e pelas ações de
  cadastro da Home, sem destino inferior exclusivo.
- Descartar deve informar que a consulta de pontos depende da integração
  EcoMed e não deve fabricar pontos, endereços ou horários.
- Histórico deve apresentar estado vazio até RF11 e RF12 possuírem persistência
  real, sem descartes de exemplo tratados como registros.
- Conta deve identificar a sessão atual como simulada, não exibir dados pessoais
  inventados e concentrar a única ação de logout da área autenticada.

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

## Fluxo vertical de medicamentos validado

Com dados em memória, o usuário pode visualizar o resumo da farmácia doméstica,
abrir a lista ordenada por validade, cadastrar, editar, detalhar e remover um
medicamento. Também foram validados estados vazio e erro simulado.

A regra usa datas civis, sem horário: uma validade anterior à data de referência
é vencida; de hoje até 30 dias, inclusive, está próxima do vencimento; acima de
30 dias está válida. O dia da validade ainda não é considerado vencido.

## Estado do fluxo de entrada

A animação Flutter somente com o símbolo, o bootstrap paralelo, o onboarding
reconciliado e a autenticação simulada estão implementados e cobertos por testes
automatizados. A splash Android continua pendente de verificação em dispositivo
ou emulador. O fluxo não solicita câmera, localização nem notificações.

A simulação não armazena senha, nome ou e-mail, não cria JWT e não representa
autenticação segura. Somente os booleanos `onboarding_completed` e
`simulated_session_active` são persistidos localmente. Autenticação real,
isolamento dos dados por usuário e tokens seguros pertencem ao M4.

Os textos efetivos dos termos de uso e da política de privacidade são
**PENDENTES** de fornecimento e aprovação; a interface valida apenas o aceite,
sem inventar conteúdo jurídico.

## Privacidade dos medicamentos

Medicamentos cadastrados são tratados como dados indiretos de saúde. O projeto
aplica minimização, não registra medicamentos, credenciais ou dados pessoais em
logs e mantém a sessão simulada separada do `MedicationStore`. Fixtures de teste
e demonstração são públicas e fictícias, sem informações reais.
