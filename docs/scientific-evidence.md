# Evidências científicas

Este arquivo é o índice de evidências do projeto. Campos sem medição permanecem
como `PENDENTE`; resultados esperados não serão apresentados como observados.

## Identificação da versão

- Data: 24/08/2026
- Funcionalidade validada: fluxo manual de medicamentos em memória
- Commits validados: `76f5abd` e `33ec173`
- Ambiente/dispositivo: Windows 11 Education, Flutter 3.47.1 e Dart 3.13.1
- Responsável pela coleta: execução automatizada local do projeto

## Requisitos validados

| Requisito | Método | Resultado | Evidência |
|---|---|---|---|
| Base visual e qualidade estática | `dart format` e `flutter analyze` | Aprovado, sem problemas | Execução local em 24/08/2026 |
| RF02 - cadastro manual | Teste de widget com validação de formulário | Aprovado | Suíte do commit `33ec173` |
| RF03 - listagem e resumo | Testes de widget e do armazenamento em memória | Aprovado | Suíte do commit `33ec173` |
| RF04 - edição e remoção | Teste de widget com confirmação | Aprovado | Suíte do commit `33ec173` |
| RF05 - situação da validade | Testes unitários de datas-limite | Aprovado | Suíte do commit `33ec173` |
| Estado vazio e erro simulado | Testes de widget | Aprovado | Suíte do commit `33ec173` |
| Suíte automatizada completa | `flutter test` | 12 testes aprovados | Execução local em 24/08/2026 |
| Compilação Web | `flutter build web` | Aprovada | Artefato local em `mobile/build/web` |

As regras de validade verificadas foram: data anterior como vencida; dia da
validade ainda dentro da janela; limite de 30 dias incluído; acima de 30 dias
como válido; e suporte interno a uma janela configurável.

## Validação automatizada do M2

- Data: 14/09/2026
- Base: commit `526feea` mais alterações locais do M2, ainda sem commit
- Ambiente: Windows 11, Flutter 3.47.1 e Dart 3.13.1 portáteis
- Resultado: formatação aprovada, análise sem problemas, 37 testes aprovados e
  build Web concluído
- Escopo observado: animação da marca, redução de movimento, bootstrap,
  onboarding, autenticação simulada, logout, navegação e regressão de
  medicamentos
- Layout automatizado: viewport 390 × 844, texto em escala 2 no onboarding e
  teclado aberto no login, sem exceção de overflow
- Ativo: PNG Flutter e recurso Android idênticos por SHA-256, 320 × 320,
  transparentes nas bordas e sem conteúdo tocando os limites
- Contraste calculado: azul-petróleo `#174C5B` sobre `#F4F7F6` = 8,77:1
- Validação Android: **PENDENTE**; Android SDK, `adb`, `sdkmanager` e JDK 17 não
  estão disponíveis. Não houve inspeção real/emulada da splash ou da transição
  nativa

Os resultados acima comprovam o comportamento automatizado e a compilação Web,
mas não comprovam aparência em Android, ausência de quadro branco no dispositivo
ou usabilidade com participantes.

## Correção técnica do M2

- Data: 21/09/2026
- Base: commit `579814d` em worktree local, sem novo commit
- Ambiente: Windows 11, Flutter 3.47.1 e Dart 3.13.1 portáteis
- Resultado: formatação aprovada, análise sem problemas, 47 testes aprovados e
  build Web concluído
- Comportamentos observados por teste: navegação com Início, Descartar,
  Histórico e Conta; Medicamentos pela Home; logout somente em Conta; sessão
  simulada sem dados pessoais; histórico vazio; bootstrap paralelo em ambas as
  ordens de conclusão; redução de movimento; onboarding e regressão do fluxo
  manual de medicamentos
- Layout automatizado: 390 × 844 com escala de texto 2 e 320 × 568 com escala
  1,6, sem exceção de overflow
- Inspeção visual Web: não realizada; o servidor local iniciou, mas nenhum
  navegador controlável estava disponível no ambiente de automação
- Validação Android: não realizada; Android SDK, `adb`, `sdkmanager` e o comando
  `java` não estavam disponíveis

Esses resultados são evidência técnica automatizada. Eles não comprovam
reconciliação no Figma, aparência ou transição em Android nem usabilidade com
participantes.

## Validação técnica de 02/10/2026

- Base: `main` em `bace4af` com as alterações locais desta etapa (sem commit)
- Ambiente: Windows 11, Flutter 3.47.1/Dart 3.13.1, Python 3.13.7, Docker
  29.3.1 com PostgreSQL 17 e Microsoft Edge headless
- Escopo: redesenho da interface, backend (M4), cliente EcoMed (M5) e registro
  e histórico de descartes (M6)

| Item | Método | Resultado observado |
|---|---|---|
| Qualidade do app | `dart format` e `flutter analyze` | Aprovado, sem problemas |
| Testes do app | `flutter test` | 88 testes aprovados |
| Compilação Web | `flutter build web` nos modos demonstração e conectado | Aprovada |
| Testes do backend | `pytest` | 37 testes aprovados |
| Qualidade do backend | `ruff check` e `ruff format --check` | Aprovado |
| Migração | Alembic em SQLite limpo (teste) e em PostgreSQL 17 (Docker) | Aplicada; esquema igual aos modelos no teste |
| API em contêiner | Teste de fumaça HTTP | 13 de 13 verificações |
| Contrato app × API | `tool/e2e/api_contract_test.dart` contra a API real | Aprovado |
| Fluxo em navegador | Build Web conectado no Edge headless | Onboarding, login e Início com dados do PostgreSQL |
| Layout automatizado | 28 capturas, inclusive 320 × 568 com texto a 160% | Sem exceção de layout |
| Contraste | Cálculo WCAG dos tokens | Texto ≥ 4,66:1 no fundo; bordas de campo 3,19:1; selos de situação 5,43–6,69:1 |

O cálculo de contraste também mostrou que o selo de situação anterior tinha
1,86:1 (âmbar) e 2,67:1 (verde), abaixo do mínimo AA; a correção está no
D025.

Esses resultados são evidência técnica automatizada e de execução local. Não
comprovam comportamento em Android, desempenho da EcoMed real, entrega de
e-mails ou usabilidade com participantes.

## Validação técnica de 03/10/2026

- Base: `main` em `bace4af` com as alterações locais acumuladas (sem commit)
- Ambiente: o mesmo de 02/10/2026, com Tesseract 5.5.0 (`por`) na imagem
  Docker da API e a chave EcoMed da equipe no `backend/.env`
- Escopo: tempo-limite da localização e retorno ao Início, Meu perfil e
  exclusão de conta, leitura da embalagem e EcoMed real

| Item | Método | Resultado observado |
|---|---|---|
| Qualidade do app | `dart format` e `flutter analyze` | Aprovado, sem problemas |
| Testes do app | `flutter test` | 104 testes aprovados |
| Compilação Web | `flutter build web` nos modos demonstração e conectado | Aprovada |
| Testes do backend | `pytest` | 49 testes aprovados |
| Qualidade do backend | `ruff check` e `ruff format --check` | Aprovado |
| Contrato app × API | `tool/e2e/api_contract_test.dart` contra a API em Docker | Aprovado, com perfil, leitura de imagem em branco e exclusão da conta descartável |
| Leitura no navegador | Build Web conectado no Edge headless, foto enviada pelo seletor de arquivos | Formulário preenchido 1,3 s após o envio |
| Layout automatizado | 33 capturas | Sem exceção de layout |
| EcoMed real | Inspeção de contrato e consultas em 12 municípios | Ver "Desempenho da API" e "Cobertura geográfica observada" |

### Complemento de 03/10/2026: abertura, onboarding e celebrações

| Item | Método | Resultado observado |
|---|---|---|
| Testes do app | `flutter test` | 151 testes aprovados (incluindo os 34 dos lembretes) |
| Layout automatizado | 39 capturas, com quadros no meio das animações | Sem exceção de layout |
| Navegador real | Build Web de demonstração no Edge headless | Abertura, onboarding e celebração renderizados durante a animação |

São verificações técnicas; a percepção das pessoas sobre esses momentos não
foi medida (PENDENTE).

## Desempenho da API

Rota `GET /v1/collection-points/nearby` da API Zelo local, com a EcoMed real,
em 03/10/2026, uma rodada, rede doméstica cabeada. P95 pelo posto mais
próximo; com poucas amostras, equivale ao maior valor.

| Cenário | Amostras | Mediana | P95 | Observações |
|---|---:|---:|---:|---|
| Cache frio | 11 | 579 ms | 1197 ms | Uma consulta por município; o maior valor foi a primeira da rodada |
| Cache quente | 12 | 5 ms | 15 ms | Segunda consulta imediata de cada município |

Uma observação isolada anterior, em Porto Alegre, levou 2053 ms sem cache.

## Cobertura geográfica observada

- Data da consulta: 03/10/2026
- Região e coordenadas de teste: sedes dos 12 municípios da lista de regiões
  do app (D031), na Região Metropolitana de Porto Alegre
- Raio: 5 km
- Pontos retornados por município: de 6 (Eldorado do Sul) a 30 (limite da
  EcoMed, atingido em Porto Alegre, Alvorada, Canoas, São Leopoldo e Sapucaia
  do Sul); detalhes em `docs/ecomed-integration.md`
- Farmácias `logmed-*`: 59 de 274 ocorrências somadas (28 de 30 em Porto
  Alegre; nenhuma em Eldorado do Sul e Viamão)
- Outras origens: 215 ocorrências, com ID sem prefixo; o app as apresenta com
  aviso para confirmar por telefone. Não foi verificado se são unidades
  públicas nem se recebem medicamentos da população: PENDENTE
- Telefone informado: 173 de 274 ocorrências
- Horários: nenhum (`schedules` ausente na lista e vazio no detalhe consultado)

## Avaliação de usabilidade

- Protocolo planejado: 12 adultos, tarefas orientadas e perguntas abertas;
  consentimento e aplicação permanecem PENDENTES
- Quantidade de participantes observada: PENDENTE
- Tempo para concluir o primeiro acesso: PENDENTE
- Tempo para cadastrar medicamento: PENDENTE
- Tempo para localizar ponto: PENDENTE
- Taxa de conclusão: PENDENTE
- Erros e dificuldades observados: PENDENTE
- Relação dos participantes com o SUS: PENDENTE
- Clareza/facilidade e respostas abertas: PENDENTE

## Enquadramento acadêmico e tratamento futuro dos dados

- ODS 3: relação conceitual confirmada pelo foco em cuidado e prevenção de risco;
  impacto mensurado: PENDENTE.
- ODS 12: relação conceitual confirmada pela redução de desperdício e descarte
  responsável; impacto mensurado: PENDENTE.
- Divergências EcoMed: metodologia futura definida por normalização,
  identificação da origem, priorização de farmácias `logmed-*`, aviso para
  unidades públicas e omissão de horários ausentes. Resultados: PENDENTE.
- Medicamentos são classificados pelo projeto como dados indiretos de saúde;
  nenhuma coleta com participantes foi realizada nesta etapa.

## OCR

Implementado em 03/10/2026 como atalho do cadastro (D035). Até aqui só há
imagens sintéticas: rótulos fictícios gerados com fontes do sistema, sem
pessoas nem dados pessoais. Fotos de embalagens reais: PENDENTE.

| Imagem | Condição | Nome | Validade | Quantidade | Tempo de resposta |
|---|---|---|---|---|---:|
| Rótulo limpo (Dipirona Monoidratada, 20 comprimidos, VAL 03/2027) | Fundo branco, sem distorção | Correto | 31/03/2027, correta | 20, correta | 473 ms |
| Rótulo "fotografado" (Loratadina, 12 comprimidos, Val. AGO/2027) | Rotação de 4°, desfoque, JPEG reenviado com qualidade 85 | Correto | 31/08/2027, correta | 12, correta | 375 ms |
| O mesmo rótulo "fotografado", outro arquivo | Mesma imagem salva com a qualidade JPEG padrão (75) | Correto | 31/08/2027, correta | **142, incorreta** | não medido |

- O erro da terceira linha veio do próprio Tesseract, que leu "12" como
  "142"; o mesmo rótulo com outra compressão foi lido corretamente. Por isso
  o app exige conferência e mostra o que foi lido antes de salvar.
- O mesmo rótulo limpo, enviado pelo navegador real, preencheu o formulário
  1,3 s após a escolha do arquivo (envio, leitura e exibição).
- Taxa de acerto com embalagens reais, condições de luz e câmeras de
  celular: PENDENTE.

### Comparativo de motores (03/10/2026)

O responsável testou com embalagens reais pelo iPhone e avaliou a leitura do
Tesseract como "bem ruim" (relato qualitativo, sem contagem). Para medir, foram
gerados dois conjuntos de 8 embalagens fictícias fotografadas de forma
simulada (`backend/scripts/ocr_benchmark.py`, sementes fixas): um usado para
calibrar o interpretador e outro, de validação, não usado em nenhum ajuste.
Medição pela API em Docker, mesmo interpretador para os dois motores:

| Motor | Conjunto | Nome | Validade | Quantidade |
|---|---|---:|---:|---:|
| Tesseract 5 | Ajuste | 6/8 | 6/8 | 8/8 |
| RapidOCR (PP-OCRv6) | Ajuste | 8/8 | 8/8 | 8/8 |
| Tesseract 5 | Validação | 7/8 | 4/8 | 7/8 |
| RapidOCR (PP-OCRv6) | Validação | 8/8 | 7/8 | 8/8 |

- O único erro de validade do RapidOCR na validação foi uma validade em
  pontinhos sob reflexo; o OCR leu "VLNC04/27", que o interpretador não aceita
  como data rotulada (a regra não foi afrouxada para não confundir código de
  lote com data nem ajustar olhando para o conjunto de validação).
- Tempo típico de 1,1–1,4 s por foto; até 8,2 s quando a validade não aparece
  em nenhuma das seis tentativas.
- São imagens sintéticas. Taxa com fotos reais: PENDENTE.

## Limitações

- No modo demonstração, medicamentos e descartes ficam somente em memória e a
  sessão é simulada. A persistência real exige o modo conectado com a API.
- O APK de debug é gerado desde 03/10/2026, mas nada foi validado em
  dispositivo ou emulador: splash, transição nativa, permissão de
  localização, câmera e galeria, armazenamento seguro e intents de mapa e
  telefone seguem PENDENTES.
- A EcoMed não fornece horários (lista sem `schedules`, detalhe vazio), e a
  maioria dos pontos fora de Porto Alegre não é LogMed; a confirmação por
  telefone continua necessária. As medições de 03/10/2026 são de uma única
  rodada.
- A leitura da embalagem foi medida apenas com embalagens sintéticas (ver o
  comparativo de motores); com fotos reais há só o relato qualitativo de que o
  Tesseract ia mal. Depende do servidor e não funciona no modo demonstração.
- A recuperação de senha não envia e-mail: falta definir um provedor.
- O backend roda apenas localmente, sem HTTPS público.
- Termos de uso e política de privacidade permanecem PENDENTES de conteúdo e
  aprovação.
- Não existem resultados de usabilidade coletados.
