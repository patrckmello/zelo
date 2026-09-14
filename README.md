# Zelo

> Cuide. Organize. Descarte certo.

O Zelo é um projeto acadêmico da disciplina de Projeto e Desenvolvimento de
Sistemas Móveis da CESUCA. O aplicativo apoiará a organização de medicamentos
armazenados em casa, o acompanhamento de validade e a localização de pontos de
descarte responsável.

O projeto está no início do desenvolvimento e será apresentado na Mostra
Científica da instituição. Funcionalidades planejadas não devem ser tratadas
como resultados comprovados.

## English summary

Zelo is an academic mobile application project from CESUCA focused on helping
people organize medicines stored at home, monitor expiration dates, and find
appropriate collection points for responsible disposal. The Android-first MVP
will use Flutter and Dart, supported by a dedicated backend that protects the
EcoMed API key and provides normalized, cached collection-point data. The repository now includes an implemented and automated-tested in-memory
medication management vertical slice. Persistence, authentication, EcoMed
integration, onboarding, and Android device validation remain planned.

## Estado atual

- **Confirmado:** Flutter/Dart, Android como prioridade, API própria e uso
  autorizado da API EcoMed por meio do backend.
- **Implementado e verificado:** repositório, documentação, scaffold Flutter,
  tema Material 3, resumo dinâmico da farmácia doméstica e fluxo manual de
  medicamentos em memória: listagem, cadastro, edição, detalhes e remoção.
- **Em validação:** símbolo oficial integrado aos ativos, splash nativa Android
  e animação curta da marca em Flutter, com desativação quando o sistema pede
  redução de movimento.
- **Verificado:** formatação, análise estática, 12 testes automatizados e build
  Web nos commits `76f5abd` e `33ec173`.
- **Pendente no ambiente atual:** restaurar o SDK Flutter portátil e disponibilizar
  Android SDK/JDK 17 para executar a nova suíte e validar a abertura no Android.
- **Planejado:** onboarding, autenticação, persistência, backend, banco, EcoMed e
  notificações.
- **Fora do núcleo inicial:** OCR e mapa embutido.

## Fluxo inicial planejado

~~~text
Splash nativa estática
→ animação curta da marca
→ verificar primeiro acesso
→ onboarding, quando necessário
→ verificar sessão
→ login ou página inicial
~~~

A splash usará fundo monocromático e a logo do Zelo. A animação deverá explorar
o movimento circular da seta de devolução sem atrasar desnecessariamente a
abertura. O onboarding apresentará organização, prevenção de desperdício e
descarte responsável. Câmera e localização serão solicitadas somente no
contexto da funcionalidade que precisar delas.

## Tecnologias planejadas

- Aplicativo: Flutter, Dart e Material 3;
- Backend: Python, FastAPI, SQLAlchemy e Alembic;
- Dados: PostgreSQL;
- Infraestrutura local: Docker Compose;
- Plataforma prioritária: Android;
- Desenvolvimento: Visual Studio Code e Git.

## Estrutura

```text
Zelo/
|-- mobile/       # Aplicativo Flutter
|-- backend/      # API própria (implementação futura)
|-- docs/         # Arquitetura, requisitos, decisões e evidências
|-- AGENTS.md     # Regras obrigatórias para agentes
|-- README.md
`-- Zelo_Documentacao_Inicial.docx
```

## Documentação viva

Código, decisões e documentação devem evoluir juntos. Toda mudança de requisito,
escopo, arquitetura, integração, teste ou estado de implementação deverá
atualizar os arquivos relacionados no mesmo ciclo de trabalho. As regras
obrigatórias estão em [AGENTS.md](AGENTS.md).

## Pré-requisitos

Para o aplicativo:

- Git;
- Flutter SDK estável, com Dart incluído;
- Android Studio ou Android SDK com platform-tools;
- JDK 17;
- Visual Studio Code com extensões Flutter e Dart.

Para o backend, quando ele for iniciado:

- Python 3.12 ou versão validada pelo projeto;
- Docker Desktop com Docker Compose, preferencialmente.

Depois de instalar o ambiente Android, execute:

```powershell
flutter doctor -v
flutter doctor --android-licenses
```

## Variáveis de ambiente

Segredos nunca devem ser versionados. A futura chave EcoMed permanecerá apenas
no backend, em arquivo `.env` local ignorado pelo Git. O repositório fornecerá
somente um `.env.example` sem valores secretos quando o backend for criado.

Não envie a chave EcoMed pelo aplicativo Flutter, pelo chat, por commits ou por
logs. O contrato real da API deverá ser inspecionado antes da implementação.

## Como executar o aplicativo

Quando disponibilizado, o SDK Flutter portátil deve ficar em `.tools/flutter` e
não é versionado. No clone inspecionado em 14/09/2026 esse diretório não estava
presente. Com o SDK restaurado, execute pela raiz do repositório:

```powershell
cd mobile
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat run -d chrome
```

Para usar uma instalação global, substitua o caminho por `flutter`. O
identificador Android provisório é `br.edu.cesuca.zelo`.

## Como executar o backend

O backend ainda não foi implementado. As instruções reais serão adicionadas no
marco correspondente; não há comandos fictícios de execução nesta versão.

## Testes

Com o SDK portátil:

```powershell
cd mobile
..\.tools\flutter\bin\dart.bat format --output=none --set-exit-if-changed .
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test
```

O plano completo está em [docs/testing-plan.md](docs/testing-plan.md). A suíte
possui 14 testes no código: os 12 testes do fluxo de medicamentos foram
executados e aprovados em 24/08/2026; os dois testes novos da abertura aguardam
execução porque o SDK Flutter não está disponível neste clone. Os dados dos
medicamentos permanecem somente em memória e são reiniciados quando o aplicativo
é fechado.

## Próximos passos

1. Restaurar o SDK Flutter portátil e executar formatação, análise e os 14 testes.
2. Instalar ou disponibilizar Android SDK e JDK 17.
3. Validar a splash em Android real ou emulador, inclusive sem tela branca.
4. Desenhar no Figma onboarding, login, cadastro e recuperação de senha.
5. Implementar o restante do fluxo inicial e sua navegação com estados simulados.
6. Iniciar backend, persistência e autenticação real.
7. Integrar o fluxo de medicamentos à API Zelo sem alterar as regras já testadas.
8. Adicionar Poppins quando os arquivos licenciados da fonte forem fornecidos.

Consulte [docs/backlog.md](docs/backlog.md) para os marcos posteriores.
