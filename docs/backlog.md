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
- [x] adicionar Poppins (pesos 400–700) a partir do repositório oficial
  google/fonts, com a licença SIL OFL 1.1 empacotada (02/10/2026, D026);
- [x] disponibilizar Android SDK e JDK 17 (03/10/2026, em `.tools/`, fora do
  Git; APK de debug gerado);
- [ ] validar execução em Android real ou emulador.

## M2 - Experiência inicial e autenticação

Estado: em andamento.

- [ ] desenhar/reconciliar no Figma splash, onboarding, login, cadastro e
  recuperação de senha;
- [x] integrar o símbolo da marca como ativo Flutter e recurso Android;
- [ ] validar a splash nativa estática com fundo monocromático e símbolo no
  Android; o primeiro build (03/10/2026) revelou um atributo inválido no tema
  do Android 12+ (`android:postSplashScreenTheme`), já removido; falta ver em
  aparelho;
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
- [x] redesenhar a interface com design system próprio, contraste AA e
  assinatura visual da validade (02/10/2026, D025);
- [x] abertura com nome, slogan e faixa de validade, contínua com o
  carregamento (03/10/2026, D036);
- [x] onboarding com cenas animadas e textos fiéis ao que existe
  (03/10/2026, D037);
- [x] celebrações do cadastro (carimbo) e do descarte (trajeto, inspirado no
  Strava) (03/10/2026, D038);
- [ ] fornecer e aprovar os textos dos termos de uso e da política de
  privacidade;
- [ ] validar visualmente em Android real ou emulador, inclusive Android 12+.

O M2 permanece **em andamento** porque a validação Android, a reconciliação
visual no Figma e os textos jurídicos seguem pendentes. A verificação visual
automatizada usa 39 capturas determinísticas e fluxos em navegador real.

## M3 - Fluxo manual simulado

Estado: concluído em 24/08/2026.

- [x] criar modelo tipado de medicamento;
- [x] classificar validade com janela padrão de 30 dias e datas-limite testadas;
- [x] listar, cadastrar, editar, detalhar e remover medicamentos em memória;
- [x] ordenar medicamentos por validade;
- [x] exibir estados vazio e erro simulado com tentativa novamente;
- [x] atualizar dinamicamente o resumo da farmácia doméstica;
- [x] validar formatação, análise estática, 12 testes e build Web.

## M4 - Backend e persistência

Estado: em andamento (implementação local concluída em 02/10/2026).

- [x] FastAPI, configuração por `.env` e testes (49 testes, ruff, em
  03/10/2026);
- [x] PostgreSQL, SQLAlchemy 2.1 e Alembic (migração inicial verificada em
  SQLite e aplicada em PostgreSQL 17);
- [x] usuários, autenticação, sessão e medicamentos isolados por conta;
- [x] armazenamento de senha com Argon2id;
- [x] fluxo de recuperação de senha com código de uso único;
- [x] Docker Compose e instruções locais;
- [x] integração do aplicativo com a API Zelo (modo conectado), com token de
  renovação em armazenamento seguro;
- [x] Meu perfil: nome, e-mail e senha com senha atual, e exclusão da conta
  com todos os dados (03/10/2026, D034);
- [x] leitura assistida da embalagem com Tesseract no backend e conferência
  no app (03/10/2026, D035);
- [ ] provedor de e-mail para entregar o código de recuperação (hoje há caixa
  de saída local em desenvolvimento);
- [ ] hospedagem com HTTPS para uso fora da rede local;
- [ ] validar o armazenamento seguro e o modo conectado em Android.

## M5 - EcoMed e pontos

Estado: concluído no escopo de lista em 03/10/2026; mapa embutido segue no M8.

- [x] inspecionar o contrato publicado na documentação pública (02/10/2026);
- [x] implementar cliente somente no backend, com chave por variável de
  ambiente;
- [x] cache geográfico com coordenadas arredondadas, normalização e limite
  local de 60 requisições por minuto;
- [x] lista de pontos no app, com detalhes;
- [x] destaque logmed-*, aviso para os demais pontos e atribuição;
- [x] abertura do ponto em aplicativo de mapas e ligação;
- [x] executar `scripts/inspect_ecomed.py` com a chave e registrar o contrato
  real (03/10/2026: campos iguais aos publicados, `logmed-*` e IDs sem
  prefixo, `medicamento(s)` e `seringas`);
- [x] horários: a EcoMed não os fornece (lista sem `schedules`, detalhe
  vazio); continuam fora do app;
- [x] medir latência com cache frio e quente (mediana 579 ms e 5 ms, uma
  rodada em 12 municípios);
- [x] tempo-limite da localização e escolha de região durante a espera
  (D033);
- [x] voltar ao Início a partir de Descartar aberto pela Início.

## M6 - Descartes e notificações

Estado: em andamento.

- [x] registrar descarte e retirar os itens da farmácia ativa (API e memória);
- [x] histórico de descartes;
- [x] configuração e notificações locais de validade (03/10/2026, D042):
  planejador, controlador, serviço Android, tela em Conta e toque que abre a
  lista, com 34 testes;
- [ ] testes de permissões e agendamento em aparelho Android: ver o aviso de
  teste, o aviso agendado, o efeito do reinício e da economia de bateria;
- [ ] lembrete de reposição por quantidade (proposta, D039).

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
- OCR com confirmação humana: antecipado e implementado em 03/10/2026 a
  pedido do responsável (D035); falta avaliar com fotos reais e, depois,
  considerar o reconhecimento no aparelho;
- lembretes de uso e de reposição (proposta pendente, D039);
- leitura de receitas (proposta pendente, não recomendada, D040);
- expansão geográfica e avaliação de iOS;
- tema escuro coerente com a splash nativa.
