# Validação — C2 Microinterações do editor e página vazia

**Como conferir:** `cmake --build --preset release` e abrir `.\build\release\more_than_a_note.exe` (com `C:\msys64\ucrt64\bin` no `PATH`), ou a galeria → "Em validação". Capturas em `build/release/evidence/tests/`.

## Qualidade da especificação (agente)

- [x] Critérios de aceite verificáveis, sem marcas `[PRECISA ESCLARECER]` abertas
- [x] Toda história tem tarefa e toda tarefa serve a uma história
- [x] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [x] `cmake --workflow --preset release` verde: na época, só a Biblioteca instável falhava, anterior à C2 (T011); 8/8 em 31/10/2026, depois da T047 da M1 (Windows 10, Qt 6.12)
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

- [x] Card fora do papel aprovado
- [x] Caderno vazio aprovado
- [x] Cursores, caret e clique fora aprovados
- [x] Controles do card acima da tinta aprovados
- [x] Hover sem travar
- [x] Observações registradas abaixo, ou nenhuma

**Observações do dono do produto:** aprovado em 31/10/2026. O dono do produto informou na sessão que as pendências de C1, C2 e C3 estavam resolvidas e pediu que fossem confirmadas; os itens acima foram marcados a pedido dele. Parte do comportamento foi refeita pela C3 (caixa fina, cursores, Espaço).
