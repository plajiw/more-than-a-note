# Tarefas — M3 Alcance do desfazer na constituição

Formato: `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. Ao concluir, marque `[x]` e anote a evidência após `→`.

## Fase 1 — Preparação

- [x] T001 Ler constituição, spec e plano; árvore com trabalho anterior → a árvore contém a M2 sem commit (só documentos, em validação); a M3 toca arquivos distintos, exceto 22 §12.1, ideias, 12 e ROADMAP, onde só acrescenta linhas. `new-activity.sh M3 constitution-undo-scope … manutencao` saída 0.

## Fase 2 — US1

- [x] T002 [US1] Reescrever o princípio I e subir para 1.2.1 em `.specify/memory/constitution.md` → frase nova no princípio I; cabeçalho "Versão 1.2.1 · … última emenda em 30/10/2026"; histórico com "1.2.1 esclarece no princípio I que o histórico de desfazer é de sessão (M3)".
- [x] T003 [US1] Conferir que nenhum documento exige desfazer entre sessões → busca `(desfazer|undo|histórico).{0,60}(reinici|reabr|entre sessões|persist)` em `docs/`: só 09 e 20 citam desfazer e reabrir como passos separados; nenhum conflito.

## Fase 3 — US2

- [x] T004 [US2] Registrar desfazer persistente em `docs/ideias.md` → entrada "Desfazer que sobrevive a reiniciar", triagem depois da beta.

## Fase 4 — Fechamento

- [x] T005 Suíte completa → não executada: esta máquina (Windows 10 Pro) não tem CMake nem MSYS2. Mudança só de documentos.
- [x] T006 `.specify/scripts/check.sh` → saída 0, "ok: regras verificáveis da constituição atendidas."
- [x] T007 Levar decisões aos documentos donos e resumir no [12](../../docs/12-registro-de-implementacao.md) → 22 §12.1 linha 7; seção M3 no 12.
- [x] T008 Atualizar roadmap e `.specify/feature.json` → ROADMAP (onde estamos, checklist, gráfico, índice); feature.json aponta para specs/003.
- [x] T009 Dono do produto aprova o novo texto do princípio I → aprovado em 30/10/2026, itens marcados por ele em checklists/validation.md.

## Pendências fora desta atividade

- Fechamento da M1 (T030) e aprovação da M2.
