# Pesquisa — M1 Limpeza e ambiente único de validação

Inventário feito em 29/10/2026 sobre `main` (`be9e29a`), com as alterações de E4.7 ainda não commitadas.

## 1. Spec Kit: o que foi adotado e o que não foi

O [GitHub Spec Kit](https://github.com/github/spec-kit) 1.0 (outubro de 2026) organiza o trabalho em *constitution → specify → clarify → plan → checklist → tasks → analyze → implement → converge*, com a feature ativa em `.specify/feature.json` e artefatos Markdown por feature. Para projetos existentes, o [guia oficial](https://github.github.io/spec-kit/guides/existing-projects.html) recomenda uma constituição só com princípios já verdadeiros ou acordados, começar por uma mudança delimitada sem especificar retroativamente o sistema inteiro e tratar cada pasta de feature como registro histórico. Os checklists pertencem ao revisor, e `/speckit.implement` os lê como portão.

**Adotado:** constituição, `feature.json`, uma pasta por atividade com spec, plano e tarefas, marcas de esclarecimento, checklist de responsabilidade do revisor, convergência e linha de base sem especificação retroativa (E0–E4.7 apontam para o 12).

**Adaptado:** a pasta leva o ID do roadmap (`001-m1-…`, `002-e4.8-…`), porque o projeto já se organiza por etapas. O checklist do revisor virou `validacao.md`, ligado à galeria. Os documentos são em português, como o restante de `docs/`.

**Não adotado agora:** a CLI `specify` e os comandos `/speckit.*` gerados por agente. A máquina não tem `uv`, e os comandos gerados ficam presos a um agente. O mesmo fluxo está descrito em `.specify/fluxo.md` para qualquer agente. Instalar a CLI depois é compatível com esta estrutura, mas `specify init --here --force` pode sobrescrever modelos: faça em branch e revise o diff.

## 2. Modos e flags do executável

Lidos em `apps/desktop/main.cpp` e `apps/desktop/Main.qml`.

| Entrada | Origem | Situação | Proposta |
| --- | --- | --- | --- |
| `--gallery` | E1 | Galeria em página única de rolagem com 12 seções | Manter como único ponto de entrada |
| `--gallery-index` | E1, passo 7 | Rola até o índice; não está no `BUILDING.md` | Virar `--gallery=indice` |
| `--gallery-text-card` | estudo E4.4 | Rola até a caixa de texto | Virar `--gallery=caixa-de-texto` |
| `--gallery-review` | revisão de 26/10 | Rola até a revisão; não está no `BUILDING.md` | Virar `--gallery=revisao` ou ser removida com a seção, se aprovada |
| `--editor-probe` | E4.1 | Sondagem temporária, substituída pelo modo persistente | Remover |
| `--page-model-demo` | E3.5 | Demonstração temporária; `PageTestAdapter` só serve a ela | Remover com o adaptador |
| `--editor-model-demo` | E4.3–E4.7 | É o editor real; sem ele, a página mostra só a prévia E2 | Ver Q1 |
| `--scale=` | E1 | Simula escala | Manter |
| `MTN_CAPTURE` | E2 | Captura a janela e encerra o app | Unificar com o diretório de evidências |
| `MTN_QT_LOG` | E2 | Log de mensagens Qt | Manter e documentar |
| `MTN_E2_CAPTURE_DIR` | E2 | Capturas do Qt Quick Test, com nome de etapa | Renomear para `MTN_CAPTURE_DIR` |

## 3. Build

- Presets `debug`, `release` e `core` em `CMakePresets.json`, mas sem `workflowPresets` e sem preset de sanitizador.
- `build/asan-e33` (64 MB) e `build/asan-e43` (314 MB) foram criados à mão em E3.3 e E4.3. `build/debug` tem só o cache, sem build.
- `build/release` acumula artefatos de sessões: `e2-access-*`, `e2-orca-*`, `e2-package-*`, `e2-scale-*`, `e2-wayland-scale-*`, `e4-*-wayland`, capturas `*.png`, logs `*-qt.log`, `install_manifest.txt` e o `.tar.gz`.
- O 12 registra comandos ad hoc (`cmake -S . -B build/qt …`, `ctest --test-dir …`) como evidência.
- `CMakeLists.txt` exige 3.24, e os presets exigem 3.25.
- As fontes de `apps/desktop` aparecem duas vezes, no app e em `workspace_quick_tests`, e `notebook_schema.cpp` aparece em quatro alvos. Uma biblioteca `desktop_core` (estática) elimina a repetição.
- O CMake 3.25 já suporta `workflowPresets` (`cmake --workflow --preset release` configura, compila e testa) e alvos personalizados que funcionam igual em PowerShell e bash, o que atende o Windows/MSYS2 sem script de shell.

## 4. Testes

- 8 executáveis no `ctest`; a interface inteira está em `tests/qml/tst_workspace.qml` (43 KB, 12 casos num único `TestCase`).
- A ordem depende do nome (`test_z…`, `test_zz…`, até `test_zzzzz…`), porque os casos compartilham o estado do caderno.
- E4.6 e E4.7 rodaram casos isolados, não a suíte. Em Wayland, `test_keyboard_navigation_and_focus_return` falha na linha 108. Em E4.5 a suíte nativa falhava em checagens antigas de pixel da tinta.
- As capturas só saem com `MTN_E2_CAPTURE_DIR`, e o destino varia por sessão.
- `QX1`: a `main` não exige checks no GitHub.

## 5. Pastas e documentos

- `preview/` tem o protótipo HTML anterior ao Qt (`index.html`, `script.js`, `style.css`), o README dele e 30 PNG versionados por sufixo (`-v1`…`-v6`, `g0`, `h0`, `y0`). Os documentos citam 7 imagens: `controls-v1`, `index-v1`, `rich-text-editor-{dark,light}`, `text-card-{dark,light}` e `text-card-gallery-v1`. A pasta está no `.dockerignore`.
- O estado do projeto se repete no 11 (“Próxima sequência” ainda diz T1.1), no 12, no 14 §1 e §7 (parado em E4.5) e no 17.
- `docs/01-layout.md` foi substituído pelo `01-layout-refeito.md`; `docs/ideias.md` está vazio.
- `README.md` e `docs/README.md` estão em inglês; os documentos de `docs/` estão em português.
- Branches locais `codex/e3-6-ci` e `codex/e4-2-ci` e o remoto `ci`, além de `origin/codex/*`, são resíduos de publicação do CI.
- `AGENTS.md` tinha só a regra visual. Não havia `CLAUDE.md`, e cada agente lia instruções diferentes.
