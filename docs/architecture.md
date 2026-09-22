# Arquitetura

## Estado

A separação de responsabilidades está confirmada. O fluxo manual de
medicamentos, a animação Flutter, o bootstrap paralelo, o onboarding, a
autenticação simulada e a navegação autenticada com quatro destinos foram
implementados e validados por testes. A splash Android ainda depende de
validação no dispositivo; backend, autenticação real, persistência de
medicamentos, histórico de descartes e integração EcoMed permanecem planejados.

## Visão de contexto

```text
usuário
  |
  v
Aplicativo Flutter (Android)
  |
  | HTTPS, somente API Zelo
  v
Backend Zelo (FastAPI)
  |                     |
  v                     v
PostgreSQL          API EcoMed
```

O aplicativo nunca acessa diretamente a EcoMed. O backend protege a chave,
estabiliza o contrato consumido pelo aplicativo, normaliza dados e controla o
limite compartilhado de requisições.

## Inicialização e roteamento

~~~text
Splash nativa estática
→ primeira renderização Flutter
  ├─ animação curta do símbolo
  └─ bootstrap centralizado em paralelo
       ├─ leitura de onboarding_completed
       └─ leitura de simulated_session_active, quando aplicável
→ onboarding, login, shell autenticada ou erro recuperável
~~~

A splash nativa cobre o período anterior à primeira renderização do Flutter.
A animação da marca pertence à camada Flutter. `AppLaunchFlow` mantém
`AppBootstrapFlow` montado sob a abertura para que as leituras comecem no
primeiro quadro, sem bloqueio ou atraso artificial. O estado de conclusão do
onboarding não é sensível e é persistido localmente. A sessão do M2 é apenas um
booleano de demonstração e não equivale a um token. Tokens reais são sensíveis
e deverão usar armazenamento seguro no M4.

### Abertura implementada

O Android usa `LaunchTheme` com fundo `#F4F7F6` e o símbolo da marca em um
recurso nativo. A primeira tela Flutter mantém o mesmo fundo e anima somente o
PNG oficial por 800 ms, sem nome ou slogan. Com redução de movimento ativa, a
tela chama a conclusão no primeiro quadro e não executa a animação.

~~~text
LaunchTheme Android
  → AppLaunchFlow
    ├─ BrandIntroPage Flutter
    └─ BootstrapController em paralelo
      ├─ primeiro acesso → OnboardingPage
      ├─ sem sessão → LoginPage
      ├─ sessão simulada → ZeloShell
      └─ falha → erro recuperável
~~~

`BootstrapController` depende apenas de `OnboardingPreferences` e
`AuthenticationService`, recebidos por construtor. Enquanto uma carga está em
andamento, chamadas adicionais compartilham a mesma operação; conclusões após
`dispose` são ignoradas. O estado de erro não expõe a exceção interna e permite
repetir a leitura. Login, cadastro, logout e conclusão do onboarding substituem
o conteúdo da rota raiz, impedindo retorno indevido ao fluxo anterior.

### Preferências e autenticação simulada

`SharedPreferencesOnboardingPreferences` persiste somente
`onboarding_completed`. `SharedPreferencesSessionStore` persiste somente
`simulated_session_active`. As abstrações são separadas do `MedicationStore` e
possuem implementações em memória nos testes.

`AuthenticationService` define restauração, login, entrada de demonstração,
cadastro, recuperação e logout. `SimulatedAuthenticationService` não cria conta,
não envia e-mail, não persiste credenciais e não emite token. Uma implementação
futura consumirá exclusivamente a API Zelo no M4.

## Aplicativo

Responsabilidades:

- interface, navegação, onboarding e formulários;
- gerenciamento visual da sessão;
- geolocalização e notificações, apenas no momento necessário;
- apresentação dos medicamentos, descartes e pontos;
- consumo exclusivo da API do Zelo;
- tratamento consistente de carregamento, sucesso, vazio e erro.

Organização por funcionalidade:

```text
lib/
|-- app/
|   |-- bootstrap/
|   `-- routing/
|-- core/
|   |-- config/
|   |-- constants/
|   |-- errors/
|   |-- network/
|   |-- storage/       # onboarding e marcador de sessão, separados
|   |-- theme/
|   `-- widgets/
|-- features/
|   |-- account/
|   |-- onboarding/
|   |-- authentication/
|   |-- medications/
|   |-- collection_points/
|   |-- disposal_history/
|   `-- settings/
`-- main.dart
```

As subcamadas são criadas quando uma funcionalidade realmente precisa delas.
Isso reduz cerimônia para uma equipe de duas pessoas.

### Navegação autenticada

`ZeloShell` mantém quatro áreas em um `IndexedStack` e uma única
`NavigationBar`: Início, Descartar, Histórico e Conta. Descartar ainda informa a
dependência da EcoMed sem fabricar pontos; Histórico apresenta estado vazio sem
persistência; Conta identifica a sessão simulada, não exibe dados pessoais e
contém o logout.

Medicamentos não pertence à barra inferior. A Home abre `MedicationsPage` como
rota por “Ver todos”, e as ações de cadastro continuam usando o mesmo formulário
e o mesmo `MedicationStore`.

### Fluxo de medicamentos implementado

`ZeloApp` cria um único `MedicationStore`, baseado em `ChangeNotifier`, e o
compartilha com a página inicial e as telas de medicamentos. O modelo de domínio
centraliza a classificação por validade e não depende da interface.

~~~text
ZeloApp
  → MedicationStore em memória
    → página inicial e resumo
    → lista de medicamentos
    → formulário de cadastro e edição
    → detalhes e remoção
~~~

O armazenamento em memória contém dados iniciais para demonstração e oferece
operações de cadastro, atualização, busca e remoção. A persistência será
substituída por um repositório conectado à API Zelo no M4, sem duplicar a regra
de validade nas telas.

Medicamentos são considerados dados indiretos de saúde. Nenhuma tela ou serviço
novo registra medicamentos, senha, nome ou e-mail em logs. A autenticação
simulada não é usada como chave de particionamento dos medicamentos; isolamento
real entre usuários depende do backend do M4.

## Backend

Responsabilidades planejadas:

- cadastro, autenticação, autorização e recuperação de senha;
- emissão, renovação e revogação de sessão;
- validação e regras de negócio;
- persistência e migrações;
- integração EcoMed e tratamento de rate limit;
- cache geográfico com latitude/longitude arredondadas a três casas;
- normalização de tipos de resíduos e classificação da origem;
- erros estáveis, observabilidade sem dados sensíveis e auditoria técnica.

Os pontos EcoMed não serão persistidos permanentemente no primeiro momento. O
tempo de expiração do cache será configurável.

## Dados iniciais

- usuário e credenciais protegidas;
- sessão ou token de renovação, conforme estratégia futura;
- Medicamento;
- configuração de notificação;
- Descarte e itens descartados;
- registros técnicos estritamente necessários;
- cache geográfico, que pode usar uma tecnologia definida no marco do backend.

## Restrições

- Android é o alvo prioritário do MVP;
- nenhum aconselhamento médico;
- nenhum segredo no aplicativo, Git ou logs;
- câmera e localização somente mediante contexto, explicação e permissão;
- dados externos não confiáveis não podem ser apresentados como garantia;
- onboarding não deve solicitar permissões antecipadamente;
- animações devem respeitar redução de movimento.
