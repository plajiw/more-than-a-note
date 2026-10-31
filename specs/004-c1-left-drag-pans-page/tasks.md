# Tarefas — C1 Botão esquerdo move a tela e rouba o arrasto do card

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. Ao concluir, marque `[x]` e anote a evidência após `→`.

## Fase 1 — Preparação

- [x] T001 Ler constituição, spec e plano; localizar a causa → `pageScroll` em `apps/desktop/Main.qml` é `Flickable` interativo (arrasto esquerdo embutido). Árvore limpa no commit `dcd4d04` antes de abrir o C1.

## Fase 2 — US1, US2 e US3

- [x] T002 [US1] `apps/desktop/Main.qml`: `interactive: false` e rolagem pela roda no `pageWheel` → editado e compilado.
- [x] T003 [US2] Alças sem roubo de gesto → a primeira versão pôs `preventStealing: true` nas alças; o dono do produto viu o card "travado" com ela no app (30/10/2026). Com o `Flickable` não interativo ninguém mais rouba o gesto, então o `preventStealing` foi retirado. A falha da linha 302 que parecia confirmar o problema era do teste: passos relativos à alça, que se move junto com o card. Teste refeito com coordenadas da vista.
- [x] T004 [US1] [US2] Casos em `tests/qml/tst_editor.qml` → alça em três passos move o card 15 pt sem mover a vista; arrasto esquerdo na faixa acima do papel não move a vista; roda rola; Shift+roda rola na horizontal.
- [x] T005 Entrada C1 em `Gallery.pendingReviews` → editado.
- [x] T010 [US3] Moldura do card com 1 px de tela em qualquer zoom (`EditorTextCard.qml`, item `editorTextCardFrame` que anula o zoom) → caso novo: largura da borda medida na vista = 1 px a 1,5× e a 3×.

## Fase 3 — Fechamento

- [x] T006 Suíte completa → `workspace_quick_tests.exe` direto (offscreen, software) 4 vezes em 30/10/2026, Windows 10 Pro, MSYS2 UCRT64, Qt 6.12: Editor passou nas 4. `cmake --workflow --preset release`: 7/8, falha só em `workspace_quick_tests` pelos testes da Biblioteca (`test_keyboard_navigation_and_focus_return`, às vezes `test_splitter_and_narrow_index`), que **também falham na `main` sem o C1** (base testada com `git stash`): instabilidade anterior, a mesma que derruba o CI do Windows na T030 da M1. Não corrigida aqui.
- [x] T007 Galeria e roteiro → entrada C1 em "Em validação"; roteiro de 8 passos no checklist; o dono do produto testou no app.
- [x] T008 Resumo no [12](../../docs/12-registro-de-implementacao.md); roadmap e `.specify/feature.json` → seção C1 no 12; roadmap com C1 aprovado.
- [x] T009 Dono do produto aprova no editor → testou no app e pediu o commit em 30/10/2026.

## Pendências fora desta atividade

- Testes da Biblioteca instáveis no Windows: T030 da M1.
- Listas da Biblioteca e do índice também arrastam com o botão esquerdo (`Flickable`); abrir desvio se incomodar.
