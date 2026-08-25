# Evidências científicas

Este arquivo é o índice de evidências do projeto. Campos sem medição permanecem
como `PENDENTE`; resultados esperados não serão apresentados como observados.

## Identificação da versão

- Data: 24/08/2026
- Versão ou commit validado: `4650efd`
- Ambiente/dispositivo: Windows 11 Education, Flutter 3.47.1 e Dart 3.13.1
- Responsável pela coleta: execução automatizada local do projeto

## Requisitos validados

| Requisito | Método | Resultado | Evidência |
|---|---|---|---|
| Base visual inicial | `flutter analyze` | Sem problemas | Saída local em 24/08/2026 |
| Página inicial | Teste de widget | Aprovado | 1 teste automatizado |
| Navegação para medicamentos | Teste de widget | Aprovado | 1 teste automatizado |
| Compilação Web | `flutter build web` | Aprovada | Artefato local em `mobile/build/web` |

Splash, onboarding e autenticação foram adicionados ao planejamento, mas ainda
não possuem evidência de implementação ou validação.

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

- Android SDK indisponível; execução Android ainda não foi validada.
- A página inicial usa dados simulados e não representa persistência real.
- Splash, onboarding e autenticação ainda estão apenas planejados.
- Não existem resultados de desempenho da API ou de usabilidade coletados.
