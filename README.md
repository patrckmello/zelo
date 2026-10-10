# Zelo

> Cuide. Organize. Descarte certo.

O Zelo é um projeto acadêmico da disciplina de Projeto e Desenvolvimento de
Sistemas Móveis da CESUCA. O aplicativo apoia a organização de medicamentos
armazenados em casa, o acompanhamento de validade, a localização de pontos de
descarte responsável e o registro dos descartes realizados.

O projeto será apresentado na Mostra Científica da instituição. Funcionalidades
planejadas não devem ser tratadas como resultados comprovados.

## English summary

Zelo is an academic mobile application project from CESUCA focused on helping
people organize medicines stored at home, monitor expiration dates, find
appropriate collection points and record responsible disposals. The
Android-first app uses Flutter and Dart. A FastAPI backend with PostgreSQL now
provides real authentication, profile management and account deletion,
per-user medications, disposal history, assisted package reading (server-side
Tesseract OCR, always confirmed by the user) and an EcoMed client that keeps
the API key on the server and was checked against live responses. The app runs
either in a local demo mode (simulated session, in-memory data) or connected
to the API. Android device validation and usability evaluation remain
pending.

## Estado atual

- **Confirmado:** Flutter/Dart, Android como prioridade, API própria e uso
  autorizado da API EcoMed somente por meio do backend.
- **Implementado e verificado (02 e 03/10/2026):**
  - interface redesenhada com design system próprio (Poppins, tokens de cor
    com contraste AA, superfícies tonais) e assinatura visual da validade
    (carimbo `VAL`, faixa de situação e linha de validade);
  - backend FastAPI + PostgreSQL com autenticação real, medicamentos isolados
    por conta, recuperação de senha por código, descartes e histórico;
  - cliente EcoMed no backend, validado com respostas reais em 03/10/2026,
    com cache por coordenadas arredondadas, limite local de 60 req/min e
    normalização;
  - aplicativo nos modos **demonstração** e **conectado**, com token de
    renovação em armazenamento seguro, busca de pontos por localização
    aproximada (com tempo-limite) ou região e abertura do ponto em aplicativo
    de mapas;
  - Meu perfil (nome, e-mail, senha) e exclusão da conta com todos os dados;
  - leitura da embalagem por foto (OCR no servidor), que só preenche o
    cadastro para a pessoa conferir;
  - lembretes de validade locais (30 dias antes, 7 dias antes e no dia, às 9h),
    ligados pela pessoa em Conta, só no aplicativo Android;
  - abertura com nome e slogan, onboarding com cenas animadas e celebrações
    no cadastro (carimbo de validade) e no descarte (trajeto que varre a tela,
    inspirado no Strava).
- **Validações executadas (03/10/2026):** 151 testes Flutter, 57 testes do
  backend, lint, build Web nos dois modos, Docker Compose com PostgreSQL,
  teste de contrato do app contra a API real, login e leitura de embalagem em
  navegador real (Edge) e medição da EcoMed em 12 municípios da RMPA.
- **Pendente:** validação em dispositivo Android (o APK de debug já é gerado), provedor de
  e-mail para recuperação de senha, notificações de validade, avaliação da
  leitura com fotos reais, textos jurídicos, reconciliação no Figma e
  avaliação com participantes.
- **Fora do núcleo inicial:** mapa embutido.

## Como funciona

~~~text
Splash nativa → animação do símbolo (bootstrap em paralelo)
→ onboarding no primeiro acesso → login, cadastro ou recuperação
→ Início | Descartar | Histórico | Conta
~~~

- **Início:** painel da farmácia com a data de referência, barra de composição
  por situação, itens que precisam de atenção e ações rápidas (cadastrar,
  escanear embalagem no modo conectado e encontrar ponto de descarte).
- **Medicamentos:** lista com filtros por situação, detalhe com linha de
  validade, cadastro e edição com prévia da situação; no modo conectado, o
  cadastro pode ser preenchido pela foto da embalagem, sempre com conferência.
- **Descartar:** vencidos separados, registro de descarte e busca de pontos
  (farmácias LogMed primeiro; demais pontos com aviso para confirmar por
  telefone; atribuição EcoMed sempre visível). Se a localização não chegar,
  a tela oferece escolher uma região; aberta pela Início, volta a ela.
- **Histórico:** descartes registrados com local, data e itens.
- **Conta:** identificação da sessão, Meu perfil (modo conectado),
  informações do projeto, licenças e saída.

Modo demonstração (padrão): sessão simulada, dados fictícios em memória e
nenhuma consulta de pontos. Modo conectado: compile o app com
`--dart-define=ZELO_API_URL=<url da API>`.

## Tecnologias

- Aplicativo: Flutter 3.47.1, Dart 3.13.1, Material 3 e Poppins (SIL OFL 1.1);
- Pacotes do app: `shared_preferences`, `http`, `flutter_secure_storage`,
  `geolocator`, `url_launcher`, `image_picker` e `flutter_local_notifications`;
- Backend: Python 3.13, FastAPI, SQLAlchemy 2.1, Alembic, Argon2, PyJWT,
  Pillow e OCR com RapidOCR (modelos PP-OCRv6, ONNX) e Tesseract 5 como
  reserva, na imagem Docker;
- Dados: PostgreSQL 17;
- Infraestrutura local: Docker Compose;
- Plataforma prioritária: Android.

## Estrutura

```text
Zelo/
|-- mobile/       # Aplicativo Flutter
|-- backend/      # API Zelo (FastAPI, PostgreSQL, Docker Compose)
|-- docs/         # Arquitetura, requisitos, decisões, testes e evidências
|-- AGENTS.md     # Regras obrigatórias para agentes
|-- README.md
`-- Zelo_Documentacao_Inicial.docx
```

## Documentação viva

Código, decisões e documentação evoluem juntos. Toda mudança de requisito,
escopo, arquitetura, integração, teste ou estado de implementação atualiza os
arquivos relacionados no mesmo ciclo de trabalho. As regras obrigatórias estão
em [AGENTS.md](AGENTS.md); o design system está em
[docs/design-system.md](docs/design-system.md).

## Pré-requisitos

- Git;
- Flutter SDK estável (o SDK portátil fica em `.tools/flutter`, não versionado);
- Docker Desktop com Docker Compose (backend);
- Python 3.13 (opcional, para rodar o backend fora do Docker);
- JDK 17 e Android SDK (plataforma 36, build-tools 36, NDK 28.2); neste
  ambiente ficam em `.tools/jdk-17` e `.tools/android-sdk`, fora do Git
  (D041).

## Variáveis de ambiente

Segredos nunca são versionados. O backend lê `backend/.env` (modelo em
`backend/.env.example`). A chave EcoMed fica **somente** nesse arquivo:

```text
ECOMED_API_KEY=<sua chave>
```

Não envie a chave pelo aplicativo, pelo chat, por commits ou por logs.

## Como executar

Backend (na pasta `backend/`, detalhes em [backend/README.md](backend/README.md)):

```powershell
docker compose up --build -d
docker compose exec api python -m scripts.seed_demo
```

Aplicativo em modo demonstração (pasta `mobile/`):

```powershell
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat run -d chrome
```

Aplicativo conectado à API local:

```powershell
# Navegador (Chrome ou Edge)
..\.tools\flutter\bin\flutter.bat run -d edge --dart-define=ZELO_API_URL=http://localhost:8000
# Emulador Android
..\.tools\flutter\bin\flutter.bat run --dart-define=ZELO_API_URL=http://10.0.2.2:8000
```

Em celular físico, use o IP do computador na rede local. HTTP sem TLS só é
aceito em builds de debug; fora do ambiente local, use HTTPS (RNF05).

Se o navegador ficar com a tela branca, veja a seção "Se a tela ficar branca
no navegador" em [mobile/README.md](mobile/README.md); para apenas ver o app,
o build de release servido na raiz é o caminho mais estável.

A conta de demonstração do backend usa `ZELO_DEMO_EMAIL` e
`ZELO_DEMO_PASSWORD` do `backend/.env`.

## Testes

```powershell
# Aplicativo (mobile/)
..\.tools\flutter\bin\dart.bat format --output=none --set-exit-if-changed .
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test

# Backend (backend/)
.\.venv\Scripts\python -m pytest
.\.venv\Scripts\ruff check .
```

Também existem um teste de contrato opcional do app contra a API real
(`mobile/tool/e2e`) e um gerador de capturas de tela determinísticas
(`mobile/tool/screenshots`). O plano completo está em
[docs/testing-plan.md](docs/testing-plan.md).

## Próximos passos

1. Instalar o APK de debug num celular e validar splash, permissões de
   localização, câmera/galeria, armazenamento seguro e abertura de mapas em
   Android 12+ (ver `mobile/README.md`).
2. Validar os lembretes de validade (RF06, já implementados) num aparelho
   Android: aviso de teste, aviso agendado e reinício.
3. Avaliar a leitura da embalagem com fotos reais e registrar acertos e
   correções.
4. Definir provedor de e-mail para a recuperação de senha e hospedagem com
   HTTPS.
5. Reconciliar as telas no Figma, aprovar os textos jurídicos e aplicar o
   protocolo de usabilidade.
6. Decidir sobre lembretes de uso e reposição (D039) e leitura de receitas
   (D040).

Consulte [docs/backlog.md](docs/backlog.md) para os marcos.
