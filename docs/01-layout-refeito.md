# 01 — Layout refeito: biblioteca e espaço do caderno

**Status:** decisão de produto para orientar protótipo e implementação. **Plataformas:** beta Windows; Linux e macOS planejados conforme `10-plano-tecnico-desktop.md`. **Escopo:** aplicativo desktop local e offline. Este documento substitui `01-layout.md` como referência de layout; os demais documentos continuam válidos onde não houver conflito explícito.

## 1. Objetivo

O usuário deve reconhecer em qual caderno está, localizar rapidamente a seção e a página desejadas e dedicar a maior parte da janela à leitura, à digitação e à escrita manual. O layout separa dois contextos: **Biblioteca**, onde se escolhe um caderno, e **Espaço do caderno**, onde se trabalha em suas seções e páginas. Durante a edição, outros cadernos não aparecem na navegação.

São decisões desta revisão:

1. A Biblioteca é uma tela própria; não divide a janela com o editor.
2. A janela de edição identifica o aplicativo e o caderno aberto.
3. Seções aparecem no índice estrutural do caderno, acima das páginas da seção ativa, e têm título, cor e ícone opcional.
4. A lista de páginas mostra apenas as páginas da seção ativa do caderno aberto.
5. Texto, Desenho e Seleção são botões compactos de ferramenta na barra superior; seus ajustes aparecem ao lado, em área contextual de geometria estável.
6. O tema escuro usa superfícies grafite, com papel e tinta independentes da aparência da interface.

O layout não determina a linguagem, o toolkit ou o formato nativo do caderno. Medidas e cores abaixo são valores iniciais para protótipo e validação, não parâmetros imutáveis.

### 1.1 Princípios gerais de layout

Estas regras orientam novas telas e futuras mudanças. Quando uma proposta conflitar com elas, registrar o motivo e validar o efeito no fluxo real de uso.

1. **Organizar pelo trabalho em curso.** Cada tela deve responder a uma tarefa principal. Biblioteca serve para escolher e gerir cadernos; espaço do caderno serve para ler, escrever e navegar dentro dele. Não trazer para a edição elementos que pertencem à escolha de outro caderno.
2. **Mostrar a hierarquia onde ela é usada.** Caderno, seção e página são níveis de navegação. Depois de abrir o caderno, apresentar seções e páginas em um índice estrutural próximo ao documento, com a seleção atual sempre visível. Não transformar esses níveis em faixas sucessivas que ocupam a largura do canvas.
3. **Dar prioridade visual ao conteúdo.** A página deve receber a maior área e o maior contraste de atenção. Barras, painéis e status existem para apoiar o documento; sua altura, largura e ornamentação precisam justificar o espaço que consomem.
4. **Separar navegação, ferramenta e propriedade.** O índice escolhe onde trabalhar; o botão de ferramenta escolhe o que fazer; os controles contextuais ajustam como a ferramenta age; um painel de propriedades aprofunda ajustes quando solicitado. A posição de cada função deve comunicar esse papel.
5. **Manter comandos comuns estáveis.** Desfazer, refazer, identificação do caderno, busca, papel e zoom não devem mudar de lugar ao alternar Texto, Desenho e Seleção. A área de opções pode mudar de conteúdo, mas não provocar saltos do canvas ou perda de foco.
6. **Usar densidade de aplicativo desktop.** Preferir barras compactas, grupos de botões, divisórias finas e painéis redimensionáveis a cartões grandes, grandes vazios e múltiplas faixas de abas. A densidade deve continuar legível e clicável com mouse e caneta.
7. **Revelar detalhes por necessidade.** Manter visíveis as ações frequentes e a ferramenta ativa; usar menus, overflow e painéis não modais para opções secundárias. Esconder um comando exige uma rota clara para reencontrá-lo, inclusive por teclado.
8. **Reduzir repetição de contexto.** Não repetir o nome da seção em vários cabeçalhos simultâneos sem ganho de orientação. Com o índice aberto, seleção da seção/página e título da folha bastam; com o índice fechado, mostrar contexto compacto e um comando para reabri-lo.
9. **Preservar a superfície de escrita.** Painéis temporários não devem cobrir a ponta ativa da caneta, capturar eventos depois de fechados ou interromper o gesto. Ao recolher painéis ou redimensionar a janela, não modificar coordenadas do documento.
10. **Usar cor como orientação, não como única informação.** A cor da seção ajuda a reconhecer o caminho; título, ícone opcional e estado de seleção dão confirmação independente. Tema da interface, cor do papel e cor da tinta são sistemas separados.
11. **Projetar estados e transições com a mesma atenção que a tela cheia.** Biblioteca vazia, seção sem páginas, busca sem resultado, salvamento em andamento e erro precisam manter contexto e próxima ação claros. Voltar à Biblioteca não pode sugerir que conteúdo não salvo já está seguro.
12. **Permitir trabalho com diferentes entradas.** Mouse, caneta, teclado e leitor de tela devem alcançar as funções essenciais. Foco, seleção e ferramenta efetiva são estados distintos e precisam de sinais distintos.
13. **Adaptar a largura sem mudar o modelo mental.** Em janela estreita, recolher o índice e mover opções secundárias para overflow; manter as mesmas relações entre caderno, seção, página, ferramenta e documento. Evitar criar uma segunda navegação completamente diferente.
14. **Validar pelo fluxo, não só pela captura.** Julgar o layout ao abrir um caderno, alternar seções, localizar uma página, escrever, desenhar, ajustar papel, recolher o índice e voltar à Biblioteca. Testar também nomes longos, muitas páginas, zoom, foco e tamanhos de janela comuns.

**Critério de decisão:** quando duas soluções forem igualmente claras, preferir a que preserva mais área de documento, reduz uma camada de interface e mantém comandos em locais previsíveis. Não aplicar essa preferência se ela piorar descoberta, acessibilidade ou uso com caneta.

**Regra de acabamento:** seleção de seção/página usa superfície, contorno discreto, texto e ícone para comunicar estado; a cor da seção fica no marcador/ícone, sem barra colorida adicional na borda do item. Separadores verticais só devem aparecer quando a distância e o agrupamento dos controles não bastarem. A Biblioteca deve ter densidade de janela de aplicativo: título funcional, busca, ordenação, criação e cadernos; evitar saudação, avatar fictício, grandes frases promocionais e linhas decorativas que não expliquem uma divisão real.

## 2. Modelo de navegação

```text
Biblioteca local
  └─ abrir caderno → Espaço do caderno
                       ├─ seção ativa → lista de suas páginas
                       ├─ página ativa → editor/canvas
                       └─ Voltar à biblioteca → Biblioteca local
```

### 2.1 Biblioteca

Tela de entrada e gestão dos cadernos. A **lista compacta é a apresentação inicial**; a grade de capas é uma opção de visualização. Cada linha reúne miniatura da capa/cor, nome e metadados discretos, com área clicável suficiente e seleção diferente de foco e hover. Ações do item ficam no menu de contexto e no teclado, sem botões decorativos repetidos em cada linha. A Biblioteca oferece busca por caderno, ordenação e ações Criar, Abrir, Renomear, Duplicar, Importar/Exportar e Excluir. Arquivos recentes podem aparecer quando ajudarem a retomar o trabalho. A Biblioteca não exibe canvas nem a árvore completa de páginas de todos os cadernos.

A barra de menus do aplicativo permanece no topo. Abaixo dela, um cabeçalho curto identifica **Biblioteca** e reúne as ações principais; busca, ordenação e alternância Lista/Grade formam a barra de controle da coleção. Não repetir a marca em outra faixa, criar um cabeçalho de boas-vindas ou usar cartões grandes como apresentação obrigatória. Menus Arquivo/Editar/Exibir/Inserir/Ajuda e comandos contextuais são as rotas completas para as funções menos frequentes.

Ao abrir um caderno, restaurar a última seção e página válidas daquele caderno quando possível. Se não houver página, mostrar o estado vazio correspondente. Voltar à Biblioteca preserva o estado salvo e encerra estados transitórios de edição com regras determinísticas; não descarta conteúdo. O autosave e seu status continuam visíveis até a transição.

### 2.2 Espaço do caderno

A barra superior mostra `Nome do software — Nome do caderno` no título da janela; dentro do espaço de trabalho, basta identificar o caderno uma vez, sem repetir a marca do aplicativo ao lado. O comando **« Biblioteca** fica visível e tem nome acessível. A busca por páginas e texto *somente no caderno aberto* fica em Editar/Buscar com atalho, sem campo de busca permanente na barra. Ações de caderno (renomear, cor, exportar, propriedades) ficam no menu Arquivo e em comandos contextuais com escopo explícito, sem trazer outros cadernos para a tela.

O nome do caderno também deve aparecer no conteúdo da janela ou barra própria, pois o título do sistema operacional pode ficar oculto em tela cheia ou em alguns ambientes Linux. Ao alternar para outro caderno, o usuário retorna à Biblioteca e abre o desejado. A política de múltiplas janelas permanece decisão separada; cada janela de edição, se suportada, deve pertencer a um caderno identificável.

## 3. Anatomia das telas

### 3.1 Biblioteca

```text
┌ Orla   Arquivo  Editar  Exibir  Inserir  Ajuda ────────────────┐
│ Biblioteca                       Novo caderno   Importar       │
│ Buscar cadernos...              Ordenar por...   Grade  Lista   │
│ Cadernos                                              3 itens   │
│ [capa] Caderno A                         seções · páginas       │
│ [capa] Caderno B                         seções · páginas       │
│ [capa] Caderno C                         seções · páginas       │
└──────────────────────────────────────────────────────────────────┘
```

Na grade opcional, as mesmas capas e informações podem ocupar cartões. Lista e grade preservam as mesmas ações, seleção, navegação por teclado e ordem dos itens. A lista deve funcionar bem com muitos cadernos e nomes longos. Ordem manual ou por atualização recente é uma preferência a validar. Não carregar miniaturas pesadas como pré-condição para abrir a Biblioteca.

### 3.2 Espaço do caderno

```text
┌ Nome do software — Caderno aberto ───────────────────────────────┐
│ « Biblioteca   Caderno aberto       Buscar neste caderno    ⋯   │
├──────────────────────────────────────────────────────────────────┤
│ ↶ ↷ │ [T] [Caneta] [Seleção] │ ajustes contextuais │ Papel     │
├───────────────────┬──────────────────────────────────────────────┤
│ Índice do caderno │                                              │
│ SEÇÕES       + ⋯  │ Título da página                             │
│ ● Pipeline        │ Data opcional                                │
│ ● Superescalares  │                                              │
│ ● Revisão         │ [Comece a escrever...]                       │
│ PÁGINAS      +    │      texto e tinta no mesmo canvas           │
│ Conceitos         │                                              │
│ Hazards           │                                              │
├───────────────────┴──────────────────────────────────────────────┤
│ Salvo localmente     Ferramenta efetiva               − 100% +   │
└──────────────────────────────────────────────────────────────────┘
```

O esquema descreve hierarquia, não aparência final. O painel esquerdo é um **índice do caderno aberto**: apresenta seções no primeiro grupo e somente as páginas da seção ativa no segundo. Não contém outros cadernos. Os dois grupos permanecem distinguíveis por cabeçalhos e divisórias finas. Páginas são destinos de navegação e ordenação; não são camadas de composição, visibilidade ou empilhamento dentro da página.

## 4. Navegação interna do caderno

### 4.1 Grupo de seções no índice

Cada seção possui **título obrigatório**, **cor configurável** e **ícone opcional** escolhido de um catálogo coerente. A cor aparece como marca de orientação discreta e nunca é o único sinal de seção ativa; usar também contorno, fundo, posição ou indicador. Ícones não substituem títulos e não são criados pelo usuário como arquivos arbitrários no MVP. O modelo conceitual da seção passa a incluir `iconId?`.

As seções formam uma lista vertical compacta no topo do índice. **+ Seção** e **Todas as seções** ficam no cabeçalho desse grupo; Todas abre uma lista pesquisável, operável por teclado e leitor de tela. Renomear, mudar cor/ícone, reordenar e excluir ficam no menu contextual ou painel de propriedades da seção. Ao trocar de seção, o grupo de páginas abaixo passa a mostrar somente páginas daquela seção; se houver última página visitada válida, restaurá-la. A seleção usa uma marca de cor e uma superfície/indicador de estado. Se houver muitas seções, a área pode rolar ou condensar por meio do seletor pesquisável, sem disputar altura ilimitada com a lista de páginas. O canvas nunca exibe páginas de seções diferentes em conjunto.

### 4.2 Índice de páginas

O grupo de páginas exibe título, ordem e indicadores úteis da página da seção ativa. O índice como um todo pode ser redimensionado e recolhido; a largura escolhida pertence ao estado local da janela. Quando recolhido, o cabeçalho da página mostra um comando **Índice** que o reabre e identifica a seção atual. Há ações acessíveis para criar, renomear, duplicar, mover, reordenar e excluir páginas. Mover para outra seção muda sua localização na navegação sem alterar seu ID ou conteúdo.

Com centenas de páginas, usar busca/filtro, rolagem eficiente e virtualização que preserve foco e semântica acessível; não depender de arrastar por longas distâncias para reordenar. Uma página com título longo pode usar duas linhas ou truncamento com nome completo acessível. A seleção atual é distinguível de foco e hover. A lista não deve trocar a página ao expandir um menu ou ao focar um item. Selecionar um resultado de busca de outra seção ativa aquela seção e página e revela ambas na navegação.

### 4.3 Busca e orientação

A busca global da Biblioteca encontra cadernos. A busca do Espaço do caderno encontra páginas e texto **dentro do caderno aberto** e informa a seção de cada resultado. Busca na página pode ser oferecida como escopo adicional. O produto deve rotular o escopo antes de pesquisar para evitar surpresa. Com o índice visível, sua seleção e o título da folha orientam o usuário; um rótulo `Seção / Página` pode aparecer discretamente acima da folha. Com o índice fechado, esse rótulo e o comando de reabertura tornam-se explícitos. Não mostrar outros cadernos em resultados da busca local.

## 5. Faixa de ferramentas e modos

A barra de ferramentas ocupa uma única linha principal acima do canvas. Sua estrutura é estável: **histórico**, **grupo compacto de ferramentas**, **ajustes contextuais**, **ações de página/exibição**. Texto, Caneta/Desenho e Seleção são botões quadrados agrupados, com ícone, tooltip e nome acessível; o estado ativo usa preenchimento/contorno além da cor. O botão de ferramenta escolhe a ação, enquanto a área ao lado configura fonte, cor, espessura ou seleção conforme a ferramenta. Trocar de ferramenta não desloca canvas nem controles comuns. Overflow guarda funções menos frequentes em janelas estreitas; comandos essenciais permanecem descobríveis.

A aplicação desktop apresenta uma barra de menus com **Arquivo, Editar, Exibir, Inserir e Ajuda**. A faixa contextual assume a função que o antigo menu Início teria; não criar uma aba Início que redesenha a interface. Arquivo reúne Novo/Abrir/Importar, Exportar caderno, Exportar página, Imprimir e Fechar; Editar reúne histórico e área de transferência; Exibir reúne índice, zoom e aparência. No protótipo HTML, os menus estão na janela para representar o destino Windows/Linux. Em macOS, uma implementação nativa deve usar a barra de menus do sistema. Não há comando “mostrar Biblioteca” como se ela fosse uma barra lateral: **Biblioteca** é uma tela de destino.

| Área | Controles principais | Regra |
|---|---|---|
| Comum | Desfazer, Refazer, indicador de salvamento | Mesma posição entre modos |
| Texto | Fonte, tamanho, negrito, itálico, sublinhado, cor, realce, listas | Estados ativos/mistos conforme seleção; indisponíveis para seleção só de tinta |
| Desenho | Caneta, borracha, espessura, nove amostras rápidas, paleta, régua quando habilitada | Prévia de cor e espessura; controles avançados em painel/popover |
| Selecionar | Tipo de seleção, alinhamento e operações sobre objetos quando aplicáveis | Não confundir seleção de caracteres com seleção espacial |
| Página/Exibir | Papel, propriedades da página, zoom e ajuste | Acesso persistente, sem abrir modal sobre a escrita |

**Modo visível** é a família de comandos apresentada. **Ferramenta selecionada** é a preferência do dispositivo. **Ferramenta efetiva** é a ação em curso. A distinção importa porque a caneta pode desenhar enquanto o mouse interage com texto no modo híbrido definido em `02-ferramentas-e-interacoes.md`. A interface mostra a ferramenta efetiva de forma discreta na faixa/status e nos cursores; trocar temporariamente para Mão com espaço ou botão central não substitui a preferência persistente.

Não há coluna vertical permanente de tinta no layout padrão. Uma faixa destacável de desenho pode ser avaliada após testes com usuários de mesa digitalizadora; ela não é requisito do MVP nem deve ser necessária para acessar comandos. Paletas e painéis abrem fora da região imediata do traço sempre que possível e não interceptam eventos do canvas quando fechados. O painel de propriedades, quando solicitado, abre à direita sem modal e mantém a página visível; fechar com `Esc` devolve o foco ao controle que o abriu. Alternar a família de comandos não deve retirar o caret do texto ou limpar a seleção sem ação explícita.

As regras de entrada permanecem: `Espaço` fora de texto e botão central pressionado fazem pan temporário; perda de foco limpa estados de tecla/botão. `E`, `T`, `P`, `V`, `1..9` e `0` não agem como atalhos de ferramenta durante digitação, busca, renomeação ou composição IME. `Ctrl+A` seleciona caracteres no texto e objetos no canvas. Tinta sobreposta não bloqueia a edição quando Texto é a ferramenta efetiva. Pan e zoom não entram no histórico de conteúdo. Essas regras são detalhadas nos documentos 02 e 03.

## 6. Editor, papel e status

A página mantém **título como metadado** e data opcional acima do canvas. O primeiro `TextContainer` é criado somente ao digitar depois do título, como nos documentos 02 e 04. Texto rico e traços vetoriais usam coordenadas lógicas da página e podem se sobrepor. Alternar modos, abrir índice ou redimensionar janela não altera coordenadas armazenadas nem reposiciona objetos.

Canvas finito (A4 ou personalizado) e infinito usam a mesma moldura de editor, com controles de papel em **painel não modal**. Mudanças de fundo e pautas aparecem na página enquanto o painel está aberto. Tema da interface, fundo do papel e cor da tinta são três estados distintos; alternar tema não recolore traços salvos.

A barra de status mostra salvamento local (`Salvando…`, `Salvo`, `Erro ao salvar`), ferramenta efetiva quando relevante e zoom. Zoom tem botões `−`, `+`, ação `100%` e ajustes por largura/página quando aplicáveis. Quando acionado no ponteiro, preserva o ponto sob ele. Erro de salvamento exige ação visível para obter detalhes e tentar novamente; não deve ser mascarado por um indicador genérico. Configurações da página são abertas pelo botão de ajuste no item da página selecionada no índice; o botão Papel deixa a barra de ferramentas. As mesmas opções permanecem acessíveis por menu e teclado quando o índice estiver recolhido.

## 7. Estados vazios, transições e erros

| Estado | Apresentação e próxima ação |
|---|---|
| Biblioteca sem cadernos | Explicar armazenamento local e oferecer **Criar caderno** / **Importar caderno** |
| Caderno sem seções | Identificar o caderno e oferecer **Criar seção** |
| Seção sem páginas | Manter faixa e índice visíveis; oferecer **Nova página** |
| Página sem conteúdo | Foco no título ao criar; indicação discreta para começar a escrever/desenhar |
| Busca sem resultados | Mostrar escopo aplicado e opção de limpar busca |
| Falha ao abrir caderno | Preservar Biblioteca, mostrar motivo e caminho de recuperação sem fingir que abriu |
| Falha de salvamento | Manter conteúdo em memória, sinalizar erro persistente e oferecer detalhes/tentativa |

Ao voltar à Biblioteca com edição em curso, finalizar ou cancelar o gesto corrente de forma determinística, conforme regras do documento 02. Se o salvamento falhar, a transição não deve fazer o usuário acreditar que os dados estão seguros; mostrar estado e alternativas de recuperação. Exclusões e ações de perda de dados exigem recuperação ou confirmação adequada.

## 8. Janela estreita e ergonomia

Em largura confortável: índice estrutural e editor ficam visíveis, com os grupos de seções e páginas no mesmo painel. Em largura reduzida: o índice recolhe em painel temporário **não modal** e mantém comando Índice no cabeçalho; Todas as seções continua acessível nesse painel; comandos de ferramenta menos frequentes vão para overflow. A barra principal não quebra em várias linhas ao alternar ferramentas. Não reduzir o canvas a ponto de torná-lo impraticável. Não transformar as seções em ícones sem título. Em tela cheia, manter acesso claro a caderno, seção, página e saída para a Biblioteca.

Áreas clicáveis devem servir mouse e caneta; o tamanho exato será validado no protótipo em escalas de UI diferentes. Popovers não devem surgir sob a mão que escreve. Atalhos de teclado e menus de contexto permanecem alternativas. A posição de um painel temporário pode considerar destros e canhotos, sem criar um segundo layout estrutural incompatível.

## 9. Sistema visual inicial

### 9.1 Tipografia e ícones

**Fonte proposta da interface: IBM Plex Sans**, por sua leitura em UI, identidade sóbria e família aberta. O texto do usuário no documento mantém fonte configurável, independente da interface. **Conjunto de ícones proposto: Phosphor Icons**, com um peso principal consistente e variação de preenchimento apenas para estado ativo quando fizer sentido. Conferir cobertura dos comandos de texto, tinta, navegação e sistema antes de fechar a dependência. Evitar misturar famílias de ícones na mesma superfície e não usar ícone isolado onde o comando exigir rótulo.

Fontes oficiais: [IBM Plex](https://github.com/IBM/plex) (Open Font License) e [Phosphor Icons](https://phosphoricons.com/) (MIT). Licenças devem acompanhar a distribuição do aplicativo. Uma alternativa para avaliar cobertura é [Tabler Icons](https://docs.tabler.io/icons?theme=auto), também com distribuição aberta; a escolha final deve ser de uma família coerente, não uma mistura casual.

### 9.2 Cores e densidade

Tema escuro inicial: base grafite `#17191C`, superfícies `#202328`, controles `#292D33`, bordas `#383D44`, texto principal `#F0F1F2` e secundário `#ADB3BA`. Usar quase preto em profundidade pontual, não como único fundo. Tema claro inicial: base `#F4F5F6`, superfícies `#FFFFFF`, controles `#ECEEF0`, bordas `#D4D8DD`, texto principal `#20242A` e secundário `#5F6872`. Cores de seção funcionam como acentos moderados; estado ativo usa forma/contorno além da cor. Foco possui token próprio e contraste verificado em ambas as aparências.

Esses HEX são candidatos para protótipo, sujeitos a testes de contraste, renderização e diferenciação dos estados. O token de foco/acento inicial pode ser `#7DAAF7` no grafite e `#2868BD` no claro; verificar o contraste no componente real. Não usar as cores da seção como cores automáticas de tinta. Espaçamento deve seguir escala curta e repetível (por exemplo 4/8/12/16/24 unidades lógicas), com alinhamento rigoroso, bordas discretas, pouco sombreamento e arredondamento contido. Como ponto de partida: fonte de interface de 13–14 unidades lógicas, ícones de 20 em grade de 24, controles de 36–40 com área alvo de 40–44, e índice de páginas de cerca de 240 (mínimo 200, máximo 320). A interface deve parecer ferramenta de trabalho, não painel de cartões decorativos. Usar os critérios pertinentes da [WCAG 2.2](https://www.w3.org/TR/WCAG22/) como meta de contraste e foco para a UI desktop, além de testes com APIs de acessibilidade das plataformas.

## 10. Teclado e acessibilidade

O fluxo Biblioteca → caderno → seção → página → editor deve ser operável por teclado. No grupo de seções, setas percorrem itens, `Home`/`End` vão aos extremos, `Enter`/`Espaço` ativam e menu de contexto oferece ações. Mover foco com as setas não troca o conteúdo antes da ativação, evitando mudança acidental de página. O grupo de páginas usa a mesma regra de foco separado da ativação, com `Shift+F10` para ações; Tab circula entre áreas principais sem obrigar o usuário a percorrer todos os itens. Foco visível, seleção atual e ferramenta ativa são estados visualmente distintos.

Leitores de tela anunciam caderno aberto, seção ativa, página ativa, títulos e ações; ícone e cor da seção recebem nome, mas não substituem o título. Após voltar à Biblioteca, foco retorna ao caderno recém-aberto. Após criar seção/página, foco vai para o campo de nome/título apropriado. Após excluir um item, foco vai ao vizinho lógico ou à ação de criação se a lista ficou vazia. Fechar paleta ou painel devolve foco ao controle de origem. Atalhos de uma tecla nunca interceptam edição textual ou composição IME, conforme `03-atalhos-e-acessibilidade.md`.

## 11. Critérios de aceitação

1. Ao abrir um caderno, nenhum outro caderno aparece na navegação de edição; nome do software e do caderno são identificáveis na janela e no conteúdo.
2. Voltar à Biblioteca e reabrir o caderno preserva conteúdo, seção e página visitadas, com status de salvamento honesto.
3. Alternar seções troca apenas a lista de páginas correspondente e não altera o conteúdo da página armazenada.
4. Seção exibe título obrigatório, cor e ícone opcional; seção ativa é reconhecível sem depender apenas da cor.
5. Criar, renomear, reordenar e mover páginas funciona com mouse e teclado; mover entre seções preserva ID e conteúdo.
6. Texto e Desenho mostram comandos adequados sem deslocar canvas, título ou controles comuns; uso híbrido mouse/caneta indica a ferramenta efetiva.
7. Em janela estreita, o índice pode recolher, mas seção, página, comandos essenciais e canvas continuam acessíveis.
8. Com muitas seções/páginas, Todas as seções e busca permitem localizar conteúdo sem depender de rolagem longa.
9. Alternar tema claro/grafite não muda papel nem cores de tinta já persistidos.
10. Biblioteca, seções, páginas, ferramentas, menus e editor são navegáveis por teclado e expõem nomes/estados a leitores de tela.
11. Painel de papel permite observar mudanças na página sem modal bloqueante; tooltips/popovers não ficam cortados nem capturam desenho quando fechados.
12. Falha de salvamento e falha ao abrir caderno exibem estado e ação de recuperação claros.

## 12. Consequências para os demais documentos e validações

- `README.md`: atualizar o resumo da navegação e apontar este arquivo como layout vigente.
- `02-ferramentas-e-interacoes.md`: manter prioridade dos dispositivos; trocar referências à coluna vertical pela faixa contextual e explicitar apresentação da ferramenta efetiva.
- `03-atalhos-e-acessibilidade.md`: acrescentar navegação dos grupos de seções e páginas, retorno à Biblioteca e foco após transições.
- `04-comportamento-editor-e-organizacao.md`: adicionar `iconId?` à seção e estado da última seção/página visitada como sessão, não conteúdo da página.
- `05-configuracoes-e-portabilidade.md`: substituir `library_visible` pelo estado de visibilidade/largura do índice de páginas; não exportar localização da janela como preferência compartilhada.

Validar em protótipo: largura mínima útil no Windows inicialmente e, antes de publicar cada porta, em Linux e macOS; barra contextual com mesa Wacom CTL-672; velocidade de troca Texto/Desenho; contraste e foco em ambos os temas; descoberta da Biblioteca e de Todas as seções; comportamento com muitos cadernos, seções e páginas. A eventual barra destacável de desenho e o suporte a múltiplas janelas dependem desses testes.

## 13. Referências de interface desktop

A revisão do protótipo em `preview/` revelou que uma faixa de seções em toda a largura se parecia com abas de navegador e somava níveis horizontais acima da folha. A decisão atual coloca a hierarquia do documento em um índice lateral único, enquanto a barra superior reúne seleção de ferramenta e opções contextuais. Essa é uma **adaptação para este produto**, não cópia literal das interfaces citadas.

- [Apple — Split views](https://developer.apple.com/design/human-interface-guidelines/split-views): níveis de hierarquia em painéis adjacentes, seleção persistente e painéis redimensionáveis.
- [Apple — Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars): agrupamento de navegação, ações comuns, título e busca em posições previsíveis.
- [Adobe Photoshop — Workspace overview](https://helpx.adobe.com/photoshop/desktop/get-started/learn-the-basics/workspace-overview.html): distinção entre janela do documento, painel de ferramentas, barra de opções e painéis de apoio.
- [Affinity Publisher — Workspace at a glance](https://affinity.help/publisher/en-US.lproj/pages/Workspace/atAglance.html): ferramentas, opções da ferramenta, painéis de estúdio e status com papéis separados.

O índice de **páginas** segue a função de um navegador de páginas/miniaturas. Um painel de **camadas**, se existir no futuro, pertencerá ao conteúdo de uma página e terá outras operações: composição, ordem de empilhamento e visibilidade.

### 13.1 Regras resultantes da revisão de controles

1. **Menus documentais são a referência completa de comandos.** Arquivo, Editar, Exibir, Inserir e Ajuda ficam disponíveis na Biblioteca e no editor; a barra de ferramentas mostra ações frequentes, sem substituí-los. [Apple — Menus](https://developer.apple.com/design/human-interface-guidelines/menus), [Adobe — organização do workspace](https://helpx.adobe.com/photoshop/desktop/get-started/learn-the-basics/workspace-overview.html), [Affinity — menu e barra contextual](https://affinity.help/publisher/en-US.lproj/pages/Workspace/atAglance.html).
2. **Exportar é uma operação de arquivo local.** Usar `Arquivo → Exportar caderno…` ou `Arquivo → Exportar página como PDF…`, com escopo e formato explícitos. Não juntar “Compartilhar ou exportar” num ícone isolado acima da folha; compartilhar seria outro fluxo, se algum dia existir. [Adobe — Exportar pelo menu Arquivo](https://helpx.adobe.com/photoshop/desktop/save-and-export/export-files-to-different-formats/export-your-work-using-the-quick-export-as-option.html).
3. **Cada menu tem dono e escopo.** Reticências no cartão, no cabeçalho do caderno, na barra de ferramentas e na folha não podem coexistir sem funções inequívocas. Menu de contexto complementa o menu principal e contém ações do objeto apontado. Retirar affordances que prometem comandos inexistentes. [Apple — Context menus](https://developer.apple.com/design/human-interface-guidelines/context-menus).
4. **Ícones representam ações conhecidas e têm nome acessível.** Seta diagonal de link externo não deve indicar abertura de caderno local; ícone de envio não deve indicar exportação. Quando o símbolo for ambíguo, usar texto ou tooltip. Estados ativo, hover, foco e desabilitado precisam de sinais distintos.
5. **Alinhar controles na mesma grade.** Botões de desfazer/refazer, ferramentas, campos de fonte/tamanho, formatação e Papel têm altura, alvo, linha de base e espaçamento consistentes. Grupos podem ser separados por distância e superfície; linha divisória só quando melhora a leitura. A ferramenta ativa é distinguível dentro do grupo sem parecer uma aba de navegação. [Apple — Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars).
6. **Biblioteca e editor compartilham a gramática do aplicativo.** Menus, tipografia, estados de botão e espaçamento seguem o mesmo sistema. A Biblioteca começa em lista documental compacta, com grade opcional; capas são miniaturas de reconhecimento, não cartões promocionais. Importar fica junto de Criar/Abrir ou em Arquivo, sem link no rodapé. Busca e ordenação permanecem controles de coleção. Uma única faixa identifica a tela e suas ações; a marca não precisa de um segundo cabeçalho.
7. **Metadados do índice devem ser consistentes.** Não mostrar “HOJE” apenas no item selecionado: data aparece com a mesma regra em todas as páginas ou fica fora da lista. Nome e seleção já comunicam a página atual. Títulos redundantes entre índice, breadcrumb e folha devem ser evitados.
8. **Painel e status têm função própria.** Índice navega; barra contextual ajusta a ferramenta; status informa salvamento, ferramenta efetiva e zoom. Não usar o status como depósito de comandos nem escrever instruções de arrastar quando a interação ainda não existe no protótipo. [Adobe — painéis no menu Janela](https://helpx.adobe.com/photoshop/desktop/get-started/learn-the-basics/add-remove-panels.html).
9. **Preferências não ocupam a barra de trabalho.** Tema da interface e outras opções gerais ficam em Preferências; busca fica em comando de menu/atalho. Identidade do aplicativo não precisa ser repetida em barras sucessivas. O item de página selecionado oferece Configurações da página; a barra de ferramentas fica dedicada a ações de edição frequentes.
10. **Ajuda contextual apresenta o atalho.** Em controles com atalho, hover e foco por teclado abrem uma dica com nome da ação e combinação em um campo visual de tecla. O texto deve corresponder ao mapa de atalhos configurado e ao sistema operacional; quando houver remapeamento, atualizar a dica. A dica não captura eventos de desenho nem substitui nome acessível.

