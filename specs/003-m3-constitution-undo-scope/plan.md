# Plano — M3 Alcance do desfazer na constituição

**Spec:** [spec.md](spec.md) · **Data:** 2026-10-30

## Resumo

Reescrever uma frase do princípio I, subir a versão para 1.2.1 (correção: só esclarece) e registrar o desfazer persistente no `ideias.md`. Nenhum código muda.

## Documentos consultados

| Documento | Seção | O que restringe |
| --- | --- | --- |
| [Constituição](../../.specify/memory/constitution.md) | I e Governança | Emenda só por manutenção; SemVer |
| [22](../../docs/22-arquitetura-editor-visual-unificado.md) | §12, decisão 7 | Origem e escolha do dono do produto |
| `docs/` (busca por desfazer/undo + reabrir/reiniciar) | 06, 09, 10, 14, 20 | Nenhum exige desfazer entre sessões; 09 e 20 pedem desfazer e reabrir como operações separadas |

## Verificação da constituição

| Princípio | Atende? | Como |
| --- | --- | --- |
| I. Sobrevive a fechar e reabrir | Sim | Esclarecido; conteúdo e posição continuam exigidos |
| II. Atividade registrada; tarefas com evidência | Sim | M3 aberta pelo script; tarefas com evidência |
| III. Validação na galeria, sem flags ou modos novos | Não se aplica | Sem mudança visível; aprovação é do texto |
| IV. Presets, suíte completa e artefatos em `build/` | Não se aplica, com ressalva | Só documentos; esta máquina não tem CMake (ver tasks) |
| V. Estudo visual registrado no 13 | Não se aplica | Sem interface |
| VI. Evidência honesta; pendências listadas | Sim | Suíte não executada registrada como tal |
| VII. Escopo protegido; mudanças de rumo marcadas | Sim | Desfazer persistente vai para depois da beta, em ideias |

## Desenho

Arquivos: `.specify/memory/constitution.md` (cabeçalho, princípio I, histórico), `docs/ideias.md`, `docs/22-arquitetura-editor-visual-unificado.md` §12.1, `docs/12-registro-de-implementacao.md`, `specs/ROADMAP.md`.

## Validação

- **Automática:** `.specify/scripts/check.sh`.
- **Galeria:** não se aplica.
- **Dono do produto:** aprovar o novo texto do princípio I.

## Riscos e alternativas descartadas

- **Entrega de desfazer persistente:** descartada para a beta; aumenta o arquivo, complica migração e é rara nas referências.
