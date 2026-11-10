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
- [x] envio do código de recuperação por SMTP com conta dedicada e senha de
  aplicativo, em segundo plano (10/10/2026, D043; testes com servidor
  simulado);
- [ ] configurar a conta SMTP no `backend/.env`, enviar um e-mail real e
  conferir caixa de entrada e spam;
- [ ] provedor transacional com domínio próprio (uso real, após a Mostra);
- [x] publicar a API no Cloud Run com Neon em modo privado (31/10/2026, D044;
  `/health`, login e medicamentos verificados na nuvem);
- [x] tornar a API pública (`allUsers` / `roles/run.invoker`) para o app no
  celular: executado pelo responsável em 31/10/2026 (a ferramenta de permissões
  havia recusado a ação);
- [x] instalar o APK apontando para a nuvem em um Galaxy A12 (Android 13) e
  validar abertura, login e tela inicial (31/10/2026);
- [ ] testar no celular os demais fluxos: cadastro, câmera e leitura de
  embalagem com fotos reais, localização e pontos, descarte, histórico,
  persistência da sessão e avisos de validade;
- [x] tratar a partida a frio: 12,19 s na primeira chamada depois de mais de
  uma hora parado (uma medição), contra o tempo limite de 15 s do app. Decisão
  de 31/10/2026: tempo limite de 40 s só até a primeira resposta
  (`firstRequestTimeout`, 153 testes Flutter passando) e aquecimento da API
  antes de apresentar (`docs/deployment.md`); instância sempre ligada
  descartada por custo (não calculado);
- [x] repetir a partida a frio com o APK novo no celular: 6,59 s, concluiu sem
  erro e restaurou a sessão (31/10/2026; medições de 6,6 s e 12,2 s);
- [x] terceira medição, a partir do computador, depois de mais de 9 dias parado:
  `/health` 200 em 14,94 s (10/11/2026); as três medições ficam entre 6,6 s e
  14,9 s, perto do limite antigo de 15 s do app, o que sustenta os 40 s na
  primeira chamada;
- [x] verificar a consulta de pontos EcoMed pela API na nuvem: 30 pontos em Porto
  Alegre (1,92 s cache frio, 0,32 s quente) e 30 em Cachoeirinha (1,03 s e
  0,36 s), sem liberação de IP (10/11/2026, por script; no celular continua
  PENDENTE);
- [ ] **condicional:** se a EcoMed exigir lista de IPs permitidos, configurar IP
  de saída fixo no Cloud Run (VPC + Cloud NAT + IP reservado), planejado e **não
  testado** em `docs/deployment.md`; o Cloud Run não tem um IP único para
  informar, e ativar a restrição antes disso derruba os pontos na nuvem;
- [x] testes reexecutados em 10/11/2026: 153 Flutter, 71 backend, `analyze`,
  formatação e `ruff` sem falhas;
- [ ] medir o tempo de abertura de um build de **release** (o de debug levou
  cerca de 9 s só para desenhar a primeira tela no Galaxy A12);
- [ ] medir a memória real com foto de 2400 × 1800 px na nuvem (leitura de 4
  fotos de 1290 × 915 px: 200, 13,96 s a primeira e 5,2–5,6 s as demais; a
  imagem ocupa 348,98 MB no repositório) e repetir a partida a frio;
- [ ] lembrar que a conta Google é de teste gratuito (69 dias restantes em
  31/10/2026): depois disso a API para, salvo "upgrade";
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
