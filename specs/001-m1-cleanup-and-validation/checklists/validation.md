# Validação — M1 Limpeza e ambiente único de validação

**Como abrir:** `cmake --build --preset release --target gallery`, ou `./build/release/more_than_a_note --gallery=<seção>` para uma seção específica. Os comandos só existem depois das tarefas T007 e T015.

## Qualidade da especificação (agente)

- [x] Critérios de aceite verificáveis
- [x] Sem marcas `[PRECISA ESCLARECER]` abertas (Q1–Q3 respondidas em 29/10/2026)
- [x] Toda história tem tarefa e toda tarefa serve a uma história
- [x] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [ ] `cmake --workflow --preset release`, `core` e `asan` completos; resultado no `tasks.md`
- [ ] `git grep` sem flags, variáveis ou pastas removidas
- [ ] Galeria abre por alvo e por `--gallery=<seção>` em todas as seções
- [ ] Seção Editor não altera o perfil real (comparar a pasta de dados do usuário antes e depois)
- [ ] Temas grafite e claro; escalas 100% e 150%; Tab e Esc no índice da galeria
- [ ] Alvo `evidence` gera as capturas da galeria (seção × tema × escala) e as dos testes em `build/release/evidence/`
- [ ] Fumaça da galeria e `failOnWarning` ativos; pulos nativos aparecem como `SKIP` com motivo
- [ ] `.specify/scripts/verificar.sh` passa localmente e no CI Linux; artefatos de captura publicados nos dois CIs

## Aprovação (somente o dono do produto marca)

1. Rodar o comando acima e percorrer o índice de seções.
2. Abrir `--gallery=caixa-de-texto` e conferir que cai na seção certa.
3. Na seção Editor, abrir o caderno de amostra, criar e mover uma caixa, fechar e reabrir a galeria.
4. Ler o `BUILDING.md` e conferir que ele basta para repetir os passos.

- [ ] Navegação da galeria aprovada
- [ ] Seção Editor aprovada como ambiente de validação
- [ ] `BUILDING.md` claro
- [ ] Observações registradas abaixo, ou nenhuma

**Observações do dono do produto:**
