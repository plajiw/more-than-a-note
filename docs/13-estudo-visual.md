# 13 — Estudo de linguagem visual: Apple, Adobe e Affinity

**Status:** estudo e proposta inicial. Nada aqui é padrão aprovado. Cada decisão passa por implementação no app real e avaliação visual antes de entrar no [01-layout-refeito.md](01-layout-refeito.md), que será reescrito ao final com os padrões aprovados.

**Base:** `preview/` (HTML, CSS e capturas v5/v6), [01-layout-refeito.md](01-layout-refeito.md) e `apps/desktop/Main.qml`. Valores marcados **[aprox.]** foram observados, não publicados, e devem ser medidos antes de virar regra.

## 1. O que cada referência faz

### 1.1 Apple (Notes, Pages, Keynote, Freeform)

- **Tipografia:** SF Pro com tracking automático por tamanho. Texto padrão de 13 pt e mínimo de 10 pt. A hierarquia vem do peso (Regular → Semibold), não de muitos tamanhos. Dígitos tabulares em contadores e zoom.
- **Cor:** cores semânticas. No escuro, o texto é branco com opacidade decrescente (≈85% / 55% / 25%) [aprox.]. Um único acento do sistema, usado só para seleção, foco e ação padrão. **Seleção fica cinza quando a janela perde o foco.** O documento nunca é recolorido pelo tema.
- **Componentes:** toolbar unificada à barra de título; sidebar com linhas de 24/28/32 pt [aprox.]; inspector à direita com seções recolhíveis; menus com atalho alinhado à direita em cinza; segmented control com trilho rebaixado e "pílula" ativa elevada.
- **Ícones:** SF Symbols com o mesmo peso óptico do texto vizinho; estado ativo pela variante preenchida.
- **Acabamento:** grade de 4 pt, raios de 5–6 pt nos controles, bordas quase invisíveis e separação por material e sombra de janela. Animações curtas (0,25–0,35 s) que respeitam "Reduzir movimento".

### 1.2 Adobe (Spectrum 2; Photoshop, Illustrator e Fresco)

- **Tipografia:** Adobe Clean Spectrum (variável), 11–12 px nos painéis [aprox.], rótulos em sentence case.
- **Cor:** 11 tons de cinza neutro por tema; as camadas de fundo sobem em passos pequenos de luminância. No escuro, o fundo mais profundo é `#1D1D1D`. Cor só no acento azul. O fundo do canvas é configurável à parte do tema.
- **Componentes:** todos os controles medem 24, 32 ou 40 px, sem exceções; raio de 4 px (o S2 é mais arredondado). A **barra de opções da ferramenta** tem geometria estável entre ferramentas. Tooltips com nome e atalho.
- **Ícones:** monocromáticos em grade de 20 px; o estado ativo é indicado por fundo e cor, não pela forma.

### 1.3 Affinity (v2 e app unificado de 2025–2026)

- **Tipografia:** fonte do sistema, rótulos de ~11 px densos.
- **Cor:** escuro por padrão. Controles separados para o **cinza do fundo do documento**, o **cinza do artboard** e a **gama da UI**: é o exemplo mais claro de canvas desacoplado do tema. A versão 3.1 trouxe acento configurável.
- **Componentes:** context toolbar enxuta (campo + stepper + slider na mesma altura), campos numéricos com arrastar para ajustar e **status bar que explica a ferramenta atual e seus modificadores**.

### 1.4 O que cria a sensação de acabamento

1. Um único acento, usado só quando significa algo.
2. Hierarquia de texto por cor/opacidade e peso, não por tamanhos variados.
3. Todos os controles na mesma escala de altura, sem exceções.
4. Camadas de cinza neutro em passos pequenos; cor só no acento e no conteúdo.
5. Ícones com o mesmo peso óptico do texto e alinhados à linha de base.
6. Barra de opções da ferramenta que não muda de geometria ao trocar de ferramenta.
7. Tooltips e menus que sempre mostram o atalho.
8. Seleção que muda para cinza quando a janela perde o foco.
9. Sombra só em elementos que flutuam (menus, popovers, papel); o resto separado por camada e borda fina.

### 1.5 Síntese para este app

| Eixo               | Apple             | Adobe S2             | Affinity         | Proposta                                              |
| ------------------ | ----------------- | -------------------- | ---------------- | ----------------------------------------------------- |
| Texto padrão da UI | 13 pt             | 12–14 px             | 11–12 px         | 13 px em listas e menus; 12 px nos campos da toolbar  |
| Altura de controle | 22–28 pt          | 32 px                | 28–32 px         | 32 px                                                 |
| Raio               | 5–6 pt            | 4 px (S2 maior)      | ~4 px            | 6 controles, 8 campos e menus, 12 diálogos            |
| Separação          | Material e sombra | Camadas e borda fina | Camadas de cinza | Camadas e borda de 1 px; sombra só em overlay e papel |
| Acento             | Azul do sistema   | Azul                 | Configurável     | Âmbar para marca e ação; azul só para foco            |
| Ícone ativo        | Variante fill     | Fundo e cor          | Fundo            | Fundo e variante fill                                 |

## 2. Licenças: o que pode ser distribuído

SF Pro, SF Symbols, Adobe Clean, os ícones do Affinity e a fonte Segoe Fluent Icons **não podem** ser distribuídos num app open source multiplataforma. Os Spectrum Workflow Icons têm pacote Apache-2.0, mas são identidade visual da Adobe; evitar.

| Candidato                  | Licença | Pontos fortes                                                                                              | Riscos                                           |
| -------------------------- | ------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| **Inter** (UI)             | OFL-1.1 | O mais próximo da neutralidade de SF e Adobe Clean; ótimo em 11–13 px; variável                            | Muito usado, pouca identidade                    |
| **IBM Plex Sans** (UI)     | OFL-1.1 | Já está no preview; bom hinting no Windows a 100%                                                          | Mais largo, pesa na toolbar densa                |
| **IBM Plex Serif** (papel) | OFL-1.1 | Já está no preview; boa leitura no conteúdo                                                                | —                                                |
| **Phosphor** (ícones)      | MIT     | Já está no preview; par regular/fill resolve o estado ativo; cobre caderno, caneta, texto, seleção e régua | Traço fino a 20 px pode borrar a 100% no Windows |
| **Fluent System Icons**    | MIT     | Desenhados por tamanho (16/20/24), nítidos no Windows; regular e filled                                    | "Cara de Microsoft"                              |
| **Lucide**                 | ISC     | Boa cobertura, traço ajustável                                                                             | Sem variante fill                                |

**Proposta a validar:** Inter na interface, Plex Serif como fonte padrão do papel e Phosphor em SVG (regular por padrão, fill no ativo). Decidir Inter × Plex Sans e Phosphor × Fluent por comparação no próprio app, no Windows a 100% e 150%. As licenças vão junto com a distribuição.

## 3. Tokens iniciais propostos

### 3.1 Cores

| Token                       | Grafite               | Claro                 | Uso                                             |
| --------------------------- | --------------------- | --------------------- | ----------------------------------------------- |
| `bg.base`                   | `#17191C`             | `#F5F6F4`             | Fundo da janela e da área do canvas             |
| `bg.surface`                | `#202328`             | `#FFFFFF`             | Painéis, menus, toolbar, status                 |
| `bg.raised`                 | `#262A30`             | `#F0F2F0`             | Campos, trilho do segmented, botão secundário   |
| `bg.hover`                  | `#2D3239`             | `#E7EAE7`             | Hover e item selecionado                        |
| `bg.pressed`                | `#343A42`             | `#DCE0DD`             | Pressionado                                     |
| `bg.overlay`                | `#2A2E35`             | `#FFFFFF`             | Menus, popovers, tooltips                       |
| `border.default`            | `#383D44`             | `#D4D9D7`             | Campos e contornos                              |
| `border.subtle`             | `#30353B`             | `#E5E8E5`             | Divisórias entre áreas                          |
| `border.strong`             | `#4A5059`             | `#B9C0BE`             | Hover de campo, item selecionado                |
| `text.primary`              | `#F0F1F2`             | `#1F252B`             | Texto principal                                 |
| `text.secondary`            | `#AEB7C2`             | `#52606C`             | Rótulos e ícones inativos                       |
| `text.tertiary`             | `#7D8793`             | `#6E7983`             | Metadados; nunca texto essencial                |
| `text.disabled`             | `#5A626C`             | `#A7AFB5`             | Desabilitado                                    |
| `accent`                    | `#DDAA75`             | `#9B6336`             | Ação primária, marca, ícone da ferramenta ativa |
| `accent.hover` / `.pressed` | `#E6B988` / `#C9965F` | `#8A5629` / `#7A4A22` | Estados do acento                               |
| `accent.on`                 | `#191D21`             | `#FFFFFF`             | Texto sobre o acento                            |
| `focus`                     | `#7DAAF7`             | `#2868BD`             | Anel de foco de 2 px                            |
| `selection.inactive`        | `bg.raised`           | `bg.raised`           | Seleção com a janela sem foco                   |
| `danger`                    | `#F07F72`             | `#C2412F`             | Erros e exclusão                                |
| `success`                   | `#8FBD9C`             | `#2F7D4F`             | "Salvo localmente"                              |
| `warning`                   | `#E0B860`             | `#9A6B00`             | Avisos                                          |

**Papel, independente do tema:** `paper.warm #F4F0E9`, `paper.white #FFFEFA`, `paper.text #282B2E`, `paper.rule #D5CCC0`. As cores de seção formam uma paleta própria de 8–10 tons e aparecem só como marca e ícone.

### 3.2 Medidas

| Grupo               | Valores                                                                                                               |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Espaçamento         | 2 · 4 · 6 · 8 · 12 · 16 · 20 · 24 · 32 · 40                                                                           |
| Raios               | 3 (tecla de atalho, chip) · 5 (botões de toolbar, linhas) · 7 (botões, campos) · 10 (menus, popovers) · 12 (diálogos) |
| Alturas de controle | 24 (ações de item, zoom) · 28 (itens de menu) · 32 (toolbar, campos, botões) · 36 (busca, diálogos)                   |
| Faixas              | Menu 28 · faixa do caderno 36 · toolbar 46 · status 30 · seção 30 · página 34 · linha da Biblioteca 88                |
| Índice lateral      | 248 (mínimo 200, máximo 320)                                                                                          |
| Ícones              | 20 na toolbar · 16 em listas, menus e campos · 14 no status                                                           |

### 3.3 Tipografia

| Token      | Tamanho/linha | Peso            | Tracking | Uso                                       |
| ---------- | ------------- | --------------- | -------- | ----------------------------------------- |
| `overline` | 10/13         | 600             | +0,6 px  | "SEÇÕES", "PÁGINAS" (caixa-alta)          |
| `caption`  | 11/14         | 400/500         | 0        | Status, breadcrumb, tooltip               |
| `control`  | 12/16         | 500             | 0        | Campos e botões da toolbar                |
| `body`     | 13/18         | 400 (ativo 600) | −0,1 px  | Listas, menus, diálogos                   |
| `title.sm` | 15/20         | 600             | −0,15 px | Título na Biblioteca, cabeçalho de painel |
| `title`    | 20/26         | 600             | −0,3 px  | "Biblioteca"                              |
| `display`  | 28/34         | 600             | −0,5 px  | Estados vazios                            |

Só os pesos 400, 500 e 600. Dígitos tabulares em zoom, contagens e números de página.

### 3.4 Elevação e movimento

- **Sombras:** nenhuma em áreas fixas. Polegar do segmented: sombra mínima (y 1, blur 2). Menus, popovers e tooltips: y 8, blur 24 com borda de 1 px. Diálogos: y 20, blur 48. Papel: y 3, blur 22 com anel de 1 px.
- **Durações:** 100 ms (cor de hover), 160 ms (pressão, segmented), 240 ms (recolher índice e painéis). Popover entra em 140 ms (opacidade e 4 px de deslocamento) e sai em 100 ms.
- **Tooltip:** 600 ms na primeira vez; imediato se outro tooltip apareceu há menos de 1,5 s.
- **Reduzir movimento:** todas as durações vão a zero.

## 4. Como aplicar em Qt Quick 6.8+

1. **Componentes próprios sobre `QtQuick.Templates`.** Um módulo QML `MtnUi` com `Button`, `IconButton`, `SegmentedGroup`, `TextField`, `ListRow`, `Menu`, `ToolTip` etc., cada um herdando de `T.Button`, `T.TextField`… Templates preservam teclado e acessibilidade. Os estilos nativos (Windows, macOS, FluentWinUI3) não permitem customização suportada.
2. **`Theme` singleton** com todos os tokens, temas escuro e claro, e acompanhamento do sistema por `Qt.styleHints.colorScheme`. Forçar o esquema também escurece a barra de título nativa do Windows 11.
3. **Fontes embarcadas** no executável e carregadas em C++ antes do engine QML. Usar `pixelSize`, `font.features` para dígitos tabulares e comparar a renderização nativa com a padrão do Qt no Windows.
4. **Ícones em SVG** recoloridos por `icon.color` nos botões e por um `Icon.qml` único fora deles; `sourceSize` igual ao tamanho lógico.
5. **Sombras com `MultiEffect`** só em overlays e no papel. **Superfícies opacas:** o blur de fundo (vibrancy, Mica) custa caro e não imita o material do sistema.
6. **Moldura nativa da janela** no Windows e Linux (mantém snap layouts e acessibilidade), com menu desenhado dentro da janela. No macOS, o `MenuBar` vira a barra de menus nativa desde o Qt 6.8. A toolbar unificada à barra de título no Mac exige Qt 6.9; janela sem moldura não é recomendada no MVP.
7. **Menus e popups** em janela própria (`Popup.Window`) para não serem cortados pela borda.
8. **High-DPI:** a 125% e 150% uma borda de 1 px fica borrada. O `Theme` expõe uma linha fina ajustada ao pixel físico, e posições são arredondadas. Testar sempre em 100%, 125% e 150%.
9. **Movimento** com `Behavior` e `transitions`; "Reduzir movimento" lido do sistema por um helper C++.
10. **Acessibilidade:** todo botão só de ícone tem nome acessível e tooltip; anel de foco só com teclado (`visualFocus`); foco em listas separado da ativação. Alto contraste do Windows pede um terceiro conjunto de tokens no futuro.

**Recursos do preview que só existem na web:** `backdrop-filter`, `color-mix()`, sombras múltiplas e `inset`, gradiente radial de fundo, `filter: brightness` e media queries. No Qt viram tokens de estado explícitos, bordas internas desenhadas, uma única sombra por elemento e breakpoints por largura no `Theme`.

## 5. Diferenças entre o preview e o app atual

1. **Fontes e ícones:** o app usa a fonte do sistema e nenhum ícone; o "+" é texto.
2. **Cores:** o app tem 6 cores, com valores diferentes do preview, e não tem bordas, terceira camada de superfície nem cor de foco.
3. **Menu:** estilo padrão do Qt, mais alto e sem acabamento. O preview mostra o nome **"Orla"**, enquanto o título da janela e os documentos usam "more-than-a-note".
4. **Faixa do caderno:** 54 px com botão padrão, contra 34 px com seta e link no preview.
5. **Toolbar e status bar:** ausentes no app.
6. **Índice lateral:** sem cabeçalho, sem recolher, sem cor de seção, ícones, hover, elisão de texto nem ações no item ativo; as linhas são botões padrão.
7. **Canvas:** papel centralizado sem rolagem, sem sombra e com cor diferente; título sem serifa; sem breadcrumb.
8. **Biblioteca:** sem capas, metadados, ordenação, alternância lista/grade nem "Importar"; linhas de 64 px só com o título.
9. **Estados:** sem hover próprio, anel de foco, tooltips, transições, breakpoints e toasts; criação por diálogo modal em vez de edição inline.

## 6. Sequência de implementação com avaliação

Cada passo marcado com **avaliar** termina com o app rodando e uma decisão do dono do produto. O padrão aprovado é registrado antes do passo seguinte.

| #  | Passo                                                                                                                      | Decisão                                     |
| -- | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| 1  | Módulo `MtnUi` e `Theme` com todos os tokens; `Main.qml` passa a usá-los                                                   | —                                           |
| 2  | Embarcar fontes e criar uma galeria de amostras: Inter × Plex Sans, renderização nativa × Qt, 100/125/150%                 | **Avaliar:** fonte e renderização           |
| 3  | Embarcar os ícones usados (Phosphor regular e fill) e comparar com Fluent na galeria                                       | **Avaliar:** família de ícones              |
| 4  | Primitivos: botões, botão de ícone, campos, busca, anel de foco e tooltip com atalho, em todos os estados e nos dois temas | **Avaliar:** estados                        |
| 5  | Toolbar: grupo Texto/Caneta/Seleção, campos de fonte e tamanho, botões de formatação e amostras de cor                     | **Avaliar:** densidade                      |
| 6  | Linhas de lista e cabeçalhos de grupo do índice                                                                            | **Avaliar**                                 |
| 7  | Menus estilizados e criação inline no lugar dos diálogos modais                                                            | **Avaliar** (rápido)                        |
| 8  | Tela da Biblioteca                                                                                                         | **Avaliar** contra `preview-library-v5.png` |
| 9  | Moldura do caderno: faixa, toolbar e status                                                                                | **Avaliar**                                 |
| 10 | Índice lateral redimensionável e recolhível                                                                                | **Avaliar**                                 |
| 11 | Área do canvas com papel, sombra e cabeçalho da página                                                                     | **Avaliar** contra `preview-caderno-v6.png` |
| 12 | Janela estreita, tooltips em todos os comandos e teclado de ponta a ponta                                                  | **Avaliar**                                 |
| 13 | Movimento, linhas finas por DPI, seleção inativa e revisão de contraste                                                    | **Avaliar:** revisão final                  |

### 6.1 Andamento

- **Passos 6 e 7 aplicados ao índice, aguardando avaliação.** Cabeçalhos `IndexHeader` usam texto discreto e adição somente por ícone. `IndexRow` mantém 30 px para seção e 34 px para página; mostra cor apenas no ícone da seção, sem barra lateral colorida, e separa seleção, hover e foco. Engrenagem e lixeira aparecem na linha ativa ou sob o ponteiro. A engrenagem abre `IndexMenu` em janela própria com renomeação e, na seção, cores; a exclusão pede confirmação. `IndexCreate` substitui os diálogos modais de nova seção e nova página por campos no próprio índice, com Enter para confirmar e Esc para cancelar. Os mesmos componentes aparecem na galeria com `--gallery-index`. O papel da página permanece para a etapa do editor; o menu atual trata apenas ações com suporte no modelo local.
- **Passo 5 implementado, aguardando avaliação.** `EditorToolbar` está no espaço do caderno e na galeria. `ToolModeButton` usa Phosphor regular/fill; só o ícone da ferramenta ativa recebe âmbar. Os três modos compartilham uma área contextual de largura fixa: Texto mostra fonte, tamanho, formatação e cores; Caneta mostra caneta/marca-texto/borracha, espessura e cores; Seleção mostra objeto/laço/mão. A ilha mede 46 px de altura, e a faixa rola horizontalmente em janelas estreitas sem quebrar em outra linha. `T`, `P`, `V` e `E` trocam ferramentas, e `Ctrl+B/I/U` mudam o estado visual de texto; os atalhos de uma tecla só atuam com foco no papel, conforme o documento 03. Desfazer/refazer ficam desabilitados até existir histórico do editor. Os ajustes são estado de UI para avaliação; ainda não alteram o conteúdo da página.

  **Cores rápidas.** Texto e Caneta exibem as mesmas nove posições, na ordem das teclas `1` a `9`. O ícone de paleta e a tecla `0` abrem um painel para escolher uma posição e substituir sua cor por um valor `#RRGGBB`; `Esc` o fecha e devolve o foco ao controle de origem. Cada amostra mantém alvo de 32 px, círculo de cor de 18 px e nome, posição e valor no nome acessível e no tooltip. Seleção usa um contorno circular de 2 px com vão de 2 px; hover usa apenas um contorno circular mais discreto. O foco de teclado preserva o anel azul do sistema de componentes. Assim, os estados são reconhecíveis sem usar somente a tonalidade e sem criar um fundo quadrado atrás da amostra. A personalização nesta fase vive no estado da UI; persistência será integrada às preferências do editor.

  **Precisão da toolbar.** O trilho de 36 px fazia as três ferramentas parecerem maiores e as deslocava 2 px acima dos controles adjacentes. Agora botões de ferramenta, comandos, campos e amostras compartilham alvo e altura de 32 px, centralizados na ilha de 46 px (7 px acima e abaixo). Espaçamento interno de cada grupo: 4 px; separação entre grupos: 8 px de cada lado do divisor de 1 px; divisor centrado verticalmente, com 20 px de altura. A largura contextual vem da medida dos controles, não de um número fixo, e permanece constante ao trocar de ferramenta. Em largura reduzida, a faixa rola horizontalmente sem comprimir alvos. Verificar em 100%, 125% e 150% antes de encerrar o passo visual. A decisão acompanha a orientação de agrupamento de [Apple Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) e de estados de seleção em [Adobe Spectrum Action Button](https://spectrum.adobe.com/page/action-button/).
- **Passo 4 implementado, aguardando avaliação.** Componentes em `apps/desktop/ui`: `ActionButton` (primário, secundário, sutil), `IconButton` (inclusive alternável), `FieldButton`, `InputField`, `SearchBox`, `HintToolTip` com `Kbd` e `FocusRing`. A galeria mostra cada um em todos os estados, lado a lado, e uma área interativa. A Biblioteca já usa o botão primário e a busca com `Ctrl K`.
- **Ilhas e rolagem implementadas** (`Island`, `ThinScrollBar`, `ScrollArea`), com demonstração na galeria. Regras em §6.4.
- **Passos 1–3 concluídos.** Decisões em §6.2.
  - Tokens em `apps/desktop/ui/Theme.qml`, já usados pelo `Main.qml`.
  - Fontes (Inter, JetBrains Mono, IBM Plex Serif) e ícones Phosphor embarcados em `apps/desktop/assets`, com licenças em `assets/licenses`.
  - Galeria em **Ajuda → Galeria visual** (ou `--gallery`), com seletores de tema e renderização que mudam o app inteiro.
- O app passou a usar o estilo Basic do Qt, porque o estilo nativo do Windows ignora as cores do tema. A barra de título nativa acompanha o tema.

### 6.2 Padrões aprovados

| Decisão               | Escolha                                    | Motivo                                                                                                                               |
| --------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| Fonte da interface    | **Inter** (400, 500, 600)                  | Aprovada na galeria.                                                                                                                 |
| Fonte mono            | **JetBrains Mono** (400, 500)              | Blocos de código e teclas de atalho; desenhada para combinar com sans neutras como a Inter.                                          |
| Fonte do papel        | IBM Plex Serif (padrão, configurável)      | Mantida da proposta; o texto do usuário tem fonte própria.                                                                           |
| Ícones                | **Phosphor** (regular; fill no ativo)      | Aprovado na galeria.                                                                                                                 |
| Renderização do texto | **Qt**                                     | Na comparação ampliada a 100% a diferença para a nativa é mínima; a do Qt escala com zoom e animação e é igual em todos os sistemas. |
| Atalhos               | Teclas em JetBrains Mono, componente `Kbd` | Ideia do dono do produto: atalho com cara de código, em tooltips e menus.                                                            |
| Ligaduras de código   | **Desligadas** por padrão                  | Preferência do usuário (`code_ligatures` no documento 05) para ligar.                                                                |
| Ferramenta ativa      | Âmbar **só no ícone** (fill)               | Mais sóbrio, como Apple e Affinity; o fundo do botão continua neutro.                                                                |

IBM Plex Sans e Fluent System Icons saíram do projeto.

### 6.3 Componentes propostos (para confirmar no passo 4)

Medidas e cores vêm de §3. Todos os componentes mostram hover, pressionado, desabilitado e foco por teclado (anel de 2 px `focus`, só com teclado), e todo botão só de ícone tem nome acessível e tooltip.

| Componente             | Uso                                       | Aparência                                                                                                                                                                                                                                 |
| ---------------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ToolModeButton**     | Texto, Caneta, Seleção                    | Alvo de 32×32, igual aos demais controles da toolbar, com 4 px entre botões; sem trilho externo mais alto. Ícone 20 regular `textSecondary`. Ativo: fundo `hover`, borda `borderStrong` e ícone **fill** em `accent`. Hover: ícone `textPrimary`. |
| **IconButton**         | Desfazer, refazer, +, engrenagem, lixeira | Fundo transparente; 24, 28 ou 32 px; ícone 16 ou 20. Hover `raised`, pressionado `pressed`, ativo (toggle B/I/U) `hover` com ícone `textPrimary`. Raio 5.                                                                                 |
| **Button** (só texto)  | Ações com texto                           | Altura 32, raio 7, texto 12/500. **Primário:** fundo `accent`, texto `accentOn` (um por tela). **Secundário:** `raised` com borda. **Sutil:** sem fundo.                                                                                  |
| **FieldButton**        | Fonte e tamanho na toolbar                | Aparência de campo (`raised`, borda, raio 7, altura 32) com seta à direita; abre menu.                                                                                                                                                    |
| **AppCheckBox**        | Preferências e propriedades booleanas    | Alvo de 32 px de altura; quadro de 18 px com preenchimento interno de 10 px quando marcado, separado da borda por 3 px. Sem marca em “V”. Foco azul no contorno, estado marcado também anunciado ao leitor de tela.                   |
| **SelectList**         | Escolha única em preferências e página   | Campo de 32 px, seta à direita e menu compacto com linhas de 32 px. Seleção por mouse e teclado; foco azul e hover neutro, seguindo os campos existentes.                                                                                 |
| **TextField / Search** | Busca, nomes                              | Altura 32 (36 na busca da Biblioteca), `raised`, borda que fica `borderStrong` no hover e `focus` com teclado. Busca com lupa à esquerda e `Kbd` à direita.                                                                               |
| **Kbd**                | Atalhos                                   | Teclas de 18 px em JetBrains Mono 11/500, `raised` com borda, raio 3, uma tecla por caixa.                                                                                                                                                |
| **ToolTip**            | Todos os botões                           | `overlay`, borda, raio 5, altura 28; nome da ação em 11 px + `Kbd`. Aparece em 600 ms (imediato se outro acabou de aparecer).                                                                                                             |
| **ListRow**            | Seções, páginas, cadernos                 | Seção 30, página 34. Seleção: fundo `hover` + borda interna; ações (engrenagem, lixeira) só no hover e no item ativo; cor da seção só no marcador.                                                                                        |


### 6.4 Regras de layout aprovadas

1. **Botão é ícone ou texto, nunca os dois.** Se o ícone sozinho comunica a ação, usar `IconButton` com tooltip e nome acessível; se não comunica, usar `ActionButton` só com texto.
2. **Painéis são ilhas.** Cada painel (barras, índice, área da página, status) é uma superfície separada do fundo da janela por **6 px** (`space.island`), inclusive nas bordas da janela, com raio **sutil de 8 px** (`radius.island`) e borda de 1 px `borderSubtle`. Componente `Island`.
3. **Rolagem sobreposta.** Sem trilho nem calha: a barra (`ThinScrollBar`) é um polegar de 6 px que aparece ao rolar ou ao passar o mouse, engrossa para 8 px sob o ponteiro e some 0,6 s depois de parar. A área de toque tem 12 px. A rolagem para nas bordas, sem efeito elástico (`ScrollArea`, e `boundsBehavior: Flickable.StopAtBounds` em listas).

## 7. Referências

- Apple: [Typography](https://developer.apple.com/design/human-interface-guidelines/typography), [Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [SF Symbols](https://developer.apple.com/sf-symbols/).
- Adobe: [Spectrum typography](https://spectrum.adobe.com/page/typography/), [design tokens](https://spectrum.adobe.com/page/design-tokens), [color system](https://spectrum.adobe.com/page/color-system), [object styles](https://spectrum.adobe.com/page/object-styles), [Spectrum Web Components styles](https://opensource.adobe.com/spectrum-web-components/tools/styles), [anúncio do Spectrum 2](https://blog.adobe.com/en/publish/2023/12/12/adobe-unveils-spectrum-2-design-system-reimagining-user-experience-over-100-adobe-applications).
- Affinity: [Workspace at a glance](https://affinity.help/publisher/en-US.lproj/pages/Workspace/atAglance.html), [UI appearance](https://affinity.help/photo2/en-US.lproj/pages/Workspace/uiAppearance.html).
- Qt: [MenuBar](https://doc.qt.io/qt-6/qml-qtquick-controls-menubar.html), [Popup](https://doc.qt.io/qt-6/qml-qtquick-controls-popup.html), [áreas de cliente expandidas no Qt 6.9](https://www.qt.io/blog/expanded-client-areas-and-safe-areas-in-qt-6.9).
- Fontes e ícones: [Inter](https://github.com/rsms/inter), [IBM Plex](https://github.com/IBM/plex), [Geist](https://github.com/vercel/geist-font), [Phosphor](https://github.com/phosphor-icons/core), [Fluent System Icons](https://github.com/microsoft/fluentui-system-icons), [Lucide](https://lucide.dev), [Tabler](https://tabler.io/icons).
