# Plano — C1 Botão esquerdo move a tela e rouba o arrasto do card

**Spec:** [spec.md](spec.md) · **Data:** 2026-10-30

## Resumo

Desligar o arrasto embutido do `Flickable` da página (`interactive: false`), levar a rolagem pela roda para o `WheelHandler` que já cuidava do Ctrl+roda, e marcar as alças do card com `preventStealing`. O pan por botão do meio, Espaço e Mão já existe em `pagePanSurface` e não muda.

## Documentos consultados

| Documento | Seção | O que restringe |
| --- | --- | --- |
| [02](../../docs/02-ferramentas-e-interacoes.md) | Tabela de ferramentas, §3, casos de borda | Mão e Espaço movem a tela com o esquerdo; mouse3 sempre; pan fora do histórico |
| [03](../../docs/03-atalhos-e-acessibilidade.md) | Atalhos | "Pan com mouse: botão central segurado + arrastar, independente da ferramenta" |
| [04](../../docs/04-comportamento-editor-e-organizacao.md) | §5 | Texto se move pela alça; corpo seleciona caracteres |
| [BUILDING](../../BUILDING.md) | Requisitos | Qt 6.8 mínimo: sem `Flickable.acceptedButtons` (6.9+) |

## Verificação da constituição

| Princípio | Atende? | Como |
| --- | --- | --- |
| I. Sobrevive a fechar e reabrir | Sim | Só viewport e gesto; conteúdo intocado |
| II. Atividade registrada; tarefas com evidência | Sim | C1 aberto pelo script |
| III. Validação na galeria, sem flags ou modos novos | Sim | Entrada em "Em validação" apontando para a seção Editor; nada novo de linha de comando |
| IV. Presets, suíte completa e artefatos em `build/` | Pendente | Esta máquina não tem CMake; a suíte roda no PC Windows 11 ou no CI |
| V. Estudo visual registrado no 13 | Não se aplica | Sem mudança de aparência; comportamento já estava especificado |
| VI. Evidência honesta | Sim | Nada marcado sem execução |
| VII. Escopo protegido | Sim | Listas da Biblioteca e toque fora de escopo |

## Desenho

- `apps/desktop/Main.qml`: `pageScroll.interactive: false`; o `WheelHandler` irmão de `pagePanSurface` (agora `pageWheel`) aceita qualquer modificador: Ctrl dá zoom ancorado como antes; sem Ctrl rola com `pixelDelta` (touchpad) ou `angleDelta` × `wheelScrollLines` × 20 px por notch; Shift troca vertical por horizontal. Limites iguais aos do pan.
- `apps/desktop/ui/TextCardMoveGrip.qml` e `TextCardResizeGrip.qml`: `preventStealing: true`.
- `apps/desktop/ui/Gallery.qml`: entrada em `pendingReviews`.
- `tests/qml/tst_editor.qml` (`test_viewport_and_infinite_page`): alça move o card sem mover a tela (vários passos de movimento); arrasto esquerdo na faixa acima do papel não move a tela; roda rola; Shift+roda rola na horizontal quando há largura para isso.

## Validação

- **Automática:** `cmake --workflow --preset release`; o CI Linux e Windows.
- **Galeria e roteiro:** `checklists/validation.md`.
- **Plataforma:** touchpad de precisão do Windows e roda de alta resolução, pelo dono do produto.

## Riscos e alternativas descartadas

- `Flickable.acceptedButtons`: existe só a partir do Qt 6.9; o mínimo é 6.8.
- Manter o `Flickable` interativo e só proteger as alças: o arrasto esquerdo no papel continuaria movendo a tela, contra o 02.
- Risco: a velocidade da roda muda em relação ao `Flickable` padrão; conferir no roteiro.
