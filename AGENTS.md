# Instruções para agentes

Estas regras se aplicam a todo o repositório Zelo.

## Regra obrigatória de documentação

A documentação faz parte da entrega. Toda alteração relevante deve atualizar, no mesmo ciclo de trabalho e preferencialmente no mesmo commit, os documentos afetados.

Considere relevante qualquer alteração de:

- requisito, escopo, prioridade ou critério de aceite;
- decisão de produto, UX, arquitetura ou tecnologia;
- funcionalidade implementada, removida, adiada ou bloqueada;
- contrato de API, modelo de dados, integração ou limitação externa;
- configuração de ambiente, dependência ou procedimento de execução;
- estratégia, resultado ou evidência de testes;
- risco, limitação conhecida ou descoberta científica.

## Antes de desenvolver

1. Leia o README.md e os documentos relacionados em docs/.
2. Confira docs/backlog.md, docs/requirements.md e docs/decisions.md.
3. Não trate item planejado como implementado.
4. Registre decisões novas ou conflitos antes de assumir uma solução definitiva.

## Durante e depois da alteração

Atualize conforme o tipo de mudança:

- README.md: estado geral, execução, tecnologias e próximos passos;
- docs/backlog.md: tarefas, marcos, bloqueios e conclusão;
- docs/requirements.md: requisitos, estados e critérios de aceite;
- docs/decisions.md: decisões aceitas, propostas, substituídas ou pendentes;
- docs/architecture.md: componentes, fluxos, responsabilidades e integrações;
- docs/testing-plan.md: cenários e comandos de validação;
- docs/scientific-evidence.md: somente resultados realmente observados.

Uma tarefa não está concluída quando o código mudou e a documentação correspondente ficou desatualizada.

## Estados e evidências

Use os estados:

- Confirmado: decisão ou requisito aprovado;
- Implementado: existe em código e foi verificado;
- Planejado: pertence ao escopo, mas ainda não existe;
- Bloqueado: depende de informação, acesso ou decisão externa;
- Descartado: saiu do escopo com justificativa registrada.

Não invente métricas, testes, funcionalidades ou resultados. Use PENDENTE quando não houver evidência.

## Qualidade e segurança

- Execute as validações proporcionais à alteração.
- Registre limitações e falhas conhecidas.
- Nunca versione chaves, tokens, senhas, arquivos .env ou dados pessoais.
- A chave EcoMed deve permanecer exclusivamente no backend.
