# Validação — C1 Botão esquerdo move a tela e rouba o arrasto do card

**Como conferir:** `cmake --build --preset release --target gallery` abre a galeria; a seção "Em validação" aponta para a seção Editor. Detalhes no [BUILDING.md](../../../BUILDING.md).

## Qualidade da especificação (agente)

- [x] Critérios de aceite verificáveis, sem marcas `[PRECISA ESCLARECER]` abertas
- [x] Toda história tem tarefa e toda tarefa serve a uma história
- [x] Verificação da constituição preenchida no plano

## Verificação técnica (agente)

- [x] `cmake --workflow --preset release` passou: na época, 7/8 pela instabilidade da Biblioteca, anterior ao C1 (ver T006); 8/8 em 31/10/2026, depois da T047 da M1 (Windows 10, Qt 6.12)
- [x] `--target evidence` gerou as capturas sem falha (31/10/2026: saída 0, 40 + 45 imagens). `tests/viewport-*.png` presentes; a caixa agora tem a aparência da C3, como esperado
- [x] `.specify/scripts/check.sh` passou (saída 0, 30/10/2026)
- [x] Cenário visível na galeria, sem opção ou modo novo; atividade listada em "Em validação"

## Roteiro (constituição III)

Na galeria, seção Editor → abrir o caderno de amostra, com uma página que tenha uma caixa de texto e zoom de 150% (Ctrl+=).

| Passo | O que fazer | Esperado |
| --- | --- | --- |
| 1 | Ferramenta Texto. Segurar o botão esquerdo no papel e arrastar | A tela não se move |
| 2 | Passar o mouse sobre a caixa; arrastar pela alça de mover | A caixa se move; a tela fica parada |
| 3 | Arrastar a alça de largura (borda direita) | A largura muda; a tela fica parada |
| 4 | Segurar o botão do meio (mouse3) e arrastar | A tela se move |
| 5 | Segurar Espaço e arrastar com o botão esquerdo; soltar Espaço | A tela se move; a ferramenta volta a Texto |
| 6 | Rolar a roda; depois Shift+roda; depois Ctrl+roda | Rola na vertical; rola na horizontal; zoom ancorado no ponteiro |
| 7 | Touchpad com dois dedos, se houver | A página rola em ambas as direções |
| 8 | Selecionar a caixa e dar zoom até 300% (Ctrl+=) | O contorno continua fino e visível |

Capturas: `tests/viewport-a4-150.png`, `tests/viewport-a4-50.png` e `tests/viewport-infinite-150.png` não mudam de aparência; o comportamento é conferido pelo teste e pelo roteiro.

## Aprovação (somente o dono do produto marca)

- [x] Botão esquerdo não move mais a tela
- [x] Alças movem e redimensionam o card
- [x] Contorno do card visível em zoom alto
- [x] Velocidade da roda e do touchpad confortável
- [x] Observações registradas abaixo, ou nenhuma

**Observações do dono do produto:** testado no app e aprovado ao pedir o commit (30/10/2026). Novos pedidos de microinteração seguem na C2.
