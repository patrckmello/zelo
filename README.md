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
- **Implementado:** repositório local, estrutura inicial do workspace e
  documentação de engenharia.
- **Pendente:** instalação do toolchain Flutter/Android e geração do aplicativo.
- **Não iniciado:** backend, banco, autenticação, EcoMed, notificações e OCR.

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
|-- mobile/       # Aplicativo Flutter (scaffold pendente)
|-- backend/      # API própria (implementação futura)
|-- docs/         # Arquitetura, requisitos, decisões e evidências
|-- README.md
`-- Zelo_Documentacao_Inicial.docx
```

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

O scaffold Flutter ainda não foi gerado porque o SDK não está disponível neste
ambiente. Quando o toolchain estiver validado, a criação planejada é:

```powershell
flutter create --org br.edu.cesuca --project-name zelo mobile
cd mobile
flutter pub get
flutter run
```

O identificador Android provisoriamente proposto é `br.edu.cesuca.zelo`.

## Como executar o backend

O backend ainda não foi implementado. As instruções reais serão adicionadas no
marco correspondente; não há comandos fictícios de execução nesta versão.

## Testes

Quando o aplicativo existir:

```powershell
cd mobile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

O plano completo está em [docs/testing-plan.md](docs/testing-plan.md).

## Próximos passos

1. Instalar ou disponibilizar Flutter, Android SDK e JDK 17.
2. Validar o ambiente com `flutter doctor -v`.
3. Gerar o projeto Flutter pelo CLI oficial.
4. Implementar tema Material 3, navegação mínima e página inicial simulada.
5. Executar formatação, análise estática e testes.

Consulte [docs/backlog.md](docs/backlog.md) para os marcos posteriores.

