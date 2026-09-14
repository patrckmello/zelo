# Arquitetura

## Estado

A separação de responsabilidades está confirmada. O fluxo manual de
medicamentos já foi implementado e validado em memória. A splash Android e a
animação Flutter estão no código, com validação pendente; backend, persistência,
autenticação e integração EcoMed permanecem planejados.

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
→ bootstrap Flutter e animação curta
→ leitura do estado de onboarding
→ onboarding, se for primeiro acesso
→ leitura segura da sessão
→ login ou shell autenticada
~~~

A splash nativa cobre o período anterior à primeira renderização do Flutter.
A animação da marca pertence à camada Flutter e não deve bloquear operações
reais de inicialização. O estado de conclusão do onboarding não é sensível e
pode ser persistido localmente. Tokens de sessão são sensíveis e deverão usar
armazenamento seguro específico da plataforma.

### Recorte de abertura em validação

O Android usa `LaunchTheme` com fundo `#F4F7F6` e o símbolo da marca em um
recurso nativo. A primeira tela Flutter mantém o mesmo fundo, anima o PNG por
800 ms e então entrega o controle à `ZeloShell`. Com redução de movimento ativa,
a tela chama a conclusão no primeiro quadro e não executa a animação.

~~~text
LaunchTheme Android
  → BrandIntroPage Flutter
    → ZeloShell existente
~~~

Esse recorte ainda não lê onboarding nem sessão. Essas ramificações continuam
planejadas e serão inseridas entre a abertura da marca e a `ZeloShell`.

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
|   |-- storage/
|   |-- theme/
|   `-- widgets/
|-- features/
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
