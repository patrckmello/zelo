# Registro de decisões

Os estados usados são **aceita**, **proposta** e **pendente**. Uma decisão só
será marcada como aceita quando confirmada ou aplicada e validada.

## D001 - Monorepo simples

- Estado: aceita
- decisão: manter `mobile`, `backend` e `docs` no mesmo repositório.
- Motivo: facilita coordenação, rastreabilidade e apresentação para uma equipe
  acadêmica de duas pessoas.

## D002 - Aplicativo Flutter com Android prioritário

- Estado: aceita
- decisão: Flutter/Dart e Material 3; Android primeiro.
- Identificador provisoriamente proposto: `br.edu.cesuca.zelo`.

## D003 - API própria entre aplicativo e EcoMed

- Estado: aceita
- decisão: somente o backend acessará a EcoMed e sua chave.
- Consequência: o Flutter não conterá chave, endpoint externo nem contrato
  acoplado a EcoMed.

## D004 - Fluxo manual antes de OCR

- Estado: aceita; revista em 03/10/2026
- decisão: OCR permanece fora do núcleo inicial.
- Motivo: preservar cadastro, classificação, descarte e testes confiáveis antes
  de introduzir reconhecimento sujeito a erro.
- Revisão (03/10/2026): com o núcleo manual implementado e testado, o
  responsável pediu a leitura da embalagem. Ela entra como atalho opcional do
  cadastro, que continua sendo o fluxo principal e o único no modo de
  demonstração. Detalhes em D035.

## D005 - Dependências Flutter

- Estado: aceita
- `shared_preferences ^2.5.5`: somente os booleanos não sensíveis de onboarding
  e sessão simulada.
- `http ^1.6.0` (02/10/2026): cliente da API Zelo; pacote oficial do Dart, com
  `MockClient` para testes sem rede.
- `flutter_secure_storage ^11.2.0` (02/10/2026): token de renovação no
  armazenamento seguro do sistema (RNF13).
- `geolocator ^14.1.1` (02/10/2026): localização aproximada sob demanda para
  buscar pontos (RF07).
- `url_launcher ^6.3.3` (02/10/2026): abrir o ponto no aplicativo de mapas e
  telefonar (RF10).
- `image_picker ^1.2.3` (03/10/2026): foto da embalagem pela câmera ou galeria
  (D035), com redução para no máximo 2400 px antes do envio. No Android usa o
  aplicativo de câmera e o seletor de fotos do sistema, sem permissão de
  câmera no manifesto.
- `http_parser ^4.1.2` (03/10/2026): tipo MIME do envio multipart; já era
  dependência transitiva de `http`.
- Continuam fora: bibliotecas de rotas, estado, animação e fontes remotas.
- Critério: adicionar apenas quando houver uso concreto, com justificativa,
  manutenção ativa, compatibilidade e impacto em testes avaliados. Todas as
  dependências ficam atrás de abstrações com implementações de teste.

## D006 - Paleta oficial

- Estado: proposta
- decisão: adotar o briefing mais recente (`#28A87B`, `#174C5B`, `#F4F7F6`,
  `#F5A623`, `#687078`) até confirmação da equipe.
- Conflito: o documento inicial registra `#28A878` e `#6B7D78`.

## D007 - Backend preferencial

- Estado: aceita em 02/10/2026
- Decisão: Python 3.13, FastAPI 0.142.2, SQLAlchemy 2.1.3, Alembic 1.20.0,
  PostgreSQL 17 (Docker), psycopg 3.3.6, Argon2 (argon2-cffi 25.1.0), PyJWT
  2.15.1 e httpx 0.28.1, fixados em `backend/requirements.txt`.
- Acréscimos (03/10/2026): python-multipart 0.0.32 (upload da foto) e Pillow
  12.3.0 (preparo da imagem), além do Tesseract 5 com o idioma `por` na imagem
  Docker (D035). Depois, rapidocr 3.9.2 e onnxruntime 1.30.0 (motor principal
  do OCR, com OpenCV e os modelos PP-OCRv6 embutidos no build).
- Validação: 37 testes, ruff, migração em banco limpo e Docker Compose com
  PostgreSQL executados em 02/10/2026.

## D008 - Navegação e mapa

- Estado: aceita para lista e mapa externo; fornecedor de mapa embutido pendente
- Decisão: lista de pontos no app e abertura externa. No Android, o intent
  `geo:` deixa a pessoa escolher o aplicativo de mapas; na Web, abre o
  OpenStreetMap no navegador. Nenhum fornecedor fica embutido no app.
- Pendente: mapa embutido (M8) e a respectiva política de uso.

## D009 - Regra de proximidade do vencimento

- Estado: aceita
- Decisão: usar janela padrão de 30 dias corridos, com comparação apenas da data.
- Limites: validade anterior à data de referência é vencida; de hoje até 30 dias,
  inclusive, está próxima do vencimento; acima de 30 dias está válida.
- Configuração: a regra aceita outra janela internamente, mas a interface ainda
  não oferece configuração ao usuário.

## D010 - Fluxo inicial obrigatório

- Estado: aceita
- Decisão: o MVP terá splash, onboarding no primeiro acesso e verificação de
  sessão antes de apresentar login ou página inicial.
- Motivo: apresentar a identidade do Zelo e orientar novos usuários antes do
  uso das funcionalidades principais.

## D011 - Animação da marca

- Estado: aceita para a camada Flutter; validação Android permanece pendente
- Decisão: usar splash nativa estática seguida de animação curta executada pelo
  Flutter, aproveitando o movimento circular da seta de devolução.
- Implementação: usar o PNG oficial disponível com opacidade, escala
  e rotação por 800 ms, sem dependência externa, nome ou slogan. Quando a
  redução de movimento está ativa, a animação é ignorada.
- Rive não foi adicionado porque o repositório ainda não contém a fonte vetorial
  da marca. A alternativa poderá ser reavaliada quando esse arquivo existir.
- Restrição: a animação não deve simular carregamento inexistente nem atrasar
  desnecessariamente a entrada. Deve respeitar redução de movimento.
- Evidência: os testes Flutter de conclusão automática e redução de movimento
  foram aprovados em 14/09/2026. A transição da splash nativa ainda precisa ser
  validada em Android real ou emulador.
- Revisão (03/10/2026): o responsável achou a abertura fraca; nome e slogan
  passam a fazer parte dela (D036).

## D012 - Autenticação do MVP

- Estado: aceita
- Decisão: incluir cadastro, login por e-mail e senha, recuperação de senha,
  restauração de sessão e logout.
- Decisão de escopo: não implementar login social no MVP.
- Mostra: manter credencial de demonstração previamente testada.

## D013 - Documentação viva

- Estado: aceita
- Decisão: implementação, requisitos, decisões, arquitetura, testes e evidências
  devem ser atualizados no mesmo ciclo de trabalho.
- Regra operacional: uma tarefa não é considerada concluída se o código mudou e
  a documentação correspondente permaneceu desatualizada.
- Aplicação: agentes devem seguir AGENTS.md em todas as sessões futuras.


## D014 - Estado do fluxo manual

- Estado: aceita
- Decisão: usar `MedicationStore` com `ChangeNotifier` e armazenamento em
  memória para validar o primeiro fluxo vertical sem dependências externas.
- Consequência: a página inicial e as telas de medicamentos compartilham o mesmo
  estado durante a execução, mas os dados são reiniciados ao fechar o app.
- Evolução: a persistência será conectada no M4 preservando as regras de domínio
  e os testes já existentes.

## D015 - Bootstrap e navegação do M2

- Estado: aceita
- Decisão: centralizar os estados `initializing`, `firstAccess`,
  `unauthenticated`, `authenticated` e `recoverableError` em um controlador
  injetável, sem biblioteca adicional de rotas ou gerenciamento de estado.
- Navegação: trocar o conteúdo da rota raiz ao autenticar ou sair. Assim, Voltar
  não reabre splash, onboarding ou login após a autenticação.
- Inicialização: montar o bootstrap sob a animação desde o primeiro quadro,
  compartilhar cargas concorrentes e ignorar conclusões após o descarte. A
  animação define somente o tempo mínimo de identidade; não simula carregamento.
- Recuperação: falhas de leitura mostram mensagem segura e ação Tentar novamente.

## D016 - Autenticação simulada e armazenamento mínimo

- Estado: aceita para o M2
- Decisão: definir uma interface substituível de autenticação e uma implementação
  simulada, com fixture pública fictícia para demonstração.
- Persistência: salvar apenas `simulated_session_active`; não persistir nome,
  e-mail ou senha e não criar token ou JWT fictício.
- Limite: o marcador booleano não é autenticação segura.
- Evolução (02/10/2026): autenticação real, isolamento de usuários e tokens
  protegidos foram implementados no modo conectado (D027, D029). A simulação
  permanece somente no modo demonstração.

## D017 - Preferência do onboarding

- Estado: aceita
- Decisão: persistir `onboarding_completed = true` ao concluir ou pular, por uma
  abstração própria apoiada em `shared_preferences` na aplicação e memória nos
  testes.
- Privacidade: a preferência não contém dado pessoal ou de saúde.

## D018 - Medicamentos como dados indiretos de saúde

- Estado: aceita
- Decisão: tratar o cadastro de medicamentos como dado capaz de revelar
  indiretamente informações de saúde.
- Consequências: minimizar dados, não registrar medicamentos ou dados pessoais em
  logs e manter sessão/autenticação separadas do armazenamento de medicamentos.

## D019 - Protocolo acadêmico de avaliação futura

- Estado: aceita como planejamento; coleta ainda PENDENTE
- Decisão: avaliar futuramente com 12 adultos em tarefas orientadas, registrando
  tempo, conclusão, erros e dificuldades, além de perguntas sobre vínculo com o
  SUS e perguntas abertas.
- Regra: resultados só serão registrados como evidência depois da coleta real e
  do procedimento acadêmico aplicável.

## D020 - Divergências dos dados EcoMed

- Estado: aceita como regra futura
- Decisão: normalizar respostas, identificar a origem, priorizar farmácias
  `logmed-*`, apresentar aviso específico para unidades públicas e omitir
  horários ausentes em vez de fabricá-los.
- Limite: a integração segue bloqueada até a inspeção do contrato e de exemplos
  reais; a regra não constitui garantia de atendimento.

## D021 - Relação com os ODS

- Estado: aceita
- Decisão: relacionar o Zelo ao ODS 3, pelo apoio ao cuidado e à prevenção de
  riscos, e ao ODS 12, pela redução de desperdício e descarte responsável.
- Limite: essa relação expressa o enquadramento do projeto e não prova impacto
  mensurado, que permanece PENDENTE.

## D022 - Contraste dos controles interativos

- Estado: aceita
- Decisão: usar azul-petróleo como cor primária interativa e manter o verde como
  cor secundária/de marca. O contraste medido do azul-petróleo sobre o fundo
  claro é 8,77:1; o verde original como texto sobre branco tinha cerca de 3,01:1.

## D023 - Navegação autenticada definitiva

- Estado: aceita
- Decisão: usar Início, Descartar, Histórico e Conta como os quatro destinos da
  barra inferior.
- Medicamentos: abrir a lista como rota a partir da Home e manter ali as ações
  de cadastro, sem criar aba exclusiva.
- Sessão: concentrar o logout em Conta e identificar toda sessão atual como
  simulada, pois o marcador booleano não distingue login, cadastro e entrada de
  demonstração. Nenhum dado pessoal deve ser inventado.
- Limites originais: Descartar futuro até a integração EcoMed e Histórico
  vazio sem RF11/RF12.
- Atualização (02/10/2026): Descartar consulta pontos pela API Zelo quando ela
  está configurada (D030) e informa a dependência quando não está; Histórico
  mostra os descartes registrados (D032), sem exemplos fabricados.
- Atualização (03/10/2026): quando Descartar é aberto pelo atalho da Início, o
  cabeçalho oferece "Início" para voltar; o voltar do sistema (ou do navegador)
  em qualquer aba que não seja Início retorna a ela antes de sair do app.

## D024 - Reconciliação visual local do M2

- Estado: aceita para a implementação Flutter; Figma e Android permanecem
  pendentes
- Decisão: manter somente o símbolo oficial na abertura e substituir os ícones
  isolados em círculos do onboarding por composições feitas com o ativo oficial,
  formas, superfícies e ícones Material.
- Restrição: não adicionar ativos externos, redesenhar a marca ou solicitar
  permissões no onboarding.
- Revisão (03/10/2026): as composições estáticas deram lugar a cenas animadas
  com as mesmas peças (D037).

## D025 - Design system e redesenho da interface

- Estado: aceita em 02/10/2026; reconciliação no Figma permanece pendente
- Decisão: tema claro único com superfícies tonais e bordas finas, Poppins com
  hierarquia por peso e cor, tokens de cor com contraste AA calculado e
  componentes compartilhados em `lib/core`. A assinatura visual é a validade:
  carimbo `VAL`, faixa de situação, linha de validade e barra de composição.
- Motivo: o pedido de interface mais moderna e limpa e a correção dos selos de
  situação, que tinham contraste de 1,86:1 (âmbar) e 2,67:1 (verde).
- Restrições: sem tema escuro nesta etapa, para manter coerência com a splash
  nativa clara; ilustrações feitas com o ativo oficial e formas simples, sem
  redesenhar a marca. Detalhes em `docs/design-system.md`.

## D026 - Fonte Poppins

- Estado: aceita em 02/10/2026
- Decisão: empacotar Poppins 400, 500, 600 e 700 obtidas do repositório oficial
  `google/fonts` (`ofl/poppins`), com hashes conferidos, e registrar a licença
  SIL OFL 1.1 na tela de licenças do app.
- Motivo: Poppins é a tipografia do Manual de Identidade; a licença permite
  distribuição embutida no aplicativo. A fonte é local, sem download em tempo de
  execução.

## D027 - Tokens de sessão

- Estado: aceita em 02/10/2026
- Decisão: token de acesso JWT HS256 de 15 minutos e token de renovação opaco
  de 30 dias, armazenado no servidor somente como SHA-256, com rotação a cada
  uso. Reuso de um token já trocado revoga todas as sessões da conta; a troca de
  senha também.
- App: guarda apenas o token de renovação no armazenamento seguro; o token de
  acesso fica em memória. Um 401 provoca uma única renovação antes de repetir a
  chamada; se ela falhar, a sessão é encerrada e o app volta ao login.

## D028 - Recuperação de senha

- Estado: aceita para o fluxo; entrega por e-mail pendente
- Decisão: código aleatório de uso único, válido por 30 minutos e guardado como
  hash. A solicitação responde igual com ou sem conta. A confirmação troca a
  senha e encerra as sessões.
- Pendente: provedor de e-mail. Em desenvolvimento, o código pode ser gravado
  em uma caixa de saída local ignorada pelo Git; em produção a entrega fica
  desativada até a escolha do provedor.

## D029 - Modos de execução do aplicativo

- Estado: aceita em 02/10/2026
- Decisão: sem `--dart-define=ZELO_API_URL`, o app roda em demonstração
  (sessão simulada, dados fictícios em memória, sem pontos). Com a URL, usa a
  API Zelo para autenticação, medicamentos, descartes e pontos.
- Motivo: manter uma apresentação possível sem servidor e, ao mesmo tempo, o
  fluxo real com persistência.
- Consequência: telas e estados são os mesmos nos dois modos; mudam somente os
  repositórios e o serviço de autenticação.

## D030 - Cliente EcoMed

- Estado: aceita; validada com respostas reais em 03/10/2026
- Fonte: https://ecomed.eco.br/desenvolvedores, consultada em 02/10/2026:
  `GET /api/public/v1/pontos/proximos?lat=&lng=&raio=` (raio 500–50.000 m,
  padrão 5.000, até 30 pontos ordenados por distância), `GET /pontos/:id`,
  header `X-API-Key`, limite de 60 requisições por minuto com cabeçalhos
  `X-RateLimit-*`.
- Decisão: cliente somente no backend; cache em memória de 300 s por chave com
  coordenadas arredondadas a três casas e raio; limitador local de 60
  requisições por minuto antes de chamar a EcoMed; pontos sem identificador,
  nome ou coordenadas válidas são descartados; `residueTypes` normalizado
  (medicamento/medicamentos, seringa/seringas).
- Origem: somente IDs `logmed-*` são marcados como farmácias LogMed; os demais
  exigem confirmação por telefone, pois podem incluir unidades públicas.
- Atribuição exibida: "Dados: EcoMed — fontes CNES/DATASUS (Ministério da
  Saúde) e LogMed/Sindusfarma.", que cobre a exigência pública "Dados: EcoMed +
  LogMed/Sindusfarma".
- Contrato real (03/10/2026): confere com o publicado; a lista não traz
  `schedules` e o detalhe consultado trouxe a lista vazia. Horários seguem
  fora do app, sem dedução. Variantes `medicamento`, `medicamentos` e
  `seringas` já eram cobertas pela normalização. Medições em
  `docs/ecomed-integration.md`.

## D031 - Localização e regiões de referência

- Estado: aceita em 02/10/2026
- Decisão: pedir somente localização aproximada (`ACCESS_COARSE_LOCATION`),
  depois de explicar o uso e apenas quando a pessoa iniciar a busca. O app
  arredonda as coordenadas a três casas antes de enviá-las.
- Alternativa: escolher um município da Região Metropolitana de Porto Alegre,
  recorte inicial do projeto; usa-se a sede municipal (coordenadas do
  Wikidata/Wikipédia, consulta em 02/10/2026).

## D032 - Registro de descarte

- Estado: aceita em 02/10/2026
- Decisão: o descarte guarda data, local informado ou ponto escolhido e uma
  cópia de nome, quantidade e validade de cada item. Os medicamentos saem da
  farmácia ativa (marcados como descartados no servidor), preservando o
  histórico mesmo que o cadastro mude depois.
- Restrição: a data não pode estar no futuro (tolerância de um dia para fusos).

## D033 - Tempo-limite da localização

- Estado: aceita em 03/10/2026
- Contexto: em um computador sem Wi-Fi o navegador concedeu a permissão, mas a
  posição nunca chegou e a tela ficou no carregamento indefinidamente.
- Decisão: a leitura da posição usa precisão baixa e tempo-limite de 15 s no
  provedor, com uma trava de 30 s no controlador. Durante a espera, a tela
  mostra "Obtendo sua localização…" e já oferece escolher uma região (D031).
  Falha, recusa ou tempo esgotado terminam em mensagem com o mesmo atalho.
- Web: o pedido de permissão é feito pelo próprio navegador ao ler a posição;
  a consulta prévia de permissão do plugin não tem tempo-limite e é evitada.

## D034 - Perfil e exclusão de conta

- Estado: aceita em 03/10/2026
- Decisão: com a API Zelo, Conta abre "Meu perfil" para alterar nome, e-mail
  (com senha atual) e senha (com senha atual), e para excluir a conta.
  Trocar a senha revoga todas as sessões e devolve uma nova; excluir apaga
  conta, medicamentos, descartes e sessões em cascata, atendendo ao direito
  de eliminação da LGPD.
- Proteção: confirmações de senha usam o mesmo limitador do login, por conta.
- Demonstração: sem servidor não há dados pessoais; Conta explica que o
  perfil exige uma conta Zelo.

## D035 - Leitura assistida da embalagem (OCR)

- Estado: aceita em 03/10/2026, a pedido do responsável
- Decisão: a foto é lida no backend com Tesseract 5 (idioma `por`), em
  `POST /v1/ocr/medication`. A imagem é processada em memória e descartada;
  não é gravada, e o log guarda só a quantidade de linhas e quais campos foram
  encontrados, nunca o texto lido.
- Resultado: sugestões de nome (por tamanho da linha), validade (rótulos
  VAL/VALIDADE/VENC, distinguindo FAB; mês/ano vale até o último dia do mês) e
  quantidade. O aplicativo preenche o formulário e exige conferência; nada é
  salvo sem a pessoa tocar em salvar.
- Motivos: funciona igual no Android e na web, não aumenta o tamanho do app e
  usa software livre sem chave externa. Custo: a foto trafega até a API Zelo
  (HTTPS em produção) e a leitura depende do servidor.
- Limites: até 8 MB e 40 megapixels por imagem, 20 leituras por minuto por
  conta, 503 quando o Tesseract não está instalado.
- Evolução registrada: reconhecimento no próprio aparelho (ex.: ML Kit) quando
  houver build Android validado, mantendo a mesma tela de conferência.
- Revisão (03/10/2026): no teste do responsável com embalagens reais a leitura
  ficou "bem ruim". O motor principal passou a ser o RapidOCR 3.9.2 com os
  modelos PP-OCRv6 *small* do PaddleOCR (ONNX Runtime 1.30, só CPU, licença
  Apache-2.0), embutidos na imagem Docker; o Tesseract ficou como reserva
  automática e pode ser escolhido com `ZELO_OCR_ENGINE=tesseract`. Quando a
  validade não aparece, a API tenta de novo com a foto levemente desfocada
  (une os pontinhos da impressão a jato de tinta) e girada 90° e 270° (validade
  na aba), parando na primeira que encontrar (até seis leituras). O
  interpretador passou a aceitar rótulo grudado na data ("VAL01/28",
  "02/2025VAL") e a ignorar nomes de laboratório e "frasco" como nome. A foto
  continua só em memória, sem sair do computador da API. Medição em
  `docs/scientific-evidence.md`.

## D036 - Abertura com assinatura completa

- Estado: aceita em 03/10/2026, a pedido do responsável; revisa o D011
- Decisão: a abertura parte do mesmo quadro da splash nativa (símbolo oficial
  centralizado, 144 px) e, em 1,3 s, gira o símbolo como antes, sobe-o e
  revela o nome "Zelo", o slogan "Cuide. Organize. Descarte certo." e a faixa
  de validade em três segmentos (verde, âmbar, vermelho). Termina com uma
  dissolução de 260 ms; um toque encerra antes.
- Carregamento: se a inicialização ainda não terminou, a tela seguinte é o
  mesmo quadro final, e só então um brilho percorre a faixa, indicando a
  espera real. Nada simula carregamento que não existe.
- Restrições mantidas: só o PNG oficial do símbolo, sem redesenho; redução de
  movimento mostra a assinatura pronta e segue sem animar; a inicialização
  roda em paralelo (o tempo de marca passou de 0,8 s para 1,3 s no pior caso
  do modo demonstração).

## D037 - Onboarding com cenas animadas

- Estado: aceita em 03/10/2026, a pedido do responsável
- Decisão: cada página tem um palco tingido (verde, âmbar, petróleo) com uma
  cena que toca quando a página aparece: embalagens pousam na prateleira e
  recebem o carimbo VAL; o marcador "Hoje" entra na janela de 30 dias e a
  embalagem passa de verde a âmbar; uma embalagem vencida segue de casa até o
  ponto de coleta. As peças acompanham o arraste (paralaxe) e o texto fica
  alinhado à esquerda, com rótulos do slogan (Organize, Cuide, Descarte
  certo).
- Texto: a segunda página deixou de prometer alertas (as notificações ainda
  não existem, RF06) e diz o que o app faz hoje: destacar o que vence em 30
  dias. A última página explica que nenhuma permissão é pedida agora.
- Acessibilidade: as cenas são decorativas, descritas por rótulo e sem escala
  de texto própria; com redução de movimento aparecem prontas.

## D038 - Celebrações do cadastro e do descarte

- Estado: aceita em 03/10/2026, a pedido do responsável
- Cadastro: depois de salvar um medicamento novo, uma confirmação curta
  (1,8 s, fecha sozinha ou com um toque) mostra a embalagem recebendo o
  carimbo VAL com a faixa da situação; em seguida o aviso oferece "Cadastrar
  outro" e some em 6 s (`persist: false`, pois o Flutter mantém avisos com
  ação abertos por padrão). Edições não são celebradas. Com redução de movimento, só o aviso.
- Descarte: inspirado no "salvar atividade" do Strava (referência do
  responsável: <https://60fps.design/shots/strava-save-activity-morph-path-animation>).
  O trajeto nasce no botão de confirmar, se desenha, engrossa e cresce até
  varrer a tela, que vira petróleo. O traçado é geométrico, como uma linha de
  metrô: trechos retos (horizontal, vertical e diagonal a 45°, a inclinação
  da cápsula do símbolo), cantos com raio constante e um laço em círculo
  perfeito, como a seta de devolução (revisto duas vezes em 03/10/2026: a
  curva livre ficou "torta" para o responsável); o "Mandou bem!" aparece com o trajeto
  animado ao fundo e números do próprio registro (medicamentos, unidades e
  ordem do descarte). Depois de 3,2 s, ou com um toque, a camada se dissolve
  no Histórico, onde o registro novo sobe com um contorno verde.
- Implementação: a celebração é uma camada acima do app; enquanto cobre a
  tela, as rotas de registro saem e o Histórico fica por baixo.
- Limites: só dados reais do registro e do histórico, sem estimar impacto
  ambiental; com leitor de tela ativo não segue sozinha; com redução de
  movimento aparece pronta e espera o toque.

## D039 - Lembretes de uso e de reposição

- Estado: pendente de decisão do responsável (proposta em 03/10/2026)
- Proposta: lembrete no horário definido pela pessoa para usar um
  medicamento, com "usei" e "pular", e aviso de reposição quando a quantidade
  estimada chegar a um limite escolhido. A dose e o horário vêm sempre da
  pessoa (ou da prescrição que ela tem em mãos); o Zelo não sugere dose,
  intervalo ou duração.
- Dependências: notificações locais (mesma base do RF06) e validação em
  Android; dados de uso são dados de saúde (D018) e ampliam o escopo do MVP.
- Recomendação registrada: implementar primeiro o RF06 (vencimento, feito em
  03/10/2026, D042), depois
  reposição simples por quantidade e, por último, lembretes de uso.

## D040 - Leitura de receitas

- Estado: pendente de decisão do responsável; não recomendada para o MVP
- Motivos: receitas costumam ser manuscritas (o Tesseract não lê bem
  manuscrito), contêm nome do paciente, do médico e posologia, e um erro de
  leitura de dose é risco à saúde. Também aproxima o app de orientação
  terapêutica, fora do escopo.
- Alternativa avaliável no futuro: receitas digitais com assinatura
  verificável, apenas para preencher nome do medicamento, sem posologia.

## D041 - Ferramentas Android locais

- Estado: aceita em 03/10/2026
- Decisão: JDK 17 (Temurin 17.0.20.1) e Android SDK (platform-tools,
  plataforma 36, build-tools 36.0.0, NDK 28.2.13676358, CMake instalado pelo
  AGP) ficam em `.tools/`, fora do Git, como o Flutter portátil. O cache do
  Gradle fica em `.tools/gradle-home` (variável `GRADLE_USER_HOME`).
- Ajustes locais, sem alterar o projeto: o `gradle.properties` de
  `.tools/gradle-home` limita o Gradle a 2 GB (o projeto pede 8 GB e a
  máquina tem pouca RAM livre), desliga o daemon residente e desliga a
  compilação incremental do Kotlin, que falha no Windows quando os plugins
  (cache do Pub no C:) e o build (no D:) estão em discos diferentes.
- Ferramenta: o `sdkmanager` das cmdline-tools de 2026 foi substituído pelo
  Android CLI (`android.exe sdk install platforms/android-36 ...`), usado com
  `--no-metrics`.

## D042 - Lembretes de validade (RF06)

- Estado: aceita em 03/10/2026; verificada em testes de VM e compilação do
  APK, **sem aviso real exibido em aparelho** (PENDENTE)
- Decisão: avisos locais agendados com `flutter_local_notifications` 22.3.1
  (e `timezone` 0.11.1), só no Android, 30 dias antes, 7 dias antes e no dia
  do vencimento, às 9h. A hora local vira um instante em UTC, então o banco de
  fusos não é carregado nem se depende de `flutter_timezone`.
- Alarmes inexatos (`inexactAllowWhileIdle`): evita a permissão de alarme
  exato (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, sujeita a revisão nas
  lojas); o aviso pode atrasar alguns minutos, o que basta. Permissões novas:
  `RECEIVE_BOOT_COMPLETED` (reagendar depois de reiniciar) e
  `POST_NOTIFICATIONS`, pedida só ao ligar. Exige desugaring do Java
  (`desugar_jdk_libs` 2.1.4).
- Privacidade: nenhum dado sai do aparelho; visibilidade "privada" esconde os
  nomes em tela bloqueada com senha; sair da conta apaga avisos pendentes e
  exibidos. A escolha (um booleano) fica em `shared_preferences` (D005).
- Limite de 60 avisos pendentes (os mais próximos), por causa das restrições
  do sistema a alarmes pendentes; reagrupar por data reduz a contagem.
- Alternativa descartada: push pelo servidor. Exigiria Firebase, token do
  aparelho no servidor e envio de nomes de medicamentos a terceiros.
- Fora desta decisão: lembrete de uso e de reposição (D039) seguem pendentes.
