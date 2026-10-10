# Aplicativo móvel

Aplicativo Flutter do Zelo, direcionado ao Android e verificado também no
navegador. Funciona em dois modos:

- **Demonstração** (padrão): sessão simulada (`simulated_session_active`),
  medicamentos fictícios em memória, descartes em memória e nenhuma consulta de
  pontos. Útil para apresentar a interface sem servidor.
- **Conectado**: compilado com `--dart-define=ZELO_API_URL=...`, usa a API Zelo
  para autenticação, perfil, medicamentos, leitura da embalagem, descartes e
  pontos de coleta. Somente o
  token de renovação é persistido, no armazenamento seguro do sistema
  (`flutter_secure_storage`); o token de acesso fica em memória.

## Funcionalidades

- abertura com o símbolo oficial, nome, slogan e faixa de validade, contínua
  com o carregamento real; onboarding com cenas animadas (prateleira,
  validade, trajeto até o ponto);
- celebrações: carimbo de validade ao cadastrar e, ao registrar um descarte,
  o trajeto que varre a tela até o "Mandou bem!" e segue para o Histórico;
  tudo desligado sob redução de movimento;
- login, cadastro, recuperação de senha (com código no modo conectado) e
  logout; a sessão expirada durante o uso volta ao login com aviso;
- Início com painel da farmácia, data de referência, itens que precisam de
  atenção e ações rápidas (no modo conectado, também "Escanear embalagem");
- lista de medicamentos com filtros por situação, detalhe com linha de
  validade, cadastro e edição com prévia da situação;
- leitura da embalagem (modo conectado): foto pela câmera ou galeria, enviada
  à API e descartada após a leitura; nome, validade e quantidade lidos só
  preenchem o formulário e a pessoa confere antes de salvar;
- Descartar com vencidos separados, registro de descarte e busca de pontos por
  localização aproximada ou por município da Região Metropolitana de Porto
  Alegre. A espera pela localização tem tempo-limite e já oferece a escolha de
  região; aberta pela Início, mostra "Início" para voltar, e o voltar do
  sistema em outra aba retorna ao Início;
- detalhe do ponto com origem (LogMed ou confirmação necessária), abertura em
  aplicativo de mapas, ligação e registro de descarte no próprio ponto;
- Histórico de descartes e Conta com identificação da sessão e licenças;
- Lembretes de validade (modo conectado, Android): avisos locais às 9h, 30
  dias antes, 7 dias antes e no dia do vencimento, ligados em Conta; a
  permissão de notificações só é pedida ao ligar, "Enviar aviso de teste"
  mostra como o aviso chega e tocar no aviso abre a lista de medicamentos;
- Meu perfil (modo conectado): alterar nome, e-mail e senha (com a senha
  atual) e excluir a conta com todos os dados.

No Android, a câmera e o seletor de fotos são os do sistema (`image_picker`),
sem permissão de câmera declarada no manifesto. A validação em aparelho segue
pendente.

A regra de validade (D009) está em um único lugar do domínio: anterior à data
de referência é vencido; de hoje até 30 dias, inclusive, está próximo; depois,
válido.

## Design system

Tema claro único, Poppins, cores com contraste AA e componentes compartilhados
em `lib/core`. Veja [../docs/design-system.md](../docs/design-system.md).

## Estrutura

```text
lib/
|-- app/            # composição, configuração, bootstrap e navegação
|-- core/           # tema, tokens, widgets, rede, armazenamento e plataforma
`-- features/
    |-- account/  authentication/  collection_points/
    |-- disposal_history/  home/  medications/  onboarding/
```

Cada funcionalidade separa domínio, dados (memória ou API), estado e
apresentação conforme a necessidade.

## Execução

```powershell
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat run -d chrome
..\.tools\flutter\bin\flutter.bat run -d edge --dart-define=ZELO_API_URL=http://localhost:8000
```

No emulador Android, a API local fica em `http://10.0.2.2:8000`. HTTP sem TLS é
permitido somente no manifesto de debug.

### Se a tela ficar branca no navegador

- No modo debug (`flutter run -d edge`), o primeiro carregamento baixa cerca de
  630 módulos e pode levar alguns segundos. Não recarregue a aba com F5: use
  `r` (hot reload) ou `R` (hot restart) no terminal. Se o terminal do
  `flutter run` for fechado ou interrompido, a aba fica branca porque perde o
  servidor que entrega os módulos.
- Não abra `build/web/index.html` com dois cliques nem sirva a pasta a partir
  de um subcaminho: o `index.html` usa `<base href="/">`, então o app precisa
  estar na raiz do servidor.
- Para só ver o app, prefira o build de release servido na raiz, que carrega
  um único `main.dart.js`:

  ```powershell
  ..\.tools\flutter\bin\flutter.bat build web --dart-define=ZELO_API_URL=http://localhost:8000 --output build/web-connected
  py -m http.server 7357 --bind 127.0.0.1 --directory build/web-connected
  # abra http://localhost:7357
  ```

- Se ainda assim ficar branco, abra o console do navegador (F12) e registre a
  primeira mensagem de erro.

## Validação

```powershell
..\.tools\flutter\bin\dart.bat format --output=none --set-exit-if-changed .
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test
..\.tools\flutter\bin\flutter.bat build web
```

Ferramentas opcionais:

```powershell
# Capturas de tela determinísticas (fontes reais) em build/screenshots
..\.tools\flutter\bin\flutter.bat test tool/screenshots/screens_test.dart

# Contrato com a API real em execução (cria e exclui uma conta descartável;
# ZELO_E2E_OCR_IMAGE, opcional, envia uma foto para leitura)
$env:ZELO_E2E_API_URL = 'http://localhost:8000'
..\.tools\flutter\bin\flutter.bat test tool/e2e/api_contract_test.dart
```

Resultado em 03/10/2026 (Flutter 3.47.1/Dart 3.13.1): formatação e análise
sem problemas, 151 testes aprovados, build Web aprovado nos dois modos,
contrato com a API real aprovado e 39 capturas geradas. O APK de debug é
gerado (modos demonstração e conectado); splash nativa, permissões, câmera,
armazenamento seguro e intents de mapa/telefone ainda não foram validados em
aparelho.

## Testar no celular pelo Tailscale (HTTPS)

Safari e Chrome só liberam localização e o armazenamento seguro em HTTPS. Com o
Tailscale no computador e no celular (mesma conta) e o recurso Serve ativado
(certificados HTTPS no painel de DNS da tailnet), na pasta `mobile/`:

```powershell
$tsHost = '<máquina>.<tailnet>.ts.net'
..\.tools\flutter\bin\flutter.bat build web --dart-define=ZELO_API_URL=https://$tsHost/api -o build/web-tailnet
..\.tools\flutter\bin\flutter.bat build web --base-href /demo/ -o build/web-tailnet-demo
py -3.13 -m http.server 8081 --bind 127.0.0.1 --directory build/web-tailnet
py -3.13 -m http.server 8082 --bind 127.0.0.1 --directory build/web-tailnet-demo
tailscale serve --bg --set-path /api http://127.0.0.1:8000
tailscale serve --bg --set-path /demo http://127.0.0.1:8082
tailscale serve --bg http://127.0.0.1:8081
```

O app conectado fica em `https://<máquina>.<tailnet>.ts.net/` (API no mesmo
endereço, em `/api`, sem CORS) e a demonstração em `/demo/`. Só os aparelhos da
tailnet acessam (`serve`, não `funnel`). Para desligar:
`tailscale serve --https=443 off`. No iPhone, o Safari pode instalar o app na
tela de início (Compartilhar → "Adicionar à Tela de Início"); ele abre em tela
cheia, com o ícone do Zelo, mas depende do Tailscale e deste computador ligados.
Verificado em 03/10/2026: login, lista de
medicamentos e busca de pontos com a EcoMed real pelo endereço da tailnet.

## Android

Com o JDK 17 e o Android SDK de `.tools/` (D041), na pasta `mobile/`:

```powershell
$env:JAVA_HOME = 'D:\Code\zelo\.tools\jdk-17'
$env:ANDROID_HOME = 'D:\Code\zelo\.tools\android-sdk'
$env:GRADLE_USER_HOME = 'D:\Code\zelo\.tools\gradle-home'
..\.tools\flutter\bin\flutter.bat build apk --debug
# Conectado à API do computador (celular na mesma rede):
..\.tools\flutter\bin\flutter.bat build apk --debug --dart-define=ZELO_API_URL=http://<IP do computador>:8000
```

O APK fica em `build/app/outputs/flutter-apk/app-debug.apk`. Para instalar:
copie para o celular e abra (permitindo "instalar apps desconhecidos") ou, com
depuração USB, `..\.tools\android-sdk\platform-tools\adb.exe install -r <apk>`.
No modo conectado, o celular precisa alcançar a porta 8000 do computador (mesma
rede e firewall do Windows liberando o Docker). HTTP sem TLS só funciona em
builds de debug.
