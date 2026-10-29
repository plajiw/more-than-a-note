# 01 — Layout e navegação desktop

> **Substituído** pelo [01 — Layout atual](01-layout-refeito.md). Mantido como registro histórico; não use como especificação.

**Status:** especificação funcional inicial · **Plataformas-alvo:** Windows e Linux · **Escopo:** desktop local, sem navegador ou servidor.

## 1. Objetivo e critérios

A interface organiza o aplicativo em **Caderno → Seção → Página**. O conteúdo ocupa a maior área possível, e o acesso às funções frequentes não depende de modais. O desenho é sóbrio, sem excesso de cores, brilhos, sombras ou arredondamentos. A aplicação nasce com temas claro e escuro e oferece paridade funcional entre ambos.

**Definido:** menu superior `Arquivo | Início | Exibir`; segunda linha horizontal para ferramentas de texto e edição; coluna vertical dedicada a desenho à esquerda da página; navegação hierárquica; editor com cabeçalho e canvas livre. **Proposta para validação:** localização exata de biblioteca, barra de estado e tratamento de janelas estreitas.

## 2. Anatomia da janela

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ Arquivo       Início       Exibir                             [—] [□] [×] │ ← linha 1
├──────────────────────────────────────────────────────────────────────────────┤
│ ↶  ↷  Texto  │ Fonte ▾  Tamanho ▾ │ B  I  U │ Destaque │ Cor ▾ │ •  1. │ ← linha 2
├──────────────────────────────┬────┬───────────────────────────────────────────┤
│ BIBLIOTECA                   │ 🖊 │ Página sem título                         │
│ ▾ Caderno: Arquitetura       │ ▧ │ 23 de outubro de 2026                    │
│   ▾ Pipeline                │ ◉ │                                           │
│     Conceitos fundamentais   │ 1 │ [Comece a escrever...]                    │
│     Hazards                 │ 2 │                                           │
│     Superpipeline           │ 3 │     texto e tinta digital independentes   │
│   ▾ Superescalares          │ ⋮ │                                           │
│     Múltipla emissão        │   │                                           │
├──────────────────────────────┴────┴───────────────────────────────────────────┤
│ Salvo localmente     Ferramenta: Caneta                        − 100% +    │ ← status
└──────────────────────────────────────────────────────────────────────────────┘
```

O diagrama é estrutural, não pixel-perfect. Os símbolos não prescrevem ícones nem cores finais.

### 2.1 Linha 1 — Navegação por menus

- **Arquivo:** novo caderno; abrir; importar/exportar cadernos; copiar/backup; configurações; sair. Ações de perda de dados exigem confirmação apropriada.
- **Início:** acesso às principais ações de edição e formatação, sem esconder a barra horizontal. Uma alternativa é tratar Início como seção de comandos, não guia que redesenha inteiramente a interface. Evitar duplicação sem função.
- **Exibir:** mostrar/ocultar biblioteca e barras; zoom; ajustar à largura/página; alternar tema; alternar guias/régua; configurações da página acessíveis em painel lateral.
- Todos os menus são operáveis por teclado, com aceleradores quando compatíveis com a plataforma e sem roubar foco inesperadamente.

### 2.2 Linha 2 — Texto e edição

Ordem inicial: **Desfazer**, **Refazer**, **Texto**, separador, **Família de fonte**, **Tamanho**, **Negrito**, **Itálico**, **Sublinhado**, **Realce**, **Cor da fonte**, **Lista com marcadores**, **Lista numerada**, **Mais opções**. Mostrar estado ativo/misto conforme a seleção. Controles devem possuir foco e tooltip com descrição e atalho.

**Lógica contextual:** sem texto selecionado, as opções podem estabelecer o estilo de digitação seguinte; durante seleção de objetos manuscritos, controles tipográficos ficam desativados e explicam o motivo no tooltip. Não deslocar os comandos a cada troca de foco, pois isso quebra a memória muscular.

### 2.3 Coluna vertical de escrita

A coluna é uma barra de ferramentas compacta, mas tátil e claramente clicável: **Caneta**, **Borracha**, **Seleção**, **Mão**, **Régua**, **Espessura**, **amostras da paleta ativa** e **abrir paleta**. Os dez atalhos numéricos referenciam nove amostras rápidas e uma ação de paleta (ver documento 03); não é obrigatório mostrar dez blocos de cor se `0` representa a abertura do seletor. As amostras podem aparecer como grupo dobrável para economizar espaço.

A ferramenta ativa recebe destaque inequívoco por contorno/preenchimento, além de ícone; nunca apenas por cor. A espessura aparece como prévia de traço e valor acessível. Para caneta Wacom, a pressão funciona mesmo quando o painel de ajustes avançados não é exibido.

### 2.4 Biblioteca / navegação

A biblioteca apresenta cadernos com nome, cor e futura capa; seções com nome e cor; páginas com título e indicadores discretos. Operações: criar, renomear, excluir, reordenar, mover páginas entre seções; expansão/recolhimento sem trocar página; pesquisa por títulos e texto. O caderno é unidade de armazenamento local e contexto de referências, não apenas pasta visual. Regras de referências: cada recurso recebe ID estável, associação ao caderno e origem/localização persistidas; nomes de arquivo não são identidades.

**Proposta:** painel da biblioteca redimensionável e recolhível, com largura persistida; opção de navegação compacta, sem esconder completamente a descoberta do caderno ativo. O aplicativo deve mostrar em qual caderno e seção a página atual está, inclusive com painel fechado.

### 2.5 Editor / cabeçalho / canvas

A página tem **título de metadado**, data opcional e superfície de conteúdo abaixo. O título nunca é um contêiner arrastável. O contêiner inicial é um **objeto normal**, criado apenas quando há conteúdo, posicionado abaixo do título. Os objetos utilizam coordenadas próprias em unidades lógicas da página; viewport, scroll e zoom não devem alterar coordenadas armazenadas. Página pode ser finita (A4 e outras dimensões) ou infinita, com fundos branco/escuro/pautado/quadriculado/pontilhado.

### 2.6 Rodapé e zoom

Status não intrusivo de salvamento, ferramenta efetiva, zoom atual, botões `− / +` e ação `100%`/ajuste. Zoom com mouse, teclado e caneta deve manter ponto âncora previsível; quando acionado no ponteiro, preferir o ponto sob ponteiro. Evitar abrir pop-ups sobre a área onde se está escrevendo.

## 3. Layout adaptativo e ergonomia

- Janelas largas: biblioteca expandida + coluna de caneta + editor.
- Janelas estreitas: biblioteca recolhida em painel temporário **não modal**; comandos de texto menos usados em menu de overflow; os controles principais nunca desaparecem sem alternativa.
- Barra lateral de caneta pode mudar de lado, importante para destros e canhotos; não posicionar popovers sob a mão que escreve.
- Tooltips acima de outras camadas, com tempo de abertura ajustável, sem interceptar eventos de desenho; exibem `nome · ação · atalho`.
- Painel de propriedades de papel deve ser não modal e manter a página visível ao aplicar alterações.
- Estados hover, foco, pressionado, selecionado, desabilitado e ferramenta temporária são visualmente distinguíveis.
- Interface não depende de gestos multitoque para funcionalidades essenciais.

## 4. Temas e design system

Tokens separados para superfície principal, painéis, bordas, textos, foco, seleção, estados e fundo do papel. **Paletas de tinta para tema claro e escuro** independentes do tema da UI: alternar o tema da interface não deve automaticamente recolorir uma anotação já escrita. Preservar legibilidade de notas em ambos os fundos e fornecer avisos discretos quando uma tinta for pouco contrastante no papel escolhido.

Componentes reutilizáveis: `ToolButton`, `ToolGroup`, `ToolbarSeparator`, `ColorSwatch`, `DropdownField`, `SectionTreeItem`, `PageItem`, `NotebookCard`, `Tooltip`, `ContextMenu`, `StatusIndicator`, `InspectorPanel`. Ícones de uma biblioteca coerente, não SVGs improvisados inconsistentes; botões com área de clique adequada.

## 5. Critérios de aceitação

1. Criar um caderno colorido, duas seções e páginas sem perder a localização na navegação.
2. Alternar entre tema claro e escuro sem alterar a cor dos traços persistidos.
3. Recolher a biblioteca mantendo caderno/página atuais identificáveis.
4. Trocar ferramenta sem deslocar a barra superior ou o canvas.
5. Aplicar novo fundo/papel observando o resultado sem modal bloqueante.
6. Operar menus, biblioteca, formatação e zoom somente pelo teclado.
7. Tooltips e menus sobrepõem corretamente a superfície e não ficam cortados sob painéis.

## 6. Pontos abertos

Definir dimensões mínimas da janela, localização final da barra de escrita (fixa ou destacável), política de múltiplas janelas e comportamento de canvas infinito no modo de impressão/exportação.
