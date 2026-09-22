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

- [ ] desenhar/reconciliar no Figma splash, onboarding, login, cadastro e
  recuperação de senha;
- [x] integrar o símbolo da marca como ativo Flutter e recurso Android;
- [ ] validar a splash nativa estática com fundo monocromático e símbolo no
  Android; a implementação foi adicionada, mas o SDK Android segue indisponível;
- [x] validar por teste automatizado a animação curta da marca após a
  inicialização do Flutter; a transição nativa ainda depende de Android;
- [x] validar que a configuração de redução de movimento ignora a animação;
- [x] criar onboarding responsivo de três páginas com opção de pular;
- [x] persistir a conclusão do onboarding no dispositivo;
- [x] criar interfaces de login, cadastro e recuperação de senha;
- [x] restaurar sessão simulada e disponibilizar logout;
- [x] disponibilizar entrada de demonstração com fixture pública fictícia;
- [x] testar primeiro acesso, retorno ao aplicativo e rotas autenticadas;
- [x] iniciar o bootstrap em paralelo à animação, sem espera artificial;
- [x] usar somente o símbolo oficial na animação Flutter;
- [x] reconciliar a navegação para Início, Descartar, Histórico e Conta;
- [x] manter Medicamentos acessível pela Home, sem aba exclusiva;
- [x] mover o logout para Conta e identificar a sessão simulada sem dados
  pessoais;
- [x] adicionar estados honestos para pontos futuros e histórico vazio;
- [x] substituir os círculos genéricos do onboarding por composições visuais
  com o ativo oficial e elementos vetoriais simples;
- [ ] fornecer e aprovar os textos dos termos de uso e da política de
  privacidade;
- [ ] validar visualmente em Android real ou emulador, inclusive Android 12+.

A interface usa autenticação simulada substituível e persiste somente um marcador
booleano não sensível. Autenticação real, isolamento de usuários, armazenamento
seguro de tokens e recuperação efetiva serão concluídos no M4.

Validação em 21/09/2026: o Flutter portátil foi restaurado; formatação, análise,
47 testes e build Web foram aprovados. O layout foi exercitado por testes em
390 × 844, 320 × 568 e com texto ampliado. A inspeção visual interativa Web
não foi realizada porque o ambiente de automação não disponibilizou navegador
controlável. O M2 permanece **em andamento** porque a validação Android, a
reconciliação visual no Figma e os textos jurídicos seguem pendentes.

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
