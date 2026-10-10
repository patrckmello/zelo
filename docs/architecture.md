# Arquitetura

## Estado

Implementado e verificado até 03/10/2026: aplicativo Flutter com design system
próprio e dois modos de execução (D029), backend FastAPI com PostgreSQL,
autenticação real, perfil e exclusão de conta, medicamentos isolados por
conta, leitura assistida da embalagem (Tesseract no servidor), descartes com
histórico e cliente EcoMed validado com respostas reais. Pendentes: validação
em Android, provedor de e-mail, hospedagem com HTTPS e notificações de
validade.

## Visão de contexto

```text
usuário
  |
  v
Aplicativo Flutter (Android; também verificado na Web)
  |
  | HTTPS fora do ambiente local, somente API Zelo
  v
Backend Zelo (FastAPI) ── Tesseract (OCR local, imagem só em memória)
  |                     |
  v                     v
PostgreSQL          API EcoMed (X-API-Key só no servidor)
```

O aplicativo nunca acessa diretamente a EcoMed. O backend protege a chave,
estabiliza o contrato consumido pelo aplicativo, normaliza dados, guarda em
cache e controla o limite compartilhado de requisições.

## Aplicativo

### Organização

```text
lib/
|-- app/
|   |-- app_config.dart        # ZELO_API_URL → demonstração ou conectado
|   |-- zelo_app.dart          # raiz de composição
|   |-- zelo_shell.dart        # Início | Descartar | Histórico | Conta
|   `-- bootstrap/             # abertura, bootstrap e roteamento raiz
|-- core/
|   |-- formatting/            # datas em português
|   |-- network/               # ZeloApiClient (sessão, renovação, erros)
|   |-- platform/              # mapas e telefone (url_launcher)
|   |-- storage/               # onboarding, sessão simulada, token seguro
|   |-- theme/                 # cores, tokens e ZeloTheme
|   `-- widgets/               # layout, estados, avisos, esqueletos, cenas
`-- features/
    |-- account/               # Conta, Meu perfil, exclusão da conta
    |-- authentication/        # domínio, simulação, API e telas de entrada
    |-- collection_points/     # domínio, localização, API, controlador, telas
    |-- disposal_history/      # domínio, memória/API, estado, registro, histórico
    |-- home/                  # Início
    |-- medications/           # domínio, memória/API, leitura da embalagem,
    |                          # estado, telas e widgets
    `-- onboarding/
```

Cada funcionalidade separa domínio (modelos e contratos), dados (implementações
em memória e pela API), estado (`ChangeNotifier`) e apresentação. As telas não
conhecem a origem dos dados.

### Composição por modo

| Dependência | Demonstração | Conectado |
|---|---|---|
| `AuthenticationService` | `SimulatedAuthenticationService` | `ApiAuthenticationService` |
| `MedicationRepository` | `InMemoryMedicationRepository` (fictícios) | `ApiMedicationRepository` |
| `DisposalRepository` | `InMemoryDisposalRepository` | `ApiDisposalRepository` |
| `CollectionPointsRepository` | ausente (estado "não configurado") | `ApiCollectionPointsRepository` |
| `AccountService` | ausente (Conta explica que o perfil exige conta) | `ApiAccountService` |
| `MedicationScanner` | ausente (sem botão de leitura) | `ImagePickerCapture` + `ApiMedicationScanService` |
| `ReminderController` | ausente (Conta não mostra Lembretes) | `LocalReminderService` + `SharedPreferencesReminderPreferences` |
| Sessão persistida | `simulated_session_active` | token de renovação no armazenamento seguro |

`LocationProvider` (`geolocator`) e `ExternalActions` (`url_launcher`) são
comuns aos dois modos e substituídos por versões falsas nos testes.

### Inicialização e roteamento

~~~text
Splash nativa estática (LaunchTheme, fundo #F4F7F6)
→ AppLaunchFlow
  ├─ BrandIntroPage (1,3 s + dissolução; toque encerra; pronta sob redução
  │  de movimento)
  └─ AppBootstrapFlow + BootstrapController em paralelo
       ├─ primeiro acesso → OnboardingPage
       ├─ sem sessão → LoginPage / RegisterPage / PasswordRecoveryPage
       ├─ sessão válida → ZeloShell
       └─ falha → erro recuperável
~~~

`BootstrapController` compartilha cargas concorrentes e ignora conclusões após
o descarte. Login, cadastro, logout e conclusão do onboarding substituem o
conteúdo da rota raiz. No modo conectado, `restoreSession` usa o token de
renovação guardado; falha de rede mostra o erro recuperável.

### Estado compartilhado

- `MedicationStore`: cópia ordenada dos medicamentos, status
  (`idle/loading/ready/failure`), carga deduplicada, `refresh` sem trocar a
  lista por carregamento e mensagens seguras para falhas. Uma geração
  incremental descarta respostas obsoletas após `clear()`.
- `DisposalStore`: histórico com o mesmo padrão.
- `CollectionPointsController`: busca por localização ou região, arredonda as
  coordenadas, ignora respostas de buscas substituídas e expõe a fase
  (`idle/locating/loading/loaded/failure`).

O shell carrega medicamentos e histórico após o primeiro quadro. Logout e
sessão expirada limpam os dois estados; a expiração também fecha rotas
empilhadas antes de mostrar o login.

### Sessão no modo conectado

~~~text
login/cadastro → access (memória) + refresh (armazenamento seguro)
requisição autenticada → 401?
  └─ POST /v1/auth/refresh (uma vez, compartilhada entre chamadas)
       ├─ sucesso → repete a requisição
       └─ falha → limpa tokens → sessionExpirations → login com aviso
logout → descarta tokens locais → POST /v1/auth/logout (melhor esforço)
troca de senha → servidor revoga as sessões → app adota o novo par de tokens
exclusão da conta → servidor apaga tudo → app descarta os tokens → login
~~~

O envio da foto (`upload`, multipart) usa a mesma renovação após 401 e um
tempo-limite próprio de 45 s.

### Pontos de coleta

~~~text
"Usar minha localização" (explicação prévia)
→ permissão aproximada → posição → arredonda a 3 casas
→ GET /v1/collection-points/nearby
→ farmácias LogMed | outros pontos com aviso | atribuição
→ detalhe → abrir no mapa (geo: / OpenStreetMap), ligar ou registrar descarte
~~~

A alternativa "Escolher uma região" usa a sede de um município da Região
Metropolitana de Porto Alegre e dispensa a localização. A leitura da posição
tem tempo-limite (15 s no provedor, 30 s no controlador); durante a espera e
em qualquer falha a tela oferece a escolha de região (D033). Aberta pelo
atalho da Início, Descartar mostra "Início" no cabeçalho para voltar.

### Celebração do descarte

~~~text
RegisterDisposalPage salva → onRegistered(registro, centro do botão)
→ ZeloShell insere DisposalCelebration no Overlay raiz
  ├─ traço nasce no botão e varre a tela (≈0,7 s)
  ├─ tela coberta → shell fecha as rotas de registro e seleciona Histórico
  ├─ "Mandou bem!" com o trajeto animado ao fundo
  └─ 3,2 s ou toque → camada se dissolve → registro novo sobe em destaque
~~~

Com leitor de tela ativo a camada espera o toque; com redução de movimento,
aparece pronta. O cadastro de medicamento novo usa uma rota transparente curta
(carimbo) e depois o aviso com "Cadastrar outro".

### Lembretes de validade

~~~text
Conta → Lembretes → liga → permissão de notificações (Android 13+)
→ ReminderController grava a escolha e planeja os avisos
   (30 dias antes, 7 dias antes e no dia, às 9h, agrupados por data)
→ LocalReminderService agenda alarmes inexatos no aparelho
MedicationStore muda (cadastro, edição, remoção, descarte, carga)
→ ReminderController reagenda (só com a lista carregada; pedidos
  simultâneos viram uma única passagem)
sair da conta / sessão expirada / conta excluída → cancela tudo
toque no aviso (aberto, em segundo plano ou fechado) → lista "Próximo do
vencimento"
~~~

O planejamento é uma função pura (`planExpirationReminders`), testada sem
plugin; o serviço fica atrás de `ReminderService` e é substituído por um falso
nos testes. Sem suporte (navegador) ou sem o plugin, o controlador assume
"indisponível" e o restante do aplicativo segue.

### Leitura da embalagem

~~~text
"Escanear embalagem" (Início) ou "Preencher pela embalagem" (cadastro)
→ câmera ou galeria (image_picker, até 2400 px, JPEG 85)
→ POST /v1/ocr/medication (multipart, autenticado)
→ sugestões: nomes, validade, quantidade
→ formulário preenchido + aviso "Confira os dados lidos antes de salvar"
→ pessoa corrige e salva (nenhum salvamento automático)
~~~

## Backend

### Organização

```text
backend/
|-- app/
|   |-- main.py            # create_app (fábrica), CORS e rotas
|   |-- config.py          # Settings lidas do .env
|   |-- container.py       # dependências compartilhadas
|   |-- database.py        # engine e sessões SQLAlchemy
|   |-- models.py          # tabelas
|   |-- schemas.py         # contratos Pydantic
|   |-- security.py        # Argon2id, JWT e tokens opacos
|   |-- errors.py          # erros estáveis sem dados internos
|   |-- dependencies.py    # sessão do banco e usuário autenticado
|   |-- routers/           # health, auth, account, medications, disposals,
|   |                      # collection_points, ocr
|   `-- services/          # ecomed, geo_cache, rate_limiter, password_reset,
|                          # sessions, medication_ocr
|-- alembic/               # migrações (0001 estrutura inicial)
|-- scripts/               # seed_demo, inspect_ecomed
|-- tests/                 # pytest com SQLite e EcoMed simulada
`-- docker-compose.yml     # PostgreSQL 17 + API
```

### Responsabilidades implementadas

- cadastro, login com limite de tentativas, renovação com rotação e detecção de
  reuso, logout, recuperação de senha com código de uso único;
- perfil: consulta com contagens, troca de nome, de e-mail e de senha (com
  senha atual e limite de tentativas) e exclusão da conta em cascata;
- medicamentos ativos por conta, com validação e 404 para itens de outra conta;
- leitura da embalagem: validação de tipo e tamanho, preparo da imagem
  (orientação EXIF, tons de cinza, 1600–2400 px, contraste), RapidOCR
  (PP-OCRv6, ONNX) com Tesseract como reserva, novas tentativas desfocada e
  girada quando a validade não aparece, e interpretação de nome, validade e
  quantidade; limite de 20 leituras por minuto por conta;
- descartes com cópia dos itens e retirada da farmácia ativa;
- pontos de coleta: cache, limite local, normalização, origem e atribuição;
- erros no formato `{"error": {"code", "message"}}`, sem ecoar dados enviados;
- logs sem segredos, tokens ou coordenadas;
- verificação de saúde com estado do banco, da configuração EcoMed e da
  disponibilidade do OCR.

### Fluxo de pontos no servidor

~~~text
GET /v1/collection-points/nearby (autenticado)
→ chave do cache: (lat 3 casas, lng 3 casas, raio)
   ├─ acerto → resposta normalizada (cache: "hit")
   └─ falta → limitador local (60/min)
        ├─ excedido → 503 collection_points_rate_limited + Retry-After
        └─ EcoMed /pontos/proximos com X-API-Key
             ├─ 200 → normaliza, guarda por 300 s, devolve (cache: "miss")
             ├─ 401/403 → 502 (registra "chave recusada", sem a chave)
             ├─ 429 → 503 com Retry-After
             └─ timeout/rede/JSON inválido → 504/502
Sem ECOMED_API_KEY → 503 collection_points_not_configured
~~~

### Modelo de dados

```text
users (id, name, email único, password_hash, created_at)
refresh_sessions (user_id, token_hash único, expires_at, revoked_at)
password_reset_tokens (user_id, token_hash único, expires_at, used_at)
medications (user_id, name, expiration_date, quantity > 0, notes,
             disposed_at, disposal_id)
disposals (user_id, disposed_on, point_external_id, point_name,
           point_address, notes)
disposal_items (disposal_id, position, medication_name, quantity,
                expiration_date)
```

Os pontos EcoMed não são persistidos: ficam apenas no cache em memória com
expiração configurável (`ECOMED_CACHE_TTL_SECONDS`). Fotos de embalagens também
não: existem só durante a requisição.

## Restrições

- Android é o alvo prioritário do MVP;
- nenhum aconselhamento médico;
- nenhum segredo no aplicativo, Git ou logs;
- câmera e localização somente mediante contexto, explicação e permissão;
- dados externos não confiáveis não podem ser apresentados como garantia;
- onboarding não solicita permissões;
- animações respeitam redução de movimento;
- HTTP sem TLS somente no manifesto de debug do Android.
