# Tarefas — M1 Limpeza e ambiente único de validação

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. `[P]` indica tarefa paralelizável e `[USn]` a história atendida. Ao concluir, marque `[x]` e anote a evidência após `→`. Tarefas da convergência entram no fim da fase, com o próximo número livre.

**Esclarecimentos:** Q1–Q3 respondidas em 29/10/2026; decisões de autonomia na spec.

Ambiente de verificação, salvo indicação: elementary OS 8.1, Wayland, Qt 6.8.3 local, GCC 13.3, CMake 3.28.3.

## Fase 1 — Preparação

- [x] T001 Commitar E4.7 como linha de base (`E4.7: …`), com autorização do dono do produto; a M1 não começa sobre a árvore suja → `96d024f`, só os 7 arquivos da E4.7
- [x] T002 Registrar a linha de base: `ctest --preset release` e `ctest --preset core` completos, com tempo e falhas preexistentes anotados aqui → sobre `96d024f`: build `release` 1m27s; `ctest --preset release` **8/8** em 5,5 s (interface offscreen **12/12** casos); interface em Wayland **12/12** em 8,5 s; `core` **4/4**. Nenhuma falha preexistente. 9 blocos `if (!isOffscreen())` desviavam checagens de pixel em silêncio

## Fase 2 — US2 Build único

- [x] T003 [US2] `CMakePresets.json`: preset `asan` e `workflowPresets` `release`, `core` e `asan` → `asan` também no macOS (`inList` Linux/Darwin); verificação final em T026
- [x] T004 [US2] `CMakeLists.txt`: mínimo 3.25 e biblioteca `desktop_core`; sem listas de fontes repetidas → cada fonte de `apps/desktop` aparece uma vez; `ink_probe_item` fica nos dois módulos QML porque usa `QML_ELEMENT`
- [x] T005 [US2] `apps/desktop/main.cpp`: `MTN_PROFILE_DIR` e `MTN_CAPTURE_DIR` → `MTN_PROFILE_DIR` lido pelo `NotebookStore`; `MTN_CAPTURE` removida; com `--gallery`, `MTN_CAPTURE_DIR` liga a captura roteirizada (`CaptureSink`)
- [x] T006 [US2] `tests/workspace_quick_tests.cpp`: `MTN_E2_CAPTURE_DIR` → `MTN_CAPTURE_DIR` → capturas em `<dir>/tests/`
- [x] T007 [US2] Alvos `gallery` e `evidence` no `CMakeLists.txt` → `gallery` abre em `build/<preset>/sandbox`; `evidence` regenera `build/<preset>/evidence` (76 imagens), ver T026
- [x] T040 [US2] Ambiente por máquina: `cmake/local.cmake` (fora do git) carregado antes de `project()`, com modelo em `cmake/local.cmake.example` → antes, Qt SDK, ninja e OpenGL só existiam no cache de `build/release`, passados à mão. Com `libgl-dev` 1.7.0 instalado pelo dono do produto, o arquivo desta máquina guarda só o Qt e o ninja
- [x] T008 [US2] `Dockerfile` e `.github/workflows/*` com `cmake --workflow` → Docker roda `release`, `evidence`, `asan` e `core` com `CXX=clang++` (sem `-D`); Windows usa `CMAKE_PREFIX_PATH` por ambiente e `cmake --workflow --preset release`. Não executados localmente (sem Docker nem Windows): ver T030
- [x] T031 [US2] Alvo `gallery` no Windows → `cmake -E env --modify PATH=path_list_prepend:<pasta do Qt6Core>` antes de `MTN_PROFILE_DIR` (a ordem importa para o `cmake -E env`); PowerShell documentado no `BUILDING.md`. Execução no Windows pendente (T030)
- [x] T032 [US2] CI publica evidências → Linux: `docker build --target evidence --output` + `upload-artifact` (`evidence-linux`); Windows: `evidence-windows`; Linux roda também `check.sh` e o workflow `asan`

## Fase 3 — US2 Testes independentes

- [x] T009 [US2] Separar `tests/qml/tst_workspace.qml` com perfil próprio e sem prefixos `z` → `AppTestCase.qml` (base: Biblioteca a cada `init()`, páginas novas por teste) e `tst_library_navigation`, `tst_editor`, `tst_gallery`, `tst_native_ink`; o setup C++ cria perfil e cadernos de amostra por arquivo. Os 14 casos passam **isoladamente**, um por processo
- [x] T010 [US2] Checagens de pixel nativas com `skip()` explícito → `tst_native_ink.qml` reúne as de tinta; offscreen mostra `SKIP` com motivo; capturas sem condição de plataforma
- [x] T011 [US2] Falha de foco do índice (linha 108) → não reproduz em T002 nem depois; nada a corrigir
- [x] T033 [US2] Erros de QML viram falha → `failOnWarning` (`TypeError`, `ReferenceError`, binding loop, atribuição inválida) em todo `init()`. Achado: `EditorToolbar` referenciava o `id` `window` do `Main.qml` e gerava `ReferenceError` na galeria; agora usa `strip.Window`
- [x] T034 [P] [US2] Driver sem nomes de etapa → `WorkspaceKeyboardDriver` → `InputDriver`, contexto `inputDriver`; `qDebug` “E4.6 wheel event” removido; caderno “Caderno E2” → “Caderno de teste”
- [x] T035 [US2] Fumaça da galeria → `tst_gallery.qml::test_every_section_opens_in_both_themes`: as 10 seções, dois temas, sem erro de QML, ID desconhecido recusado
- [x] T012 [US2] Suíte completa em offscreen e em sessão nativa → offscreen **21 passaram, 1 SKIP** (tinta nativa); Wayland **22/22** na primeira rodada. Depois, em Wayland, `Editor::test_viewport_and_infinite_page` falhou 3/3 no zoom pela roda, com a janela em outro estado da área de trabalho, e passou 3/3 em offscreen: no Wayland a geometria da janela depende do compositor. Por isso só `tst_native_ink` roda na sessão gráfica (constituição III); a falha nativa fica registrada no roadmap
- [x] T042 [US2] Preferências no perfil isolado → `useIsolatedProfileSettings()` aponta `QSettings` (e o `Settings` do QML) para `MTN_PROFILE_DIR/settings`; antes, testes e galeria liam e gravavam as preferências reais
- [x] T043 [US2] Casos levados da sondagem E4.1 para o editor real → `test_typing_keeps_tools_and_ime` (atalhos `t p v` não trocam ferramenta na digitação; pré-edição e commit de IME) e a checagem do ponto isolado em `tst_native_ink`

## Fase 4 — US1 Galeria como ambiente único

- [x] T013 [US1] Registro do índice da galeria no [13](../../docs/13-estudo-visual.md) §6.1 → “Índice da galeria, 29/10/2026 (M1)”, com tokens existentes e referências Apple/Adobe
- [x] T014 [US1] `Gallery.qml`: índice e IDs estáveis → `pending`, `editor`, `components`, `toolbar`, `text-card`, `index`, `islands`, `typography`, `icons`, `colors` (IDs em inglês, constituição IV)
- [x] T015 [US1] `--gallery[=<seção>]` no lugar das três variantes → `startWith*Gallery` removidos; seção desconhecida gera aviso e fica no topo
- [x] T016 [US1] Seção Editor → `Main.openSampleEditor()` cria ou reabre o “Caderno de amostra” só com perfil isolado; `test_gallery_opens_sample_editor`
- [x] T017 [US1] Remover sondagens e tornar o editor padrão → saem `--editor-probe`, `--page-model-demo`, `--editor-model-demo`, `page_test_adapter.*`, os campos fixos da sondagem no `EditorProbe` e os ramos de `Main.qml`. Botão “Salvar textos” e dica de Ctrl+S ficam (produto; anotado em `docs/ideias.md`)
- [x] T018 [US1] `tests/fixtures/make_e2_fixture.py` → removido: o caderno de amostra da galeria e o perfil por arquivo de teste o substituem, sem Python nem `XDG_*`
- [x] T036 [US1] Capturas da galeria pelo caminho comum → `gallery/<seção>-<graphite|light>-<100|150>.png`, seção inteira por `grabToImage`, depois de 450 ms para assentar as transições de tema. Sempre em offscreen: uma janela coberta no Wayland para de receber quadros e travava a captura. O renderizador de software marca algumas imagens como `RGB32` com alpha zerado; `CaptureSink` as reinterpreta antes de compor sobre o fundo
- [x] T037 [US1] Seção “Em validação” → lista `pendingReviews` com M1, o polimento de 26–27/10 (ainda sem aprovação registrada no 13) e as ações do card; o conteúdo de “Revisão 26/10” fica sob ela, como pendência anterior ao Spec Kit
- [x] T038 [US1] Maquetes identificadas → `index` e `islands` levam `mockup: true` (texto “Maquete: …”); nota da toolbar atualizada (ela já estava ligada ao editor desde a E4.5)

## Fase 5 — US3 Pastas e artefatos

- [x] T019 [US3] `build/` só com presets → também foram os artefatos não versionados de E2–E4 citados no 12; os resultados seguem em texto
- [x] T020 [US3] `preview/` → 7 imagens citadas em `docs/images/` com links atualizados no 12 e no 13; protótipo HTML e capturas não citadas removidos (no git em `be9e29a`, anotado em 01, 06, 10 e 13)
- [x] T021 [US3] Branches → as locais `codex/e3-6-ci` e `codex/e4-2-ci` eram idênticas em árvore a `origin/codex/e3-6-ci` e `origin/codex/e4-3-ci`; removidas, junto com a worktree órfã em `/tmp` e a referência solta `ci/e3-6-ci`. `origin/codex/*` mantidas
- [x] T044 [US3] Nomes em inglês → `specs/001-m1-cleanup-and-validation/`, `checklists/validation.md`, `.specify/workflow.md`, `.specify/scripts/new-activity.sh` e `check.sh`, `validation-template.md`, `docs/experiments/`, `docs/images/`, alvos `gallery` e `evidence`, pasta `evidence/`

## Fase 6 — US4 Documentação e regras

- [x] T022 [P] [US4] `BUILDING.md` → reescrito em pt-BR: ciclo por workflow, validação, lista fechada, ambiente por máquina e instalação nos três sistemas
- [x] T023 [P] [US4] 14 §1, §6 e §7 e 11 “Próxima sequência” → estado e fila apontam para o roadmap; §6 diz que o experimento roda dentro de uma atividade
- [x] T024 [P] [US4] `README.md` e `docs/README.md` em pt-BR, com estrutura e comandos; aviso de substituição em `docs/01-layout.md`; `docs/ideias.md` com modelo e duas entradas
- [x] T025 [US4] Constituição 1.2.0 → comandos `gallery` e `evidence`, lista fechada, testes visuais roteirizados, idioma de comandos e documentos, mesmo fluxo nos três sistemas, `check.sh` obrigatório
- [x] T041 [US4] Roadmap vivo em `specs/ROADMAP.md` → substitui `specs/README.md`; constituição 1.1.0 e fluxo (passos 1, 6, 7 e 9)
- [x] T039 [US4] `.specify/scripts/check.sh` → atividade ativa e roadmap, esclarecimentos abertos, lista fechada de opções e variáveis, testes sem prefixo `z` nem desvio silencioso, `build/` só com presets, commits com ID; no CI Linux e nos passos 7 e 9 do fluxo
- [x] T045 [US4] Roteiro obrigatório → modelo `validation-template.md` com tabela de roteiro (passo, onde, capturas); fluxo passo 4 e `AGENTS.md`

## Fase 7 — Fechamento

- [x] T026 Workflows completos a partir de `build/` vazio → `release` **8/8** (120 s), `asan` **8/8** sem relato (152 s), `core` **4/4** (GCC; Clang só no CI), `evidence` 21 + 1 SKIP em offscreen e tinta nativa 3/3, **76** imagens. Contra T002: a interface passou de 12 para 14 casos (−2 sondagens, +4 novos)
- [x] T027 Resíduos → `git grep` das opções, variáveis, pastas e arquivos removidos: nenhuma ocorrência fora dos registros históricos, que levam “(removida na M1)”; `check.sh` ok
- [x] T028 Galeria e roteiro → itens técnicos marcados no `checklists/validation.md`; M1 listada em “Em validação”; estado **em validação**
- [x] T029 Resumo da M1 no [12](../../docs/12-registro-de-implementacao.md); roadmap atualizado. `feature.json` continua na M1 até a aprovação
- [ ] T030 CI Linux e Windows depois de autorização para push: confirmar Docker com `asan` e `evidence`, o alvo `gallery` e a captura no Windows, e baixar os artefatos

## Pendências fora desta atividade

- Zoom pela roda falha no teste nativo Wayland conforme o estado da janela (T012): investigar como desvio se aparecer no uso.
- Renomear a superfície do editor e o botão “Salvar textos”: em `docs/ideias.md`.
- QX3, regressão visual automática no CI, em E7; as capturas de `evidence` são a base.
- QX1, checks obrigatórios na `main`: configuração do GitHub, a cargo do dono do produto.
