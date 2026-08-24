# Plano de testes

## Objetivo

Validar regras críticas, fluxos do usuário, integração e desempenho, mantendo
evidências reproduzíveis para o desenvolvimento e a Mostra Científica.

## Aplicativo

- testes unitários da classificação por validade, inclusive datas-limite;
- testes de widgets para carregamento, sucesso, vazio e erro;
- validação de formulários de medicamento;
- testes de navegação do fluxo vertical;
- teste manual em pelo menos um smartphone Android real;
- verificacao de layout com tamanhos de tela e escala de fonte diferentes.

## Backend

- regras de autorização e isolamento dos dados do usuário;
- validação das operações de medicamento e descarte;
- migrações em banco limpo;
- normalização das respostas EcoMed com fixtures anonimizadas;
- chave de cache com coordenadas arredondadas a três casas;
- expiração, cache hit/miss, timeout e rate limit;
- ausencia de chaves e dados sensíveis nos logs.

## Fluxos funcionais

1. cadastrar medicamento manualmente;
2. editar e remover medicamento;
3. identificar sua situação de validade;
4. localizar e consultar um ponto;
5. abrir rota externa;
6. registrar e consultar um descarte.

## Evidências

Cada execucao relevante deve registrar data, versão/commit, dispositivo ou
ambiente, massa de dados, passos, resultado esperado, resultado observado e
evidência associada. Falhas não devem ser ocultadas.

métricas planejadas:

- tempo para cadastrar um medicamento;
- tempo para localizar um ponto;
- sucesso dos fluxos sem ajuda;
- percepção de clareza e facilidade;
- latência da API com cache frio e quente;
- quantidade de pontos retornados no recorte definido.

## Comandos de qualidade do Flutter

Quando o scaffold existir:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
