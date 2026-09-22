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

- criação de conta e prevenção de e-mail duplicado;
- autenticação válida e rejeição de credenciais incorretas;
- hash de senha e ausência de senha ou token em logs;
- recuperação de senha com token temporário;
- renovação, expiração e revogação de sessão;
- regras de autorização e isolamento dos dados do usuário;
- validação das operações de medicamento e descarte;
- migrações em banco limpo;
- normalização das respostas EcoMed com fixtures anonimizadas;
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
9. registrar e consultar um descarte.

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

## Comandos de qualidade do Flutter

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```

A documentação relacionada deve ser revisada antes de considerar qualquer
cenário implementado ou marco concluído.
