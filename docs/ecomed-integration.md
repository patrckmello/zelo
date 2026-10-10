# Integração EcoMed

## Estado

- **Uso acadêmico:** autorizado. A chave fica somente no `backend/.env`
  (`ECOMED_API_KEY`); nunca no aplicativo, no Git, no chat ou em logs.
- **Contrato público:** inspecionado em 02/10/2026 em
  <https://ecomed.eco.br/desenvolvedores>.
- **Cliente:** implementado no backend conforme esse contrato (D030), com
  testes usando respostas simuladas baseadas no exemplo publicado.
- **Respostas reais:** observadas em 03/10/2026 com a chave da equipe; o
  contrato real confere com o publicado (seção "Contrato observado").

## Contrato observado (03/10/2026)

Inspeção com `python -m scripts.inspect_ecomed --detalhe` (estrutura sem
valores pessoais) e consultas pela API Zelo local:

- `pontos/proximos` respondeu 200 com `source`, `attribution`, `count`,
  `query {lat, lng, raio_metros}` e `pontos`; cabeçalhos `X-RateLimit-Limit:
  60`, `X-RateLimit-Remaining` e `X-RateLimit-Reset` (epoch em milissegundos).
- Cada ponto da lista traz `id`, `name`, `address`, `city`, `state`,
  `latitude`, `longitude`, `phone` (texto ou `null`), `residueTypes` e
  `distancia_metros`. **A lista não traz `schedules`.**
- `pontos/:id` traz os mesmos campos (sem distância), mais `zipCode` e
  `schedules`; no ponto LogMed consultado, `schedules` veio como lista vazia.
- `residueTypes` observados: `medicamento`, `medicamentos` e `seringas`.
- IDs: `logmed-*` para as farmácias LogMed; os demais são identificadores
  alfanuméricos de 25 caracteres, sem prefixo.
- `attribution` real: "Dados originais: LogMed / Sindusfarma (programa oficial
  de logística reversa de medicamentos no Brasil). Uso autorizado para fins
  educativos e não comerciais." `source`: "EcoMed Public API v1".

Consequências: a normalização existente cobriu todas as variantes sem ajuste;
horários continuam fora do app, porque não há dados de `schedules` para
exibir, e o aviso para confirmar horário por telefone permanece.

## Contrato publicado (02/10/2026)

Autenticação: header `X-API-Key` em todas as requisições.

`GET /api/public/v1/pontos/proximos`

| Parâmetro | Tipo | Padrão | Limites |
|---|---|---|---|
| `lat` | número | — | -90 a 90 (obrigatório) |
| `lng` | número | — | -180 a 180 (obrigatório) |
| `raio` | metros | 5000 | 500 a 50.000 |

Devolve até 30 pontos aprovados, ordenados por distância. Exemplo publicado:

```json
{
  "source": "EcoMed Public API v1",
  "attribution": "Dados originais: LogMed / Sindusfarma...",
  "count": 12,
  "query": { "lat": -23.5505, "lng": -46.6333, "raio_metros": 5000 },
  "pontos": [
    {
      "id": "logmed-001234",
      "name": "Farmácia Exemplo - Centro",
      "address": "Rua das Flores, 100",
      "city": "São Paulo",
      "state": "SP",
      "latitude": -23.5489,
      "longitude": -46.6388,
      "phone": "(11) 3333-4444",
      "residueTypes": ["medicamento"],
      "distancia_metros": 412
    }
  ]
}
```

`GET /api/public/v1/pontos/:id`: detalhes completos de um ponto, incluindo
`schedules` por dia da semana. **O formato de `schedules` não é documentado.**

Limites e termos publicados:

- 60 requisições por minuto por chave (janela deslizante), acompanhadas por
  `X-RateLimit-Limit`, `X-RateLimit-Remaining` e `X-RateLimit-Reset`;
- CORS liberado só para o domínio registrado (irrelevante: as chamadas partem
  do servidor);
- atribuição "Dados: EcoMed + LogMed/Sindusfarma" junto aos pontos;
- uso educativo e não comercial.

## Regras obrigatórias (implementadas)

- chave apenas no backend, por variável de ambiente;
- aplicativo consulta exclusivamente a API Zelo;
- cache geográfico antes da consulta externa, com latitude e longitude
  arredondadas a três casas e o raio na chave; expiração configurável
  (`ECOMED_CACHE_TTL_SECONDS`, padrão 300 s);
- limitador local de 60 requisições por minuto (`ECOMED_RATE_LIMIT_PER_MINUTE`)
  antes de chamar a EcoMed;
- falhas explícitas, sem substituição por dados inventados.

## Contrato da API Zelo

`GET /v1/collection-points/nearby?latitude=&longitude=&radius_m=` (autenticado)
devolve:

```json
{
  "points": [
    {
      "id": "logmed-001234",
      "name": "Farmácia Exemplo - Centro",
      "address": "Rua das Flores, 100",
      "city": "São Paulo",
      "state": "SP",
      "latitude": -23.5489,
      "longitude": -46.6388,
      "phone": "(11) 3333-4444",
      "residue_types": ["medicamento"],
      "distance_m": 412,
      "origin": "logmed",
      "requires_confirmation": false
    }
  ],
  "count": 1,
  "radius_m": 5000,
  "attribution": "Dados: EcoMed — fontes CNES/DATASUS (Ministério da Saúde) e LogMed/Sindusfarma.",
  "cache": "miss"
}
```

Códigos de erro estáveis: `collection_points_not_configured` (503, sem chave),
`collection_points_rate_limited` (503 com `Retry-After`),
`collection_points_timeout` (504), `collection_points_unavailable` (502, inclui
chave recusada, sem expor a chave) e `collection_point_not_found` (404).

## Normalização aplicada

- `residueTypes`: minúsculas, espaços normalizados, singular/plural de
  medicamento e seringa unificados, itens desconhecidos preservados;
- origem: somente IDs `logmed-*` são farmácias LogMed; os demais recebem
  `requires_confirmation = true` e aviso para confirmar por telefone, pois
  podem incluir unidades públicas (CNES/DATASUS) que não recebem medicamentos
  da população;
- pontos sem ID, nome ou coordenadas válidas são descartados (contagem
  registrada em log, sem dados);
- telefone vazio vira ausente; UF em maiúsculas; distância arredondada;
- `schedules` não é exposto: horários não são exibidos nem deduzidos.

## Atribuição

O aplicativo exibe, junto aos pontos:

> Dados: EcoMed — fontes CNES/DATASUS (Ministério da Saúde) e LogMed/Sindusfarma.

Esse texto atende à orientação da equipe EcoMed (20/08/2026) e inclui a
exigência pública "Dados: EcoMed + LogMed/Sindusfarma".

## Inspeção com a chave

Para repetir (na pasta `backend/`, com `ECOMED_API_KEY` no `.env`):
`python -m scripts.inspect_ecomed --detalhe --saida <arquivo.json>`. O script
faz no máximo duas requisições e mostra só a estrutura: campos, tipos,
variantes de `residueTypes`, prefixos de ID e formato de `schedules`. Depois
de trocar a chave, recrie o contêiner da API
(`docker compose up -d --force-recreate api`).

## Evidências

Medição em 03/10/2026, uma rodada, a partir do computador de desenvolvimento
(rede doméstica cabeada), pela API Zelo em Docker com a chave real. Cada
município foi consultado na sede (D031), raio de 5 km, duas vezes seguidas.

| Município | Pontos | LogMed | Outras origens | 1ª consulta (ms) | 2ª consulta (ms) |
|---|---:|---:|---:|---:|---:|
| Alvorada | 30 | 3 | 27 | 1197 | 5 |
| Cachoeirinha | 27 | 5 | 22 | 1061 | 6 |
| Canoas | 30 | 5 | 25 | 574 | 5 |
| Eldorado do Sul | 6 | 0 | 6 | 577 | 5 |
| Esteio | 28 | 2 | 26 | 664 | 5 |
| Gravataí | 15 | 3 | 12 | 576 | 7 |
| Guaíba | 11 | 1 | 10 | 584 | 4 |
| Novo Hamburgo | 27 | 5 | 22 | 576 | 5 |
| São Leopoldo | 30 | 5 | 25 | 583 | 12 |
| Sapucaia do Sul | 30 | 2 | 28 | 579 | 5 |
| Viamão | 10 | 0 | 10 | 574 | 15 |
| Porto Alegre | 30 | 28 | 2 | 9 (cache) | 6 |

- Latência sem cache (11 municípios): mediana 579 ms, mínimo 574 ms, máximo
  1197 ms (primeira chamada da rodada). Uma observação isolada anterior, em
  Porto Alegre, levou 2053 ms.
- Latência com cache: mediana 5 ms, máximo 15 ms (12 consultas). Todas as
  segundas consultas foram atendidas pelo cache; a primeira de Porto Alegre
  também, por causa de uma consulta feita minutos antes.
- Pontos: 274 ocorrências somadas (pode haver repetição entre municípios
  vizinhos); 59 LogMed e 215 de outras origens; 173 com telefone. Fora de
  Porto Alegre, a maioria dos pontos não é LogMed e recebe o aviso de
  confirmação por telefone.
- Eldorado do Sul e Viamão não tiveram ponto LogMed no raio de 5 km.
- Limite, indisponibilidade e dados incompletos: tratados em testes
  simulados; não foram provocados contra a EcoMed real.

São números de uma única rodada, sem valor estatístico; servem para
dimensionar o cache e a expectativa de espera no app.
