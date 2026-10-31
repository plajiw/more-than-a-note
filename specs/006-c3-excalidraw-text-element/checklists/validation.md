# Validação — C3 Card de texto no estilo Excalidraw

Estado: **aprovada** pelo dono do produto em 31/10/2026. Para conferir: `cmake --build --preset release` e abrir `.\build\release\more_than_a_note.exe` (com `C:\msys64\ucrt64\bin` no `PATH`), ou a galeria → "Em validação" → seção Editor. Capturas em `build/release/evidence/tests/` (`text-tool-caret`, `text-box-selected`, `text-box-rotated-90`).

**Atenção:** abrir um caderno e gravar nele o converte para o formato v5. Cards antigos continuam com a mesma aparência (largura fixa).

## Qualidade da especificação (agente)

- [x] Critérios de aceite verificáveis, sem marcas `[PRECISA ESCLARECER]` abertas
- [x] Toda história tem tarefa e toda tarefa serve a uma história
- [x] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [x] `cmake --workflow --preset release` passou: 8/8
- [x] `--target evidence` gerou as capturas sem falha
- [x] `.specify/scripts/check.sh` passou
- [x] Atividade listada em "Em validação" na galeria, sem opção ou modo novo
- [ ] Temas grafite e claro; escala 150% física (roteiro do dono do produto). Fica como pendência de plataforma no roadmap; não bloqueou a aprovação

## Roteiro (constituição III)

| Passo | O que fazer | Esperado |
| --- | --- | --- |
| 1 | Ferramenta Texto; clicar no papel | Só o cursor piscando, sem caixa |
| 2 | Digitar uma frase longa | A caixa aparece e cresce para a direita, numa linha, sem limite |
| 3 | `Esc` | O card fica selecionado e a ferramenta volta para Seleção |
| 4 | Ferramenta Texto, clicar e sair sem digitar | Nada fica na página |
| 5 | Com Seleção, passar o mouse sobre cada alça e sobre o corpo | Cursor de redimensionar (`↔`, `↕`, diagonais) na direção da alça; cruz de mover sobre o texto |
| 5a | Segurar `Espaço` e arrastar, com um card selecionado e sem seleção | A mão aparece e a página se desloca; ao soltar, os cursores voltam |
| 5b | Olhar o contorno de um card selecionado, reto e girado | Cantos arredondados, alças de canto redondas, de lado em pílula, haste até a alça de rotação |
| 6 | Puxar cada alça (lados e cantos); `Shift` num canto | Só a caixa muda; a letra fica igual; `Shift` mantém a proporção |
| 7 | Começar a puxar uma alça e apertar `Esc` | A caixa volta ao tamanho anterior |
| 8 | Arrastar a alça de rotação; depois com `Shift` | Gira em torno do centro; com `Shift`, de 15 em 15° |
| 9 | Duplo clique no card girado e digitar | O texto edita normalmente |
| 10 | Arrastar o corpo do card com Seleção | Move; `Ctrl+Z` desfaz |
| 11 | `Alt`+arrastar o corpo | O original fica; a cópia aparece onde soltar |
| 12 | `Ctrl+D` e `Delete` com o card selecionado | Duplica; exclui |
| 13 | Setas e `Shift`+setas; `Alt`+setas laterais | Move 1/10 pt; muda a largura |
| 14 | Clique no vazio; duplo clique no vazio | Limpa a seleção; começa um texto |
| 15 | Fechar e reabrir o caderno | Tamanho, rotação e posição iguais |
| 16 | Um caderno antigo, com cards de antes | Aparência igual à de antes |
| 17 | Abrir uma página | Papel limpo: sem título "Prova do editor", sem botão "Salvar textos", sem "Alterações salvas"; a caneta desenha no papel inteiro |

## Aprovação (somente o dono do produto marca)

- [x] Ferramenta Texto por clique aprovada
- [x] Caixa fina, oito alças e cursores aprovados
- [x] Rotação aprovada
- [x] Seleção, Alt+arrastar, Ctrl+D e Delete aprovados
- [x] Cadernos antigos sem mudança de aparência
- [x] Observações registradas abaixo, ou nenhuma

Correção (31/10/2026): os cursores não apareciam porque duas superfícies transparentes da página cobriam o card com a seta padrão. Corrigido e testado pelo cursor real da janela; `Espaço` e contorno arredondado entraram na mesma rodada. Recompilar o app antes de conferir (ele estava aberto durante a correção).

**Observações do dono do produto:**
