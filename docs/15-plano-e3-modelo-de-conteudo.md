# 15 — Plano técnico de E3: contrato do conteúdo da página

**Estado:** E3.1–E3.6 concluídos em 24 de outubro de 2026 para Linux e Windows no CI; macOS fica para um runner futuro. **Entrada:** moldura E2 funcional no Linux; página ainda é prévia. **Saída E3:** contrato C++ verificável para iniciar E4. Este plano detalha [14 §4](14-plano-de-evolucao-e-experimentos.md); as decisões de E3.1 estão nos requisitos [04](04-comportamento-editor-e-organizacao.md) e [02](02-ferramentas-e-interacoes.md).

## 1. Objetivo e limites

O Orla precisa combinar texto rico livre, escrita manuscrita, imagens, gráficos estáticos, formas e diagramas conectados numa página local. Objetos devem sobreviver a salvar/reabrir, mover, agrupar, desfazer e exportar sem deslocamento entre Windows, Linux e, depois, macOS. E3 define a semântica comum e implementa o núcleo independente da interface. A interação visual e a escolha entre Qt Quick e Widgets são experimentos E4; hardware de caneta é E5; imagens, diagramas e grupos completos entram no Marco 3; PDF anotável no Marco 4; recuperação e exportação robustas no Marco 5/E6.

O código em `core/model` já contém a hierarquia, os tipos e validadores de objeto e o histórico reversível por página. `NotebookStore` usa SQLite `user_version=1` para caderno/seção/página, sem conteúdo. E3 não deve tratar essa prévia como editor nem acrescentar tabelas de conteúdo ao esquema 1 sem mudar a versão.

## 2. Decisões de produto e representação

| Tema | Decisão para v1 (E3.1) | Limite explícito |
| --- | --- | --- |
| Gráfico | Imagem raster ou SVG **incorporado**, com papel semântico de gráfico, descrição textual, seleção, tamanho e movimento | Dados/tabela e gráfico nativo editável ficam após a beta |
| Diagrama | Formas e linhas/setas; conector guarda IDs e portas dos nós e recalcula extremos quando eles se movem | Roteamento automático avançado fica fora da v1 |
| Tinta e conteúdo | Traços, texto e imagens têm IDs próprios; grupo manual ou vínculo explícito é a resposta inicial para mover anotações juntas | Não há âncora automática nem reflow da tinta quando o texto cresce |
| PDF de aula | Reservar referência versionável a página de PDF com tamanho, ID e vínculo das anotações | Importar e anotar PDF pertence ao Marco 4; PDF não vira texto editável automaticamente |

Essas decisões seguem [07 §1](07-revisao-especializada-dos-requisitos.md) e [08](08-pesquisa-de-campo-onenote.md) e foram incorporadas ao [04 §2.2](04-comportamento-editor-e-organizacao.md). A interação concreta de gráfico, conector e grupo ainda será testada no Marco 3.

## 3. Contrato do documento

### 3.1 Página, unidades e objetos comuns

- Página guarda ID, título como **metadado**, tipo A4/infinita e snapshot das opções de papel. Fundo, pauta e margem são parâmetros da página, não objetos móveis. Preferências globais só afetam páginas novas.
- Escolher como unidade canônica o ponto de página (`1/72` de polegada), com `double` finito. A4 retrato mede `595,276 × 841,890` pontos. Origem no canto superior esquerdo; `x` cresce à direita e `y` para baixo. Canvas infinito admite coordenadas negativas. A camada de visualização converte pontos para unidades lógicas Qt (convenção inicial: `4/3` px lógicos por ponto em 100%) e para PDF; zoom, pan, resolução e escala do monitor nunca entram no documento. Verificar essa convenção em EX5 antes de fixar o formato publicado.
- `PageObject` possui `id` UUID estável, `pageId`, `kind` discriminado, transformação local→página, `zOrder`, `readingOrder`, `locked`, descrição acessível opcional e referências tipadas opcionais (`groupId`, `assetId`, alvos de conector). Definir uma única fonte persistida para posição/transformação; `bounds` e índice espacial são derivados e reconstruíveis.
- Coordenadas, tamanhos e transformações inválidas (`NaN`, infinito, escala nula) são rejeitadas no núcleo. Transformações permitidas por tipo são declaradas: texto move/redimensiona; tinta move; imagem/forma movem/redimensionam/rotacionam quando adequado; conectores seguem seus alvos. A ordem visual é persistida por página, inclusive entre texto e tinta; a ferramenta decide o alvo do clique sem alterar essa ordem.
- IDs e referências não dependem da posição na lista, do caminho local ou da ordem de criação. Mover preserva IDs; duplicar/colar cria IDs novos e remapeia referências internas. Referências entre páginas são explícitas e validadas. Objetos bloqueados não podem ser transformados por comandos comuns.
- Ao copiar seleção para outra página, conector copiado sem o alvo correspondente vira extremo livre na mesma posição visual; referências internas de objetos copiados são remapeadas. Ao excluir um nó de diagrama, seus conectores ficam com extremos livres na posição visual anterior; o comando registra o estado anterior para undo. Validar a usabilidade dessa regra no cenário de diagrama do Marco 3.

### 3.2 Família de objetos v1

| Tipo | Conteúdo persistido | Invariantes e implementação posterior |
| --- | --- | --- |
| `TextContainer` | Documento rico canônico, posição, largura `auto/fixed`, largura máxima e estilo de caixa | Primeiro texto é objeto comum criado ao digitar após o título; altura deriva do layout, sem mover tinta vizinha; edição E4 |
| `InkStroke` | Amostras locais, cor, largura base, pincel, transformação | Um gesto gera um traço; pontos originais não são substituídos por bitmap ou suavização; desenho E4/E5 |
| `ImageObject` | `assetId`, tamanho/corte e texto alternativo | Original incorporado, sem caminho absoluto; importação e interação Marco 3 |
| `GraphicAssetObject` | Mesmo recurso gerenciado de imagem/SVG, com papel semântico de gráfico | Gráfico estático manipulável; sem tabela editável; Marco 3 |
| `ShapeObject` | Tipo e parâmetros geométricos, contorno/preenchimento | Formas básicas, reta e seta; Marco 3 |
| `ConnectorObject` | Dois extremos livres ou `targetId + portId` por extremo, rota e posições de fallback | Alvos existentes na mesma página; mover nós atualiza geometria; Marco 3 |
| `GroupObject` | Lista ordenada de IDs filhos | Começar com grupos planos, um pai por objeto, sem ciclos; mover grupo transforma membros em uma operação sem arredondar coordenadas; Marco 3 |

`PdfPageReference` fica reservado no contrato de evolução, sem instância criada em E3. Para imagem/SVG, guardar ativo original e metadados (`assetId`, hash, MIME, dimensões, nome de origem); URL externa e caminho absoluto não são fonte canônica. Definir limites de tamanho e validar entradas antes de decodificar. SVG importado é conteúdo estático não confiável: impedir busca de recursos externos e validar referências e dimensões antes de exibir. A ligação entre printout e anotação será definida no Marco 4 por ID, nunca por coincidência de coordenadas.

### 3.3 Texto e tinta

- Documento rico v1: sequência de parágrafos com texto Unicode, estilo semântico, lista/nível e trechos com marcas (`bold`, `italic`, `underline`, cor, realce e link). Definir normalização e validação de links; preservar acentos, emoji, texto RTL e quebras de linha. Texto vazio é válido durante edição. HTML/Markdown do Qt são formatos de importação/exportação ou adaptadores, não a fonte canônica. A integração com `QTextDocument`, caret, IME e composição será provada em EX2.
- Guardar largura e conteúdo, nunca pixels calculados de fonte, caret, seleção ou preedit. Offsets temporários de edição precisam respeitar limites de caracteres Unicode; não persistir offset do Qt como identidade de conteúdo. A ordem de leitura semântica independe de `zOrder` para que um objeto sobreposto possa ser encontrado por teclado e leitor de tela.
- Amostra de tinta v1: `x,y` finitos no espaço local do traço, pressão opcional normalizada, tempo relativo monotônico opcional e inclinação opcional. Mouse recebe pressão nominal; ausência de pressão não é zero. Definir formato binário versionado com identificador, versão, ordem de bytes, flags e contagem antes de persistir. Validar contagem/tamanho e round-trip exato; desenhar a prévia em memória e gravar apenas no fim do gesto. Suavização, quando houver, altera a renderização sem sobrescrever amostras originais.

### 3.4 Relações e operações

- Definir `Create`, `Delete`, `EditText`, `FormatText`, `AddStroke`, `ReplaceStrokeSegments`, `Move`, `Resize`, `Rotate`, `SetStyle`, `SetLock`, `SetAltText`, `Reorder`, `Group`, `Ungroup`, `AttachAsset`, `Connect` e `Disconnect` como comandos tipados. Cada comando valida pré-condições, aplica e reverte preservando IDs e referências. Borracha parcial só é ativada após prova de uso; o contrato de substituição de segmentos prepara esse teste.
- Um gesto concluído corresponde a uma entrada no histórico; digitação contínua pode agrupar edições próximas. Prévia de tinta, arrasto e transformação não entra no histórico nem no banco. `Esc` cancela a prévia; novo comando após undo invalida redo. Comandos em lote de seleção mista são atômicos e revertem como uma unidade. Pan/zoom e foco ficam fora do histórico de conteúdo.
- Histórico unificado **por página** cobre texto, tinta e transformação. `QTextDocument` tem seu próprio undo: E4 precisa coordená-lo ou desativá-lo como autoridade, para que `Ctrl+Z` siga uma única linha do tempo. Mover/duplicar páginas ou conteúdo entre cadernos usa transação de domínio própria, definida antes do Marco 3; nunca supor que duas pilhas por página resolvem operação entre páginas.
- Seleção textual, seleção espacial e laço são estados diferentes. Com caret em texto, `Ctrl+A/C/X/V`, `Delete`, espaço e teclas simples pertencem ao editor; no canvas, pertencem a objetos/ferramentas conforme [03](03-atalhos-e-acessibilidade.md). Hit test considera ferramenta e objeto bloqueado; Texto alcança caracteres mesmo sob tinta. `Esc` segue a pilha de estados do 03.

## 4. Arquitetura e custo

1. Criar tipos de valor, validadores e comandos em `core/model` sem QML, `QQuickItem`, widget, SQL ou evento de plataforma. Adaptadores `Qt → comandos` e `comandos → estado observável` ficam fora do núcleo. Resolver a dívida D3 integrando o núcleo gradualmente, sem manter duas regras de negócio divergentes no SQL e no modelo.
2. A página carregada mantém objetos por ID e uma ordem visual/semântica explícita. Consultas geométricas usam bounds derivados e índice espacial reconstruível; viewport/renderização consulta só a área visível. Não criar item QML por ponto de tinta. Invalidar regiões afetadas por transformação e descarregar caches de páginas fora de uso.
3. Ativos grandes mantêm original e miniaturas/cache derivados; inspecionar dimensão antes de decodificar e limitar memória. O cache pode variar por escala/zoom, mas nunca altera coordenadas nem conteúdo salvo. Medir antes de escolher estrutura de índice, tamanho de ladrilho e limite de cache.
4. Persistência usa repositório por caderno e IDs/versões explícitos. E3.4 implementou DTOs, codecs e a migração explícita `v1 → v2` descritos no [16](16-formato-conteudo-v2.md); E4 liga o editor ao **esquema mínimo v2** e executa round-trip de texto/tinta para cumprir EX8. E6 completa autosave transacional, checkpoint, backup consistente, recuperação, lixeira e migrações de versões publicadas. Cadernos de versão futura não são regravados. Fixtures v1 permanecem nos testes.
5. Caminhos são resolvidos na borda com API da plataforma; nenhum separador de caminho, ponteiro, tamanho de `size_t`, endianidade nativa, DPI ou objeto Qt entra no formato. Dados do usuário ficam fora do diretório de instalação para sobreviver a atualizações e remoções.

## 5. Sequência de implementação de E3

| Passo | Trabalho | Evidência de conclusão |
| --- | --- | --- |
| E3.1 ✅ | Fechar decisões de gráfico/diagrama, unidades, identidade, transformações e ordem; atualizar 02/04 e registrar restrições | Contrato registrado no 02/04/05; `zOrder`, seleção e ordem de leitura separados |
| E3.2 ✅ | Implementar tipos, IDs, validação, referências e grupos em `core/model` | `page_content.h/.cpp` e `page_content_tests.cpp`; build/testes core e Release passaram no Linux |
| E3.3 ✅ | Implementar comandos atômicos e histórico da página | `page_history.h/.cpp` e `page_history_tests.cpp`: criação, movimento, grupo e desfazer/refazer preservam IDs e amostras; lotes inválidos revertem por inteiro; núcleo testado com sanitizers no Linux |
| E3.4 ✅ | Implementar DTO de texto, codec de tinta, ativos e migração mínima v1→v2; preparar fixture | `rich_text`, `content_codec`, `asset_record`, `notebook_schema`; round-trip canônico e fixture v1 passaram no Linux; formato no [16](16-formato-conteudo-v2.md) |
| E3.5 ✅ | Conectar uma página de teste ao núcleo com adaptador fino, sem editor visual final | `PageTestAdapter` (removido na M1) fornecia snapshot, criação/movimento e undo/redo à prévia temporária `--page-model-demo`; Qt Quick Test percorre o fluxo e a troca de página limpa a sessão |
| E3.6 ✅ | Rodar o mesmo núcleo e testes em Linux e Windows CI; revisar macOS quando houver runner | Linux/GCC Release 7/7 e Clang core 4/4; Windows/MinGW GCC Release 7/7. Resultados e diferenças no [12](12-registro-de-implementacao.md) |

**Critério de saída E3:** tipos e invariantes documentados em 02/04; modelo C++ com testes para IDs, relações, geometria e undo; formato v2 mínimo/migração especificados; decisões de gráfico/diagrama registradas; matriz EX1–EX9 de E4 preparada. E3 não aprova editor, caneta, acessibilidade do canvas, DPI misto ou distribuição.

**Implementação E3.3:** `PageSession` possui a página e é a única via de alteração enquanto ela está aberta. Cada `PageCommand` agrupa mudanças tipadas de criação, exclusão ou campo; a página final é validada antes de aceitar o lote. Desfazer/refazer troca os valores antigos e novos e move a posse dos objetos criados/excluídos, sem copiar amostras de tinta ao mover um traço. O histórico retém por padrão até 512 comandos ou cerca de 64 MiB estimados; um comando acima de 16 MiB é recusado sem mudar a página. Uma entrada nova após undo descarta redo. Índice de IDs temporário acelera lotes maiores e é liberado ao fim da operação. Os limites podem ser configurados por sessão. E3.4 definiu o DTO e o codec do conteúdo; E3.5 integrou a sessão à prévia de teste da UI. A edição de texto ainda não existe, portanto seus comandos semânticos e a coordenação com `QTextDocument` serão implementados na prova E4.

**Implementação E3.5:** `PageTestAdapter` (removido na M1, junto com a demonstração E3.5) observava a página selecionada no `NotebookStore`, cria um `PageSession` vazio em memória e expõe um snapshot compacto ao QML. A opção `--page-model-demo` mostra controles de teste para criar/mover uma caixa de texto e usar undo/redo na toolbar. O QML apresenta o snapshot e envia coordenadas em pontos de página; IDs, validação e histórico permanecem no núcleo. Trocar de página ou sair do modo libera a sessão. Nenhum objeto de demonstração é gravado no SQLite, e a tela declara isso. O editor e a gravação reais continuam em E4.

**Implementação E3.6:** o workflow Linux usa Debian 13, GCC para o app Release e Clang para o preset `core`; o workflow Windows instala MSYS2 UCRT64, Ninja e os módulos Qt Base/Declarative/Svg e usa o mesmo preset Release. Os quatro testes puros de `core/model` passaram nos dois sistemas; Release inclui também SQLite e Qt Quick Test, com 7/7 em cada runner. Nenhum código do domínio usa `#ifdef` de plataforma. Versões e links das execuções estão no [12](12-registro-de-implementacao.md).

## 6. Protocolo de teste e portões por plataforma

- **Modelo automatizado, Linux e Windows:** coordenadas negativas e extremas válidas, rejeição de `NaN`/infinito, A4/infinita, ordem e IDs após duplicar/colar, grupos acíclicos, conector seguindo nó, bloqueio, Unicode (acentos, emoji, RTL), blob de tinta com pressão ausente/presente, undo/redo misto, abrir fixture v1 e recusar versão futura sem regravar. Executar em CI com compiladores distintos; usar os mesmos arquivos de fixture em ambos.
- **E4 na interface real:** EX1–EX9: `QTextDocument`/IME, caret, texto sob tinta, atalhos de tecla única, acesso por teclado, árvore semântica, zoom/pan/DPI e round-trip. Medir EX4 com 2.000 traços e cena densa; determinar orçamento final após medir. Linux: Orca/AT-SPI em Wayland/X11 conforme ambiente; Windows: Narrator/NVDA e APIs de acessibilidade; macOS: VoiceOver no portão P2. Resultado de uma plataforma não aprova outra.
- **E5/Marco 3/4:** Wacom real para pressão/hover/borracha e perda de foco; depois imagens de alta resolução, SVGs, agrupamento, conectores e PDF anotado em cenários de aula. Validar monitor de DPI misto fisicamente (VX13/EX5) e conservação de geometria ao salvar/reabrir.
- **Desempenho:** instrumentar tempo de quadro, latência de gesto, abertura de página, memória e tamanho dos dados; medir 2.000 traços em E4 e imagens grandes em Marco 3. Índice espacial, cache e batching só entram conforme gargalo medido. Verificar que editar um objeto não relê todo o caderno nem regrava todos os traços.

## 7. Referências técnicas

- [Qt — texto rico e `QTextDocument`](https://doc.qt.io/qt-6/richtext.html), [`QQuickItem` e métodos de entrada](https://doc.qt.io/qt-6/qquickitem.html), [`QInputMethodEvent`](https://doc.qt.io/qt-6/qinputmethodevent.html).
- [Qt — acessibilidade em Qt Quick](https://doc.qt.io/qt-6/accessible-qtquick.html), [`QAccessibleInterface`](https://doc.qt.io/qt-6/qaccessibleinterface.html), [`QTabletEvent`](https://doc.qt.io/qt-6/qtabletevent.html), [`QImageReader`](https://doc.qt.io/qt-6/qimagereader.html).
- [SQLite — alterações de esquema](https://sqlite.org/lang_altertable.html). Todas as APIs Qt usadas na implementação devem ser conferidas contra o mínimo do projeto, Qt 6.8.
