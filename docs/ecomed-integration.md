# Integração EcoMed

## Estado

Uso acadêmico autorizado, mas integração ainda não iniciada. Endpoints, schemas
e exemplos de resposta não serão inferidos. A documentação técnica e respostas
reais devem ser inspecionadas antes de escrever o cliente.

## Regras obrigatórias

- chave apenas no backend e por variavel de ambiente;
- nenhum segredo no Flutter, Git, chat ou logs;
- Flutter consulta exclusivamente a API Zelo;
- limite externo de 60 requisições por minuto por chave, compartilhado;
- cache geográfico antes da consulta externa;
- latitude e longitude arredondadas a três casas na chave do cache;
- expiração configuravel;
- falhas explicitas, sem substituicao por dados inventados.

## Normalização conhecida

O backend deverá normalizar variantes de `residueTypes`, incluindo singular e
plural de medicamento e seringa, e identificar explicitamente a origem de cada
registro. A tabela final somente será definida após analisar o conjunto real de
valores.

O campo `schedules` é opcional na prática. Horários só serão exibidos quando
houver dados válidos; quando ausentes, o campo será omitido. O aplicativo não
deduzirá estado aberto/fechado.

IDs no formato `logmed-NNNNNN` identificam farmácias vinculadas ao catálogo
LogMed e serão priorizados no MVP. Unidades públicas oriundas do CNES/DATASUS
exigem aviso para confirmar por telefone antes do deslocamento.

## Atribuição obrigatória

Quando dados externos forem apresentados:

> Dados: EcoMed - fontes CNES/DATASUS (Ministerio da saúde) e LogMed/Sindusfarma.

## Evidências futuras

- versão/data do contrato consultado;
- cenarios e respostas anonimizadas usadas nos testes;
- latência com cache frio e quente;
- taxa de acerto do cache;
- quantidade de pontos no recorte testado;
- respostas de limite, indisponibilidade e dados incompletos;
- variantes reais encontradas em tipos de resíduos.

Nenhum resultado será preenchido antes da medição.
