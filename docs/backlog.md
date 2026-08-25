# Backlog e marcos

Estados: **concluído**, **em andamento**, **planejado** e **bloqueado**.

## M0 - Diagnóstico e planejamento

Estado: concluído em 24/08/2026.

- inventariar repositório e documentação;
- verificar Flutter, Dart, Java, Android SDK, Python, Docker, Git e VS Code;
- registrar conflitos e decisões abertas;
- definir workspace e plano incremental.

## M1 - Fundação Flutter

Estado: em andamento.

- [x] disponibilizar Flutter 3.47.1 e Dart 3.13.1 de forma portátil;
- [x] executar `flutter doctor -v`;
- [x] gerar aplicativo com CLI oficial;
- [x] configurar identificador Android como `br.edu.cesuca.zelo`;
- [x] aplicar lints, Material 3 e paleta provisoriamente validada;
- [x] criar página inicial simulada e navegação mínima;
- [x] executar formatação, análise, testes e build Web;
- [ ] disponibilizar Android SDK e JDK 17;
- [ ] validar execução em Android real ou emulador;
- [ ] adicionar Poppins após receber os arquivos licenciados.

## M2 - Fluxo manual simulado

Estado: planejado.

- modelo tipado de medicamento;
- regra testada de situação da validade;
- lista, cadastro, edição, detalhes e remoção em memória;
- estados vazio e erro simulados;
- resumo da farmácia doméstica.

## M3 - Backend e persistência

Estado: planejado.

- FastAPI, configuração e testes;
- PostgreSQL, SQLAlchemy e Alembic;
- usuários, autenticação e medicamentos;
- Docker Compose e instruções locais;
- integração do aplicativo com a API Zelo.

## M4 - EcoMed e pontos

Estado: bloqueado pela documentação técnica e exemplos reais.

- inspecionar contrato real;
- implementar cliente somente no backend;
- cache geográfico, normalização e tratamento de limite;
- lista e detalhes de pontos;
- destaque `logmed-*`, aviso para unidades públicas e atribuição;
- abertura de rota externa.

## M5 - Descartes e notificações

Estado: planejado.

- registrar descarte e atualizar medicamentos;
- histórico;
- configuração e notificações locais de validade;
- testes de permissões e agendamento.

## M6 - Validação e Mostra Científica

Estado: planejado.

- testes funcionais e em Android real;
- medição da API com e sem cache;
- protocolo e testes de usabilidade;
- consolidação de limitações e evidências reais;
- resumo e apresentação conforme regulamento.

## M7 - Evoluções condicionais

Estado: planejado, fora do núcleo.

- mapa embutido;
- OCR com confirmação humana;
- expansão geográfica e avaliação de iOS.
