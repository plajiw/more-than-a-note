# Validação — C2 Microinterações do editor e página vazia

**Como conferir:** `cmake --build --preset release` e abrir `.\build\release\more_than_a_note.exe` (com `C:\msys64\ucrt64\bin` no `PATH`), ou a galeria → "Em validação". Capturas em `build/release/evidence/tests/`.

## Qualidade da especificação (agente)

- [x] Critérios de aceite verificáveis, sem marcas `[PRECISA ESCLARECER]` abertas
- [x] Toda história tem tarefa e toda tarefa serve a uma história
- [x] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [ ] `cmake --workflow --preset release` verde: o editor passa; a falha restante é a Biblioteca instável, anterior à C2 (T011)
- [x] Capturas `card-off-paper.png` e `empty-notebook.png` conferidas
- [x] `.specify/scripts/check.sh` passou
- [x] Atividade listada em "Em validação" na galeria, sem opção ou modo novo

## Roteiro (constituição III)

| Passo | O que fazer | Esperado |
| --- | --- | --- |
| 1 | Criar um caderno novo | Só o fundo, sem papel, texto ou botão |
| 2 | Criar seção e página | O papel aparece |
| 3 | Ferramenta Texto; passar o mouse sobre um card | Cursor I sobre todo o card, inclusive a margem; nunca a mira |
| 4 | Clicar na margem do card | Cursor de texto piscando no ponto mais próximo |
| 5 | Clicar fora do card em edição | A edição termina e nenhum card novo nasce; o clique seguinte cria |
| 6 | Caneta; desenhar um traço sobre um card | Mira em toda a página; contorno, alças e botões do card ficam acima do traço |
| 7 | Arrastar um card pela alça para a direita e para baixo, além do papel | Fica onde foi solto; dá para rolar até ele; reabrir a página mantém a posição |
| 8 | Passar o mouse sobre um card não selecionado e sair | Contorno aparece e some; nada fica preso |
| 9 | Trocar de página com um card selecionado | Nenhuma alça "fantasma" sobra na tela |
| 10 | Segurar Espaço e arrastar; soltar | Mão aberta/fechada durante o pan; depois, cursores normais de novo |
| 11 | Menus, índice e barra | Texto em Inter |

## Aprovação (somente o dono do produto marca)

- [ ] Card fora do papel aprovado
- [ ] Caderno vazio aprovado
- [ ] Cursores, caret e clique fora aprovados
- [ ] Controles do card acima da tinta aprovados
- [ ] Hover sem travar
- [ ] Observações registradas abaixo, ou nenhuma

**Observações do dono do produto:**
