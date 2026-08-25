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

- Estado: aceita
- decisão: OCR permanece fora do núcleo inicial.
- Motivo: preservar cadastro, classificação, descarte e testes confiáveis antes
  de introduzir reconhecimento sujeito a erro.

## D005 - Dependências Flutter

- Estado: pendente
- decisão necessária: navegação, estado, HTTP, configuração e fontes.
- critério: adicionar apenas quando houver uso concreto, com justificativa,
  manutenção ativa, compatibilidade e impacto em testes avaliados.

## D006 - Paleta oficial

- Estado: proposta
- decisão: adotar o briefing mais recente (`#28A87B`, `#174C5B`, `#F4F7F6`,
  `#F5A623`, `#687078`) até confirmação da equipe.
- Conflito: o documento inicial registra `#28A878` e `#6B7D78`.

## D007 - Backend preferencial

- Estado: proposta
- decisão: FastAPI, SQLAlchemy, Alembic e PostgreSQL.
- Condição: validar compatibilidade das versões antes de fixar dependências.

## D008 - Navegação e mapa

- Estado: pendente
- Proposta: começar pela lista de pontos e abertura em mapa externo; mapa
  embutido apenas após o fluxo essencial.
- Pendente: escolher fornecedor de mapas e política de uso.

## D009 - Regra de proximidade do vencimento

- Estado: pendente
- Questão: quantos dias antes da validade classificam um medicamento como
  próximo do vencimento e se o usuário poderá configurar esse período.

## D010 - Fluxo inicial obrigatório

- Estado: aceita
- Decisão: o MVP terá splash, onboarding no primeiro acesso e verificação de
  sessão antes de apresentar login ou página inicial.
- Motivo: apresentar a identidade do Zelo e orientar novos usuários antes do
  uso das funcionalidades principais.

## D011 - Animação da marca

- Estado: proposta
- Proposta: usar splash nativa estática seguida de animação curta executada pelo
  Flutter, aproveitando o movimento circular da seta de devolução.
- Preferência técnica: avaliar Rive a partir da logo vetorial.
- Restrição: a animação não deve simular carregamento inexistente nem atrasar
  desnecessariamente a entrada. Deve respeitar redução de movimento.

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
