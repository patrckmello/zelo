# Plano de testes

## Objetivo

Validar regras críticas, fluxos do usuário, integração e desempenho, mantendo
evidências reproduzíveis para o desenvolvimento e a Mostra Científica.

## Aplicativo

- testes unitários da classificação por validade, inclusive datas-limite;
- testes de widgets para carregamento, sucesso, vazio e erro;
- validação de formulários de medicamento, login, cadastro e recuperação;
- testes de navegação do fluxo vertical;
- teste manual em pelo menos um smartphone Android real;
- verificação de layout com tamanhos de tela e escala de fonte diferentes.

## Fluxo inicial

- primeiro acesso exibe splash e onboarding;
- usuário pode avançar, voltar e pular o onboarding;
- onboarding concluído não reaparece na próxima abertura;
- preferência de redução de movimento evita animação desnecessária;
- sessão ausente ou inválida direciona ao login;
- sessão válida direciona à página inicial;
- logout remove a sessão e retorna ao login;
- falha durante bootstrap apresenta recuperação segura, sem loop infinito;
- credencial de demonstração funciona antes da apresentação.

## Backend

- criação de conta e prevenção de e-mail duplicado;
- autenticação válida e rejeição de credenciais incorretas;
- hash de senha e ausência de senha ou token em logs;
- recuperação de senha com token temporário;
- renovação, expiração e revogação de sessão;
- regras de autorização e isolamento dos dados do usuário;
- validação das operações de medicamento e descarte;
- migrações em banco limpo;
- normalização das respostas EcoMed com fixtures anonimizadas;
- chave de cache com coordenadas arredondadas a três casas;
- expiração, cache hit/miss, timeout e rate limit;
- ausencia de chaves e dados sensíveis nos logs.

## Fluxos funcionais

1. concluir ou pular onboarding;
2. cadastrar conta e autenticar;
3. recuperar acesso e encerrar sessão;
4. cadastrar medicamento manualmente;
5. editar e remover medicamento;
6. identificar sua situação de validade;
7. localizar e consultar um ponto;
8. abrir rota externa;
9. registrar e consultar um descarte.

## Evidências

Cada execução relevante deve registrar data, versão/commit, dispositivo ou
ambiente, massa de dados, passos, resultado esperado, resultado observado e
evidência associada. Falhas não devem ser ocultadas.

Métricas planejadas:

- tempo para concluir o primeiro acesso;
- tempo para cadastrar um medicamento;
- tempo para localizar um ponto;
- sucesso dos fluxos sem ajuda;
- percepção de clareza e facilidade;
- latência da API com cache frio e quente;
- quantidade de pontos retornados no recorte definido.

## Comandos de qualidade do Flutter

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

A documentação relacionada deve ser revisada antes de considerar qualquer
cenário implementado ou marco concluído.
