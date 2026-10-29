# Tarefas — M1 Limpeza e ambiente único de validação

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. `[P]` indica tarefa paralelizável e `[USn]` a história atendida. Ao concluir, marque `[x]` e anote a evidência após `→`. Tarefas da convergência entram no fim da fase, com o próximo número livre.

**Esclarecimentos:** Q1–Q3 respondidas em 29/10/2026 (spec).

## Fase 1 — Preparação

- [x] T001 Commitar E4.7 como linha de base (`E4.7: …`), com autorização do dono do produto; a M1 não começa sobre a árvore suja → `96d024f`, só os 7 arquivos da E4.7
- [ ] T002 Registrar a linha de base: `ctest --preset release` e `ctest --preset core` completos, com tempo e falhas preexistentes anotados aqui

## Fase 2 — US2 Build único (base das outras fases)

- [ ] T003 [US2] `CMakePresets.json`: preset `asan` (configure, build e test) e `workflowPresets` `release`, `core` e `asan`
- [ ] T004 [US2] `CMakeLists.txt`: mínimo 3.25 e biblioteca `desktop_core`; remover listas de fontes repetidas do app e de `workspace_quick_tests`
- [ ] T005 [US2] `apps/desktop/main.cpp`: `MTN_PROFILE_DIR` (perfil isolado) e `MTN_CAPTURE` → `MTN_CAPTURE_DIR`
- [ ] T006 [US2] `tests/workspace_quick_tests.cpp`: `MTN_E2_CAPTURE_DIR` → `MTN_CAPTURE_DIR`
- [ ] T007 [US2] Alvos `galeria` e `evidencias` no `CMakeLists.txt`, com saída em `build/<preset>/sandbox` e `build/<preset>/evidencias`
- [ ] T008 [US2] Conferir que `Dockerfile` e `.github/workflows/*` continuam compatíveis; usar `cmake --workflow` onde simplificar

## Fase 3 — US2 Testes independentes

- [ ] T009 [US2] Separar `tests/qml/tst_workspace.qml` em `tst_navegacao`, `tst_editor`, `tst_historico`, `tst_viewport` e `tst_caixa_galeria`, com perfil próprio por caso e sem prefixos `z`
- [ ] T010 [US2] Checagens de pixel nativas com `skip()` explícito no offscreen
- [ ] T011 [US2] Falha de foco do índice (`test_keyboard_navigation_and_focus_return`, linha 108): corrigir se for do teste; se for do produto, abrir desvio `C1`
- [ ] T012 [US2] `cmake --workflow --preset release` completo em offscreen e suíte de interface completa em Wayland

## Fase 4 — US1 Galeria como ambiente único

- [ ] T013 [US1] Estudo curto do índice da galeria e registro no [13](../../docs/13-estudo-visual.md) §6.1 (constituição V)
- [ ] T014 [US1] `apps/desktop/ui/Gallery.qml`: índice de seções e IDs estáveis (`componentes`, `toolbar`, `revisao`, `caixa-de-texto`, `indice`, `ilhas`, `tipografia`, `icones`, `cores`, `editor`)
- [ ] T015 [US1] `main.cpp`: `--gallery[=seção]` no lugar de `--gallery-index`, `--gallery-text-card` e `--gallery-review`; ajustar `startWith*` em `Main.qml` e `Gallery.qml`
- [ ] T016 [US1] Seção Editor: caderno de amostra criado pelo `NotebookStore` sob `MTN_PROFILE_DIR`, abrindo a janela principal nele (Q1)
- [ ] T017 [US1] Remover `--editor-probe`, `--page-model-demo`, `apps/desktop/page_test_adapter.*` e os ramos de `Main.qml`; editor como padrão conforme Q1
- [ ] T018 [US1] Decidir o destino de `tests/fixtures/make_e2_fixture.py` (substituído pelo caderno de amostra ou mantido com uso documentado)

## Fase 5 — US3 Pastas e artefatos

- [ ] T019 [US3] Apagar `build/asan-e33`, `build/asan-e43` e `build/debug`; reconfigurar `build/release` limpo (artefatos gerados, sem dados do usuário)
- [ ] T020 [US3] `preview/` conforme Q2; atualizar links em `docs/12` e `docs/13`
- [ ] T021 [US3] Branches conforme Q3

## Fase 6 — US4 Documentação

- [ ] T022 [P] [US4] `BUILDING.md`: “Validar na galeria”, workflow, preset `asan` e lista fechada de opções e variáveis
- [ ] T023 [P] [US4] [14](../../docs/14-plano-de-evolucao-e-experimentos.md) §1, §6 e §7 e [11](../../docs/11-tarefas-de-implementacao.md) “Próxima sequência”: estado → link para `specs/README.md`; §6 aponta `.specify/fluxo.md`
- [ ] T024 [P] [US4] `docs/README.md` e `README.md`: apontar `specs/` e `.specify/`; aviso de substituição em `docs/01-layout.md`; cabeçalho de triagem em `docs/ideias.md`
- [ ] T025 [US4] Constituição 1.1.0: a regra III passa a citar a lista fechada do `BUILDING.md`

## Fase 7 — Fechamento

- [ ] T026 `cmake --workflow` dos presets `release`, `core` e `asan` completos; comparar com T002
- [ ] T027 Busca de resíduos: `git grep` dos nomes removidos, sem ocorrências fora do histórico do 12
- [ ] T028 Galeria: seguir `checklists/validacao.md`, marcar os itens técnicos e passar a atividade para **em validação**
- [ ] T029 Resumo da M1 no [12](../../docs/12-registro-de-implementacao.md); `specs/README.md` atualizado; `feature.json` apontando a E4.8
- [ ] T030 CI Linux e Windows na branch da M1, depois de autorização para push

## Pendências fora desta atividade

- Renomear `InkProbeItem`/`EditorProbe` para nomes de produto (anotar em `docs/ideias.md`).
- QX3, regressão visual automática no CI, em E7.
- QX1, checks obrigatórios na `main`: configuração do GitHub, a cargo do dono do produto.
