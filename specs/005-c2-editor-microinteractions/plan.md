# Plano — C2 Microinterações do editor e página vazia

**Spec:** [spec.md](spec.md) · **Data:** 2026-10-30

## Resumo

Uma camada de controles (`chromeLayer`) acima da tinta recebe contorno, alças e ações de cada card; superfícies de ferramenta existem só com a ferramenta ativa; a margem do card leva ao texto; o clique fora encerra a edição; o card pode sair do papel pela direita e por baixo; a página some sem página ativa; Inter vira a fonte padrão também nos testes.

## Documentos consultados

| Documento | Seção | O que restringe |
| --- | --- | --- |
| [04](../../docs/04-comportamento-editor-e-organizacao.md) | §5 | `zOrder` e overlays acima do conteúdo; limites horizontais no A4 (alterados aqui) |
| [17](../../docs/17-plano-e4-card-de-texto.md) | Limites | Movimento e largura dentro do papel no A4 (alterados aqui) |
| [13](../../docs/13-estudo-visual.md) | §6.1 | Alças assentadas, contorno neutro, ações só no hover |
| [20](../../docs/20-plano-marco3-objetos-e-diagramas.md) | §2 | Seleção não muda a pintura; só overlays sobem (aprovado 30/10, antecipado) |
| [02](../../docs/02-ferramentas-e-interacoes.md) | §3 | Ferramenta efetiva e cursores |

## Verificação da constituição

| Princípio | Atende? | Como |
| --- | --- | --- |
| I. Sobrevive a fechar e reabrir | Sim | Posição fora do papel persiste pelo mesmo `moveText`; teste de reabertura existente cobre (900, 1000) |
| II. Atividade registrada | Sim | C2 aberto pelo script |
| III. Galeria, sem flags novas | Sim | Entrada em "Em validação" e roteiro; capturas `card-off-paper` e `empty-notebook` |
| IV. Presets e suíte | Sim, com ressalva | Suíte do editor passa; Biblioteca instável antes e depois (T030 da M1) |
| V. Estudo visual no 13 | Sim | Síntese "Microinterações do card (C2)" no 13 §6.1 |
| VI. Evidência honesta | Sim | Hover preso sem reprodução determinística, declarado |
| VII. Escopo protegido | Sim | Esquerda/topo e painel de papel fora |

## Desenho

- `apps/desktop/ui/EditorProbe.qml`: `chromeLayer` (z 4, acima da tinta z 2 e da caneta z 3); `committedExtentRight`; superfícies de texto e caneta com `visible` pela ferramenta; clique fora encerra a edição; textos do papel com `QtRendering`; `onItemRemoved` retira os controles do card removido.
- `apps/desktop/ui/EditorTextCard.qml`: contorno, alças e ações com `parent: chromeParent`, posição somada a `card.x/y`, `z` por seleção só na camada; `z` do card fixo; margem com cursor I e foco no texto; limites `x, y ≥ 0`, largura 120–500 pt.
- `apps/desktop/page_editor_adapter.cpp`: `validTextGeometry` sem limite do A4.
- `apps/desktop/Main.qml`: `pageScene` invisível sem página e largura pela extensão gravada; texto e botão de estado vazio removidos; cursor de pan num `MouseArea` próprio, visível só durante o pan.
- `apps/desktop/app_fonts.*` (novo, em `desktop_core`): registra as fontes e define Inter como padrão; chamado por `main.cpp` e pelo `workspace_quick_tests`.
- Testes: `test_card_microinteractions` e `test_empty_notebook_has_no_paper` em `tests/qml/tst_editor.qml`.

## Validação

- **Automática:** testes do editor; suíte completa.
- **Galeria e roteiro:** `checklists/validation.md`.
- **Plataforma:** cursores e hover no Windows real, pelo dono do produto.

## Riscos e alternativas descartadas

- Elevar o card selecionado acima da tinta: contraria o 04 §5 e a decisão do 20 §2.
- Deslocar a origem da cena para aceitar coordenadas negativas: a cena se moveria sob o ponteiro durante o arraste; adiado.
- Cursor por `enabled`: o Qt mantém o cursor de `MouseArea` desabilitado; trocado por `visible`.
