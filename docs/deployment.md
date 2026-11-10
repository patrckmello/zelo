# Publicação da API (Google Cloud Run + Neon)

Estado: **Implementado e público** (31/10/2026): publicado em modo privado e
aberto ao público pelo responsável, que executou o comando da seção "Abrir ao
público". Validado no celular em 31/10/2026 só o login, a sessão e a tela
inicial; os demais fluxos no aparelho seguem PENDENTES. A consulta de pontos da
EcoMed a partir da nuvem foi verificada em 10/11/2026 pela API (não pelo
celular). A escolha e as pesquisas estão na D044 (`docs/decisions.md`); o envio
de e-mail, na D043.

**O endereço real da API não é versionado**: o repositório é público e a API,
aberta e sem limite de uso além do login. Este documento usa `<URL_DA_API>`.
Para obtê-lo, com o `gcloud` autenticado:

```powershell
gcloud run services describe zelo-api --region us-central1 --format "value(status.url)"
```

Observado em 31/10/2026:

- a conta Google Cloud é de **teste gratuito** (R$ 1.779,29 de crédito e 69 dias
  restantes, conforme o painel de faturamento) e há um orçamento de R$ 5 com
  alerta; sem o "upgrade" para conta completa, não há cobrança no cartão, mas
  os serviços deixam de funcionar quando o crédito ou o prazo acabarem;
- projeto Google Cloud `zelo-mostra-4f2a9c`, com faturamento vinculado e as APIs
  `run`, `cloudbuild` e `artifactregistry` ativadas;
- Neon: AWS us-east-2, PostgreSQL 18; conexão direta (host sem `-pooler`,
  `sslmode=require`) testada a partir do computador com `psycopg`;
- serviço `zelo-api` (revisão `zelo-api-00001-tfm`) em `us-central1`, 2 GiB,
  1 vCPU, no máximo 1 instância, **privado** na primeira publicação (URL do
  tipo `https://zelo-api-<NÚMERO>.us-central1.run.app`); build e deploy levaram
  185 s;
- sem credencial do Google, `/health` responde 403; com credencial, 200 com
  `database: ok`, `ecomed_configured: true` e `ocr_available: true`;
- os registros mostram a migração `0001` aplicada no Neon na partida e o
  servidor pronto cerca de 5 s depois do início da migração, sem erros;
- conta de demonstração criada no Neon com `scripts/seed_demo`; pela API na
  nuvem: login 200, senha errada 401, `/v1/auth/me` 200, `/v1/medications` com
  os 3 medicamentos fictícios e chamada sem o token do app 401;
- o repositório do Artifact Registry ocupa 348,98 MB (com uma imagem), abaixo
  dos 0,5 GB gratuitos;
- depois de aberto ao público: `/health` 200 sem credencial (1,27 s na primeira
  chamada), rota protegida sem token 401 (da API, não do Google) e HTTP
  redirecionado (302) para HTTPS;
- leitura de embalagem na nuvem, com 4 fotos sintéticas de 1290 × 915 px
  (101–180 KB) e login da conta demo: as 4 retornaram 200 com nome, validade e
  quantidade; a primeira, que carrega o motor de OCR, levou 13,96 s e as demais
  5,21–5,64 s. Os registros mostram `motor=RapidOcrRecognizer` e só dados
  agregados (nunca o texto lido);
- 20 chamadas seguidas com o token do app (`/auth/me` e `/medications`): 20
  respostas 200, mediana de 0,34 s;
- **uma falha observada:** logo depois de abrir ao público, a primeira chamada
  de OCR recebeu 401 do portão do Google ("The access token could not be
  verified") e a mesma chamada passou cerca de 30 s depois. A hipótese é a
  propagação da permissão de acesso (IAM), **não provada**; depois disso não
  houve nova ocorrência. Se o app receber 401 logo após uma nova abertura,
  espere alguns minutos.

- **partida a frio medida no celular** (Galaxy A12, Android 13, Wi-Fi), com o
  APK de debug apontando para a nuvem, depois de mais de uma hora sem tráfego: a
  primeira chamada, um `refresh` de sessão guardada (resposta 401, esperada para
  token desconhecido), levou **12,19 s** no Cloud Run; o login seguinte, 0,46 s.
  Pelos registros (UTC): instância iniciada às 18:01:31,97; o processo Python
  começou a aplicar as migrações às 18:01:37,38 (cerca de 5,4 s depois); o
  servidor ficou pronto às 18:01:43,45 (cerca de 6,1 s de `alembic upgrade head`,
  que inclui conectar ao Neon suspenso); a resposta saiu cerca de 0,7 s depois.
  A causa do tempo das migrações (retomada do Neon ou outra) **não foi
  separada**;
- **segunda medição, com o APK novo (tempo limite de 40 s na primeira chamada)**,
  cerca de 19 min depois da última chamada: o app reabriu, restaurou a sessão
  sozinho (`refresh` 200 em **6,59 s**, com instância nova iniciada às
  18:22:10,65 e servidor pronto às 18:22:16,71) e mostrou a tela inicial com os
  3 medicamentos, sem pedir login e sem erro. Portanto a partida a frio medida
  fica entre **6,6 s e 12,2 s** (duas medições, sem explicação separada para a
  diferença);
- no mesmo teste, o Android informou `Displayed ... +8s957ms`: o build de
  **debug** (`DEBUGGABLE`) levou cerca de 9 s só para desenhar a primeira tela
  neste aparelho de entrada, e o app enviou a primeira chamada cerca de 12 s
  depois do toque. Do toque até a tela inicial passaram-se cerca de 20 s; o
  tempo de um build de release **não foi medido**;
- login no celular com a conta demo: tela inicial com os 3 medicamentos fictícios
  vindos da nuvem (válido 1, próximo do vencimento 1, vencido 1).

**Atenção:** o tempo limite padrão do app é de 15 s (45 s na leitura de
embalagem), e a partida a frio de 12,19 s passou com folga de menos de 3 s.
Por isso, em 31/10/2026, o cliente de rede passou a usar **40 s** até receber a
primeira resposta do servidor (`firstRequestTimeout`), voltando a 15 s depois
(testes automatizados cobrem os dois casos; 40 s é cerca de 3 vezes a medição,
uma margem escolhida e não calculada). Isso evita o erro, mas **não** reduz a
espera de cerca de 12 s da primeira abertura.

**Aquecer antes de apresentar:** uns 5 minutos antes, abra o app uma vez ou rode
`curl.exe <URL_DA_API>/health` (em PowerShell, `$url` da seção 5). A instância
tende a ficar ativa por cerca de 15 minutos sem uso (valor aproximado, não
medido aqui); depois volta a zero.

Observado em 10/11/2026, a partir do computador (rede doméstica), depois de mais
de 9 dias sem tráfego:

- **terceira medição de partida a frio:** `/health` respondeu 200 com
  `database: ok`, `ecomed_configured: true` e `ocr_available: true` em
  **14,94 s** (`curl`, tempo total). As três medições ficam entre **6,6 s e
  14,9 s**; a mais longa veio depois do maior período parado e ficou muito perto
  do limite antigo de 15 s do app, o que confirma a necessidade dos 40 s na
  primeira chamada. Não foi separada a parcela do Neon suspenso;
- **pontos EcoMed pela API na nuvem** (primeira vez que essa rota foi exercitada
  fora do computador), com a conta demo: Porto Alegre, 30 pontos em 1,92 s com
  cache frio e 0,32 s com cache quente; Cachoeirinha, 30 pontos em 1,03 s e
  0,36 s. A EcoMed respondeu a partir do Cloud Run **sem nenhuma liberação de
  IP**. Isso foi feito por script, não pelo celular.

**Não testado:** uso de memória real (as fotos testadas são menores que o pico
de 2400 × 1800 px da D044), e-mail de recuperação e os demais fluxos no celular
(cadastro, câmera, localização, descarte, histórico). Os tempos de `/health` logo
após o deploy foram de uma instância recém-criada e **não** representam a partida
a frio.

Os comandos abaixo seguem a documentação pública dos provedores e foram
conferidos com `gcloud run deploy --help` (as opções usadas existem).

## Arquitetura

```text
APK Android ──HTTPS──▶ Cloud Run (API Zelo, 2 GiB, 1 instância)
                           ├──▶ Neon (PostgreSQL)
                           └──▶ EcoMed (chave só no backend)
```

O aplicativo conectado recebe a URL da API na compilação
(`--dart-define=ZELO_API_URL=https://...`). Sem ela, roda na demonstração.

## Como evitar cobrança

Os valores abaixo vêm de páginas públicas consultadas em 10/10/2026; **confirme
nas páginas oficiais**, pois mudam.

- **Cloud Run:** franquia mensal recorrente (2 milhões de requisições, 180 mil
  vCPU-segundos e 360 mil GiB-segundos na cobrança por requisição, regiões da
  camada 1). Use `us-central1`, que é da camada 1. A região de São Paulo é de
  outra camada e não foi verificada.
- **Cloud Build:** 2.500 minutos de build por mês gratuitos.
- **Artifact Registry:** 0,5 GB gratuito; acima disso, cerca de US$ 0,10 por
  GB-mês. A imagem da API (OCR com ONNX, OpenCV e Tesseract) pode passar de
  0,5 GB: o tamanho real é PENDENTE de medição (`gcloud artifacts docker images
  list`). Apague imagens antigas depois de cada deploy; o custo esperado é de
  centavos, não zero garantido.
- **Neon:** plano gratuito (0,5 GB e 100 CU-horas por mês), com suspensão após 5
  minutos sem uso.
- **Orçamento com alerta:** no console, Faturamento → Orçamentos e alertas,
  valor baixo (por exemplo R$ 5) com avisos em 50%, 90% e 100%. O alerta
  **avisa, não bloqueia** o gasto.
- `--max-instances 1` impede escala (e custo) inesperados e mantém coerente o
  limite de tentativas de login, que é por instância.
- Ao terminar, apague tudo (seção "Desligar").

## Pré-requisitos

1. Conta Google com um cartão cadastrado (exigência do faturamento).
2. Google Cloud CLI instalado. No Claude Code, o login interativo pode ser feito
   digitando `! gcloud auth login`.
3. Conta no [Neon](https://neon.com).
4. `backend/.env` local funcionando (serve de referência para os valores).

## 1. Banco no Neon

1. Crie um projeto, na região mais próxima de `us-central1` (EUA).
2. Copie a string de conexão **direta**, a do host sem `-pooler`. Ela vem como
   `postgresql://usuario:senha@host.neon.tech/banco?sslmode=require`.
3. Troque o prefixo para `postgresql+psycopg://`. O resto fica igual.

A API aplica as migrações do Alembic ao iniciar; não é preciso criar tabelas.
O `pool_pre_ping` já descarta conexões encerradas pela suspensão do Neon.

## 2. Projeto no Google Cloud

```powershell
gcloud auth login
gcloud projects create zelo-mostra-SEUID --name "Zelo"   # o ID precisa ser único
gcloud config set project zelo-mostra-SEUID
gcloud billing accounts list
gcloud billing projects link zelo-mostra-SEUID --billing-account=ID_DA_CONTA
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
```

Crie o orçamento com alerta pelo console, como descrito acima.

## 3. Variáveis

```powershell
cd D:\Code\zelo\backend
Copy-Item cloudrun.env.example.yaml cloudrun.env.yaml
# edite cloudrun.env.yaml: ZELO_DATABASE_URL, ZELO_JWT_SECRET e ECOMED_API_KEY
```

`cloudrun.env.yaml` está no `.gitignore` e no `.gcloudignore`: não é versionado
nem enviado ao Cloud Build. As variáveis ficam visíveis a quem administra o
projeto Google; para algo além da demonstração, use o Secret Manager.

## 4. Publicar

```powershell
cd D:\Code\zelo\backend
gcloud run deploy zelo-api `
  --source . `
  --region us-central1 `
  --no-allow-unauthenticated `
  --port 8000 `
  --memory 2Gi --cpu 1 --cpu-boost `
  --min-instances 0 --max-instances 1 `
  --concurrency 20 `
  --env-vars-file cloudrun.env.yaml
```

- `--memory 2Gi`: medi 806 MB de pico no OCR com foto de 2400 × 1800 px (D044);
  512 MB não bastaria.
- `--cpu-boost` reduz a partida a frio.
- O primeiro deploy pergunta se pode criar o repositório
  `cloud-run-source-deploy` no Artifact Registry; confirme.
- A resposta traz a URL (`https://zelo-api-...run.app`). O HTTPS é automático.
- O primeiro deploy foi feito **privado** (`--no-allow-unauthenticated`): a
  ferramenta de permissões do Claude Code recusou `--allow-unauthenticated`,
  que expõe a API à internet, e essa decisão ficou com o responsável (ver
  "Abrir ao público").

## 5. Verificar

Com o serviço privado, use a credencial do Google. Para não ocupar o cabeçalho
`Authorization`, que o app usa para o seu próprio token, envie a credencial em
`X-Serverless-Authorization`:

```powershell
$url = gcloud run services describe zelo-api --region us-central1 --format "value(status.url)"
$tok = gcloud auth print-identity-token
curl.exe -H "Authorization: Bearer $tok" "$url/health"
```

Nas rotas `/v1/...`, use `X-Serverless-Authorization: Bearer $tok` para a
credencial do Google e `Authorization: Bearer <token do app>` para o login do
Zelo (foi assim que o login, `/auth/me` e `/medications` foram testados em
31/10/2026, por um script em Python).

Depois, registre o resultado real (tempo da primeira resposta a frio, erros) em
`docs/testing-plan.md` e `docs/scientific-evidence.md`. Não registre nada que
não tenha sido observado.

## Abrir ao público

O aplicativo no celular não envia credenciais do Google, então só funciona com
o serviço público. Quem decide é o responsável pelo projeto; foi executado por
ele em 31/10/2026:

```powershell
gcloud run services add-iam-policy-binding zelo-api --region us-central1 `
  --member=allUsers --role=roles/run.invoker
```

O que isso muda: qualquer pessoa com a URL consegue chamar a API. Os dados de
cada conta seguem protegidos pelo login, a chave EcoMed fica só no servidor, o
limite de tentativas de login vale e `--max-instances 1` limita escala e custo.
Para voltar ao modo privado, use `gcloud run services remove-iam-policy-binding`
com os mesmos argumentos.

## 6. Conta de demonstração

Executada em 31/10/2026 (a senha foi informada pelo responsável e **não** é
gravada em arquivo do repositório). A partir do computador, apontando para o
Neon (as variáveis do processo têm prioridade sobre o `backend/.env`):

```powershell
cd D:\Code\zelo\backend
$env:ZELO_DATABASE_URL = '<mesma string do Neon>'
$env:ZELO_JWT_SECRET = '<mesmo segredo>'
$env:ZELO_DEMO_PASSWORD = '<senha da conta demo>'
.\.venv\Scripts\python.exe -m scripts.seed_demo
```

## 7. APK apontando para a nuvem

Siga a seção Android de `mobile/README.md` (JDK, SDK e Gradle de `.tools/`) e
acrescente a URL:

```powershell
..\.tools\flutter\bin\flutter.bat build apk --debug --dart-define=ZELO_API_URL=<URL_DA_API>
```

Com HTTPS, o celular não precisa estar na mesma rede nem no Tailscale.

## E-mail de recuperação (opcional)

Só a recuperação de senha envia e-mail (D043). Se a demonstração não a usar,
não configure nada: a entrega fica desativada e o login não é afetado.

Para ativar, acrescente `ZELO_SMTP_HOST`, `ZELO_SMTP_USER` e
`ZELO_SMTP_PASSWORD` ao `cloudrun.env.yaml` e republique com
`--no-cpu-throttling`. Sem essa opção, o Cloud Run reduz a CPU quando a resposta
termina e o envio, que ocorre depois dela, pode não concluir. Essa opção cobra o
tempo de vida da instância (a franquia de cobrança por instância é separada) e
foi lida na documentação, não testada.

A porta 587 do Gmail a partir do Cloud Run **não foi confirmada** (a
documentação do Google trata das VMs). Se der tempo esgotado, mantenha o e-mail
desativado ou use a API HTTPS de um provedor transacional (D044).

## IP de saída fixo (só se a EcoMed exigir)

**Estado: Planejado, não executado e não testado.** Em 10/11/2026 a EcoMed
respondeu a partir do Cloud Run sem restrição de IP, então nada disto é
necessário hoje. O Cloud Run não tem IP de saída fixo por padrão; o caminho
descrito na documentação do Google é saída pela rede VPC com um Cloud NAT e um
IP externo reservado:

```powershell
gcloud services enable compute.googleapis.com
gcloud compute addresses create zelo-saida-ip --region us-central1
gcloud compute routers create zelo-roteador --network default --region us-central1
gcloud compute routers nats create zelo-nat --router zelo-roteador --region us-central1 `
  --nat-external-ip-pool zelo-saida-ip --nat-all-subnet-ip-ranges
gcloud run services update zelo-api --region us-central1 `
  --network default --subnet default --vpc-egress all-traffic
gcloud compute addresses describe zelo-saida-ip --region us-central1 --format "value(address)"
```

O último comando mostra o IP a informar à EcoMed. Pontos de atenção, todos
**não verificados**: a rede `default` pode não existir no projeto; o IP reservado
e o Cloud NAT são cobrados por hora (valores não consultados; saem do crédito do
teste gratuito); com `all-traffic` o tráfego para o Neon e para a EcoMed passa
pelo NAT, o que pode alterar o tempo das chamadas. Se o IP for apenas do
computador de desenvolvimento, ele muda com o provedor de internet e não vale
para a nuvem.

## Limitações conhecidas

- **Partida a frio:** com `--min-instances 0` e o Neon suspenso, a primeira
  requisição depois de um tempo parado demora (carregamento da imagem, conexão
  ao banco acordando e, na primeira leitura de embalagem, o motor de OCR). Abra
  o aplicativo uma vez antes de apresentar. Medido: 12,19 s (31/10/2026, mais
  de uma hora parado), 6,59 s (31/10/2026, cerca de 19 min parado) e 14,94 s
  (10/11/2026, mais de 9 dias parado); a primeira leitura de embalagem na nuvem
  levou 13,4 s no servidor contra 5,2–5,6 s nas seguintes.
- **Sem IP de saída fixo:** o Cloud Run sai para a internet por endereços do
  Google que mudam; não existe "o IP do backend" para informar a terceiros. Em
  10/11/2026 a EcoMed respondeu sem liberação de IP, então hoje isso não é um
  bloqueio. Se a EcoMed passar a exigir uma lista de IPs permitidos, os pontos de
  coleta **deixam de funcionar na nuvem** até configurar um IP fixo (seção "IP de
  saída fixo"). Não ative a restrição na EcoMed antes de a nuvem ter IP fixo.
- **Limite de login:** é por instância e usa o IP visto pela API; atrás do
  Cloud Run esse IP é o do proxy do Google, então o limite vale na prática por
  e-mail. Ainda protege contra tentativas em série; não foi ajustado.
- **Segredos em variáveis de ambiente**, e não no Secret Manager.
- **Sem domínio próprio:** a URL `run.app` é a do serviço.

## Desligar tudo

```powershell
gcloud run services delete zelo-api --region us-central1
gcloud artifacts repositories delete cloud-run-source-deploy --location us-central1
```

Apague também o projeto no Neon. A forma mais simples de encerrar qualquer
cobrança futura é excluir o projeto inteiro: `gcloud projects delete
zelo-mostra-4f2a9c` (o projeto usado em 31/10/2026).
