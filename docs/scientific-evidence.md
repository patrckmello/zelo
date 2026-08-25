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

- Protocolo e consentimento definidos: PENDENTE
- Quantidade de participantes: PENDENTE
- Tempo para concluir o primeiro acesso: PENDENTE
- Tempo para cadastrar medicamento: PENDENTE
- Tempo para localizar ponto: PENDENTE
- Taxa de conclusão: PENDENTE
- Clareza/facilidade percebida: PENDENTE
- Problemas observados: PENDENTE

## OCR

Fora do núcleo inicial. Caso seja implementado, registrar conjunto de imagens,
condições, campos esperados, acertos, erros e correções manuais, respeitando
privacidade e sem armazenar dados pessoais desnecessários.

## Limitações

- O armazenamento é somente em memória e volta aos dados iniciais ao reiniciar.
- Android SDK indisponível; execução Android ainda não foi validada.
- Splash, onboarding e autenticação ainda estão apenas planejados.
- Backend, persistência e integração EcoMed ainda não foram implementados.
- Não existem resultados de desempenho da API ou de usabilidade coletados.
