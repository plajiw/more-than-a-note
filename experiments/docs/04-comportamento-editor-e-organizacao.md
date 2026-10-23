# 04 — Modelo de conteúdo, interação e organização local

**Status:** requisitos e contratos conceituais para implementação posterior; não prescreve linguagem ou framework.

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
    │   │   └── objects[]: TextContainer | InkStroke | ...
    │   └── Página...
    └── Seção...
```

O caderno opera como unidade local de organização e persistência, com metadados das referências (imagens, anexos e objetos externos futuros), índices e versões de esquema. A página não deve depender do caminho do arquivo de outra página para permanecer íntegra. Todos os objetos têm IDs estáveis. **Não supor** que caderno = um diretório literal do sistema: isso é opção de formato a definir, embora a experiência se comporte como uma pasta.

### 1.1 Operações de biblioteca

Criar, renomear e excluir caderno; definir cor; futura capa; criar, renomear, reordenar e mover seção; criar, mover, duplicar e excluir página. Exclusões devem ter mecanismo de recuperação (lixeira local ou confirmação com backup). Mover página entre seções deve preservar IDs, conteúdo e referências; mover entre cadernos precisa atualizar dependências e copiar recursos vinculados conforme regras explícitas. Pesquisa deve considerar títulos e texto estruturado, respeitando caderno e seção.

## 2. Página e espaço de coordenadas

**Modo A aprovado:** o primeiro contêiner é um `TextContainer` comum, sem privilégios no modelo. O título da página é metadado e pertence a uma faixa de cabeçalho, não é objeto livre. Pressionar Enter após editar título posiciona o caret na área inicial; digitar cria contêiner de modo preguiçoso. Se o usuário desenhar primeiro, a página pode continuar sem texto.

A página possui sistema lógico de coordenadas independente dos pixels de monitor, DPI, deslocamento e zoom. Converter entrada: `screen → viewport → page`; renderizar: `page → viewport → screen`. Canvas absoluto: alterar conteúdo de um contêiner **não reposiciona automaticamente** os demais objetos. A arquitetura reserva associação futura `anchor/group`, porém não cria relações automáticas no MVP.

### 2.1 Dimensões do papel

- **Infinita:** extensão lógica progressiva; viewport deslocável; origem consistente e coordenadas eventualmente negativas conforme política escolhida.
- **Finita:** dimensões padrão (A4, outras) configuráveis; texto e tinta dentro de limites; margens e exportação respeitam escala e proporção.
- Fundo é configuração de **cada página** e não objeto raster: papel claro/escuro, pauta horizontal, margem vertical, quadriculado ou pontilhado. Grades devem manter espaçamento estável no espaço da página sob zoom.
- Preferência global define defaults **apenas para páginas novas**; alterar a preferência global não sobrescreve páginas existentes.

## 3. Contêiner de texto: modelo

```text
TextContainer
  id
  pageId
  position: { x, y }
  sizing: { mode: auto | fixed, width, maxWidth }
  zOrder
  richTextDocument: paragraphs[]
  anchorId?: null  // reservado para expansão futura
```

O documento rico preserva semântica de parágrafos, spans com marcas e listas. Um `#` digitado não deve necessariamente virar título como no Markdown: títulos são estilos do editor e podem receber atalhos, comandos ou transformação opcional explícita. Formatações previstas: negrito, itálico, sublinhado, links, listas de marcadores/numeradas, estilos de título, cor e realce. Posição, tamanho e conteúdo são persistidos separadamente.

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
  points: [{ x, y, pressure?, timestamp?, tilt? }]
  pen: { color, baseWidth, brushType }
  zOrder
  bounds  // índice geométrico calculável
  anchorId?: null
```

O traço é vetorial, contínuo, livre e sem reconhecimento obrigatório de formas. Renderização ao vivo deve ter baixa latência, e armazenamento dos pontos não pode ser reduzido a bitmap. Pressão modula largura quando o dispositivo fornecer dados; mouse usa pressão nominal constante. Borracha, seleção, movimento e histórico devem operar de forma consistente com os objetos de texto. Não oferecer UI de estabilização avançada no MVP; defaults internos validados em tablet real.

## 5. Colisão, ordem e seleção

Texto e tinta podem ocupar as mesmas coordenadas. Uma tinta pode atravessar vários contêineres. Ordem inicial: fundo → contêineres → tinta → seleção/overlays. Na ferramenta Texto, tinta sobreposta não bloqueia a seleção de caracteres; na ferramenta Seleção, o sistema usa heurística/contexto e permite alternar alvos sobrepostos. Movimentação acontece pela alça, enquanto seleção de tinta pode usar laço/retângulo. Guia de alinhamento opcional; sem reorganização automática do canvas no MVP.

## 6. Histórico de operações e autosave

**Undo/redo único por página**, abrangendo inserção/exclusão/formatação textual, criação/movimento/redimensionamento de contêiner, criação/apagamento/movimento de tinta. Digitação contínua pode ser agregada em unidades de undo; gesto de um traço constitui normalmente uma operação. Pan e zoom não entram no histórico de conteúdo. Operações que afetem várias páginas/cadernos exigem histórico transacional ou confirmação/reversão própria a definir.

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

## 9. Questões para próxima fase

Formato nativo de caderno (diretório versionado versus pacote portátil), limites do canvas infinito, paginação/exportação de conteúdo além da borda A4, estratégia de índice e recuperação e suporte a reordenação arbitrária com centenas de páginas.
