# Validação — {{ID}} {{TITULO}}

**Como conferir:** `cmake --build --preset release --target evidence` gera as capturas em `build/release/evidence/`; `cmake --build --preset release --target gallery` abre a galeria. Detalhes no [BUILDING.md](../../../BUILDING.md).

## Qualidade da especificação (agente)

- [ ] Critérios de aceite verificáveis, sem marcas `[PRECISA ESCLARECER]` abertas
- [ ] Toda história tem tarefa e toda tarefa serve a uma história
- [ ] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [ ] `cmake --workflow --preset release` passou; resultado anotado no `tasks.md`
- [ ] `--target evidence` gerou as capturas do roteiro abaixo, sem falha
- [ ] `.specify/scripts/check.sh` passou
- [ ] Cenário visível na galeria, sem opção ou modo novo; atividade listada em “Em validação”
- [ ] Temas grafite e claro; escalas 100% e 150%
- [ ] Teclado: Tab, Esc e retorno de foco; nomes acessíveis

## Roteiro (constituição III)

Cada passo diz onde conferir e qual captura o comprova.

| Passo | Onde | Capturas |
| --- | --- | --- |
| 1. … | Galeria → seção `…` | `gallery/<seção>-graphite-100.png`, `tests/<nome>.png` |

## Aprovação (somente o dono do produto marca)

- [ ] Aparência aprovada
- [ ] Comportamento aprovado
- [ ] Observações registradas abaixo, ou nenhuma

**Observações do dono do produto:**
