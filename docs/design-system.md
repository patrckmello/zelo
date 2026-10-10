# Design system

Estado: **implementado** no aplicativo Flutter em 02/10/2026 (D025). A
paleta-base continua **proposta** até a confirmação da equipe (D006).

## Direção

- **Quem usa:** uma pessoa em casa, com a caixa do remédio em uma mão e o
  celular na outra, querendo saber se o item ainda está bom e onde levá-lo.
- **Sensação:** cuidado e confiança, como uma prateleira organizada com
  etiquetas legíveis; nada de tom hospitalar ou alarmista.
- **Assinatura:** a validade como objeto visual — o carimbo `VAL dd/mm/aaaa`
  impresso nas embalagens, a faixa de situação nos cartões (como a tarja das
  caixas), a linha de validade com o marcador "Hoje" no detalhe e a barra de
  composição da farmácia na Início.
- **Padrões rejeitados:** três cartões de resumo idênticos, ícone isolado no
  centro de estados vazios, AppBar branca destacada do fundo, Roboto com
  hierarquia apenas por tamanho e cores de status como texto sem contraste.

## Superfícies e profundidade

Superfícies tonais com bordas finas, sem sombras decorativas. A única elevação
fica no botão flutuante, que passa sobre o conteúdo.

| Token | Valor | Uso |
|---|---|---|
| `shelf` | `#F4F7F6` | Fundo ("prateleira") e AppBar |
| `paper` | `#FFFFFF` | Cartões, campos e diálogos |
| `shelfDeep` | `#E9EFED` | Avisos neutros e esqueletos de carregamento |
| `hairline` | `#DDE5E3` | Bordas de cartões e divisores |
| `fieldBorder` | `#7E8D90` | Bordas de campos (≥ 3:1) |

## Cor e contraste

Contraste WCAG calculado em 02/10/2026.

| Token | Valor | Contraste |
|---|---|---|
| `ink` (azul-petróleo) | `#174C5B` | 9,45:1 no branco; 8,77:1 no fundo |
| `inkSoft` | `#3F5660` | 7,75:1 no branco; 7,19:1 no fundo |
| `inkMuted` (cinza) | `#687078` | 5,03:1 no branco; 4,66:1 no fundo |
| `fieldBorder` | `#7E8D90` | 3,44:1 no branco; 3,19:1 no fundo |
| `validInk` sobre `validTint` | `#1B6E52` / `#E3F4EE` | 5,43:1 |
| `expiringInk` sobre `expiringTint` | `#7A4A00` / `#FDF1DC` | 6,69:1 |
| `expiredInk` sobre `expiredTint` | `#9E3535` / `#F8ECEC` | 6,04:1 |

As cores de destaque (`#28A87B`, `#F5A623`, `#B64343`) aparecem em faixas,
barras e pontos, sempre acompanhadas de texto. O selo de situação anterior
usava âmbar sobre âmbar a 12% (1,86:1) e verde sobre verde a 12% (2,67:1),
abaixo do mínimo AA; os novos tons escuros corrigem isso.

O azul-petróleo é a cor interativa (D022). O verde fica para a marca, estados
positivos e o indicador da navegação.

## Tipografia

Poppins (pesos 400, 500, 600 e 700), com hierarquia por peso e cor:

| Estilo | Tamanho/peso | Uso |
|---|---|---|
| `displaySmall` | 34/600 | Número da farmácia |
| `headlineLarge` | 28/600 | Títulos das áreas e do login |
| `headlineMedium` | 24/600 | Nome do medicamento, onboarding |
| `headlineSmall` | 21/600 | Prazo no detalhe, estados vazios |
| `titleMedium` | 16/600 | Cabeçalhos de seção e nomes nos cartões |
| `bodyLarge`/`bodyMedium` | 16 e 14/400 | Texto corrido (`inkSoft`) |
| `bodySmall` | 12/400 | Metadados (`inkMuted`) |
| `labelLarge` | 15/600 | Botões |
| `labelSmall` | 11/500, espaçado | Rótulos como "HOJE" e "VAL" |

Os algarismos da Poppins são proporcionais e a fonte não oferece `tnum`; por
isso não há contadores animados.

## Espaço, forma e movimento

- Espaçamento em múltiplos de 4 (`ZeloSpace`), margem lateral de 20 px.
- Raios: carimbo 6, controles 14, cartões 20, folhas e diálogos 28.
- Botões com 52 px de altura; áreas de toque de pelo menos 48 px.
- Movimento curto (160–240 ms) com desaceleração, desligado quando o sistema
  pede redução de movimento.

## Momentos de marca

Movimentos maiores ficam restritos a quatro momentos, todos feitos com as peças
da própria interface e desligados sob redução de movimento:

| Momento | O que acontece | Duração |
|---|---|---|
| Abertura (`BrandLockup`) | Símbolo gira e sobe; nome, slogan e faixa de validade aparecem | 1,3 s + 260 ms de dissolução |
| Carregamento | Mesmo quadro final; um brilho percorre a faixa enquanto a inicialização real continua | enquanto durar |
| Onboarding | Cenas por página (prateleira e carimbo, linha de validade, trajeto até o ponto), com paralaxe no arraste | 1,6 s por página |
| Cadastro salvo | Carimbo VAL "bate" na embalagem com a faixa da situação | 1,8 s, toque encerra |
| Descarte registrado | Trajeto nasce no botão, varre a tela em petróleo e fica animado atrás do "Mandou bem!"; dissolve no Histórico | 1,9 s + 3,2 s de leitura |

A faixa de três segmentos (`ValidityBar`) e o carimbo VAL são a assinatura
desses momentos; a celebração do descarte usa o trajeto (`disposal_route.dart`)
desenhado como linha de metrô: retas a 0°, 90° e 45°, cantos de raio constante
e um laço em círculo perfeito, como a seta de devolução do símbolo.

## Componentes

| Componente | Local |
|---|---|
| Tema completo (`ZeloTheme.light`) | `lib/core/theme/zelo_theme.dart` |
| Tokens (`ZeloColors`, `ZeloSpace`, `ZeloRadii`, `ZeloMotion`) | `lib/core/theme/` |
| `PageScrollView`, `PageHeader` (com atalho de volta opcional), `SectionHeader` | `lib/core/widgets/page_layout.dart` |
| `BrandLockup`, `ValidityBar` | `lib/core/widgets/brand_lockup.dart` |
| Carimbo do cadastro (`showMedicationSaved`) | `lib/features/medications/presentation/medication_saved_overlay.dart` |
| Celebração do descarte e trajeto | `lib/features/disposal_history/presentation/disposal_celebration.dart`, `disposal_route.dart` |
| `StateMessage`, `CenteredState` | `lib/core/widgets/state_message.dart` |
| `InlineNotice` (neutro, positivo, atenção) | `lib/core/widgets/inline_notice.dart` |
| `SkeletonBlock`, `SkeletonList` | `lib/core/widgets/skeleton.dart` |
| Primitivas de ilustração (`ScenePanel`, `ScenePackage`, `SceneTile`, `SceneShelf`, `SceneDashedLine`) | `lib/core/widgets/scene.dart` |
| `MedicationTile`, `ValidityTrack`, `PharmacyOverview` | `lib/features/medications/presentation/widgets/` |
| `MedicationStatusBadge`, `ValidityStamp`, `StatusStripe` | `lib/features/medications/presentation/medication_presentation.dart` |
| `ProfileAvatar` (iniciais) e formulário de conta | `lib/features/account/presentation/` |

Ações rápidas da Início: com a leitura disponível, "Cadastrar" (preenchida em
petróleo) e "Escanear embalagem" dividem a linha, e "Encontrar ponto de
descarte" ocupa a largura toda em formato horizontal. O cartão de leitura do
cadastro usa o mesmo selo verde dos ícones de ação e um `InlineNotice`
positivo para pedir a conferência.

## Ícones da versão web (PWA)

`mobile/web/icons/` e `favicon.png` são gerados a partir do símbolo oficial
(`assets/branding/zelo-symbol.png`), sem redesenho, sobre o fundo `#F4F7F6`:
192 e 512 px (símbolo em 68%), versões "maskable" (56%, dentro da área segura),
`apple-touch-icon.png` de 180 px para a tela de início do iPhone e favicon de
64 px. O manifesto e o `index.html` usam o nome "Zelo", o slogan como
descrição, `pt-BR` e a cor de fundo da marca (03/10/2026; antes eram os ícones
e o nome padrão do Flutter).

## Acessibilidade

- Contraste AA em todo texto e ≥ 3:1 nas bordas de campos.
- Situação nunca comunicada só por cor; ilustrações com rótulo semântico e
  linhas de resumo como itens próprios para leitores de tela.
- Cabeçalhos de seção quebram a ação para a linha seguinte com texto ampliado,
  em vez de cortar palavras.
- Tema claro único, coerente com a splash nativa (que também é clara em modo
  noturno). Tema escuro fica como evolução futura.

## Verificação visual

`mobile/tool/screenshots/screens_test.dart` gera 39 capturas determinísticas
com as fontes reais, incluindo 320 × 568 com texto a 160%. Elas não substituem
a inspeção em dispositivo Android, ainda pendente.
