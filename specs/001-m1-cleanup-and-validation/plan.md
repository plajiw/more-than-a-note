# Plano — M1 Limpeza e ambiente único de validação

**Spec:** [spec.md](spec.md) · **Pesquisa:** [research.md](research.md) · **Data:** 2026-10-29

## Resumo

Primeiro se fixa a base de build (presets de workflow, preset `asan`, biblioteca única das fontes desktop, diretório de evidências). Em seguida, os testes de interface se tornam independentes de ordem, para que a suíte completa seja a evidência padrão. Depois a galeria vira o único ponto de entrada de validação, com índice de seções, `--gallery=<seção>` e uma seção de editor sobre perfil isolado; os modos de demonstração obsoletos saem. Por fim, pastas e documentos são limpos. Nenhum comportamento de produto muda, exceto o editor virar o padrão, se Q1 for aceita.

## Documentos consultados

| Documento | Seção | O que restringe |
| --- | --- | --- |
| Constituição | III, IV | Entradas do executável e caminho de build únicos |
| [14](../../docs/14-plano-de-evolucao-e-experimentos.md) | §2.2, §6, §10 | “Tudo no app real”: a galeria é a bancada, não uma versão paralela |
| [13](../../docs/13-estudo-visual.md) | §6 | Componentes e tokens para o índice da galeria |
| `BUILDING.md` | Presets, App options | Documento que recebe os comandos finais |
| `.github/workflows/*`, `Dockerfile` | — | Não podem quebrar |

## Verificação da constituição

| Princípio | Atende? | Como |
| --- | --- | --- |
| I. Sobrevive a fechar e reabrir | Sim | Não altera esquema nem formato; a suíte de reabertura continua obrigatória |
| II. Atividade registrada | Sim | Esta pasta; commits prefixados `M1:` |
| III. Galeria única, sem flags novas | Sim, com exceção justificada | A M1 **define** a lista fechada de entradas: `--gallery[=seção]`, `--scale=`, `MTN_PROFILE_DIR`, `MTN_CAPTURE_DIR` e `MTN_QT_LOG`. `MTN_PROFILE_DIR` é nova e substitui o uso solto de `XDG_*`, que não existe no Windows. A lista entra no `BUILDING.md` e na constituição 1.1.0 |
| IV. Presets e suíte completa | Sim | É o objetivo da US2 |
| V. Estudo visual | Parcial | O índice da galeria é ferramenta interna; reaproveita `IndexRow`/`SelectList` e tokens existentes, com nota curta no 13 §6.1 e sem padrão novo |
| VI. Evidência honesta | Sim | T002 registra as falhas que já existiam antes da M1 |
| VII. Escopo protegido | Sim | Renomear `InkProbeItem`/`EditorProbe` e QX3 ficam fora (spec, Fora de escopo) |

## Desenho

### Build (US2)

- `CMakePresets.json`:
  - preset `asan` (Debug, `-fsanitize=address,undefined -fno-omit-frame-pointer`, `build/asan`; só Linux, por condição `hostSystemName`) e testPreset `asan` com `ASAN_OPTIONS=detect_leaks=1:halt_on_error=1` e `UBSAN_OPTIONS=halt_on_error=1`;
  - `workflowPresets` `release`, `core` e `asan`: um comando configura, compila e testa (`cmake --workflow --preset release`).
- `CMakeLists.txt`: `cmake_minimum_required(VERSION 3.25)`. Biblioteca estática `desktop_core` com todas as fontes de `apps/desktop` menos `main.cpp`; app e testes passam a ligá-la, e as listas repetidas somem. Os testes que hoje compilam só `notebook_schema` e `page_repository` também podem ligar `desktop_core`, desde que o tempo de link não pese; se pesar, manter as listas mínimas.
- Alvos personalizados, iguais em PowerShell e bash:
  - `gallery`: executa o app com `--gallery` e `MTN_PROFILE_DIR=<build>/sandbox`;
  - `evidence`: roda o Qt Quick Test com `MTN_CAPTURE_DIR=<build>/evidence`.
  - Uso: `cmake --build --preset release --target gallery`.
- `main.cpp`:
  - `--gallery[=seção]` substitui as três variantes;
  - `MTN_PROFILE_DIR`, quando definido, redireciona dados e configurações por `QStandardPaths`/`QSettings` antes de criar o `NotebookStore`;
  - `MTN_CAPTURE` passa a `MTN_CAPTURE_DIR`, com a captura salva em `<dir>/<janela>.png`.

### Testes (US2)

- Separar `tst_workspace.qml` por área: `tst_library_navigation.qml`, `tst_editor.qml`, `tst_gallery.qml` e `tst_native_ink.qml`, sobre a base `AppTestCase.qml`. O `quick_test_main` já roda todos os `tst_*.qml` do diretório.
- Cada arquivo recebe o próprio perfil no `qmlEngineAvailable` do setup C++, e cada teste de editor trabalha em páginas novas; isso elimina a dependência dos prefixos `z`.
- Checagens de pixel que só valem em sessão nativa usam `skip("requer sessão nativa")` no offscreen.
- A falha de foco do índice (linha 108) não se reproduziu na linha de base (T002).
- Os 9 desvios `if (!isOffscreen())` viram `skip()` com motivo, em casos separados das checagens que valem em qualquer plataforma.
- `failOnWarning` com expressões para erros de QML em todos os `TestCase`; os avisos aceitos ficam numa lista explícita.
- Fumaça da galeria: um `TestCase` instancia `Gallery` e percorre todos os IDs de seção nos dois temas.
- Os casos de `--page-model-demo` e `--editor-probe` saem junto com os modos.

### Galeria (US1)

- Índice de seções à esquerda, no padrão das ilhas, com âncoras para os cabeçalhos que já existem. `--gallery=<id>` rola até a seção.
- Seção **Editor**, conforme Q1: botão “Abrir editor com caderno de amostra”, habilitado só sob `MTN_PROFILE_DIR`. Ele cria o caderno de amostra pelo `NotebookStore` (C++, sem Python, para funcionar no Windows) e mostra a janela principal nele.
- `--editor-model-demo` sai e o editor vira o padrão, conforme Q1. Saem também `--editor-probe`, `--page-model-demo`, `PageTestAdapter`, `startWithEditorProbe` e os ramos correspondentes de `Main.qml`. `tests/fixtures/make_e2_fixture.py` é substituído pelo caderno de amostra ou mantido só se algum documento depender dele.

- **Capturas pelo caminho comum.** O alvo `evidence` roda o Qt Quick Test com `MTN_CAPTURE_DIR` e, depois, o app com `--gallery` num modo de captura que percorre seções × temas × escalas. Esse modo é ligado pela própria `MTN_CAPTURE_DIR`, sem flag nova. As escalas usam processos separados (`--scale=1.5`), porque o fator de escala é fixado na inicialização.
- **Seção “Em validação”.** Lista fixa no QML, mantida na mesma mudança que passa uma atividade para **em validação**; ler `specs/` em tempo de execução acoplaria o app ao repositório. A seção “Revisão 26/10” é desmontada: o aprovado vai para a seção do componente.

### Automação das regras

- `.specify/scripts/check.sh` (bash; no Windows, pelo bash do MSYS2 ou do Git) implementa as checagens da US4.4 e roda no CI Linux. O fluxo passa a exigi-lo nos passos 7 e 9.
- O CI Linux também roda `cmake --workflow --preset asan`. Os dois CIs enviam `build/release/evidence/` como artefato.

### Pastas e documentos (US3, US4)

- `build/`: remover `asan-e33`, `asan-e43` e `debug` (vazio), e esvaziar os artefatos de sessão de `build/release` reconfigurando o preset. São só saídas geradas.
- `preview/`, conforme Q2. Branches, conforme Q3.
- `BUILDING.md`: nova seção “Validar na galeria”, “App options” com a lista fechada, preset `asan` e workflow.
- 14 §1 e §7 e 11 “Próxima sequência”: trocar o texto de estado por links para `specs/ROADMAP.md`. `docs/README.md`: apontar `specs/` e `.specify/`. `docs/01-layout.md`: aviso de documento substituído no topo. `docs/ideias.md`: cabeçalho e modelo de entrada.
- O 12 mantém os comandos antigos como histórico e recebe o resumo da M1.

## Validação

- **Automática:** `cmake --workflow --preset release`, `--preset core` e `--preset asan` passando completos. A suíte de interface também roda em sessão nativa Wayland, com os pulos explícitos contados.
- **Galeria:** índice de seções, `--gallery=<seção>` para cada seção, seção Editor sobre o caderno de amostra sem tocar o perfil real, nos dois temas e a 150%.
- **CI:** Linux e Windows verdes na branch da M1, depois de o dono do produto autorizar o push.
- **Plataforma:** o alvo `gallery` no Windows/MSYS2 depende de execução manual em Windows; fica pendente se não houver máquina.

## Riscos e alternativas descartadas

- **Script `dev.sh`/`dev.ps1`:** descartado. Seriam dois scripts para manter; presets e alvos CMake já são multiplataforma.
- **`QStandardPaths::setTestModeEnabled`** para o perfil isolado: descartado, porque mistura com a pasta de testes do Qt (`~/.qttest`) e não é configurável.
- **Separar os testes muda o tempo da suíte:** medir antes (T002) e depois.
- **Tornar o editor padrão (Q1)** muda o que o usuário vê sem flag. É decisão do dono do produto, não da limpeza.
