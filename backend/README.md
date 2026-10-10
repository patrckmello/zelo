# API Zelo

API própria do Zelo (M4–M6): cadastro e autenticação, perfil e exclusão de
conta, medicamentos isolados por conta, leitura da embalagem por foto (OCR),
registro e histórico de descartes e consulta de pontos de coleta via EcoMed. O aplicativo nunca acessa a EcoMed diretamente (D003): a chave fica
somente aqui, no arquivo `.env` local.

Tecnologias: Python 3.13, FastAPI 0.142, SQLAlchemy 2.1, Alembic 1.20,
PostgreSQL 17, Argon2 (argon2-cffi), PyJWT, httpx, python-multipart e Pillow.
Versões fixadas em `requirements.txt`. A leitura de embalagens usa o RapidOCR
(modelos PP-OCRv6 do PaddleOCR em ONNX Runtime, só CPU), com o Tesseract 5 em
português como reserva; a imagem Docker instala os dois e baixa os modelos no
build. `ZELO_OCR_ENGINE=tesseract` força o Tesseract.

## Configuração

1. Copie `.env.example` para `.env` e preencha `ZELO_DB_PASSWORD`,
   `ZELO_JWT_SECRET` (32+ caracteres) e `ZELO_DEMO_PASSWORD`.
2. Para consultar pontos reais, preencha `ECOMED_API_KEY`. Sem a chave, a API
   funciona normalmente e responde `503 collection_points_not_configured` na
   busca de pontos.
3. Nunca versione o `.env`; ele já está no `.gitignore`.

> Neste repositório, um `backend/.env` local foi gerado em 02/10/2026 com
> segredos aleatórios de desenvolvimento; a equipe adicionou a
> `ECOMED_API_KEY` depois. Ele não é versionado.

## Execução com Docker (recomendada)

```powershell
cd backend
docker compose up --build -d
docker compose exec api python -m scripts.seed_demo   # conta de demonstração
```

- API: <http://localhost:8000> (documentação interativa em `/docs`).
- Saúde: <http://localhost:8000/health> informa banco, se a EcoMed está
  configurada e se o OCR está disponível (`ocr_available`).
- PostgreSQL: `localhost:5433` (porta do host configurável por `ZELO_DB_PORT`,
  para não conflitar com um PostgreSQL local na 5432).
- As migrações (`alembic upgrade head`) rodam automaticamente na subida.

Depois de preencher ou trocar a `ECOMED_API_KEY`, recrie o contêiner da API:

```powershell
docker compose up -d --force-recreate api
```

A senha do PostgreSQL é gravada no volume na primeira subida. Para trocá-la,
remova o volume (`docker compose down -v`), o que apaga os dados locais.

## Execução local sem Docker

Requer um PostgreSQL acessível em `ZELO_DATABASE_URL`. A leitura da embalagem
usa o RapidOCR instalado pelo `requirements.txt` (os modelos são baixados na
primeira leitura); sem ele, recorre ao `tesseract` no `PATH` com o idioma `por`.
Sem nenhum dos dois, a rota responde `503 ocr_unavailable` e o restante
funciona.

## Comparativo do OCR

`scripts/ocr_benchmark.py` gera embalagens fictícias "fotografadas" (sementes
fixas, com gabarito) e mede a API em execução:

```powershell
.\.venv\Scripts\python -m scripts.ocr_benchmark gerar --conjunto validacao
.\.venv\Scripts\python -m scripts.ocr_benchmark medir --conjunto validacao --api http://localhost:8000
```

O conjunto `ajuste` foi usado para calibrar o interpretador; o `validacao`,
não. Para comparar motores, suba outra instância com
`ZELO_OCR_ENGINE=tesseract` (ex.: `docker compose run -d --rm -e
ZELO_OCR_ENGINE=tesseract -p 8001:8000 api`) e meça em `--api
http://localhost:8001`.

```powershell
cd backend
py -3.13 -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements-dev.txt
.\.venv\Scripts\alembic upgrade head
.\.venv\Scripts\uvicorn app.main:create_app --factory --reload
```

## Validação

```powershell
cd backend
.\.venv\Scripts\python -m pytest
.\.venv\Scripts\ruff check .
.\.venv\Scripts\ruff format --check .
```

Os testes usam SQLite isolado por teste e uma EcoMed simulada
(`httpx.MockTransport`); nenhum teste acessa a rede. A migração inicial também
é verificada contra os modelos em banco limpo.

## Inspeção do contrato real da EcoMed

Com a chave no `.env`, o script abaixo faz no máximo duas requisições e mostra
somente a estrutura da resposta (campos, tipos, variantes de `residueTypes`,
prefixos de ID e formato de `schedules`). Não imprime a chave, endereços,
telefones ou coordenadas.

```powershell
.\.venv\Scripts\python -m scripts.inspect_ecomed --detalhe --saida ..\artifacts\ecomed-contrato.json
```

Resultado de 03/10/2026 registrado em `docs/ecomed-integration.md`: campos
iguais aos publicados e `schedules` ausente na lista e vazio no detalhe.

## Endpoints

Todas as rotas `/v1`, exceto as de autenticação, exigem
`Authorization: Bearer <access_token>`. Erros seguem
`{"error": {"code": "...", "message": "..."}}`, sem dados internos.

| Método e rota | Descrição |
|---|---|
| `GET /health` | Banco, configuração da EcoMed e disponibilidade do OCR |
| `POST /v1/auth/register` | Cria conta e devolve tokens |
| `POST /v1/auth/login` | Autentica (limite de tentativas por IP e e-mail) |
| `POST /v1/auth/refresh` | Troca o token de renovação (rotação com detecção de reuso) |
| `POST /v1/auth/logout` | Revoga o token de renovação |
| `GET /v1/auth/me` | Conta autenticada |
| `POST /v1/auth/password-reset/request` | Gera código de recuperação (resposta igual com ou sem conta) |
| `POST /v1/auth/password-reset/confirm` | Troca a senha e encerra as sessões |
| `GET/PATCH /v1/account` | Perfil com contagens; troca o nome |
| `POST /v1/account/email` | Troca o e-mail (exige `current_password`) |
| `POST /v1/account/password` | Troca a senha, revoga as sessões e devolve tokens novos |
| `POST /v1/account/delete` | Exclui conta, medicamentos, descartes e sessões (204) |
| `GET/POST /v1/medications` | Lista ativos (ordem de validade) e cadastra |
| `PUT/DELETE /v1/medications/{id}` | Atualiza e remove (404 para itens de outra conta) |
| `GET/POST /v1/disposals` | Histórico e registro de descarte |
| `GET /v1/collection-points/nearby` | Pontos próximos (`latitude`, `longitude`, `radius_m` 500–50.000) |
| `GET /v1/collection-points/{id}` | Detalhe normalizado de um ponto |
| `POST /v1/ocr/medication` | Lê a foto (`image`, JPG/PNG/WebP até 8 MB) e sugere nome, validade e quantidade |

## Segurança e privacidade

- Senhas com Argon2id; tokens de renovação e códigos de recuperação guardados
  somente como SHA-256.
- Token de acesso JWT de 15 minutos; renovação de 30 dias com rotação e
  revogação de todas as sessões ao detectar reuso ou trocar a senha.
- Medicamentos e descartes sempre filtrados pelo dono.
- Alterar e-mail, trocar senha e excluir a conta exigem a senha atual, com o
  mesmo limite de tentativas do login.
- Fotos de embalagem: processadas em memória e descartadas ao fim da
  requisição; o log registra só quantas linhas foram lidas e quais campos
  foram encontrados. Limite de 20 leituras por minuto por conta.
- Logs sem senhas, tokens, chave EcoMed ou coordenadas; o logger do httpx fica
  em `WARNING` porque registraria URLs com coordenadas.
- Recuperação de senha: sem provedor de e-mail definido (PENDENTE). Em
  desenvolvimento, `ZELO_PASSWORD_RESET_OUTBOX_DIR` grava o código em arquivo
  local ignorado pelo Git; em produção a entrega fica desativada.
