# Tarefas — {{ID}} {{TITULO}}

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. `[P]` indica tarefa paralelizável e `[USn]` a história atendida. Ao concluir, marque `[x]` e anote a evidência após `→`, por exemplo `→ ctest --preset release 9/9`. Tarefas acrescentadas na convergência entram no fim da fase correspondente, com o próximo número livre.

## Fase 1 — Preparação

- [ ] T001 Ler constituição, spec e plano; confirmar a árvore limpa ou commitar o trabalho anterior de outra atividade

## Fase 2 — US1

- [ ] T002 [US1] …

## Fase N — Fechamento

- [ ] T0xx Suíte completa: `ctest --preset release` (e `core` se o núcleo mudou)
- [ ] T0xx Galeria: seguir `checklists/validacao.md`, marcar os itens técnicos e passar a atividade para **em validação**
- [ ] T0xx Levar as decisões aos documentos donos e resumir no [12](../../docs/12-registro-de-implementacao.md)
- [ ] T0xx Atualizar `specs/README.md` e `.specify/feature.json`; triar `docs/ideias.md`

## Pendências fora desta atividade

- …
