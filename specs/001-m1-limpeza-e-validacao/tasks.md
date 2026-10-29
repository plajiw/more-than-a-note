# Tarefas — M1 Limpeza e ambiente único de validação

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. `[P]` indica tarefa paralelizável e `[USn]` a história atendida. Ao concluir, marque `[x]` e anote a evidência após `→`. Tarefas da convergência entram no fim da fase, com o próximo número livre.

**Esclarecimentos:** Q1–Q3 respondidas em 29/10/2026 (spec).

## Fase 1 — Preparação

- [x] T001 Commitar E4.7 como linha de base (`E4.7: …`), com autorização do dono do produto; a M1 não começa sobre a árvore suja → `96d024f`, só os 7 arquivos da E4.7
- [x] T002 Registrar a linha de base: `ctest --preset release` e `ctest --preset core` completos, com tempo e falhas preexistentes anotados aqui → sobre `96d024f`, Linux local, Qt 6.8.3: build `release` 1m27s; `ctest --preset release` **8/8** em 5,5 s (interface offscreen **12/12** casos, 0 pulados, 1 aviso de grab de teclado no offscreen); interface em Wayland nativo **12/12** em 8,5 s com 17 capturas em `build/release/evidencias/t002`; `ctest --preset core` **4/4**. Nenhuma falha preexistente. Atenção: 9 blocos `if (!isOffscreen())` desviam checagens de pixel em silêncio, então o `ctest` e o CI nunca as executam

## Fase 2 — US2 Build único (base das outras fases)

- [x] T003 [US2] `CMakePresets.json`: preset `asan` (configure, build e test) e `workflowPresets` `release`, `core` e `asan` → do zero, sem flags: `cmake --workflow --preset release` **8/8** (86 s), `asan` **8/8** sem relato de sanitizador (108 s), `core` **4/4**
- [x] T004 [US2] `CMakeLists.txt`: mínimo 3.25 e biblioteca `desktop_core`; remover listas de fontes repetidas do app e de `workspace_quick_tests` → cada fonte aparece uma vez; `ink_probe_item` fica nos dois alvos de módulo QML porque usa `QML_ELEMENT` (`qml_type_sources`); galeria abriu em offscreen sem aviso QML
- [ ] T005 [US2] `apps/desktop/main.cpp`: `MTN_PROFILE_DIR` (perfil isolado) e `MTN_CAPTURE` → `MTN_CAPTURE_DIR`
- [ ] T006 [US2] `tests/workspace_quick_tests.cpp`: `MTN_E2_CAPTURE_DIR` → `MTN_CAPTURE_DIR`
- [ ] T007 [US2] Alvos `galeria` e `evidencias` no `CMakeLists.txt`, com saída em `build/<preset>/sandbox` e `build/<preset>/evidencias`
- [x] T040 [US2] Ambiente por máquina: `cmake/local.cmake` (fora do git), carregado antes de `project()`, com modelo em `cmake/local.cmake.example`. Nesta máquina ele guarda o Qt SDK em `~/.local/share/mtn-qt`, o ninja em `~/.local/bin` e o OpenGL extraído (os links de `mtn-opengl` estão quebrados, e o sistema não tem `libgl-dev`). Antes, esses cinco valores só existiam no cache de `build/release`, passados à mão → `release`, `asan` e `core` configuram do zero sem `-D`. Depois que o dono do produto instalou `libgl-dev` 1.7.0, o OpenGL vem do sistema e o `local.cmake` guarda só o Qt e o ninja: os três workflows passaram de novo do zero (8/8, 8/8 e 4/4)
- [ ] T008 [US2] Conferir que `Dockerfile` e `.github/workflows/*` continuam compatíveis; usar `cmake --workflow` onde simplificar
- [ ] T031 [US2] Alvo `galeria` no Windows: executar a partir de `build/dist` (após `cmake --install`) ou com o `PATH` do Qt, porque o exe de `build/release` não abre fora do MSYS2; documentar o equivalente em PowerShell
- [ ] T032 [US2] Linux CI: rodar também o workflow `asan` no Docker; os dois CIs publicam `build/release/evidencias/` como artefato, para conferir capturas do Windows sem máquina Windows

## Fase 3 — US2 Testes independentes

- [ ] T009 [US2] Separar `tests/qml/tst_workspace.qml` em `tst_navegacao`, `tst_editor`, `tst_historico`, `tst_viewport` e `tst_caixa_galeria`, com perfil próprio por caso e sem prefixos `z`
- [ ] T010 [US2] Checagens de pixel nativas com `skip()` explícito no offscreen
- [x] T011 [US2] Falha de foco do índice (`test_keyboard_navigation_and_focus_return`, linha 108): corrigir se for do teste; se for do produto, abrir desvio `C1` → não reproduz em T002 (passou em offscreen e em Wayland); nada a corrigir
- [ ] T033 [US2] Avisos QML viram falha: `failOnWarning` para erros de binding, `TypeError` e `ReferenceError` em todos os `TestCase`; manter só os avisos de plataforma conhecidos (grab de teclado no offscreen) numa lista explícita
- [ ] T034 [P] [US2] `tests/workspace_quick_tests.cpp`: remover o `qDebug` “E4.6 wheel event” e nomes de etapa no driver; o driver passa a se chamar pelo que faz
- [ ] T035 [US2] Teste de fumaça da galeria: abrir cada ID de seção por `--gallery=<id>` (ou pela mesma API em QML), nos dois temas, sem aviso QML; protege a galeria de quebrar sem ninguém ver
- [ ] T012 [US2] `cmake --workflow --preset release` completo em offscreen e suíte de interface completa em Wayland, com o número de pulos explícitos anotado

## Fase 4 — US1 Galeria como ambiente único

- [ ] T013 [US1] Estudo curto do índice da galeria e registro no [13](../../docs/13-estudo-visual.md) §6.1 (constituição V)
- [ ] T014 [US1] `apps/desktop/ui/Gallery.qml`: índice de seções e IDs estáveis (`componentes`, `toolbar`, `revisao`, `caixa-de-texto`, `indice`, `ilhas`, `tipografia`, `icones`, `cores`, `editor`)
- [ ] T015 [US1] `main.cpp`: `--gallery[=seção]` no lugar de `--gallery-index`, `--gallery-text-card` e `--gallery-review`; ajustar `startWith*` em `Main.qml` e `Gallery.qml`
- [ ] T016 [US1] Seção Editor: caderno de amostra criado pelo `NotebookStore` sob `MTN_PROFILE_DIR`, abrindo a janela principal nele (Q1)
- [ ] T017 [US1] Remover `--editor-probe`, `--page-model-demo`, `apps/desktop/page_test_adapter.*` e os ramos de `Main.qml`; editor como padrão conforme Q1
- [ ] T018 [US1] Decidir o destino de `tests/fixtures/make_e2_fixture.py` (substituído pelo caderno de amostra ou mantido com uso documentado)
- [ ] T036 [US1] Capturas da galeria pelo caminho comum: o alvo `evidencias` também grava cada seção da galeria nos temas grafite e claro e a 100% e 150%, em `build/<preset>/evidencias/galeria/<seção>-<tema>-<escala>.png`, substituindo a captura única de `MTN_CAPTURE`. É o mesmo conjunto de prints para o agente e para o dono do produto
- [ ] T037 [US1] Seção “Revisão 26/10 · para aprovar”: o que foi aprovado vai para a seção do próprio componente; o que está pendente fica numa seção “Em validação”, que lista só as atividades com estado **em validação** e aponta a seção e o checklist de cada uma. Seções datadas deixam de existir
- [ ] T038 [US1] Auditar as maquetes da galeria (“Ilhas e rolagem”, páginas e status falsos): onde já houver componente real, usar o real (14 §2.2); onde não houver, marcar como maquete no texto da seção

## Fase 5 — US3 Pastas e artefatos

- [x] T019 [US3] Apagar `build/asan-e33`, `build/asan-e43` e `build/debug`; reconfigurar `build/release` limpo (artefatos gerados, sem dados do usuário) → `build/` contém só `asan`, `core` e `release`. Foram junto os artefatos não versionados de E2–E4 citados no 12 (capturas, perfis, logs, `.tar.gz`) e as capturas da T002; os resultados seguem registrados em texto
- [ ] T020 [US3] `preview/` conforme Q2; atualizar links em `docs/12` e `docs/13`
- [ ] T021 [US3] Branches conforme Q3

## Fase 6 — US4 Documentação

- [ ] T022 [P] [US4] `BUILDING.md`: “Validar na galeria”, workflow, preset `asan` e lista fechada de opções e variáveis
- [ ] T023 [P] [US4] [14](../../docs/14-plano-de-evolucao-e-experimentos.md) §1, §6 e §7 e [11](../../docs/11-tarefas-de-implementacao.md) “Próxima sequência”: estado → link para `specs/ROADMAP.md`; §6 aponta `.specify/fluxo.md`
- [ ] T024 [P] [US4] `docs/README.md` e `README.md`: apontar `specs/` e `.specify/`; aviso de substituição em `docs/01-layout.md`; cabeçalho de triagem em `docs/ideias.md`
- [ ] T025 [US4] Constituição 1.2.0: a regra III passa a citar a lista fechada do `BUILDING.md`
- [x] T041 [US4] Roadmap vivo em `specs/ROADMAP.md`, com “Onde estamos”, gráfico de ramificações do caminho percorrido, gráfico do caminho à frente, checklist (concluído, em andamento, próximo, pendências) e registro; substitui `specs/README.md`. Constituição 1.1.0 e fluxo (passos 1, 6, 7 e 9) exigem a atualização em texto, checklist e gráfico → referências trocadas; `git grep specs/README` vazio
- [ ] T039 [US4] `.specify/scripts/verificar.sh`, rodado pelo agente antes de pedir validação e pelo CI Linux: `feature.json` aponta para pasta existente; nenhuma atividade **planejada** ou posterior com `[PRECISA ESCLARECER]`; nenhuma opção de linha de comando ou `MTN_*` fora da lista fechada; nenhum diretório em `build/` fora dos presets; commits da branch começam por um ID de atividade; todo ID do registro do roadmap aparece no checklist e no gráfico, e a atividade de `feature.json` está em “Em andamento”. Documentar em `.specify/fluxo.md` (passos 7 e 9)

## Fase 7 — Fechamento

- [ ] T026 `cmake --workflow` dos presets `release`, `core` e `asan` completos; comparar com T002
- [ ] T027 Busca de resíduos: `git grep` dos nomes removidos, sem ocorrências fora do histórico do 12; `.specify/scripts/verificar.sh` passa
- [ ] T028 Galeria: seguir `checklists/validacao.md`, marcar os itens técnicos e passar a atividade para **em validação**
- [ ] T029 Resumo da M1 no [12](../../docs/12-registro-de-implementacao.md); `specs/ROADMAP.md` atualizado; `feature.json` apontando a E4.8
- [ ] T030 CI Linux e Windows na branch da M1, depois de autorização para push

## Pendências fora desta atividade


- Renomear `InkProbeItem`/`EditorProbe` para nomes de produto (anotar em `docs/ideias.md`).
- QX3, regressão visual automática no CI, em E7.
- QX1, checks obrigatórios na `main`: configuração do GitHub, a cargo do dono do produto.
