# Plano de testes

## Objetivo

Validar regras críticas, fluxos do usuário, integração e desempenho, mantendo
evidências reproduzíveis para o desenvolvimento e a Mostra Científica.

## Aplicativo

- testes unitários da classificação por validade, inclusive datas-limite;
- testes de widgets para carregamento, sucesso, vazio e erro;
- validação de formulários de medicamento, login, cadastro e recuperação;
- testes de navegação do fluxo vertical;
- teste manual em pelo menos um smartphone Android real;
- verificação de layout com tamanhos de tela e escala de fonte diferentes.

## Fluxo inicial

- primeiro acesso exibe splash e onboarding;
- usuário pode avançar, voltar e pular o onboarding;
- onboarding concluído não reaparece na próxima abertura;
- preferência de redução de movimento evita animação desnecessária;
- sessão ausente ou inválida direciona ao login;
- sessão válida direciona à página inicial;
- logout remove a sessão e retorna ao login;
- logout está disponível somente em Conta, que identifica a sessão simulada;
- a navegação autenticada exibe Início, Descartar, Histórico e Conta, sem aba
  de Medicamentos;
- “Ver todos” na Home abre a lista e preserva o fluxo manual de medicamentos;
- Histórico vazio não fabrica descartes e Descartar não fabrica pontos;
- falha durante bootstrap apresenta recuperação segura, sem loop infinito;
- bootstrap inicia em paralelo à animação, independentemente de qual termine
  primeiro, sem chamadas duplicadas ou atualizações depois do descarte;
- credencial de demonstração funciona antes da apresentação.

## Backend

Cenários abaixo cobertos por `backend/tests` em 02/10/2026, exceto onde
indicado como pendente.

- criação de conta e prevenção de e-mail duplicado;
- autenticação válida e rejeição de credenciais incorretas;
- hash de senha e ausência de senha ou token em logs;
- recuperação de senha com token temporário;
- renovação, expiração e revogação de sessão;
- regras de autorização e isolamento dos dados do usuário;
- validação das operações de medicamento e descarte;
- migrações em banco limpo;
- normalização das respostas EcoMed com fixtures baseadas no exemplo da
  documentação pública; o contrato real observado em 03/10/2026 tem os mesmos
  campos (fixtures anonimizadas de respostas reais: PENDENTE);
- perfil: consulta, troca de nome, de e-mail e de senha com senha atual,
  revogação das sessões e exclusão em cascata (03/10/2026);
- leitura da embalagem: tipo e tamanho da imagem, imagem inválida, servidor
  sem OCR, limite por conta, interpretação de validade (mês/ano, FAB × VAL,
  confusões de dígitos), nome e quantidade, e log sem o texto lido
  (03/10/2026);
- chave de cache com coordenadas arredondadas a três casas;
- expiração, cache hit/miss, timeout e rate limit;
- ausência de chaves e dados sensíveis nos logs.

## Fluxos funcionais

1. concluir ou pular onboarding;
2. cadastrar conta e autenticar;
3. recuperar acesso e encerrar sessão;
4. cadastrar medicamento manualmente;
5. editar e remover medicamento;
6. identificar sua situação de validade;
7. localizar e consultar um ponto;
8. abrir rota externa;
9. registrar e consultar um descarte;
10. voltar ao Início a partir de Descartar e escapar de uma localização que
    não chega;
11. alterar dados do perfil e excluir a conta;
12. preencher o cadastro pela foto da embalagem e conferir antes de salvar.

## Validação executada no M3

Em 24/08/2026, os commits `76f5abd` e `33ec173` foram verificados com:

- formatação do código Dart;
- `flutter analyze` sem problemas;
- 12 testes automatizados aprovados;
- `flutter build web` concluído;
- testes unitários das datas-limite e das operações do `MedicationStore`;
- testes de widget para resumo, navegação, validação, cadastro, edição, remoção,
  estado vazio e recuperação do erro simulado.

A execução em Android real ou emulador permanece pendente por indisponibilidade
do Android SDK no ambiente usado.

## Validação pendente da abertura

Em 14/09/2026 o Flutter 3.47.1/Dart 3.13.1 foi restaurado em `.tools/flutter`.
Os dois testes adicionados no commit `526feea` foram executados. O teste de
conclusão usava uma verificação rígida no instante final e falhou; após trocar a
sincronização por `pumpAndSettle`, os cenários de conclusão automática e
`disableAnimations` foram aprovados. A duração de produção permaneceu em 800 ms.

Também permanecem pendentes em Android real ou emulador:

- exibição do símbolo sobre fundo monocromático durante a inicialização nativa;
- ausência de quadro branco na transição para Flutter;
- dimensões e recorte do símbolo em versões anteriores e posteriores ao Android 12;
- transição automática para a página inicial.

## Validação executada no M2

Em 21/09/2026, no Windows 11 com Flutter 3.47.1 e Dart 3.13.1:

- `dart format --output=none --set-exit-if-changed .`: aprovado;
- `flutter analyze`: aprovado, sem problemas;
- `flutter test`: 47 testes aprovados;
- `flutter build web`: aprovado;
- bootstrap: primeiro acesso, sem sessão, sessão restaurada, erro, tentativa,
  paralelismo com a animação, deduplicação e descarte seguro;
- onboarding: avançar, voltar, pular, concluir e não reaparecer;
- autenticação simulada: login válido/inválido, cadastro, confirmação de senha,
  aceite, recuperação genérica, logout e bloqueio do retorno ao login;
- navegação: Início, Descartar, Histórico e Conta, sem aba de Medicamentos,
  com acesso à lista por “Ver todos” e logout somente na Conta;
- estados: pontos de descarte futuros sem dados EcoMed fabricados, Histórico
  vazio e identificação da sessão simulada sem dados pessoais;
- regressão: os testes do fluxo manual de medicamentos permanecem aprovados;
- layout automatizado: viewports 390 × 844 e 320 × 568, onboarding com texto
  em escalas 2 e 1,6 e login com teclado aberto, sem exceção de overflow;
- áreas de toque: botão principal do onboarding verificado com altura mínima de
  48 px na tela pequena;
- visual: abertura somente com o símbolo oficial e onboarding com composições
  de superfícies, trajetos e ícones em vez de ícones isolados em círculos.

Essa verificação de layout é automatizada e não substitui inspeção visual em
dispositivo. O servidor Web local iniciou em `http://localhost:7357`, mas a
inspeção visual interativa não foi realizada porque o ambiente de automação
não disponibilizou navegador controlável. Contraste calculado: azul-petróleo
`#174C5B` sobre o fundo `#F4F7F6` = 8,77:1. O símbolo Flutter e o recurso Android
têm o mesmo SHA-256, 320 × 320, transparência nas bordas e conteúdo sem tocar
os limites.

O build APK e a inspeção da splash não foram executados: `flutter doctor -v`
não encontrou Android SDK, `adb` ou `sdkmanager`, e o comando `java` não está
disponível. Portanto, JDK 17, splash nativa e transição Android → Flutter não
foram validados.

O build Web terminou com sucesso e registrou um aviso não bloqueante de fonte
`CupertinoIcons` ausente do conjunto final; `MaterialIcons` foi incluída e
reduzida por tree-shaking. Nenhuma dependência foi alterada nesta correção.

## Validação executada em 02/10/2026 (redesenho, M4, M5 e M6)

Ambiente: Windows 11, Flutter 3.47.1/Dart 3.13.1 portáteis, Python 3.13.7,
Docker 29.3.1, PostgreSQL 17 (imagem `postgres:17-alpine`) e Microsoft Edge
headless.

Aplicativo (`mobile/`):

- `dart format --output=none --set-exit-if-changed .`: aprovado;
- `flutter analyze`: sem problemas;
- `flutter test`: 88 testes aprovados, incluindo regras de validade e datas,
  textos relativos, estado assíncrono dos medicamentos (deduplicação, falha
  segura, `clear` e `refresh`), filtros da lista, prévia e falha do
  formulário, painel da Início, controlador e tela de pontos (arredondamento,
  região, permissão negada, falha da API, resposta obsoleta, agrupamento LogMed,
  aviso, atribuição, mapa e ligação), registro e histórico de descartes,
  cliente da API (renovação após 401, expiração, restauração, erros de rede e
  logout) e o modo conectado de ponta a ponta com uma API falsa em memória;
- `flutter build web`: aprovado no modo demonstração e no modo conectado
  (`--dart-define=ZELO_API_URL=http://localhost:8000`);
- capturas determinísticas: 28 telas geradas por
  `tool/screenshots/screens_test.dart` com fontes reais, inclusive 320 × 568
  com texto a 160%, sem exceção de layout.

Backend (`backend/`):

- `pytest`: 37 testes aprovados (autenticação, rotação e reuso de tokens,
  limite de login, recuperação, isolamento de medicamentos, descartes, pontos
  com EcoMed simulada, cache, limite local, 429, chave recusada sem vazamento
  em respostas e logs, timeout, resposta inválida, migração em banco limpo e
  saúde);
- `ruff check .` e `ruff format --check .`: aprovados.

Integração real:

- `docker compose up --build -d`: PostgreSQL e API saudáveis; a migração
  `0001` foi aplicada no PostgreSQL;
- teste de fumaça via HTTP contra a API em contêiner: 13 de 13 verificações
  (saúde, cadastro, `me`, login, lista ordenada, atualização, descarte,
  retirada da farmácia, histórico, pontos sem chave → `503
  collection_points_not_configured`, renovação, logout e CORS);
- `tool/e2e/api_contract_test.dart`: aprovado contra a API real, exercitando os
  repositórios Dart do aplicativo;
- navegador real: build Web conectado servido localmente e conduzido no Edge
  headless via DevTools — primeiro acesso com onboarding, login com a conta de
  demonstração criada por `scripts/seed_demo.py`, Início com os três
  medicamentos vindos do PostgreSQL, Descartar e Conta com o e-mail da conta.

Não executado:

- consultas à EcoMed real: a chave ainda não está no `backend/.env`;
- Android: Android SDK, `adb`, `sdkmanager` e `java` continuam ausentes;
  permissões, armazenamento seguro, intents de mapa/telefone, APK e splash não
  foram validados em dispositivo ou emulador;
- envio de e-mail de recuperação: não há provedor configurado.

O build Web mantém o aviso não bloqueante sobre `CupertinoIcons`.

## Validação executada em 03/10/2026 (localização, perfil, leitura e EcoMed real)

Ambiente: o de 02/10/2026, com Tesseract 5.5.0 (`por`) na imagem Docker e a
chave EcoMed no `backend/.env`.

Aplicativo (`mobile/`):

- `dart format` e `flutter analyze`: sem problemas;
- `flutter test`: 104 testes aprovados. Novos cenários: tempo-limite da
  localização com escolha de região durante a espera, atalho "Início" e voltar
  do sistema, Meu perfil (nome, troca de senha com nova sessão, exclusão da
  conta) e explicação na demonstração, leitura da embalagem (preenchimento,
  progresso, outras leituras do nome, nome digitado preservado, foto sem
  texto, falha, desistência, ausência na edição e na demonstração), envio
  multipart com renovação após 401 e o fluxo conectado da Início até salvar;
- `flutter build web`: aprovado nos dois modos;
- capturas: 33 telas, incluindo Início conectada, escolha da foto, resultado
  da leitura, Meu perfil e "Obtendo sua localização…".

Backend (`backend/`):

- `pytest`: 49 testes aprovados; `ruff check` e `ruff format --check`:
  aprovados.

Integração real:

- `tool/e2e/api_contract_test.dart` contra a API em Docker: aprovado, agora
  com perfil, leitura de uma imagem em branco (resultado vazio) e exclusão da
  conta descartável. Com `ZELO_E2E_OCR_IMAGE` apontando para um rótulo
  sintético, a leitura devolveu nome e validade corretos e quantidade errada
  (ver `docs/scientific-evidence.md`);
- navegador real (Edge headless via DevTools): login com a conta de
  demonstração, "Escanear embalagem", "Escolher imagem" com o seletor de
  arquivos interceptado e formulário preenchido pela API;
- EcoMed real: inspeção de contrato e medição em 12 municípios
  (`docs/ecomed-integration.md`).

Não executado: Android (SDK ausente), fotos de embalagens reais, provocação de
limite e indisponibilidade na EcoMed real.

## Validação executada em 03/10/2026 (abertura, onboarding e celebrações)

- `dart format` e `flutter analyze`: sem problemas;
- `flutter test`: 117 testes aprovados. Novos cenários: a abertura começa no
  quadro da splash (símbolo centralizado), revela nome e slogan e um toque a
  encerra; a espera real reutiliza a assinatura; o onboarding tem cenas
  prontas sob redução de movimento, dispensa o Pular na última página e
  explica permissões; o carimbo do cadastro fecha sozinho, fecha com um toque,
  oferece "Cadastrar outro" e não aparece com redução de movimento; a
  celebração do descarte cobre a tela antes do conteúdo, mostra os números do
  registro, segue sozinha, segue antes com "Ver no histórico", espera a pessoa
  com leitor de tela e fica parada com redução de movimento; os fluxos de
  descarte (demonstração e conectado) terminam no Histórico;
- `flutter build web`: aprovado nos dois modos;
- capturas: 39 telas, incluindo quadros no meio das animações (carimbo,
  traço, varredura e "Mandou bem!");
- navegador real (Edge headless, build de demonstração): abertura, as três
  cenas do onboarding, entrada de demonstração e a celebração do descarte
  capturadas durante a animação. Com a acessibilidade do Flutter Web ligada
  pelo script, a celebração esperou o toque, como previsto para leitor de
  tela.

Correções após teste do responsável (03/10/2026):

- o aviso "… foi cadastrado." ficava aberto para sempre: no Flutter 3.47 um
  `SnackBar` com ação persiste por padrão. Agora usa `persist: false` e 6 s
  (com leitor de tela o Flutter continua mantendo-o aberto); há teste
  garantindo que some sozinho;
- o trajeto da celebração estava "torto": passava por dez pontos com curvas
  apertadas. Uma segunda versão com curvas largas ainda parecia traço à mão;
  a versão final é geométrica (retas a 0°, 90° e 45°, cantos de raio
  constante, laço em círculo perfeito), conferida nas capturas.

Não executado: Android (SDK ausente), avaliação com pessoas sobre o tempo das
animações.

## Build Android executado em 03/10/2026

- `flutter build apk --debug`: aprovado no modo demonstração e no modo
  conectado (`--dart-define=ZELO_API_URL=http://<IP da rede local>:8000`).
  O primeiro build levou cerca de 12 min (download do Gradle e dependências);
  os seguintes, cerca de 6 min.
- Falhas encontradas e corrigidas no caminho: tema do Android 12+ com
  `android:postSplashScreenTheme` (atributo inexistente; a troca de tema já é
  feita pelo `meta-data` NormalTheme) e cache incremental do Kotlin entre
  discos (desligado localmente, D041).
- `aapt2 dump badging`: pacote `br.edu.cesuca.zelo` 1.0.0, targetSdk 36,
  permissões somente `INTERNET` e `ACCESS_COARSE_LOCATION` (câmera e galeria
  pelo app do sistema, sem permissão de câmera).
- APKs de debug em `mobile/build/apk/` (fora do Git): demonstração (165 MB) e
  conectado (189 MB; debug inclui todas as arquiteturas e o modo JIT).

Não executado: instalação e uso em aparelho ou emulador (não há aparelho
conectado e a máquina não comporta um emulador com a RAM livre atual).

## OCR com fotos simuladas (03/10/2026)

Motivação: no teste do responsável com embalagens reais pelo iPhone, a leitura
com Tesseract ficou ruim. Método: `backend/scripts/ocr_benchmark.py` gera dois
conjuntos de 8 embalagens fictícias "fotografadas" com gabarito (perspectiva,
reflexo, pouca luz, desfoque, validade em pontinhos e texto girado na aba). O
conjunto de ajuste serviu para calibrar o interpretador; o de validação não foi
usado em nenhum ajuste. Ambos foram medidos pela API em Docker, com o mesmo
interpretador para os dois motores.

| Motor | Ajuste: nome / validade / quantidade | Validação: nome / validade / quantidade |
|---|---|---|
| Tesseract 5 | 6/8 · 6/8 · 8/8 | 7/8 · 4/8 · 7/8 |
| RapidOCR (PP-OCRv6) | 8/8 · 8/8 · 8/8 | 8/8 · 7/8 · 8/8 |

- Tempo por foto com RapidOCR: cerca de 1,1–1,4 s; com novas tentativas,
  2,5–2,7 s; o pior caso (validade não encontrada, seis leituras) levou 8,2 s.
- `pytest`: 57 testes aprovados, com interpretação de rótulos grudados,
  nomes de laboratório ignorados, sequência de novas tentativas e reserva
  entre motores.
- Limite: imagens sintéticas, mais fáceis que fotos reais (caixas curvas,
  plástico brilhante, letras miúdas). A taxa com embalagens reais continua
  PENDENTE.

## Lembretes de validade (03/10/2026)

- `flutter test`: 151 testes aprovados (34 novos):
  - planejador (`expiration_reminder_plan_test.dart`): 30 dias antes, 7 dias
    antes e no dia, às 9h; avisos passados ignorados; aviso das 9h ainda
    válido antes das 9h; agrupamento por data; ordem e limite de 60; textos e
    lista de nomes; virada de mês;
  - controlador (`reminder_controller_test.dart`): ligar pede a permissão,
    grava a escolha e agenda; permissão negada mantém desligado; desligar
    cancela; sem a lista carregada nada é reagendado (não apaga avisos
    válidos); mudanças na lista reagendam e pedidos simultâneos viram uma só
    passagem a mais; falha ao agendar não derruba; sair da conta apaga os
    avisos e mantém a escolha; permissão revogada bloqueia e devolvida
    reagenda; sem suporte nada é pedido;
  - tela e aplicativo (`reminders_flow_test.dart`): estados desligado,
    ligado com próximo aviso, sem aviso agendado, aviso de teste, permissão
    negada com atalho às configurações, bloqueado pelo sistema, sem suporte;
    no modo conectado, ligar em Conta agenda e o toque no aviso abre a lista
    "Próximo do vencimento", a escolha guardada reagenda ao entrar, aviso que
    abriu o aplicativo leva direto à lista e sair da conta apaga os avisos.
- `flutter build apk --debug` (conectado): aprovado em 4 min com o plugin e o
  desugaring. `aapt2 dump badging`: permissões `RECEIVE_BOOT_COMPLETED`,
  `POST_NOTIFICATIONS` (e `VIBRATE`, do plugin), além de internet e
  localização aproximada; o manifesto final traz `ScheduledNotificationReceiver`
  e `ScheduledNotificationBootReceiver`, e o recurso `ic_stat_zelo` está no
  APK.
- Falha encontrada e corrigida: `SharedPreferencesReminderPreferences` criava
  o armazenamento no construtor e quebrou 7 testes do modo conectado; passou
  a criá-lo só no primeiro uso.

**Não executado (PENDENTE, depende de aparelho Android):** ver o aviso de
teste na bandeja; ver um aviso agendado chegar às 9h; efeito de reiniciar o
aparelho; efeito da economia de bateria sobre alarmes inexatos; diálogo de
permissão do Android 13+; tocar no aviso com o aplicativo fechado; texto
escondido em tela bloqueada com senha.

## Evidências

Cada execução relevante deve registrar data, versão/commit, dispositivo ou
ambiente, massa de dados, passos, resultado esperado, resultado observado e
evidência associada. Falhas não devem ser ocultadas.

Métricas planejadas:

- tempo para concluir o primeiro acesso;
- tempo para cadastrar um medicamento;
- tempo para localizar um ponto;
- sucesso dos fluxos sem ajuda;
- percepção de clareza e facilidade;
- latência da API com cache frio e quente;
- quantidade de pontos retornados no recorte definido.

### Avaliação acadêmica futura

A avaliação de usabilidade está planejada com 12 adultos, mediante procedimento
acadêmico e consentimento aplicáveis. Os participantes executarão tarefas
orientadas do fluxo inicial, cadastro de medicamento e localização de ponto.
Serão registrados tempo, conclusão, erros e dificuldades, além da relação com o
SUS e respostas a perguntas abertas. Nenhum desses resultados foi coletado até
esta versão e todos permanecem `PENDENTE`.

## Comandos de qualidade

Aplicativo (pasta `mobile/`):

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
flutter test tool/screenshots/screens_test.dart      # capturas opcionais
$env:ZELO_E2E_API_URL = 'http://localhost:8000'
$env:ZELO_E2E_OCR_IMAGE = 'C:\caminho\rotulo.jpg'    # opcional: lê uma foto
flutter test tool/e2e/api_contract_test.dart         # contrato com a API real
```

Backend (pasta `backend/`):

```powershell
.\.venv\Scripts\python -m pytest
.\.venv\Scripts\ruff check .
.\.venv\Scripts\ruff format --check .
docker compose up --build -d
docker compose exec api python -m scripts.seed_demo
```

Com a chave EcoMed configurada:

```powershell
.\.venv\Scripts\python -m scripts.inspect_ecomed --detalhe --saida ..\artifacts\ecomed-contrato.json
```

A documentação relacionada deve ser revisada antes de considerar qualquer
cenário implementado ou marco concluído.
