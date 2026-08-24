# Arquitetura

## Estado

Documento inicial. A separacao de responsabilidades esta confirmada; detalhes
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

## Aplicativo

Responsabilidades:

- interface, navegação e formulários;
- geolocalização e notificações, apenas no momento necessário;
- apresentação dos medicamentos, descartes e pontos;
- consumo exclusivo da API do Zelo;
- tratamento consistente de carregamento, sucesso, vazio e erro.

Organizacao inicial por funcionalidade:

```text
lib/
|-- app/
|-- core/
|   |-- config/
|   |-- constants/
|   |-- errors/
|   |-- network/
|   |-- theme/
|   `-- widgets/
|-- features/
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

- autenticação e autorização;
- validação e regras de negócio;
- persistência e migrações;
- integração EcoMed e tratamento de rate limit;
- cache geográfico com latitude/longitude arredondadas a três casas;
- normalização de tipos de resíduos e classificação da origem;
- erros estáveis, observabilidade sem dados sensíveis e auditoria técnica.

Os pontos EcoMed não serão persistidos permanentemente no primeiro momento. O
tempo de expiração do cache será configuravel.

## Dados iniciais

- usuário;
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
- dados externos não confiáveis não podem ser apresentados como garantia.
