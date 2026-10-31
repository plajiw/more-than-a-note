# Tarefas — C3 Card de texto no estilo Excalidraw

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. Ao concluir, marque `[x]` e anote a evidência após `→`. Ambiente das evidências: Windows 10 Pro, MSYS2 UCRT64, Qt 6.12, GCC 16.2, 30–31/10/2026.

## Fase 1 — Preparação

- [x] T001 Avaliação da proposta por agente especializado (só leitura) e decisões do dono do produto → spec, tabela D1–D7 (30/10/2026); escala da letra recusada (alças só mudam a caixa).
- [x] T002 Estudo visual no 13 §6.1 → parágrafo "Card de texto no estilo Excalidraw (C3)": contorno 1 px `paper.focus`, alças 8 px com alvo 16 px, rotação 24 px acima, cursores, margem 8 px, estados.

## Fase 2 — Fatia 1: modelo, persistência e comandos (US2, US5)

- [x] T003 [US5] `TextContainer.height_pt`/`fixed_height`; SQLite v5 (`text_height_pt`, `text_fixed_height`; caixas existentes com `text_fixed_width = 1`); `migrateNotebookSchemaV5`; recusa de v6 sem escrita; repositório e `NotebookStore` em v5 → `notebook_schema_tests`, `page_repository_tests`, `notebook_store_tests` verdes.
- [x] T004 [US2] `validate_page` aceita rotação em texto (escala segue recusada; tinta sem rotação); `rebuildVisual` envia `heightPt`, `fixedHeight`, `rotation` → `page_content_tests` com os casos novos.
- [x] T005 [US1] [US2] [US5] Adaptador: `setTextBox` (um comando com origem e tamanho, mínimo 24 pt, sem máximo), `rotateText` (ângulo normalizado e origem), `duplicateTextTo` (Alt+arrastar); `createTextAt` no ponto exato; `duplicateText` sem prender ao papel → compilado e coberto pelos testes de interface.
- [x] T006 Testes C++: migração v4→v5 com fixture e idempotência; altura fixa 140 pt e rotação 30° sobrevivem a fechar e reabrir → `ctest -R "schema|repository|content|store"` 5/5.

## Fase 3 — Fatia 2: caixa de seleção (US1, US2)

- [x] T007 [US1] `apps/desktop/ui/TextSelectionBox.qml` na camada de controles: contorno, oito alças, alça de rotação, cursores por direção corrigidos pela rotação → `test_handle_cursors_follow_rotation`.
- [x] T008 [US1] `EditorTextCard.qml` reescrito sem cápsula, alça de largura e botões; foco de objeto `editorTextObject` (setas, `Alt`+setas, `Enter`, `Esc`, `Delete`, `Ctrl+D`). Os componentes antigos ficam só na seção "Caixa de texto" da galeria, como estudo anterior.
- [x] T009 [US2] Rotação em torno do centro, `Shift` em 15° → `test_rotation_around_centre`: 90° com o centro parado (< 1,5 px), texto girado editável, ângulo após reabrir.
- [x] T010 Testes das oito alças em zoom 1, `Esc` durante o gesto, desfazer/refazer e caixa fixa → `test_eight_handles_resize_the_box`; moldura de 1 px a 1,5× e 3× e alça em tamanho de tela → `tst_editor` `test_viewport_and_infinite_page`; capturas `text-box-selected.png`, `text-box-rotated-90.png`.

## Fase 4 — Fatia 3: ferramentas (US3, US4)

- [x] T011 [US3] Superfície da Seleção (`editorProbeSelectSurface`): clique no vazio limpa, duplo clique inicia texto; corpo do card (`editorTextCardBodyArea`) seleciona, move, duplo clique edita.
- [x] T012 [US3] `Alt`+arrastar: contorno da cópia durante o gesto, um comando ao soltar → `test_selection_tool_moves_duplicates_and_deletes` (original parado, cópia +90 pt, um desfazer remove).
- [x] T013 [US4] Ferramenta Texto por clique: cursor sem caixa até digitar, largura automática sem limite (> 500 pt numa linha), `Esc` ou clique fora devolve para Seleção, cursor vazio não deixa objeto → `test_text_tool_works_per_click`; captura `text-tool-caret.png`.
- [x] T014 Testes ajustados ao card novo em `tst_editor.qml` (teclado do objeto, alça direita, corpo com Seleção, ferramenta que volta para Seleção) e `tst_page_bounds.qml` (sair e voltar ao papel pelo corpo).

## Fase 5 — Fechamento

- [x] T015 Documentos donos: 04 §3.1/§3.2, 17 (Mover, Largura, Ações, Acessibilidade), 13 §6.1, 02, 03 §2, 16 (v4→v5), 20 (rotação de texto antecipada); registro no 12; roadmap; galeria em "Em validação".
- [x] T016 Suíte e evidência → `cmake --workflow --preset release` 8/8; `workspace_quick_tests` 35/35 em quatro rodadas seguidas (2 SKIP de tinta offscreen); `tst_native_ink` em janela nativa 4/4; `--target evidence` saída 0 (40 capturas de galeria, 45 de testes); `.specify/scripts/check.sh` saída 0. A instabilidade da Biblioteca que ainda derrubava a suíte foi corrigida e registrada na M1 (T046).
- [x] T018 [US6] Página limpa: sem título, dica, botão "Salvar textos" e status no papel; falhas em `editorProblem` na barra de status; caneta em todo o papel → `tst_editor` usa `Ctrl+S` no lugar do botão; `tst_native_ink` com traço sobre o texto 4/4 em janela nativa; interface 35/35 duas vezes (31/10/2026). O app não recompilou nesta rodada porque estava aberto.
- [x] T019 [US3] Cursores na tela, não só pedidos pela alça: `pagePanSurface` e `editorProbeSelectSurface` nasciam com a seta padrão de toda `MouseArea` e cobriam a cruz de mover e as setas de redimensionar; agora usam `cursorShape: undefined`. `inputDriver.cursorAt` lê o cursor da janela → `test_pointer_shows_move_and_resize_cursors`: cruz no corpo (sem e com seleção), oito alças, mão na rotação, I com Texto. Antes da correção: seta (0) no lugar da cruz (9).
- [x] T020 [US3] `Espaço` pelo nível da área de trabalho (`workspaceBody`), ignorando a repetição automática do Windows → `tst_editor` `test_viewport_and_infinite_page` com `inputDriver.keyRepeat` (o pan continua); `test_text_tool_returns_to_selection_on_any_finish`: Texto volta para Seleção ao clicar fora, duplo clique no vazio cria texto, Espaço com card selecionado mostra a mão e devolve a cruz.
- [x] T021 Contorno arredondado (`TextSelectionBox.qml`): raio `radius.sm`, cantos redondos, lados em pílula, haste da rotação, hover → capturas `text-box-selected.png` e `text-box-rotated-90.png` revisadas; `ctest --preset release` 8/8 (31/10/2026); `check.sh` saída 0. O executável do app não religou porque estava aberto: o roteiro pede recompilar.
- [x] T017 Dono do produto aprova pelo roteiro → aprovada em 31/10/2026, após a rodada de cursores, Espaço e contorno.

## Pendências fora desta atividade

- Menu de contexto (botão direito, `Shift+F10`) e copiar/colar de objetos com `Ctrl+C`/`Ctrl+V`: próxima atividade.
- Seção "Caixa de texto" da galeria ainda mostra o estudo anterior (cápsula e botões): atualizar ou retirar.
- IME e leitor de tela com texto girado, caneta real e 150% físico: portões de plataforma.
