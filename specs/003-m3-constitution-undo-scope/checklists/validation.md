# Validação — M3 Alcance do desfazer na constituição

Estado: **aprovada** pelo dono do produto em 30/10/2026. Mudança só de texto; sem galeria nem capturas.

## Qualidade da especificação (agente)

- [x] Critérios de aceite verificáveis, sem marcas `[PRECISA ESCLARECER]` abertas
- [x] Toda história tem tarefa e toda tarefa serve a uma história
- [x] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [ ] `cmake --workflow --preset release`: não executado; sem CMake nesta máquina (mudança só de documentos)
- [x] `.specify/scripts/check.sh` passou
- Galeria, temas, escalas e teclado: não se aplicam

## Roteiro

| Passo | Onde | O que conferir |
| --- | --- | --- |
| 1 | [Constituição, princípio I](../../../.specify/memory/constitution.md#i-só-conta-o-que-sobrevive-a-fechar-e-reabrir) | O texto diz que o desfazer é de sessão e que conteúdo e posição sobrevivem a reabrir |
| 2 | Constituição, Governança → Histórico | Linha 1.2.1 com motivo e M3 |
| 3 | [ideias](../../../docs/ideias.md) | Entrada do desfazer persistente, depois da beta |

**Texto novo do princípio I:** "Uma função visualmente pronta que perde conteúdo ou posição, ou que perde o histórico de desfazer enquanto o app está aberto, não está entregue. O desfazer vale para a sessão: ao fechar e reabrir, conteúdo e posição voltam íntegros e a pilha de desfazer começa vazia."

## Aprovação (somente o dono do produto marca)

- [x] Texto do princípio I aprovado
- [x] Observações registradas abaixo, ou nenhuma

**Observações do dono do produto:** nenhuma.
