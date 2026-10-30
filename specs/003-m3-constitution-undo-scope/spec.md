# M3 — Alcance do desfazer na constituição

- **Tipo:** manutencao
- **Estado:** aprovada
- **Aberta em:** 2026-10-30
- **Origem:** decisão 7 da M2 ([22 §12.1](../../docs/22-arquitetura-editor-visual-unificado.md#121-respostas-do-dono-do-produto-30102026)), aceita pelo dono do produto em 30/10/2026
- **Documentos donos:** [constituição](../../.specify/memory/constitution.md) (princípio I e histórico), [ideias](../../docs/ideias.md)

> **Nome:** esta manutenção M3 não tem relação com o Marco 3 nem com os cortes M3.1–M3.10 do [20](../../docs/20-plano-marco3-objetos-e-diagramas.md). O ID segue a numeração de manutenções do fluxo.

## Problema e objetivo

O princípio I dizia que uma função que "perde conteúdo, posição ou histórico" não está entregue. "Histórico" admitia duas leituras: a pilha de desfazer da sessão ou um desfazer que sobrevive a fechar e reabrir o app. O editor implementa a primeira (E4.7). A M2 apontou que, na segunda leitura, nenhum portão poderia ser declarado atendido.

O dono do produto escolheu esclarecer o texto: o desfazer vale durante a sessão e o conteúdo nunca se perde. É o comportamento de OneNote, Excalidraw e Xournal. Desfazer persistente vai para depois da beta.

## Histórias

### US1 — Princípio I sem ambiguidade (P1)

Agentes e o dono do produto leem o princípio I e sabem o que precisa sobreviver a fechar e reabrir.

**Critérios de aceite**

1. **Dado** o princípio I, **quando** alguém pergunta se a pilha de desfazer deve sobreviver ao reinício, **então** o texto responde que não: desfazer é de sessão, conteúdo e posição voltam íntegros.
2. **Dado** o histórico de versões, **então** a 1.2.1 aparece como correção (SemVer), com o motivo e a atividade.

### US2 — Alternativa guardada (P2)

O desfazer persistente fica registrado como ideia para depois da beta, sem entrar no MVP.

**Critérios de aceite**

1. **Dado** o `docs/ideias.md`, **então** há uma entrada com a triagem "depois da beta" e o motivo.

## Casos de borda

- Perder a pilha de desfazer **durante** a sessão (por exemplo, ao trocar de página e voltar) continua sendo falha de entrega.
- Recuperação após crash é conteúdo (E6), não histórico de desfazer.

## Fora de escopo

- Qualquer mudança de código ou de formato.
- O fechamento da M1 e a aprovação da M2.

## Esclarecimentos

Nenhum aberto.

## Critérios de sucesso

`check.sh` passa; o princípio I tem uma única leitura; o dono do produto aprova o texto.
