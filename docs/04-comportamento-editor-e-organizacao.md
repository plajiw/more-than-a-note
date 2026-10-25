# 04 — Modelo de conteúdo, interação e organização local

**Status:** requisitos e contratos conceituais; decisões E3.1 registradas em 24 de outubro de 2026. Não prescreve linguagem ou framework.

## 1. Domínio e hierarquia

```text
Biblioteca local
└── Caderno (Notebook)
    ├── metadata: id, nome, cor, capa?, datas, ordem, referências
    ├── Seção (Section)
    │   ├── metadata: id, título, cor, ordem
    │   ├── Página (Page)
    │   │   ├── metadata: id, título, datas, ordem
    │   │   ├── pageSettings: tamanho, papel, fundo, pautas/grades
    │   │   └── objects[]: TextContainer | InkStroke | ImageObject | GraphicAssetObject | ShapeObject | ConnectorObject | GroupObject
    │   └── Página...
    └── Seção...
```

O caderno opera como unidade local de organização e persistência, com metadados das referências (imagens, anexos e objetos externos futuros), índices e versões de esquema. A página não deve depender do caminho do arquivo de outra página para permanecer íntegra. Todos os objetos têm IDs estáveis. **Não supor** que caderno = um diretório literal do sistema: isso é opção de formato a definir, embora a experiência se comporte como uma pasta.

### 1.1 Operações de biblioteca

Criar, renomear e excluir caderno; definir cor; futura capa; criar, renomear, reordenar e mover seção; criar, mover, duplicar e excluir página. Exclusões devem ter mecanismo de recuperação (lixeira local ou confirmação com backup). Mover página entre seções deve preservar IDs, conteúdo e referências; mover entre cadernos precisa atualizar dependências e copiar recursos vinculados conforme regras explícitas. Pesquisa deve considerar títulos e texto estruturado, respeitando caderno e seção.

## 2. Página e espaço de coordenadas

**Modo A aprovado:** o primeiro contêiner é um `TextContainer` comum, sem privilégios no modelo. O título da página é metadado e pertence a uma faixa de cabeçalho, não é objeto livre. Pressionar Enter após editar título posiciona o caret na área inicial; digitar cria contêiner de modo preguiçoso. Se o usuário desenhar primeiro, a página pode continuar sem texto.

A página usa **pontos de página** (`1 pt = 1/72 pol.`) como unidade canônica. Posição, tamanho, largura do traço, pautas e margens são números `double` finitos nessa unidade, sem arredondamento pelo DPI. A4 retrato mede aproximadamente `595,276 × 841,890 pt`; a origem é o canto superior esquerdo, com `x` para a direita e `y` para baixo. O canvas infinito usa a mesma unidade e aceita coordenadas negativas. Uma transformação local → página por objeto é a fonte persistida da posição; limites de desenho (`bounds`) são derivados e podem ser recalculados. Rejeitar `NaN`, infinito, tamanho negativo e transformações não invertíveis.

Converter entrada `screen → viewport → page` e renderizar `page → viewport → screen`. A convenção inicial de exibição é `1 pt = 4/3 px lógicos Qt` em zoom de 100%; escala de monitor altera o raster, não as coordenadas salvas. PDF converte diretamente pontos de página para pontos de saída. Zoom, pan, resolução, monitor e escala de interface pertencem ao estado de visualização, não ao conteúdo. EX5 em E4 deve verificar conversões de ida e volta e passagem entre DPI diferentes antes de publicar um formato. Alterar conteúdo de um contêiner **não reposiciona automaticamente** os demais objetos; agrupamento manual e vínculo explícito preservam relações escolhidas pelo usuário.

### 2.1 Dimensões do papel

- **Infinita:** extensão lógica progressiva; viewport deslocável; origem estável e coordenadas negativas permitidas.
- **Finita:** dimensões padrão (A4, outras) configuráveis; criação começa na área do papel. Um objeto que ultrapasse a borda continua íntegro no modelo e deve ser indicado na edição e na prévia de exportação, sem descarte ou corte silencioso. Margens e exportação respeitam escala e proporção; a política final de paginação pertence ao Marco 5.
- Fundo é configuração de **cada página** e não objeto raster: papel claro/escuro, pauta horizontal, margem vertical, quadriculado ou pontilhado. Grades devem manter espaçamento estável no espaço da página sob zoom.
- Preferência global define defaults **apenas para páginas novas**; alterar a preferência global não sobrescreve páginas existentes.

## 2.2 Família e relações dos objetos da v1

Todo `PageObject` tem `id` estável, `pageId`, tipo, transformação local → página, `zOrder` visual, `readingOrder` semântica, estado bloqueado e descrição acessível quando pertinente. Referências a grupo, ativo ou alvo de conector são por ID. `bounds` e índice espacial são dados derivados, não fontes persistidas de posição. Duplicar ou colar gera IDs novos e remapeia referências internas; mover preserva IDs. O modelo rejeita referências a objetos ausentes ou de outra página e ciclos de grupos.

| Tipo | Semântica da v1 | Etapa de interação completa |
| --- | --- | --- |
| `TextContainer` | Texto rico livre, editável, movível e redimensionável | E4 |
| `InkStroke` | Traço vetorial com amostras originais e pressão quando disponível | E4 com mouse; E5 com caneta real |
| `ImageObject` | Imagem bitmap ou SVG incorporada, movível e redimensionável | Marco 3 |
| `GraphicAssetObject` | **Gráfico estático incorporado** como imagem/SVG; papel e descrição próprios, sem tabela de dados editável | Marco 3 |
| `ShapeObject` | Forma básica, reta ou seta com estilo e geometria editáveis | Marco 3 |
| `ConnectorObject` | Linha/seta com extremos livres ou ligados por `targetId` e porta a formas/objetos da mesma página | Marco 3 |
| `GroupObject` | Grupo manual plano de objetos com um único pai; mover seus membros é uma operação | Marco 3 |

**Decisão de gráfico:** a v1 permite inserir, selecionar, mover, redimensionar, alinhar e descrever o gráfico visualmente. Editar dados/tabela e regenerar o gráfico é posterior à beta. O ativo original fica incorporado ao caderno; não depender de URL para abrir offline.

**Decisão de diagrama:** conectores ligados acompanham movimento, tamanho e rotação dos nós por suas portas. Cada extremo guarda alvo/porta e uma posição de fallback; a posição visual ligada é calculada, não uma segunda coordenada autoritativa. Ao excluir um nó, seus conectores ficam com extremos livres congelados no lugar visual anterior, na mesma operação reversível. Copiar um conector sem seu alvo também libera o extremo na posição atual. Linhas e setas livres continuam possíveis; roteamento automático avançado fica posterior à v1. Assim, “diagrama editável” exige relações por ID, não apenas linhas que coincidem visualmente com formas.

Grupos são explícitos e não criam âncoras automáticas. `GroupObject` é um nó de organização, sem camada própria de pintura: os filhos mantêm seu `zOrder`, e agrupar/desagrupar não muda a aparência. Seu `zOrder` comum não participa da pintura; a seleção do grupo usa a união dos limites dos filhos. Agrupar texto, tinta e imagem permite movê-los juntos sem reflow do conteúdo. Uma referência futura a página de PDF anotável deve ter ID e tamanho estáveis e vínculo explícito com anotações; importar e anotar PDF pertence ao Marco 4.

## 3. Contêiner de texto: modelo

```text
TextContainer
  id
  pageId
  transform: local → page
  sizing: { mode: auto | fixed, width, maxWidth }
  richTextDocument: paragraphs[]
  // zOrder, readingOrder e descrição vêm de PageObject
```

O documento rico preserva semântica de parágrafos, spans com marcas e listas. Um `#` digitado não deve necessariamente virar título como no Markdown: títulos são estilos do editor e podem receber atalhos, comandos ou transformação opcional explícita. Formatações previstas: negrito, itálico, sublinhado, links, listas de marcadores/numeradas, estilos de título, cor e realce. Posição, tamanho e conteúdo são persistidos separadamente.

O DTO e o codec binário do texto, bem como as regras de UTF-8 e os limites de leitura, estão no [16](16-formato-conteudo-v2.md). E3.4 definiu a representação persistente; caret, IME e composição com `QTextDocument` continuam na prova E4.

### 3.1 Criação e edição

| Evento | Comportamento |
|---|---|
| Criar página | Foco no título; indicação inicial discreta abaixo dele |
| Enter no título | Foco na área inicial; somente ao digitar há objeto persistido |
| Clique vazio com Texto | Criar `TextContainer` naquela coordenada e posicionar caret |
| Clique em texto existente | Entrar em edição no ponto clicado |
| Duplo clique | Selecionar palavra; preservar semântica de pontuação/idioma |
| Triplo clique | Selecionar parágrafo |
| Arrasto interno | Seleção de caracteres, não movimentação do objeto |
| Enter | Novo parágrafo, com continuação de lista quando pertinente |
| Shift+Enter | Quebra de linha no mesmo parágrafo |
| Clique fora | Encerrar edição; borda/alças desaparecem |
| Esc | Encerrar edição; Esc subsequente remove seleção do objeto |
| Conteúdo vazio ao sair | Descartar contêiner que nunca recebeu conteúdo ou foi esvaziado, após encerrar eventual transação de desfazer |
| Ctrl+A em texto | Selecionar somente o texto daquele contêiner |
| Ctrl+A no canvas | Selecionar objetos da página |

O aplicativo deve distinguir **seleção textual**, **seleção espacial** e **seleção de tinta**, e fornecer um feedback diferente para cada estado. Não permitir arrastar o corpo do texto para mover contêiner; usar alça superior e manipulação por teclado.

### 3.2 Dimensionamento

Largura inicial é **auto** até um máximo de legibilidade. Após ajuste pela alça, muda para `fixed`, e texto quebra conforme largura. Altura cresce com conteúdo. A primeira versão não dispõe de rolagem interna em caixas. Largura mínima impede colapso impraticável. Redimensionar não altera a posição armazenada do texto vizinho. Formatação contextual só aparece se necessária, sem toolbar permanente em cada objeto.

## 4. Traço manuscrito: modelo

```text
InkStroke
  id
  pageId
  points: [{ x, y, pressure?, relativeTime?, tilt? }]  // coordenadas locais em pt
  pen: { color, baseWidth, brushType }
  // transformação e ordens vêm de PageObject; bounds é calculável
```

O traço é vetorial, contínuo, livre e sem reconhecimento obrigatório de formas. Renderização ao vivo deve ter baixa latência, e armazenamento dos pontos não pode ser reduzido a bitmap. Pressão modula largura quando o dispositivo fornecer dados; mouse usa pressão nominal constante. Borracha, seleção, movimento e histórico devem operar de forma consistente com os objetos de texto. Não oferecer UI de estabilização avançada no MVP; defaults internos validados em tablet real.

## 5. Colisão, ordem e seleção

Texto e tinta podem ocupar as mesmas coordenadas; um traço pode atravessar vários contêineres. **`zOrder` é a única ordem visual persistida** entre objetos da página. O papel fica abaixo de todos; seleção, caret e régua são overlays temporários acima deles. Ao criar, tinta entra acima de todos os objetos; texto/imagem/forma/gráfico entram imediatamente abaixo da tinta visualmente mais baixa ou acima de todos se não houver tinta. Trazer à frente/enviar atrás pode mudar essa ordem sem restrição por tipo. Empates são resolvidos de modo determinístico pelo ID até normalizar a ordem. A ferramenta Texto alcança caracteres mesmo quando a tinta aparece acima; a ferramenta Seleção usa o objeto elegível mais alto e oferece acesso aos demais candidatos sobrepostos sem reordenar a página. Objetos bloqueados continuam localizáveis para leitura/propriedades, mas não se movem por gesto comum. Movimentar texto exige alça, enquanto tinta pode ser selecionada por laço/retângulo; o corpo do texto seleciona caracteres.

**`readingOrder` é independente de `zOrder` e de geometria.** Ao criar objeto, ele entra após o último na ordem de leitura; mover, sobrepor ou trazer à frente não muda essa sequência. Uma ação de propriedades permite reordená-la deliberadamente. Navegação de objetos por teclado e a árvore de acessibilidade seguem `readingOrder`, com ID como desempate estável; grupos são anunciados como unidade e seus filhos mantêm ordem própria. Nome, papel, estado de seleção/bloqueio e descrição são expostos semanticamente. Imagens, gráficos, formas e diagramas recebem descrição textual editável; tinta livre pode ser descrita individualmente ou num grupo de traços, sem alegar reconhecimento de escrita. A escolha exata da API Qt e a fala real pertencem a EX7 em E4 e aos portões de plataforma.

Guia de alinhamento é opcional; não há reorganização automática do canvas no MVP.

## 6. Histórico de operações e autosave

**Undo/redo único por página**, abrangendo inserção/exclusão/formatação textual, criação/movimento/redimensionamento de contêiner, criação/apagamento/movimento de tinta. Digitação contínua pode ser agregada em unidades de undo; gesto de um traço constitui normalmente uma operação. Pan e zoom não entram no histórico de conteúdo. Operações que afetem várias páginas/cadernos exigem histórico transacional ou confirmação/reversão própria a definir.

O núcleo E3.3 mantém comandos atômicos por página, com limites configuráveis de memória e entradas. O padrão inicial é 64 MiB estimados, até 512 entradas e até 16 MiB por comando; operações maiores retornam erro sem alterar a página. Objetos e amostras não são copiados para registrar apenas movimento. A UI deve comunicar a recusa de um comando grande e a indisponibilidade de undo além da janela retida. Os valores finais precisam ser medidos com páginas reais em E4.

Persistência local automática com snapshots/checkpoints e transações. Não gravar um arquivo inteiro por ponto coletado da caneta. Evitar corrupção ao encerrar durante uma gravação. Estado de edição temporário (caret, hover, seleção, prévia de traço) não deve ser confundido com conteúdo; viewport/última página podem ser salvos como preferências de sessão.

## 7. Referências e ativos locais

Caderno mantém inventário de referências com `assetId`, `kind`, hash opcional, nome original, localização controlada, tamanho, origem e ligações a objetos/páginas. Preferir referências internas ou cópias gerenciadas para um pacote de caderno portátil; links a arquivos externos devem ser explicitamente marcados como externos e sujeitos a quebra. Não usar URLs de internet como requisito de leitura offline. Política de deduplicação e remoção de recursos órfãos pode ser posterior, mas o formato deve permitir migrações.

## 8. Cenários de aceitação

1. Criar caderno/seção/página; alterar nomes, cores e ordem; fechar/reabrir conservando tudo.
2. Criar o primeiro contêiner digitando após título e segundo clicando em área livre; ambos compartilham comportamento idêntico.
3. Redimensionar caixa e obter quebra automática sem mover tinta vizinha.
4. Escrever uma seta por cima da frase, entrar em Texto e editar sem selecionar a seta.
5. Salvar e restaurar pressão/posição de tinta em qualquer zoom e em outra resolução de monitor.
6. Alternar A4 e canvas infinito em páginas distintas do mesmo caderno; fundos também distintos.
7. Executar undo/redo alternando digitação, traço, movimento e exclusão.
8. Exportar/backup de caderno conserva referências locais e metadados.
9. Inserir gráfico como imagem/SVG incorporado, movê-lo e redimensioná-lo sem conexão de rede ou promessa de editar sua tabela de dados.
10. Ligar conector a duas formas; mover uma, excluir outra, desfazer e copiar apenas o conector para outra página sem referência órfã.
11. Sobrepor tinta e texto; trazer cada um à frente sem mudar a ordem de leitura, e localizar ambos por teclado/leitor de tela.

## 9. Questões para próxima fase

Formato nativo de caderno (diretório versionado versus pacote portátil), limites do canvas infinito, paginação/exportação de conteúdo além da borda A4, estratégia de índice e recuperação e suporte a reordenação arbitrária com centenas de páginas.
