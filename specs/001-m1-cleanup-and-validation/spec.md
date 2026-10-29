# M1 — Limpeza e ambiente único de validação

- **Tipo:** manutenção
- **Estado:** aprovada (29/10/2026); fecha após o CI (T030)
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
5. **Dado** que o agente ou eu queremos prints, **quando** executamos o comando de evidências, **então** cada seção da galeria é capturada nos dois temas e a 100% e 150%, com nomes estáveis em `build/<preset>/evidence/gallery/`. Ninguém precisa improvisar uma captura.
6. **Dado** atividades com estado **em validação**, **quando** abro a galeria, **então** uma seção “Em validação” lista essas atividades com a seção e o checklist de cada uma. Não existem mais seções datadas como “Revisão 26/10”.
7. **Dado** uma seção da galeria, **quando** ela mostra um componente que já existe no app, **então** usa o componente real; o que ainda é maquete está marcado como tal.

### US2 — Um caminho de build e teste (P1)

Como qualquer agente ou pessoa, sigo o `BUILDING.md` e obtenho o mesmo resultado em qualquer sessão, sem inventar comandos.

**Critérios de aceite**

1. **Dado** um clone limpo, **quando** executo o fluxo documentado (configurar, compilar, testar), **então** ele usa apenas presets e a suíte completa passa em offscreen.
2. **Dado** que preciso de sanitizadores, **quando** procuro como rodar, **então** existe um preset `asan` em `build/asan`, e não `build/asan-e33` ou `build/asan-e43`.
3. **Dado** o `CMakeLists.txt`, **quando** leio as fontes do app, **então** cada arquivo de `apps/desktop` aparece uma única vez, numa biblioteca usada pelo app e pelos testes.
4. **Dado** os testes de interface, **quando** rodo `ctest --preset release`, **então** todos os casos passam juntos, sem depender de ordem alfabética (`test_zzzz…`), cada um com seu próprio perfil temporário.
5. **Dado** que quero capturas para revisão, **quando** uso o comando documentado, **então** as imagens vão para `build/<preset>/evidence/` por uma única variável (`MTN_CAPTURE_DIR`), sem nome de etapa.
6. **Dado** um erro de QML (binding, `TypeError`, `ReferenceError`) em qualquer tela ou seção da galeria, **quando** a suíte roda, **então** ela falha. Um teste de fumaça abre todas as seções da galeria nos dois temas.
7. **Dado** uma checagem que só vale em sessão nativa, **quando** a suíte roda em offscreen, **então** ela aparece como pulada (`SKIP`) com motivo, e não passa em silêncio.
8. **Dado** o CI Linux e Windows, **quando** ele roda, **então** inclui o preset `asan` no Linux e publica as capturas como artefato, inclusive do Windows.

### US3 — Pastas e artefatos organizados (P2)

Como dono do produto, sei onde está cada coisa e o que pode ser apagado.

**Critérios de aceite**

1. **Dado** a pasta `build/`, **quando** a limpeza termina, **então** só existem diretórios de presets, e o `BUILDING.md` diz como recriá-los.
2. **Dado** a pasta `preview/`, **quando** a limpeza termina, **então** cada imagem citada por documentos continua acessível pelo mesmo link ou por um link atualizado, e o restante segue a decisão de Q2.
3. **Dado** as branches locais `codex/*`, **quando** a limpeza termina, **então** as já integradas ou abandonadas foram removidas com a confirmação do dono do produto.

### US4 — Documentação sem estado duplicado (P2)

Como agente numa sessão nova, encontro o estado do projeto em um lugar e as regras em outro.

**Critérios de aceite**

1. **Dado** `specs/ROADMAP.md`, **quando** procuro o estado de uma etapa, **então** ele é a fonte. O 14 §1 e §7 e o 11 “Próxima sequência” apontam para ele, em vez de repetir status.
2. **Dado** `docs/01-layout.md`, que foi substituído, e `docs/ideias.md`, que está vazio, **quando** a limpeza termina, **então** o primeiro está marcado como histórico ou removido e o segundo tem o cabeçalho de triagem do 14 §10.
3. **Dado** o `BUILDING.md`, **quando** leio “App options”, **então** só aparecem as opções que existem depois da limpeza.
4. **Dado** qualquer sessão ou agente, **quando** roda `.specify/scripts/check.sh`, **então** o script aponta violações das regras verificáveis da constituição: atividade ativa inexistente, esclarecimento aberto em atividade planejada, opção ou variável fora da lista fechada, build fora dos presets e commit sem ID de atividade. O CI Linux roda o mesmo script.
5. **Dado** o [roadmap vivo](../ROADMAP.md), **quando** uma atividade abre, conclui uma fase, vai para validação ou fecha, **então** o texto, o checklist e o gráfico mostram o mesmo estado, com desvios e manutenções como ramos que saem do ponto de origem e voltam ao fechar.

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
- **Q2 — `preview/`.** Remover o protótipo HTML (`index.html`, `script.js`, `style.css`), o README dele e as capturas não citadas, que continuam no histórico do git. As 7 imagens citadas vão para `docs/imagens/`, com os links atualizados. Daqui em diante, a evidência aprovada fica em `specs/NNN-…/evidence/`.
- **Q3 — branches.** Remover as branches locais `codex/e3-6-ci` e `codex/e4-2-ci` e o remoto `ci`. As branches `origin/codex/*` ficam, porque o 12 cita links delas como evidência de CI; apagar só com confirmação explícita e troca dos links por commits.
- **Autonomia, 29/10/2026.** O dono do produto deu autonomia total às decisões da M1, com estas exigências: ambiente limpo, sem os resíduos anteriores; build, teste local e validação simples; comandos e estrutura de pastas em inglês e documentos em pt-BR; testes visuais sempre roteirizados; build limpo e padronizado em Linux, Windows e macOS; e todos os pontos levantados garantidos. Decisões tomadas a partir disso:
  - IDs, alvos, scripts e pastas renomeados para o inglês (T044); `BUILDING.md` e os dois `README` reescritos em pt-BR.
  - `evidence` sempre renderiza em offscreen, porque uma janela coberta no Wayland deixa de receber quadros e a posição da janela muda o resultado (T012, T036). Só a tinta, que o renderizador de software não desenha, roda na sessão gráfica.
  - Preferências também ficam no perfil isolado (T042). `make_e2_fixture.py` sai em favor do caderno de amostra (T018).
  - Roteiro obrigatório no `checklists/validation.md` e constituição 1.2.0 (T025, T045).
- **Caminho comum de evidência.** O agente roda testes à vontade, e os testes automatizados continuam. Capturas e confirmações usam sempre o caminho fixo da constituição III: suíte por preset, comando de evidências em `build/<preset>/evidence/` e galeria.

## Critérios de sucesso

- Um agente numa sessão nova, lendo só `AGENTS.md` e `BUILDING.md`, compila, roda a suíte completa e abre a galeria na seção certa sem perguntar nada.
- `ctest --preset release` passa por completo em offscreen. Com a captura habilitada, as imagens saem em `build/release/evidence/`.
- `git grep` não encontra `--gallery-index`, `--gallery-text-card`, `--gallery-review`, `--editor-probe`, `--page-model-demo`, `MTN_E2_CAPTURE_DIR`, `asan-e33` ou `asan-e43` fora do histórico do [12](../../docs/12-registro-de-implementacao.md).
- O dono do produto aprova a navegação da galeria e a seção do editor no `checklists/validation.md`.
