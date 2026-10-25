# 16 — Contrato de conteúdo v2 (E3.4)

**Estado:** contrato e migração implementados em 24 de outubro de 2026. A UI ainda não edita nem grava objetos de página; a ligação entre editor, `PageSession` e SQLite pertence a E3.5/E4. O formato binário não depende de Qt, endianidade nativa, `size_t` ou DPI.

## Texto canônico

`RichTextDocument` contém parágrafos ordenados. Cada parágrafo tem estilo `Body` ou `Heading1..3`, lista `None/Bullet/Numbered`, nível 0 sem lista ou 1–8 com lista, e trechos (`TextRun`) ordenados. Cada trecho contém UTF-8 e marcas de negrito, itálico, sublinhado, cor, realce e link. Cor e realce usam `#RRGGBBAA` maiúsculo. Links aceitos: `http://`, `https://` e `mailto:` absolutos. Documento e parágrafo vazios são válidos durante a edição. `\n` dentro de um trecho representa quebra manual no parágrafo; parágrafos são separações semânticas. O adaptador Qt converte CRLF em LF na entrada. O formato preserva os bytes UTF-8 válidos, inclusive combinações Unicode, sem normalização NFC automática. Caret, seleção, layout de fonte e preedit nunca entram no DTO.

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

## Tinta

`InkStroke` guarda as amostras locais originais em pontos de página, `base_width_pt`, pincel (`Pen=0`, `Highlighter=1`) e cor `#RRGGBBAA`. O blob `MTNI` v1 usa os mesmos 16 bytes de cabeçalho (`MTNI`, versão 1, `LE`, flags 0, número de pontos), seguidos de `base_width_pt:f64` IEEE 754, `brush:u8` e 9 bytes ASCII de cor. Cada ponto contém `x:f64`, `y:f64`, `flags:u8`; os bits 0–3 indicam presença de pressão, tempo relativo, inclinação X e inclinação Y, nessa ordem. Cada valor presente vem como `f64`. Ausência de pressão não se converte em zero. Todos os doubles são little endian; `NaN`, infinito, pressão fora de 0–1, tempo regressivo e inclinação fora de −90 a 90 são recusados. Limites: 1–250.000 pontos e blob de até 16 MiB. O decoder verifica o tamanho mínimo antes de reservar memória e rejeita truncamento, flags desconhecidas e bytes extras. Suavização visual não altera esse blob.

## Inventário de ativos

`AssetRecord` guarda UUID, tipo raster/SVG, SHA-256 hexadecimal minúsculo do original, MIME, tamanho em bytes, dimensões e nome de origem apenas para exibição. O caminho controlado deriva de hash e MIME: `assets/<dois primeiros hex>/<hash>.<extensão>`. Nome de origem não é usado como caminho. A validação do DTO aceita PNG, JPEG, WebP e SVG, até 256 MiB, lados até 32.768 px e no máximo 128 megapixels. O importador posterior deve conferir o hash dos bytes, validar e limitar a decodificação, bloquear referências externas em SVG e gravar o original; E3.4 não importa arquivos.

## SQLite v1 → v2

`migrateNotebookSchema` é uma operação explícita e transacional sobre um caderno aberto. O esquema 1 contém `notebook`, `sections` e `pages`, sem conteúdo; a migração preserva as linhas e IDs, cria `page_settings` com padrão A4 para cada página, `page_objects` para payloads `text`/`ink` versionados e `assets` para inventário. Um trigger cria `page_settings` para páginas inseridas depois. `PRAGMA user_version` só passa de 1 para 2 na transação que cria e preenche as tabelas; falha reverte tudo. Migração repetida é idempotente. Esquema 0/inválido e versão acima de 2 não são alterados. A fixture `tests/fixtures/notebook_v1.sql` preserva título Unicode, seção, página e seleção para o teste. `NotebookStore` pode abrir v1 e v2 sem migrar por conta própria; cadernos novos continuam v1 até E4 integrar a escrita de conteúdo e passar a criá-los em v2.

Em `page_settings`, `canvas_kind=0` é A4 e `1` é canvas infinito. As dimensões padrão do A4 são `595,2755905512 × 841,8897637795 pt`; no canvas infinito elas não limitam a cena. `paper_kind` fica reservado para o adaptador visual em E4 (0–4) e não altera objetos ou coordenadas nesta etapa. O acabamento do papel, cor e espaçamento ainda exigem colunas versionadas antes da primeira distribuição do editor.

`page_objects` v2 aceita somente texto e tinta no momento. Transformação, ordens, bloqueio e descrição ficam em colunas; `payload_version=1` e `payload` guarda `MTNT` ou `MTNI`. Título continua em `pages`, nunca como objeto. Grupos, conectores e payloads de imagem exigem evolução explícita do esquema, sem interpretar bytes desconhecidos como outra versão. E4 deve usar transação para salvar objeto e estado da página, validar o codec ao abrir, e recusar versão futura sem regravar o caderno. Autosave, backup e recuperação completos continuam em E6.

**Limite da primeira implementação do repositório (E4.2):** `page_objects` v2 ainda não tem campos para a largura e o modo de largura do contêiner de texto. O repositório aceita apenas os valores padrão (`width_pt=240`, `max_width_pt=500`, largura flexível) e recusa outras geometrias, para não perder essa informação ao salvar. Uma evolução explícita do esquema/codec deverá armazená-la antes de permitir redimensionar texto na UI. Cada objeto é gravado por uma transação própria; um comando que altere vários objetos exigirá uma transação de lote.
