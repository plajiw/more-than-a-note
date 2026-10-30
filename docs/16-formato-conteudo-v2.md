# 16 — Contrato de conteúdo v2 (E3.4)

**Estado:** contrato e migração v1→v2 implementados em 24 de outubro de 2026. E4.3 ligou texto e tinta ao SQLite; E4.4 acrescentou a geometria no esquema v3; E4.5 acrescentou fontes e tamanhos ao MTNT v2 e ao esquema v4. O formato binário não depende de Qt, endianidade nativa, `size_t` ou DPI.

## Texto canônico

`RichTextDocument` contém parágrafos ordenados. Cada parágrafo tem estilo `Body` ou `Heading1..3`, lista `None/Bullet/Numbered`, nível 0 sem lista ou 1–8 com lista, e trechos (`TextRun`) ordenados. Cada trecho contém UTF-8 e marcas de negrito, itálico, sublinhado, cor, realce e link; no MTNT v2 pode conter família e tamanho de fonte. Cor e realce usam `#RRGGBBAA` maiúsculo. Links aceitos: `http://`, `https://` e `mailto:` absolutos. Documento e parágrafo vazios são válidos durante a edição. `\n` dentro de um trecho representa quebra manual no parágrafo; parágrafos são separações semânticas. O adaptador Qt converte CRLF em LF na entrada. O formato preserva os bytes UTF-8 válidos, inclusive combinações Unicode, sem normalização NFC automática. Caret, seleção, layout de fonte e preedit nunca entram no DTO.

O blob `MTNT` v1 usa todos os inteiros em **little endian**:

| Campo | Tamanho | Valor |
| --- | ---: | --- |
| Identificador | 4 bytes | `MTNT` |
| Versão | `u16` | 1 |
| Marcador de endianidade | 2 bytes | `LE` |
| Flags reservadas | `u32` | 0 |
| Número de parágrafos | `u32` | 0–100.000 |
| Cada parágrafo | 8 bytes | `kind:u8`, `list:u8`, `level:u8`, reservado 0, `run_count:u32` |
| Cada trecho | variável | `flags:u8` (bits 0–5: bold, italic, underline, color, highlight, link), `utf8_length:u32`, UTF-8; se houver cor/realce, 9 bytes cada; se houver link, `length:u32` e bytes ASCII |

Limites: 100.000 trechos por documento, 16 MiB de texto e links e 32 MiB para o blob. Versão, flags, contagens, UTF-8, estilos, links, truncamento e bytes excedentes são verificados ao ler. Um reencode do DTO aceito produz os mesmos bytes.

O blob **MTNT v2** conserva o cabeçalho e os campos v1, mas usa versão 2 e acrescenta dois bits por trecho: bit 6 para família (`length:u32` e UTF-8; no editor, Inter, IBM Plex Serif ou JetBrains Mono) e bit 7 para tamanho em pontos (`f64` little endian, intervalo 6–96). O decoder aceita v1 e v2; o encoder v1 recusa estilos que só cabem em v2. O formato canônico é o DTO estruturado, não HTML gerado pelo Qt. O adaptador lê e escreve diretamente os formatos de bloco e caractere do `QTextDocument`, preservando parágrafos, listas, títulos, links e trechos.

## Tinta

`InkStroke` guarda as amostras locais originais em pontos de página, `base_width_pt`, pincel (`Pen=0`, `Highlighter=1`) e cor `#RRGGBBAA`. O blob `MTNI` v1 usa os mesmos 16 bytes de cabeçalho (`MTNI`, versão 1, `LE`, flags 0, número de pontos), seguidos de `base_width_pt:f64` IEEE 754, `brush:u8` e 9 bytes ASCII de cor. Cada ponto contém `x:f64`, `y:f64`, `flags:u8`; os bits 0–3 indicam presença de pressão, tempo relativo, inclinação X e inclinação Y, nessa ordem. Cada valor presente vem como `f64`. Ausência de pressão não se converte em zero. Todos os doubles são little endian; `NaN`, infinito, pressão fora de 0–1, tempo regressivo e inclinação fora de −90 a 90 são recusados. Limites: 1–250.000 pontos e blob de até 16 MiB. O decoder verifica o tamanho mínimo antes de reservar memória e rejeita truncamento, flags desconhecidas e bytes extras. Suavização visual não altera esse blob.

## Inventário de ativos

`AssetRecord` guarda UUID, tipo raster/SVG, SHA-256 hexadecimal minúsculo do original, MIME, tamanho em bytes, dimensões e nome de origem apenas para exibição. O caminho controlado deriva de hash e MIME: `assets/<dois primeiros hex>/<hash>.<extensão>`. Nome de origem não é usado como caminho. A validação do DTO aceita PNG, JPEG, WebP e SVG, até 256 MiB, lados até 32.768 px e no máximo 128 megapixels. O importador posterior deve conferir o hash dos bytes, validar e limitar a decodificação, bloquear referências externas em SVG e gravar o original; E3.4 não importa arquivos.

## SQLite v1 → v2

`migrateNotebookSchema` é uma operação explícita e transacional sobre um caderno aberto. O esquema 1 contém `notebook`, `sections` e `pages`, sem conteúdo; a migração preserva as linhas e IDs, cria `page_settings` com padrão A4 para cada página, `page_objects` para payloads `text`/`ink` versionados e `assets` para inventário. Um trigger cria `page_settings` para páginas inseridas depois. `PRAGMA user_version` só passa de 1 para 2 na transação que cria e preenche as tabelas; falha reverte tudo. Migração repetida é idempotente. A fixture `tests/fixtures/notebook_v1.sql` preserva título Unicode, seção, página e seleção para o teste. `NotebookStore` abre v1–v4 sem migrar por conta própria; cadernos novos ainda nascem em v1 e passam a v4 na primeira gravação de objeto.

Em `page_settings`, `canvas_kind=0` é A4 e `1` é canvas infinito. As dimensões padrão do A4 são `595,2755905512 × 841,8897637795 pt`; no canvas infinito elas não limitam a cena. `paper_kind` fica reservado para o adaptador visual em E4 (0–4) e não altera objetos ou coordenadas nesta etapa. O acabamento do papel, cor e espaçamento ainda exigem colunas versionadas antes da primeira distribuição do editor.

`page_objects` v2 aceita somente texto e tinta no momento. Transformação, ordens, bloqueio e descrição ficam em colunas; `payload_version=1` e `payload` guarda `MTNT` ou `MTNI`. Título continua em `pages`, nunca como objeto. Grupos, conectores e payloads de imagem exigem evolução explícita do esquema, sem interpretar bytes desconhecidos como outra versão. E4 usa transação para salvar cada objeto, valida o codec ao abrir e recusa versão futura sem regravar o caderno. Autosave, backup e recuperação completos continuam em E6.

## SQLite v2 → v3 (E4.4)

`migrateNotebookSchemaV3` executa v1→v2, se necessário, e depois acrescenta a `page_objects` as colunas `text_width_pt`, `text_max_width_pt` e `text_fixed_width` numa transação v2→v3. Objetos já existentes recebem os padrões 240 pt, 500 pt e largura flexível, sem mudar ID, posição, texto ou tinta. A posição já era salva em `tx` e `ty` no v2. A leitura de v1/v2 não escreve no arquivo. O blob `MTNT` v1 não inclui geometria: ela pertence ao objeto.

## SQLite v3 → v4 (E4.5)

`migrateNotebookSchemaV4` reconstrói `page_objects` em transação, preserva os campos e amplia `payload_version` para 1 ou 2. Texto novo é gravado como MTNT v2 com `payload_version=2`; tinta permanece MTNI v1. Texto legado em MTNT v1 continua legível e é convertido a v2 quando editado. A leitura de v1–v3 não escreve; a primeira gravação válida percorre as migrações até v4. Versão 5 ou superior é recusada sem escrita.

**Descrição histórica da E4.5, revista por constatação na M2:** a transação por objeto foi ampliada em E4.7. Na base `25f20a2`, `savePageChanges` em [page_repository.cpp](../apps/desktop/page_repository.cpp) já prepara e grava upserts/exclusões de um comando em uma transação; `PageEditorAdapter::persist` utiliza esse lote. Isso não significa autosave/recuperação completos: o flush de múltiplos documentos ricos ainda executa comandos separados. A fidelidade entre editor e PDF será verificada em MX7/Marco 5.

## M2 — evolução de objetos e confiabilidade, proposta pendente

O [20 §5](20-plano-marco3-objetos-e-diagramas.md) propõe payloads explícitos para formas, conectores e grupos, rótulos ricos incorporados e migração para a próxima versão livre após E6. Os exemplos são DTOs semânticos, não um codec já aceito. A M2 não reserva versão 5 nem altera MTNT v2/MTNI v1, colunas ou leitores atuais. O contrato binário completo, limites e fixtures devem ser aprovados antes da implementação.

O [21](21-auditoria-confiabilidade-e6.md) aponta a diferença entre limites de leitura por página e limites de escrita por objeto, além da necessidade de validar relações no estado final do lote. Recomenda limites simétricos, migração recuperável e revisão confirmada; são propostas de E6, não garantias atuais. “Conteúdo v2”, versão SQLite e versão de cada payload são eixos distintos.
