# Requisitos

## Legenda

- **Confirmado:** aprovado para o produto.
- **Implementado:** existe em código e foi verificado.
- **Planejado:** pertence a um marco futuro.
- **Pendente:** depende de decisão ou insumo.

O aplicativo tem dois modos (D029). No **modo conectado** os requisitos usam a
API Zelo; no **modo demonstração** a sessão é simulada e os dados ficam em
memória. A coluna de estado registra o que foi verificado em 02/10/2026; a
validação em Android continua pendente para todos os itens.

## Funcionais do MVP

| ID | Requisito | Estado |
|---|---|---|
| RF01 | Cadastrar conta com nome, e-mail e senha | Implementado na API (Argon2id); simulado na demonstração |
| RF02 | Cadastrar medicamento com nome, validade, quantidade e observações | Implementado com persistência na API; em memória na demonstração |
| RF03 | Listar medicamentos | Implementado, ordenado por validade e com filtros por situação |
| RF04 | Editar e remover medicamentos | Implementado, isolado por conta na API |
| RF05 | Classificar como válido, próximo do vencimento ou vencido | Implementado e testado (regra única no domínio) |
| RF06 | Notificar proximidade do vencimento | Implementado e testado em VM (151 testes); aviso real em aparelho Android **PENDENTE** (D042) |
| RF07 | Consultar pontos próximos por meio da API Zelo | Implementado e verificado com respostas reais da EcoMed (03/10/2026) |
| RF08 | Exibir pontos em lista e posteriormente em mapa | Lista implementada; mapa embutido planejado (M8) |
| RF09 | Exibir informações disponíveis e confiabilidade do ponto | Implementado (origem LogMed ou confirmação necessária); horários não exibidos porque a EcoMed não os fornece (lista sem `schedules`, detalhe vazio) |
| RF10 | Abrir rota em aplicativo externo | Implementado (intent `geo:` no Android, OpenStreetMap na Web); Android pendente |
| RF11 | Registrar descarte simples | Implementado na API; em memória na demonstração |
| RF12 | Consultar histórico de descartes | Implementado na API; em memória na demonstração |
| RF13 | Autenticar usuário por e-mail e senha | Implementado na API; simulado na demonstração |
| RF14 | Solicitar recuperação de senha | Implementado com código de uso único; entrega por e-mail **PENDENTE** de provedor |
| RF15 | Restaurar uma sessão válida ao reabrir o aplicativo | Implementado com token de renovação em armazenamento seguro; simulado na demonstração |
| RF16 | Encerrar a sessão do usuário | Implementado, com revogação no servidor, exclusivamente pela Conta |
| RF17 | Exibir splash nativa com fundo monocromático e logo do Zelo | Compila no APK (tema do Android 12+ corrigido em 03/10/2026); verificação em aparelho pendente |
| RF18 | Exibir animação curta da marca após a inicialização do Flutter | Implementado e testado; transição Android pendente |
| RF19 | Apresentar onboarding no primeiro acesso | Implementado e testado |
| RF20 | Permitir pular o onboarding e não repeti-lo após sua conclusão | Implementado e testado |
| RF21 | Consultar e alterar nome, e-mail e senha da conta | Implementado na API e no app (Meu perfil); indisponível na demonstração |
| RF22 | Excluir a conta e todos os dados associados | Implementado (exclusão em cascata com confirmação por senha) |
| RF23 | Preencher o cadastro a partir da foto da embalagem, com conferência | Implementado com RapidOCR (PP-OCR) no backend e Tesseract como reserva (D035); somente no modo conectado; avaliação com fotos reais PENDENTE |

## Critérios do fluxo inicial

- A splash nativa deve aparecer sem tela branca intermediária.
- A animação deve representar a seta circular de devolução e terminar
  automaticamente, sem impedir a inicialização; um toque a encerra antes.
- O onboarding deve ter três páginas: organização de medicamentos, prevenção de
  desperdício e descarte responsável, cada uma com uma cena animada que fica
  pronta sob redução de movimento (D037).
- O onboarding deve possuir Pular (exceto na última página), Continuar e
  Começar, e não deve prometer funções que ainda não existem.
- Câmera e localização não devem ser solicitadas no onboarding.
- No retorno ao aplicativo, uma sessão válida direciona o usuário à página
  inicial; sessão ausente ou inválida direciona ao login.
- A Mostra deverá possuir credencial de demonstração previamente validada
  (modo demonstração ou conta criada por `scripts/seed_demo.py`).
- Erros de preferências ou de conexão no início devem exibir mensagem segura e
  permitir nova tentativa.
- Login e logout devem substituir o fluxo raiz, sem retorno às páginas de
  entrada pelo botão Voltar depois da autenticação.
- A leitura do onboarding e da sessão deve iniciar em paralelo à animação,
  sem atraso artificial, chamadas duplicadas ou atualização após descarte.
- A abertura Flutter parte do símbolo oficial centralizado e revela nome,
  slogan e a faixa de validade em até 1,3 s (D036). Se a inicialização
  continuar, a mesma assinatura indica a espera real.

## Celebrações

- Um medicamento novo salvo recebe o carimbo de validade numa confirmação de
  até 2 s, que fecha sozinha ou com um toque, seguida de um aviso com
  "Cadastrar outro" que some sozinho em 6 s.
- Um descarte registrado mostra a celebração do trajeto (D038) com dados do
  próprio registro e segue sozinho para o Histórico, onde o registro novo
  aparece em destaque.
- Celebrações não estimam impacto nem usam números que o app não conhece.
- Com leitor de tela, a celebração do descarte espera a pessoa seguir; com
  redução de movimento, nada anima.

## Critérios da navegação autenticada

- A barra inferior deve conter Início, Descartar, Histórico e Conta.
- Medicamentos deve permanecer acessível por “Ver todos” e pelas ações de
  cadastro da Home, sem destino inferior exclusivo.
- Descartar não deve fabricar pontos, endereços ou horários: sem servidor
  configurado, informa a dependência da integração EcoMed; com servidor, mostra
  somente o que a API devolver, com atribuição.
- A localização só é pedida depois que a pessoa toca em "Usar minha
  localização", com explicação prévia; é aproximada e arredondada a três casas
  antes de sair do aparelho. A busca por região dispensa a localização.
- A espera pela posição tem limite (15 s no provedor, 30 s no controlador) e
  mostra "Obtendo sua localização…" com a opção de escolher uma região;
  recusa, serviço desligado ou tempo esgotado terminam em mensagem com o mesmo
  atalho, nunca em carregamento infinito (D033).
- Quando Descartar é aberto pelo atalho da Início, o cabeçalho oferece voltar
  ao Início; o voltar do sistema em outra aba retorna ao Início antes de sair.
- Pontos fora do programa LogMed devem exibir aviso para confirmar por telefone.
- Histórico mostra somente descartes registrados pela pessoa; sem registros,
  apresenta estado vazio.
- Conta identifica a sessão: "Sessão simulada" na demonstração, sem dados
  pessoais inventados; no modo conectado, o nome e o e-mail da própria conta.
  A única ação de logout da área autenticada fica na Conta.
- No modo conectado, Conta abre "Meu perfil" (RF21, RF22); alterar e-mail,
  trocar senha e excluir a conta exigem a senha atual, e a exclusão pede
  confirmação explícita.
- Uma sessão expirada durante o uso fecha telas empilhadas, limpa os dados
  locais e volta ao login com aviso.

## Não funcionais

| ID | Requisito | Estado |
|---|---|---|
| RNF01 | Funcionar em smartphones Android | Confirmado; APK de debug gerado (minSdk 24, targetSdk 36); validação em dispositivo pendente |
| RNF02 | Ter interface responsiva, legível e com contraste adequado | Implementado (contraste AA medido, 320 × 568 com texto a 160%) |
| RNF03 | Não bloquear a interface durante operações externas | Implementado (estados de carregamento e chamadas assíncronas) |
| RNF04 | Tratar falhas de rede sem travamento ou dados fabricados | Implementado e testado |
| RNF05 | Usar HTTPS fora do ambiente local | Confirmado; HTTP liberado só no manifesto de debug; hospedagem pendente |
| RNF06 | Proteger senhas, tokens e credenciais | Implementado (Argon2id, hashes de tokens, rotação de sessão) |
| RNF07 | Solicitar e explicar permissões apenas quando necessárias | Implementado para localização; validação Android pendente |
| RNF08 | Manter a chave EcoMed somente no backend | Implementado e testado |
| RNF09 | Não registrar segredos, dados pessoais ou coordenadas precisas | Implementado e testado nos logs do backend |
| RNF10 | Ter testes para regras críticas e execução local documentada | Implementado |
| RNF11 | Evitar atraso artificial durante splash e animação inicial | Implementado e testado |
| RNF12 | Respeitar a preferência de redução de movimento do sistema | Implementado e testado |
| RNF13 | Armazenar tokens de sessão em mecanismo seguro do dispositivo | Implementado com `flutter_secure_storage`; validação Android pendente |

## Fora do MVP

- aconselhamento, diagnóstico, dose ou recomendação de medicamentos;
- substituição ou interrupção de tratamento;
- prontuários, marketplace, venda, doação ou chat médico;
- garantia de atendimento por qualquer unidade pública;
- login social;
- iOS como prioridade;
- OCR antes da estabilidade do fluxo manual (revisto em 03/10/2026: a leitura
  da embalagem entrou como atalho opcional, D035);
- lembretes de uso e de reposição (proposta pendente, D039);
- leitura de receitas (proposta pendente e não recomendada, D040).

## Regra de validade

A regra usa datas civis, sem horário: uma validade anterior à data de referência
é vencida; de hoje até 30 dias, inclusive, está próxima do vencimento; acima de
30 dias está válida. O dia da validade ainda não é considerado vencido. A regra
existe uma única vez em `medication.dart` e é usada pela lista, pelo detalhe,
pela prévia do formulário e pela linha de validade.

## Autenticação e sessão

No modo conectado, a API emite um token de acesso de 15 minutos e um token de
renovação de 30 dias. O aplicativo guarda somente o de renovação, no
armazenamento seguro; a renovação troca o token a cada uso e o servidor revoga
todas as sessões se detectar reuso ou quando a senha é trocada. No modo
demonstração, persiste-se apenas `simulated_session_active`.

Os textos efetivos dos termos de uso e da política de privacidade são
**PENDENTES** de fornecimento e aprovação; a interface valida apenas o aceite,
sem inventar conteúdo jurídico.

## Privacidade dos medicamentos

Medicamentos cadastrados são tratados como dados indiretos de saúde (D018). O
projeto aplica minimização, não registra medicamentos, credenciais ou dados
pessoais em logs, isola os dados por conta no backend e descarta a cópia local
ao sair ou quando a sessão expira. Fixtures de teste e demonstração são
públicas e fictícias.

## Leitura da embalagem

- Disponível somente com a API Zelo: no cadastro de um novo medicamento e pelo
  atalho "Escanear embalagem" da Início, que abre a escolha entre câmera e
  galeria.
- A foto é enviada à API, processada em memória e descartada; o log guarda só
  quantas linhas foram lidas e quais campos foram encontrados.
- O resultado apenas preenche o formulário: nome (com outras leituras como
  opção), validade e quantidade. Nome digitado pela pessoa não é substituído.
  Nada é salvo sem tocar em salvar.
- Validade só com mês e ano vale até o último dia do mês, e a tela avisa.
- Foto sem texto reconhecível, imagem inválida, servidor sem OCR ou excesso de
  leituras mostram mensagem e mantêm o preenchimento manual.

## Lembretes de validade

- Opcionais: ficam desligados até a pessoa ligá-los em Conta → Lembretes, e a
  permissão de notificações do sistema só é pedida nesse momento (RNF07).
- Cada medicamento gera um aviso 30 dias antes, 7 dias antes e no dia do
  vencimento, às 9h (horário local); medicamentos com o mesmo vencimento viram
  um só aviso, com no máximo três nomes na mensagem.
- Os avisos são agendados no próprio aparelho, sem passar pelo servidor, e
  recalculados quando a lista de medicamentos muda ou é carregada. Ao sair da
  conta, expirar a sessão ou excluir a conta, os avisos pendentes e os já
  mostrados são apagados; a escolha de receber lembretes é do aparelho e
  continua.
- Com a lista ainda não carregada (ex.: antes do login) nada é reagendado,
  para não apagar avisos válidos.
- Conta oferece o próximo aviso previsto e "Enviar aviso de teste". Se o
  sistema bloquear as notificações, a tela explica e abre as configurações.
- Tocar num aviso, com o aplicativo aberto, em segundo plano ou fechado, abre
  a lista de medicamentos que pedem atenção.
- Em tela bloqueada com senha, o Android esconde o conteúdo (nomes de
  medicamentos são dados de saúde, D018). Os textos não dão orientação médica.
- Disponíveis só no aplicativo Android com a API Zelo; no navegador, a Conta
  informa que o recurso é do aplicativo Android, e a demonstração não os
  oferece.
