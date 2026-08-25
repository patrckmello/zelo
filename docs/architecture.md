# Arquitetura

## Estado

Documento inicial. A separação de responsabilidades está confirmada; detalhes
de implementação permanecem planejados até serem validados em código.

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

## Aplicativo

Responsabilidades:

- interface, navegação, onboarding e formulários;
- gerenciamento visual da sessão;
- geolocalização e notificações, apenas no momento necessário;
- apresentação dos medicamentos, descartes e pontos;
- consumo exclusivo da API do Zelo;
- tratamento consistente de carregamento, sucesso, vazio e erro.

Organizacao inicial por funcionalidade:

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

As subcamadas `data`, `domain` e `presentation` serão criadas apenas quando uma
funcionalidade realmente precisar delas. Isso reduz cerimônia para uma equipe
de duas pessoas.

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
tempo de expiração do cache será configuravel.

## Dados iniciais

- usuário e credenciais protegidas;
- sessão ou token de renovação, conforme estratégia futura;
- Medicamento;
- configuração de notificação;
- Descarte e itens descartados;
- registros tecnicos estritamente necessarios;
- cache geográfico, que pode usar uma tecnologia definida no marco do backend.

## Restrições

- Android e o alvo prioritário do MVP;
- nenhum aconselhamento médico;
- nenhum segredo no aplicativo, Git ou logs;
- câmera e localização somente mediante contexto, explicacao e permissão;
- dados externos não confiáveis não podem ser apresentados como garantia;
- onboarding não deve solicitar permissões antecipadamente;
- animações devem respeitar redução de movimento.
