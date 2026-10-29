# Validação — M1 Limpeza e ambiente único de validação

**Como conferir:** `cmake --build --preset release --target evidence` gera as capturas em `build/release/evidence/`; `cmake --build --preset release --target gallery` abre a galeria. Detalhes no [BUILDING.md](../../../BUILDING.md).

## Qualidade da especificação (agente)

- [x] Critérios de aceite verificáveis
- [x] Sem marcas `[PRECISA ESCLARECER]` abertas (Q1–Q3 respondidas em 29/10/2026)
- [x] Toda história tem tarefa e toda tarefa serve a uma história
- [x] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [x] `cmake --workflow --preset release`, `core` e `asan` completos a partir de `build/` vazio (T026)
- [x] `--target evidence` gerou 76 capturas sem falha; tinta nativa passou na sessão Wayland
- [x] `.specify/scripts/check.sh` passou
- [x] `git grep` sem opções, variáveis ou pastas removidas fora dos registros históricos
- [x] Galeria abre por alvo e por `--gallery=<seção>`; as 10 seções passam na fumaça, nos dois temas
- [x] Seção Editor só funciona com perfil isolado; cadernos e preferências ficam em `build/release/sandbox`
- [x] Temas grafite e claro e escalas 100% e 150% nas capturas da galeria
- [x] Teclado no índice da galeria: Tab entra, setas percorrem, Enter, Return ou Espaço levam à seção
- [ ] CI Linux e Windows verdes, com os artefatos `evidence-linux` e `evidence-windows` (depende do push, T030)

## Roteiro (constituição III)

| Passo | Onde | Capturas |
| --- | --- | --- |
| 1. Rodar `cmake --build --preset release --target gallery` e percorrer o índice à esquerda | Galeria | `gallery/pending-graphite-100.png` |
| 2. Conferir a lista de pendências: M1, polimento de 26–27/10 e ações do card | Galeria → Em validação | `gallery/pending-light-100.png` |
| 3. Clicar em “Abrir o editor no caderno de amostra”, criar uma caixa, mover, escrever, fechar e reabrir a galeria pelo alvo | Galeria → Editor | `gallery/editor-graphite-100.png`, `tests/editor-text-ink.png` |
| 4. Abrir direto numa seção: `MTN_PROFILE_DIR=build/release/sandbox ./build/release/more_than_a_note --gallery=text-card` | Galeria → Caixa de texto | `gallery/text-card-graphite-100.png`, `gallery/text-card-light-150.png` |
| 5. Ver as maquetes identificadas | Galeria → Índice e Ilhas | `gallery/index-graphite-100.png`, `gallery/islands-light-100.png` |
| 6. Rodar `cmake --build --preset release --target evidence` e abrir a pasta `build/release/evidence/` | Pasta de capturas | `gallery/` (40) e `tests/` (36) |
| 7. Ler o `BUILDING.md` e o roadmap e conferir que bastam para repetir os passos | `BUILDING.md`, `specs/ROADMAP.md` | — |

## Aprovação (somente o dono do produto marca)

- [x] Navegação da galeria e seção “Em validação” aprovadas
- [x] Seção Editor aprovada como ambiente de validação
- [x] Capturas de `evidence` suficientes para conferir sem abrir o app
- [x] `BUILDING.md`, `README.md` e roadmap claros
- [x] Observações registradas abaixo, ou nenhuma

**Observações do dono do produto:** aprovado e validado em 29/10/2026, sem observações.
