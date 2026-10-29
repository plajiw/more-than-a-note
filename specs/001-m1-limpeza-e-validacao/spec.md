# M1 — Limpeza e ambiente único de validação

- **Tipo:** manutenção
- **Estado:** planejada
- **Aberta em:** 2026-10-29
- **Origem:** pedido do dono do produto após E4.7. Antecede E4.8 para que todo o trabalho seguinte use o mesmo caminho de build, teste e validação.
- **Documentos donos:** `BUILDING.md`, [14](../../docs/14-plano-de-evolucao-e-experimentos.md) (§1, §6 e §7), [11](../../docs/11-tarefas-de-implementacao.md), [docs/README](../../docs/README.md), `AGENTS.md`, constituição

## Problema e objetivo

Cada sessão e cada agente compilou, testou e demonstrou o trabalho de um jeito: oito flags de linha de comando, três variáveis de ambiente, pastas de build fora dos presets, capturas e logs espalhados em `build/release`, testes de interface executados um por um e o estado do projeto repetido em quatro documentos. O dono do produto não tem um lugar fixo para ver o que está pendente de aprovação, e um agente novo não sabe qual caminho é o oficial. O inventário completo está em [research.md](research.md).

**Objetivo:** um único caminho para compilar, testar e validar, e a galeria como o ambiente onde o dono do produto confere e aprova. Sem mudar o comportamento do produto nem os dados de cadernos.

## Histórias

### US1 — A galeria como único ambiente de validação (P1)

Como dono do produto, abro a galeria com um comando e encontro, em seções nomeadas, tudo o que preciso conferir, inclusive o editor de página. Não preciso lembrar de flags específicas.

**Critérios de aceite**

1. **Dado** um build do preset `release`, **quando** executo o comando documentado da galeria, **então** ela abre com um índice de seções e consigo ir direto a qualquer uma, como componentes, toolbar, caixa de texto, índice, ilhas, tipografia ou editor.
2. **Dado** o comando com o nome de uma seção, **quando** a galeria abre, **então** ela já está posicionada nessa seção. Isso substitui `--gallery-index`, `--gallery-text-card` e `--gallery-review`.
3. **Dado** que preciso validar o editor persistente, **quando** abro a seção correspondente, **então** ele roda sobre um caderno de amostra isolado, sem tocar nos meus cadernos reais. Ver Q1.
4. **Dado** o código depois da limpeza, **quando** procuro modos de demonstração, **então** `--editor-probe`, `--page-model-demo` e seu código morto (`PageTestAdapter`, caminhos de `Main.qml`) não existem mais, e `--editor-model-demo` foi substituído conforme Q1.

### US2 — Um caminho de build e teste (P1)

Como qualquer agente ou pessoa, sigo o `BUILDING.md` e obtenho o mesmo resultado em qualquer sessão, sem inventar comandos.

**Critérios de aceite**

1. **Dado** um clone limpo, **quando** executo o fluxo documentado (configurar, compilar, testar), **então** ele usa apenas presets e a suíte completa passa em offscreen.
2. **Dado** que preciso de sanitizadores, **quando** procuro como rodar, **então** existe um preset `asan` em `build/asan`, e não `build/asan-e33` ou `build/asan-e43`.
3. **Dado** o `CMakeLists.txt`, **quando** leio as fontes do app, **então** cada arquivo de `apps/desktop` aparece uma única vez, numa biblioteca usada pelo app e pelos testes.
4. **Dado** os testes de interface, **quando** rodo `ctest --preset release`, **então** todos os casos passam juntos, sem depender de ordem alfabética (`test_zzzz…`), cada um com seu próprio perfil temporário.
5. **Dado** que quero capturas para revisão, **quando** uso o comando documentado, **então** as imagens vão para `build/<preset>/evidencias/` por uma única variável (`MTN_CAPTURE_DIR`), sem nome de etapa.

### US3 — Pastas e artefatos organizados (P2)

Como dono do produto, sei onde está cada coisa e o que pode ser apagado.

**Critérios de aceite**

1. **Dado** a pasta `build/`, **quando** a limpeza termina, **então** só existem diretórios de presets, e o `BUILDING.md` diz como recriá-los.
2. **Dado** a pasta `preview/`, **quando** a limpeza termina, **então** cada imagem citada por documentos continua acessível pelo mesmo link ou por um link atualizado, e o restante segue a decisão de Q2.
3. **Dado** as branches locais `codex/*`, **quando** a limpeza termina, **então** as já integradas ou abandonadas foram removidas com a confirmação do dono do produto.

### US4 — Documentação sem estado duplicado (P2)

Como agente numa sessão nova, encontro o estado do projeto em um lugar e as regras em outro.

**Critérios de aceite**

1. **Dado** `specs/README.md`, **quando** procuro o estado de uma etapa, **então** ele é a fonte. O 14 §1 e §7 e o 11 “Próxima sequência” apontam para ele, em vez de repetir status.
2. **Dado** `docs/01-layout.md`, que foi substituído, e `docs/ideias.md`, que está vazio, **quando** a limpeza termina, **então** o primeiro está marcado como histórico ou removido e o segundo tem o cabeçalho de triagem do 14 §10.
3. **Dado** o `BUILDING.md`, **quando** leio “App options”, **então** só aparecem as opções que existem depois da limpeza.

## Casos de borda

- **E4.7 ainda não commitada:** quatro QML e três documentos modificados. Ela é commitada como baseline antes de qualquer mudança da M1, ou o dono do produto decide o que fazer com ela.
- **Windows (MSYS2/PowerShell):** o comando da galeria e o fluxo de build precisam funcionar sem bash. Daí a preferência por presets e alvos CMake em vez de scripts de shell.
- **CI:** a mudança de presets e de alvos de teste não pode quebrar os workflows Linux (Docker) e Windows.
- **Testes nativos (Wayland):** checagens de pixel que só funcionam fora do offscreen ficam marcadas e são puladas no offscreen, nunca falham em silêncio.

## Fora de escopo

- Qualquer mudança de comportamento ou aparência do produto, e o acabamento da galeria além da navegação por seções.
- QX3 (regressão visual automática no CI) fica para E7. A M1 só prepara as capturas num lugar previsível.
- Renomear `InkProbeItem` e `EditorProbe` para nomes de produto. Anotar em `docs/ideias.md`.
- Reescrever o 01 a partir do 13, que já está planejado para E7.

## Esclarecimentos

Respostas do dono do produto em 29/10/2026, aceitando as recomendações:

- **Q1 — editor e galeria.** O editor persistente passa a ser o comportamento padrão do app, e `--editor-model-demo` deixa de existir. A galeria ganha a seção “Editor”, que abre a janela principal sobre um perfil isolado em `build/<preset>/sandbox`, com caderno de amostra; os cadernos reais nunca são tocados.
- **Q2 — `preview/`.** Remover o protótipo HTML (`index.html`, `script.js`, `style.css`), o README dele e as capturas não citadas, que continuam no histórico do git. As 7 imagens citadas vão para `docs/imagens/`, com os links atualizados. Daqui em diante, a evidência aprovada fica em `specs/NNN-…/evidencias/`.
- **Q3 — branches.** Remover as branches locais `codex/e3-6-ci` e `codex/e4-2-ci` e o remoto `ci`. As branches `origin/codex/*` ficam, porque o 12 cita links delas como evidência de CI; apagar só com confirmação explícita e troca dos links por commits.
- **Caminho comum de evidência.** O agente roda testes à vontade, e os testes automatizados continuam. Capturas e confirmações usam sempre o caminho fixo da constituição III: suíte por preset, comando de evidências em `build/<preset>/evidencias/` e galeria.

## Critérios de sucesso

- Um agente numa sessão nova, lendo só `AGENTS.md` e `BUILDING.md`, compila, roda a suíte completa e abre a galeria na seção certa sem perguntar nada.
- `ctest --preset release` passa por completo em offscreen. Com a captura habilitada, as imagens saem em `build/release/evidencias/`.
- `git grep` não encontra `--gallery-index`, `--gallery-text-card`, `--gallery-review`, `--editor-probe`, `--page-model-demo`, `MTN_E2_CAPTURE_DIR`, `asan-e33` ou `asan-e43` fora do histórico do [12](../../docs/12-registro-de-implementacao.md).
- O dono do produto aprova a navegação da galeria e a seção do editor no `checklists/validacao.md`.
