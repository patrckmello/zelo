# Backlog e marcos

Estados: **concluído**, **em andamento**, **planejado** e **bloqueado**.

## Regra de conclusão

Uma tarefa que altera código, escopo, requisito, arquitetura, integração ou
teste só pode ser marcada como concluída quando a documentação relacionada
também estiver atualizada. Consulte AGENTS.md.

## M0 - Diagnóstico e planejamento

Estado: concluído em 24/08/2026.

- inventariar repositório e documentação;
- verificar Flutter, Dart, Java, Android SDK, Python, Docker, Git e VS Code;
- registrar conflitos e decisões abertas;
- definir workspace e plano incremental.

## M1 - Fundação Flutter

Estado: em andamento.

- [x] disponibilizar Flutter 3.47.1 e Dart 3.13.1 de forma portátil;
- [x] executar flutter doctor -v;
- [x] gerar aplicativo com CLI oficial;
- [x] configurar identificador Android como br.edu.cesuca.zelo;
- [x] aplicar lints, Material 3 e paleta provisoriamente validada;
- [x] criar página inicial simulada e navegação mínima;
- [x] executar formatação, análise, testes e build Web;
- [ ] disponibilizar Android SDK e JDK 17;
- [ ] validar execução em Android real ou emulador;
- [ ] adicionar Poppins após receber os arquivos licenciados.

## M2 - Experiência inicial e autenticação

Estado: em andamento.

- desenhar no Figma splash, onboarding, login, cadastro e recuperação de senha;
- [x] integrar o símbolo da marca como ativo Flutter e recurso Android;
- [ ] validar a splash nativa estática com fundo monocromático e símbolo no
  Android; a implementação foi adicionada, mas o SDK Android segue indisponível;
- [ ] validar a animação curta da marca após a inicialização do Flutter; a
  implementação e os testes existem, mas ainda não foram executados;
- [ ] validar que a configuração de redução de movimento ignora a animação; o
  cenário automatizado existe, mas ainda não foi executado;
- criar onboarding de três páginas com opção de pular;
- persistir a conclusão do onboarding no dispositivo;
- criar interfaces de login, cadastro e recuperação de senha;
- restaurar sessão válida e disponibilizar logout;
- preparar credencial de demonstração para a Mostra;
- testar primeiro acesso, retorno ao aplicativo e rotas autenticadas.

A interface poderá começar com estado simulado. Autenticação real, armazenamento
seguro de tokens e recuperação de senha serão concluídos junto ao backend.

Bloqueio de validação em 14/09/2026: o clone atual não contém `.tools/flutter` e
não há Flutter/Dart global. A evidência anterior de 12 testes do M3 permanece
válida, mas não cobre as mudanças desta etapa.

## M3 - Fluxo manual simulado

Estado: concluído em 24/08/2026.

- [x] criar modelo tipado de medicamento;
- [x] classificar validade com janela padrão de 30 dias e datas-limite testadas;
- [x] listar, cadastrar, editar, detalhar e remover medicamentos em memória;
- [x] ordenar medicamentos por validade;
- [x] exibir estados vazio e erro simulado com tentativa novamente;
- [x] atualizar dinamicamente o resumo da farmácia doméstica;
- [x] validar formatação, análise estática, 12 testes e build Web.

Limitação conhecida: a versão deste marco não possui persistência. Os dados
voltam ao estado inicial quando o aplicativo é reiniciado.

## M4 - Backend e persistência

Estado: planejado.

- FastAPI, configuração e testes;
- PostgreSQL, SQLAlchemy e Alembic;
- usuários, autenticação, sessão e medicamentos;
- armazenamento de senha com hash apropriado;
- fluxo de recuperação de senha;
- Docker Compose e instruções locais;
- integração do aplicativo com a API Zelo.

## M5 - EcoMed e pontos

Estado: bloqueado pela documentação técnica e exemplos reais.

- inspecionar contrato real;
- implementar cliente somente no backend;
- cache geográfico, normalização e tratamento de limite;
- lista e detalhes de pontos;
- destaque logmed-*, aviso para unidades públicas e atribuição;
- abertura de rota externa.

## M6 - Descartes e notificações

Estado: planejado.

- registrar descarte e atualizar medicamentos;
- histórico;
- configuração e notificações locais de validade;
- testes de permissões e agendamento.

## M7 - Validação e Mostra Científica

Estado: planejado.

- testes funcionais e em Android real;
- medição da API com e sem cache;
- protocolo e testes de usabilidade;
- consolidação de limitações e evidências reais;
- resumo e apresentação conforme regulamento.

## M8 - Evoluções condicionais

Estado: planejado, fora do núcleo.

- mapa embutido;
- OCR com confirmação humana;
- expansão geográfica e avaliação de iOS.
