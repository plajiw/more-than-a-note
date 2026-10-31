# Tarefas — C2 Microinterações do editor e página vazia

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. Ao concluir, marque `[x]` e anote a evidência após `→`.

## Fase 1 — Preparação e investigação

- [x] T001 Ler constituição e documentos donos; abrir C2 → `new-activity.sh C2 editor-microinteractions … desvio` saída 0, sobre o commit `7deb136`.
- [x] T002 Investigar as causas → tabela "Investigação" na spec; fonte verificada com `qml.exe` (Inter e IBM Plex Serif resolvem; padrão sem família caía no sistema); harness de testes sem `addApplicationFont`.

## Fase 2 — Implementação

- [x] T003 [US1] Limites do card: `EditorTextCard.qml` (`clampXPt`, `clampYPt`, `clampWidthPt`) e `validTextGeometry` → compilado.
- [x] T004 [US1] Cena cresce pela extensão gravada (`committedExtentRight`, `pageScene.width`) → compilado.
- [x] T005 [US2] `pageScene` invisível sem página; estado vazio removido de `Main.qml` → compilado.
- [x] T006 [US3] `app_fonts.*` em `desktop_core`, usado por `main.cpp` e `workspace_quick_tests.cpp` → compilado.
- [x] T007 [US4] `chromeLayer` e controles do card reparentados; `z` do card fixo → compilado.
- [x] T008 [US5] Superfícies de ferramenta por `visible`; cursor de pan próprio; margem do card com cursor I e foco; clique fora encerra a edição → compilado.
- [x] T009 [US6] `retired`/`onItemRemoved`: controles de card removido saem da camada → compilado.
- [x] T010 Testes `test_card_microinteractions` e `test_empty_notebook_has_no_paper` → `workspace_quick_tests.exe -input tst_editor.qml`: 10/10 em 30/10/2026 (Windows 10, MSYS2 UCRT64, Qt 6.12, offscreen); suíte de interface completa 3×: editor sempre verde.

## Fase 3 — Fechamento

- [x] T011 Suíte completa → testes C++ verdes; `workspace_quick_tests` falha só em `test_keyboard_navigation_and_focus_return` (Tab não alcança a página em 40 passos, linha 81). Comparação no mesmo PC só do arquivo da Biblioteca: base sem C2 4/6 falhas, com C2 6/6; mesmo ponto de falha. Instabilidade anterior, da T030 da M1; não corrigida aqui.
- [x] T012 Evidência → `build/release/evidence/tests/card-off-paper.png` (card além da borda direita, cena ampliada) e `empty-notebook.png` (só o fundo, interface em Inter) conferidas.
- [x] T013 Documentos donos: 04 §5, 17 (limites), 13 §6.1 (síntese C2), 20 §2 (antecipação), registro no 12; roadmap e galeria → editados.
- [x] T015 [US7] Card volta ao papel → `EditorProbe` com `paperWidth`/`paperHeight` e tamanho que cobre os cards; causa confirmada por teste: com a camada maior a alça recebe o clique. `tests/qml/tst_page_bounds.qml` `test_card_leaves_and_returns_to_paper`: sai (x > 595 pt) e volta (x < 495 pt) pela alça, em passos na vista.
- [x] T016 [US8] Tinta recortada no papel (`clip` no `InkProbeItem` do tamanho do papel) → `tst_page_bounds.qml` `test_ink_stays_on_the_paper` (lógico) e `tst_native_ink.qml` `test_ink_is_cut_at_the_paper_edge` (pixels, janela nativa via `run-windowed.cmd`): 4/4; captura `native-ink-cut-at-paper-edge.png` mostra o traço parando na borda.
- [x] T014 Dono do produto aprova pelo roteiro → aprovada em 31/10/2026, junto com C1 e C3 ("já foram resolvidas, pode confirmá-las"); itens marcados a pedido dele em `checklists/validation.md`.

## Pendências fora desta atividade

- Biblioteca instável no Windows: T030 da M1.
- Card fora do papel pela esquerda/topo.
- Papel e modelo de página: etapa própria.
