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
EcoMed API key and provides normalized, cached collection-point data. The
project is currently in its initial planning and workspace setup phase.

## Estado atual

- **Confirmado:** Flutter/Dart, Android como prioridade, API própria e uso
  autorizado da API EcoMed por meio do backend.
- **Implementado:** repositório, documentação, scaffold Flutter, tema Material 3,
  página inicial simulada, navegação mínima e testes de widgets.
- **Pendente:** Android SDK/JDK 17 para executar e validar o aplicativo no Android.
- **Planejado:** splash, onboarding, autenticação, fluxo manual de medicamentos,
  backend, banco, EcoMed e notificações.
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

O SDK Flutter portátil está em `.tools/flutter` e não é versionado. Nesta
máquina, execute pela raiz do repositório:

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

O plano completo está em [docs/testing-plan.md](docs/testing-plan.md).

## Próximos passos

1. Instalar ou disponibilizar Android SDK e JDK 17.
2. Validar o ambiente Android com `flutter doctor -v`.
3. Desenhar no Figma splash, onboarding, login, cadastro e recuperação de senha.
4. Implementar o fluxo inicial e sua navegação com estados simulados.
5. Implementar o fluxo manual de medicamentos com dados simulados.
6. Iniciar backend, persistência e autenticação real.
7. Adicionar Poppins quando os arquivos licenciados da fonte forem fornecidos.

Consulte [docs/backlog.md](docs/backlog.md) para os marcos posteriores.
