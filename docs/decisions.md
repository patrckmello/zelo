# Registro de decisões

Os estados usados são **aceita**, **proposta** e **pendente**. Uma decisão só
será marcada como aceita quando confirmada ou aplicada e validada.

## D001 - Monorepo simples

- Estado: aceita
- decisão: manter `mobile`, `backend` e `docs` no mesmo repositório.
- Motivo: facilita coordenação, rastreabilidade e apresentação para uma equipe
  acadêmica de duas pessoas.

## D002 - Aplicativo Flutter com Android prioritário

- Estado: aceita
- decisão: Flutter/Dart e Material 3; Android primeiro.
- Identificador provisoriamente proposto: `br.edu.cesuca.zelo`.

## D003 - API própria entre aplicativo e EcoMed

- Estado: aceita
- decisão: somente o backend acessará a EcoMed e sua chave.
- Consequência: o Flutter não conterá chave, endpoint externo nem contrato
  acoplado a EcoMed.

## D004 - Fluxo manual antes de OCR

- Estado: aceita
- decisão: OCR permanece fora do núcleo inicial.
- Motivo: preservar cadastro, classificação, descarte e testes confiáveis antes
  de introduzir reconhecimento sujeito a erro.

## D005 - Dependências Flutter

- Estado: aceita para preferências locais; demais categorias permanecem pendentes
- Decisão aplicada: usar `shared_preferences 2.5.5` somente para os booleanos não
  sensíveis de onboarding e sessão simulada. Não adicionar biblioteca de rotas,
  estado ou animação no M2.
- Critério: adicionar apenas quando houver uso concreto, com justificativa,
  manutenção ativa, compatibilidade e impacto em testes avaliados.

## D006 - Paleta oficial

- Estado: proposta
- decisão: adotar o briefing mais recente (`#28A87B`, `#174C5B`, `#F4F7F6`,
  `#F5A623`, `#687078`) até confirmação da equipe.
- Conflito: o documento inicial registra `#28A878` e `#6B7D78`.

## D007 - Backend preferencial

- Estado: proposta
- decisão: FastAPI, SQLAlchemy, Alembic e PostgreSQL.
- Condição: validar compatibilidade das versões antes de fixar dependências.

## D008 - Navegação e mapa

- Estado: pendente
- Proposta: começar pela lista de pontos e abertura em mapa externo; mapa
  embutido apenas após o fluxo essencial.
- Pendente: escolher fornecedor de mapas e política de uso.

## D009 - Regra de proximidade do vencimento

- Estado: aceita
- Decisão: usar janela padrão de 30 dias corridos, com comparação apenas da data.
- Limites: validade anterior à data de referência é vencida; de hoje até 30 dias,
  inclusive, está próxima do vencimento; acima de 30 dias está válida.
- Configuração: a regra aceita outra janela internamente, mas a interface ainda
  não oferece configuração ao usuário.

## D010 - Fluxo inicial obrigatório

- Estado: aceita
- Decisão: o MVP terá splash, onboarding no primeiro acesso e verificação de
  sessão antes de apresentar login ou página inicial.
- Motivo: apresentar a identidade do Zelo e orientar novos usuários antes do
  uso das funcionalidades principais.

## D011 - Animação da marca

- Estado: aceita para a camada Flutter; validação Android permanece pendente
- Decisão: usar splash nativa estática seguida de animação curta executada pelo
  Flutter, aproveitando o movimento circular da seta de devolução.
- Implementação: usar o PNG oficial disponível com opacidade, escala
  e rotação por 800 ms, sem dependência externa, nome ou slogan. Quando a
  redução de movimento está ativa, a animação é ignorada.
- Rive não foi adicionado porque o repositório ainda não contém a fonte vetorial
  da marca. A alternativa poderá ser reavaliada quando esse arquivo existir.
- Restrição: a animação não deve simular carregamento inexistente nem atrasar
  desnecessariamente a entrada. Deve respeitar redução de movimento.
- Evidência: os testes Flutter de conclusão automática e redução de movimento
  foram aprovados em 14/09/2026. A transição da splash nativa ainda precisa ser
  validada em Android real ou emulador.

## D012 - Autenticação do MVP

- Estado: aceita
- Decisão: incluir cadastro, login por e-mail e senha, recuperação de senha,
  restauração de sessão e logout.
- Decisão de escopo: não implementar login social no MVP.
- Mostra: manter credencial de demonstração previamente testada.

## D013 - Documentação viva

- Estado: aceita
- Decisão: implementação, requisitos, decisões, arquitetura, testes e evidências
  devem ser atualizados no mesmo ciclo de trabalho.
- Regra operacional: uma tarefa não é considerada concluída se o código mudou e
  a documentação correspondente permaneceu desatualizada.
- Aplicação: agentes devem seguir AGENTS.md em todas as sessões futuras.


## D014 - Estado do fluxo manual

- Estado: aceita
- Decisão: usar `MedicationStore` com `ChangeNotifier` e armazenamento em
  memória para validar o primeiro fluxo vertical sem dependências externas.
- Consequência: a página inicial e as telas de medicamentos compartilham o mesmo
  estado durante a execução, mas os dados são reiniciados ao fechar o app.
- Evolução: a persistência será conectada no M4 preservando as regras de domínio
  e os testes já existentes.

## D015 - Bootstrap e navegação do M2

- Estado: aceita
- Decisão: centralizar os estados `initializing`, `firstAccess`,
  `unauthenticated`, `authenticated` e `recoverableError` em um controlador
  injetável, sem biblioteca adicional de rotas ou gerenciamento de estado.
- Navegação: trocar o conteúdo da rota raiz ao autenticar ou sair. Assim, Voltar
  não reabre splash, onboarding ou login após a autenticação.
- Inicialização: montar o bootstrap sob a animação desde o primeiro quadro,
  compartilhar cargas concorrentes e ignorar conclusões após o descarte. A
  animação define somente o tempo mínimo de identidade; não simula carregamento.
- Recuperação: falhas de leitura mostram mensagem segura e ação Tentar novamente.

## D016 - Autenticação simulada e armazenamento mínimo

- Estado: aceita para o M2
- Decisão: definir uma interface substituível de autenticação e uma implementação
  simulada, com fixture pública fictícia para demonstração.
- Persistência: salvar apenas `simulated_session_active`; não persistir nome,
  e-mail ou senha e não criar token ou JWT fictício.
- Limite: o marcador booleano não é autenticação segura. Autenticação real,
  isolamento de usuários e tokens protegidos permanecem no M4.

## D017 - Preferência do onboarding

- Estado: aceita
- Decisão: persistir `onboarding_completed = true` ao concluir ou pular, por uma
  abstração própria apoiada em `shared_preferences` na aplicação e memória nos
  testes.
- Privacidade: a preferência não contém dado pessoal ou de saúde.

## D018 - Medicamentos como dados indiretos de saúde

- Estado: aceita
- Decisão: tratar o cadastro de medicamentos como dado capaz de revelar
  indiretamente informações de saúde.
- Consequências: minimizar dados, não registrar medicamentos ou dados pessoais em
  logs e manter sessão/autenticação separadas do armazenamento de medicamentos.

## D019 - Protocolo acadêmico de avaliação futura

- Estado: aceita como planejamento; coleta ainda PENDENTE
- Decisão: avaliar futuramente com 12 adultos em tarefas orientadas, registrando
  tempo, conclusão, erros e dificuldades, além de perguntas sobre vínculo com o
  SUS e perguntas abertas.
- Regra: resultados só serão registrados como evidência depois da coleta real e
  do procedimento acadêmico aplicável.

## D020 - Divergências dos dados EcoMed

- Estado: aceita como regra futura
- Decisão: normalizar respostas, identificar a origem, priorizar farmácias
  `logmed-*`, apresentar aviso específico para unidades públicas e omitir
  horários ausentes em vez de fabricá-los.
- Limite: a integração segue bloqueada até a inspeção do contrato e de exemplos
  reais; a regra não constitui garantia de atendimento.

## D021 - Relação com os ODS

- Estado: aceita
- Decisão: relacionar o Zelo ao ODS 3, pelo apoio ao cuidado e à prevenção de
  riscos, e ao ODS 12, pela redução de desperdício e descarte responsável.
- Limite: essa relação expressa o enquadramento do projeto e não prova impacto
  mensurado, que permanece PENDENTE.

## D022 - Contraste dos controles interativos

- Estado: aceita
- Decisão: usar azul-petróleo como cor primária interativa e manter o verde como
  cor secundária/de marca. O contraste medido do azul-petróleo sobre o fundo
  claro é 8,77:1; o verde original como texto sobre branco tinha cerca de 3,01:1.

## D023 - Navegação autenticada definitiva

- Estado: aceita
- Decisão: usar Início, Descartar, Histórico e Conta como os quatro destinos da
  barra inferior.
- Medicamentos: abrir a lista como rota a partir da Home e manter ali as ações
  de cadastro, sem criar aba exclusiva.
- Sessão: concentrar o logout em Conta e identificar toda sessão atual como
  simulada, pois o marcador booleano não distingue login, cadastro e entrada de
  demonstração. Nenhum dado pessoal deve ser inventado.
- Limites: Descartar continua futuro até a integração EcoMed; Histórico mostra
  estado vazio e não representa RF11 ou RF12 como implementados.

## D024 - Reconciliação visual local do M2

- Estado: aceita para a implementação Flutter; Figma e Android permanecem
  pendentes
- Decisão: manter somente o símbolo oficial na abertura e substituir os ícones
  isolados em círculos do onboarding por composições feitas com o ativo oficial,
  formas, superfícies e ícones Material.
- Restrição: não adicionar ativos externos, redesenhar a marca ou solicitar
  permissões no onboarding.
