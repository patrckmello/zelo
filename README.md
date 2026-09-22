# Zelo

> Cuide. Organize. Descarte certo.

O Zelo é um projeto acadêmico da disciplina de Projeto e Desenvolvimento de
Sistemas Móveis da CESUCA. O aplicativo apoiará a organização de medicamentos
armazenados em casa, o acompanhamento de validade e a localização de pontos de
descarte responsável.

O projeto está no início do desenvolvimento e será apresentado na Mostra
Científica da instituição. Funcionalidades planejadas não devem ser tratadas
como resultados comprovados.

## English summary

Zelo is an academic mobile application project from CESUCA focused on helping
people organize medicines stored at home, monitor expiration dates, and find
appropriate collection points for responsible disposal. The Android-first MVP
uses Flutter and Dart, supported in the future by a dedicated backend that
protects the EcoMed API key and provides normalized, cached collection-point
data. The repository includes an in-memory medication flow plus a three-page
onboarding and replaceable simulated authentication. Real authentication,
backend persistence, EcoMed integration, and Android device validation remain
planned or pending.

## Estado atual

- **Confirmado:** Flutter/Dart, Android como prioridade, API própria e uso
  autorizado da API EcoMed por meio do backend.
- **Implementado e verificado:** repositório, documentação, scaffold Flutter,
  tema Material 3, fluxo manual de medicamentos em memória, animação Flutter,
  bootstrap recuperável, onboarding e autenticação simulada substituível.
- **Persistido localmente:** somente `onboarding_completed` e o marcador booleano
  não sensível `simulated_session_active`, por meio de `shared_preferences`.
- **Verificado em 21/09/2026:** formatação, análise estática, 47 testes
  automatizados e build Web com Flutter 3.47.1/Dart 3.13.1.
- **Pendente no ambiente atual:** Android SDK, JDK 17 e dispositivo/emulador para
  validar a splash nativa e a transição Android → Flutter.
- **Planejado para o M4:** autenticação real, isolamento entre usuários,
  armazenamento seguro de tokens, backend e persistência de medicamentos.
- **Fora do núcleo inicial:** OCR e mapa embutido.

## Fluxo inicial implementado

~~~text
Splash nativa estática
→ primeira renderização Flutter
  ├─ animação curta do símbolo
  └─ bootstrap recuperável em paralelo
→ verificar primeiro acesso
→ onboarding, quando necessário
→ verificar sessão
→ login ou página inicial
~~~

A splash usa fundo monocromático e o símbolo do Zelo. A animação Flutter de
800 ms exibe somente o símbolo oficial e ocorre em paralelo à leitura do
onboarding e da sessão. Se a leitura ainda estiver em andamento ao fim da
animação, o aplicativo mostra o carregamento real e discreto; não há espera
artificial. A animação é ignorada quando o sistema solicita redução de
movimento.

O onboarding apresenta organização, prevenção de desperdício e descarte
responsável por meio de composições vetoriais simples e do ativo oficial, sem
redesenhar a marca. Câmera, localização e notificações não são solicitadas
nesse fluxo.

A autenticação desta versão é deliberadamente simulada. Login, cadastro,
recuperação, restauração de sessão e logout exercitam a interface e a navegação,
mas não representam proteção de conta. Nenhuma senha, nome ou e-mail é
persistido; o aplicativo salva apenas um booleano de sessão de demonstração.

A navegação autenticada possui **Início**, **Descartar**, **Histórico** e
**Conta**. Medicamentos continua acessível por “Ver todos” e pelas ações de
cadastro da Home, sem aba exclusiva. Descartar informa que a EcoMed ainda será
integrada; Histórico permanece sem persistência real e inicia vazio; Conta
identifica a sessão simulada, não exibe dados pessoais e concentra o logout.

## Tecnologias planejadas

- Aplicativo: Flutter, Dart e Material 3;
- Preferências locais não sensíveis: `shared_preferences 2.5.5`;
- Backend: Python, FastAPI, SQLAlchemy e Alembic;
- Dados: PostgreSQL;
- Infraestrutura local: Docker Compose;
- Plataforma prioritária: Android;
- Desenvolvimento: Visual Studio Code e Git.

## Estrutura

```text
Zelo/
|-- mobile/       # Aplicativo Flutter
|-- backend/      # API própria (implementação futura)
|-- docs/         # Arquitetura, requisitos, decisões e evidências
|-- AGENTS.md     # Regras obrigatórias para agentes
|-- README.md
`-- Zelo_Documentacao_Inicial.docx
```

## Documentação viva

Código, decisões e documentação devem evoluir juntos. Toda mudança de requisito,
escopo, arquitetura, integração, teste ou estado de implementação deverá
atualizar os arquivos relacionados no mesmo ciclo de trabalho. As regras
obrigatórias estão em [AGENTS.md](AGENTS.md).

## Pré-requisitos

Para o aplicativo:

- Git;
- Flutter SDK estável, com Dart incluído;
- Android Studio ou Android SDK com platform-tools;
- JDK 17;
- Visual Studio Code com extensões Flutter e Dart.

Para o backend, quando ele for iniciado:

- Python 3.12 ou versão validada pelo projeto;
- Docker Desktop com Docker Compose, preferencialmente.

Depois de instalar o ambiente Android, execute:

```powershell
flutter doctor -v
flutter doctor --android-licenses
```

## Variáveis de ambiente

Segredos nunca devem ser versionados. A futura chave EcoMed permanecerá apenas
no backend, em arquivo `.env` local ignorado pelo Git. O repositório fornecerá
somente um `.env.example` sem valores secretos quando o backend for criado.

Não envie a chave EcoMed pelo aplicativo Flutter, pelo chat, por commits ou por
logs. O contrato real da API deverá ser inspecionado antes da implementação.

## Como executar o aplicativo

O SDK Flutter portátil restaurado deve ficar em `.tools/flutter` e não é
versionado. Com ele, execute pela raiz do repositório:

```powershell
cd mobile
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat run -d chrome
```

Para usar uma instalação global, substitua o caminho por `flutter`. O
identificador Android provisório é `br.edu.cesuca.zelo`.

## Como executar o backend

O backend ainda não foi implementado. As instruções reais serão adicionadas no
marco correspondente; não há comandos fictícios de execução nesta versão.

## Testes

Com o SDK portátil:

```powershell
cd mobile
..\.tools\flutter\bin\dart.bat format --output=none --set-exit-if-changed .
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test
```

O plano completo está em [docs/testing-plan.md](docs/testing-plan.md). A suíte
possui 47 testes aprovados em 21/09/2026. Ela cobre a abertura, redução de
movimento, bootstrap paralelo, onboarding, autenticação simulada, os quatro
destinos autenticados, acesso a Medicamentos pela Home, responsividade essencial
e o fluxo manual de medicamentos. Os dados dos medicamentos permanecem somente
em memória e são reiniciados quando o aplicativo é fechado.

## Próximos passos

1. Instalar ou disponibilizar Android SDK e JDK 17.
2. Validar a splash e a transição em Android 12+ real ou emulador, inclusive sem
   quadro branco, distorção ou recorte.
3. Desenhar e reconciliar no Figma onboarding, login, cadastro e recuperação.
4. Fornecer e aprovar os textos jurídicos de termos e política de privacidade.
5. Iniciar backend, persistência e autenticação real no M4.
6. Integrar o fluxo de medicamentos à API Zelo sem alterar as regras testadas.
7. Adicionar Poppins quando os arquivos licenciados da fonte forem fornecidos.

Consulte [docs/backlog.md](docs/backlog.md) para os marcos posteriores.
