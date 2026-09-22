# Correção e reconciliação do M2 — Design

## Contexto e objetivo

Esta intervenção evolui incrementalmente a experiência inicial e a autenticação
simulada presentes em `main`, nos commits `526feea` e `579814d`. O fluxo manual
de medicamentos permanece intacto e acessível pela Home. O trabalho corrige a
navegação principal, coordena bootstrap e animação de abertura, refina o
onboarding e atualiza testes e documentação sem antecipar funcionalidades dos
marcos futuros.

O M2 continuará **em andamento** enquanto a validação Android, a reconciliação
no Figma e os textos jurídicos permanecerem pendentes.

## Diagnóstico inicial

- A árvore de trabalho estava limpa em `main`, no commit `579814d`, alinhada a
  `origin/main`.
- O shell autenticado possui três abas: Início, Medicamentos e Descarte.
- A Home contém o logout no cabeçalho.
- A abertura exibe símbolo, nome e slogan e somente inicia o bootstrap depois da
  animação.
- O onboarding usa um ícone Material centralizado em um círculo para cada página.
- A documentação registra 37 testes aprovados em 14/09/2026. No diagnóstico de
  21/09/2026, Flutter, Android SDK e JDK não estavam disponíveis no ambiente;
  por isso nenhuma validação nova foi declarada nessa etapa.

## Direção de produto e visual

O produto atende uma pessoa organizando medicamentos domésticos e procurando
uma destinação responsável. A interface deve transmitir cuidado, clareza e
honestidade sobre o que ainda não está integrado.

- **Domínio:** cuidado doméstico, validade, organização, devolução, descarte
  responsável e confiança.
- **Mundo de cor:** fundo claro, azul-petróleo, verde Zelo, âmbar de atenção,
  vermelho de vencimento e branco.
- **Assinatura:** continuidade e devolução sugeridas pelo movimento do símbolo
  oficial e por trajetos vetoriais discretos, sem redesenhar a marca.
- **Padrões rejeitados:** ícone isolado em círculo, cards decorativos idênticos e
  ilustrações externas sem relação com o produto.

A implementação reutilizará tema, cores, componentes Material e o PNG oficial.
Não serão adicionados ativos, fontes ou dependências visuais.

## Arquitetura escolhida

O shell e o bootstrap existentes serão evoluídos sem reimplementar o marco.

1. `ZeloApp` continuará criando uma única instância de cada dependência.
2. Um coordenador de lançamento manterá `AppBootstrapFlow` montado desde o
   primeiro quadro e sobreporá `BrandIntroPage` enquanto a animação estiver em
   curso.
3. `AppBootstrapFlow` iniciará uma única carga no `initState`. O controlador
   compartilhará a operação em andamento e ignorará resultados após o descarte.
4. A remoção da sobreposição revelará imediatamente o estado já resolvido, o
   carregamento discreto ou o erro recuperável existente.
5. O `MedicationStore` continuará único e compartilhado entre Home, lista,
   formulário e detalhes.

Essa composição evita uma segunda leitura do bootstrap, não introduz atraso
artificial e preserva a substituição do fluxo raiz após login e logout.

## Navegação autenticada

A barra inferior terá quatro destinos persistentes e na ordem abaixo:

1. Início;
2. Descartar;
3. Histórico;
4. Conta.

Medicamentos não será um destino inferior. A lista abrirá como rota empilhada a
partir de “Ver todos” na Home. O cadastro continuará disponível na Home e dentro
da lista, usando os mesmos formulário, modelo e store atuais.

### Início

- Preserva resumo, slogan, ações rápidas e aviso de armazenamento em memória.
- Remove o logout do cabeçalho.
- “Ver todos” abre a lista de medicamentos.
- “Cadastrar medicamento” abre o formulário atual.
- “Encontrar ponto de descarte” seleciona Descartar.

### Descartar

- Apresenta a área de pontos de descarte.
- Informa que a consulta será disponibilizada quando a integração EcoMed
  estiver pronta.
- Não solicita localização e não exibe pontos, endereços ou horários fictícios.

### Histórico

- Apresenta estado vazio com a informação de que descartes registrados
  aparecerão ali.
- Não cria persistência, exemplos ou registros falsos.

### Conta

- Identifica toda sessão atual como **Sessão simulada**, pois o armazenamento
  atual não distingue login, cadastro e entrada de demonstração.
- Explica que a versão não representa uma conta real.
- Não exibe nome, e-mail, avatar, plano ou outros dados pessoais inventados.
- Contém a única ação de logout da área autenticada, incluindo estado de
  processamento e o tratamento de erro existente.

## Abertura e bootstrap

`BrandIntroPage` usará somente `assets/branding/zelo-symbol.png`, centralizado
sobre o fundo atual. O nome “Zelo” e o slogan serão removidos dessa tela. A
duração padrão permanecerá em 800 ms e a animação continuará baseada em
opacidade, escala e rotação.

Sequências observáveis:

- **Bootstrap termina primeiro:** o símbolo permanece até o fim da animação e
  então a tela resolvida aparece imediatamente.
- **Animação termina primeiro:** a abertura é removida e aparece o carregamento
  discreto “Preparando o Zelo…” até a conclusão real.
- **Bootstrap falha:** depois da animação aparece a mensagem segura e a ação
  “Tentar novamente” existentes.
- **Redução de movimento:** o símbolo não é animado; a abertura conclui no
  primeiro quadro sem impedir que o bootstrap já esteja em andamento.

Não haverá `Future.delayed`, temporizador adicional ou espera criada para
simular carregamento.

## Onboarding

As três mensagens, sua ordem, a persistência e as ações Pular, Próximo, Voltar
e Começar permanecem inalteradas.

Cada página receberá uma composição responsiva feita com o símbolo oficial,
formas geométricas, linhas, cards e ícones Material usados como elementos de uma
cena, não como um ícone solto em um círculo:

- organização: embalagens/cartões organizados em uma base;
- desperdício: validade e sinalização de atenção em uma pequena composição;
- descarte: trajeto de devolução até um ponto responsável.

O conteúdo continuará rolável e limitado em largura. As ilustrações se
reduzirão em telas baixas ou com texto ampliado, preservando leitura e controles.
Botões Material manterão área de toque mínima de 48 px. Mudanças de página e
indicadores continuarão respeitando `disableAnimations`. Nenhuma permissão será
solicitada.

## Testes

O desenvolvimento seguirá ciclos teste-falha, implementação mínima e
regressão. A cobertura incluirá:

- os quatro rótulos e destinos da navegação;
- ausência de Medicamentos na barra inferior;
- lista de medicamentos aberta por “Ver todos”;
- cadastro e fluxo manual de medicamentos preservados;
- logout ausente da Home e funcional somente na Conta;
- identificação de Sessão simulada sem dados pessoais;
- estado futuro de Descartar e estado vazio do Histórico;
- bootstrap iniciado antes do fim da animação;
- bootstrap concluído antes e depois da animação;
- erro recuperável, deduplicação e descarte seguro do controlador;
- abertura sem nome ou slogan e redução de movimento;
- onboarding completo, texto ampliado, tela pequena e redução de movimento.

Ao final, em `mobile/`, serão executados:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```

Android será validado somente se Android SDK e JDK 17 estiverem realmente
disponíveis. Caso contrário, a limitação será registrada sem declarar build,
splash ou transição como verificados.

## Documentação

O mesmo ciclo atualizará `README.md`, `docs/backlog.md`,
`docs/requirements.md`, `docs/decisions.md`, `docs/architecture.md`,
`docs/testing-plan.md` e `mobile/README.md`. `docs/scientific-evidence.md` somente
será alterado se houver nova evidência observada que pertença ao seu escopo.

Os documentos registrarão a navegação definitiva, o acesso a Medicamentos pela
Home, o logout na Conta, a ausência de persistência real do Histórico, o
bootstrap paralelo, as alterações visuais e os resultados efetivamente
executados. Android, Figma e textos jurídicos continuarão pendentes enquanto não
houver evidência real.

## Fora do escopo

- autenticação real ou diferenciação persistida do tipo de sessão;
- persistência do histórico ou dos medicamentos;
- integração EcoMed, pontos reais ou permissão de localização;
- novos ativos, redesenho da marca, fonte Poppins ou dependências Flutter;
- conteúdo jurídico inventado;
- marcação do M2 como concluído;
- commit, push ou pull request sem autorização.

## Critérios de aceite

O trabalho estará tecnicamente entregue quando código e documentação estiverem
coerentes, as validações disponíveis tiverem resultados registrados e nenhuma
regressão do fluxo manual de medicamentos for observada. Isso não altera o
estado global do M2: o marco permanece em andamento até o atendimento dos
critérios externos ainda pendentes.
