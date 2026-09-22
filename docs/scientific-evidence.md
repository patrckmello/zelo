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

## Desempenho da API

| Cenário | Amostras | Mediana | P95 | Observações |
|---|---:|---:|---:|---|
| Cache frio | PENDENTE | PENDENTE | PENDENTE | PENDENTE |
| Cache quente | PENDENTE | PENDENTE | PENDENTE | PENDENTE |

## Cobertura geográfica observada

- Região e coordenadas de teste: PENDENTE
- Raio: PENDENTE
- Pontos retornados: PENDENTE
- Farmácias `logmed-*`: PENDENTE
- Unidades públicas: PENDENTE
- Data da consulta: PENDENTE

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

Fora do núcleo inicial. Caso seja implementado, registrar conjunto de imagens,
condições, campos esperados, acertos, erros e correções manuais, respeitando
privacidade e sem armazenar dados pessoais desnecessários.

## Limitações

- O armazenamento é somente em memória e volta aos dados iniciais ao reiniciar.
- Android SDK, `adb`, `sdkmanager` e comando `java` indisponíveis; APK, splash e
  transição nativa não foram validados em dispositivo ou emulador.
- A autenticação é simulada e persiste somente um marcador booleano. Não há
  proteção de conta, isolamento de usuários, token seguro ou envio de e-mail.
- Termos de uso e política de privacidade permanecem PENDENTES de conteúdo e
  aprovação.
- Backend, persistência e integração EcoMed ainda não foram implementados.
- Não existem resultados de desempenho da API ou de usabilidade coletados.
