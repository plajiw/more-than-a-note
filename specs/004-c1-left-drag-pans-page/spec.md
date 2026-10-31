# C1 — Botão esquerdo move a tela e rouba o arrasto do card

- **Tipo:** desvio
- **Estado:** fechada (aprovada em 30/10/2026; pendências resolvidas em 31/10/2026)
- **Aberta em:** 2026-10-30
- **Origem:** uso do editor pelo dono do produto, 30/10/2026
- **Documentos donos:** [02](../../docs/02-ferramentas-e-interacoes.md) §3 e [03](../../docs/03-atalhos-e-acessibilidade.md), que já definem o comportamento certo; esta atividade só faz o código obedecer

## Problema e objetivo

Segurar o botão esquerdo e arrastar na página move a tela (câmera). Ao tentar arrastar um card pela alça, a tela se move no lugar dele e o gesto fica "bugado". Causa: a área da página é um `Flickable` do Qt com arrasto embutido pelo botão esquerdo, e as alças do card não impedem esse `Flickable` de assumir o gesto.

O 02 §3 e o 03 já dizem: botão do meio + arrasto move a tela, independente da ferramenta; o botão esquerdo só move a tela com a ferramenta Mão ou com Espaço segurado. Ao fim, o botão esquerdo nunca move a tela por acidente, e as alças movem e redimensionam o card.

## Histórias

### US1 — Botão esquerdo não move a tela (P1)

**Critérios de aceite**

1. **Dado** a ferramenta Texto, Caneta ou Seleção (sem Mão), **quando** o usuário arrasta com o botão esquerdo na página, **então** a tela não se move.
2. **Dado** qualquer ferramenta, **quando** o usuário arrasta com o botão do meio, **então** a tela se move.
3. **Dado** Espaço segurado ou a ferramenta Mão, **quando** arrasta com o botão esquerdo, **então** a tela se move (comportamento já definido no 02).
4. **Dado** a roda do mouse ou o touchpad, **então** a página rola na vertical; com Shift, na horizontal; com Ctrl, o zoom continua como antes.

### US2 — Alça move o card (P1)

**Critérios de aceite**

1. **Dado** um card com a alça de mover visível, **quando** o usuário arrasta a alça, **então** o card se move e a tela fica parada.
2. **Dado** a alça de largura, **quando** arrasta, **então** a largura muda e a tela fica parada.

### US3 — Contorno do card visível com zoom alto (P1)

Acrescentada em 30/10/2026, relatada pelo dono do produto no mesmo uso. A borda tinha `1/zoom` unidades de página; o Qt suaviza bordas de cantos arredondados com uma faixa de meia unidade, calculada antes do zoom, e a borda some acima de ~200%.

**Critérios de aceite**

1. **Dado** um card com a moldura visível, **em** qualquer zoom de 50% a 300%, **então** a moldura mede 1 px na tela e é visível.

## Casos de borda

- Soltar o botão fora da janela durante o arrasto da alça: o gesto termina, como antes.
- Página infinita: a página cresce ao rolar pela roda perto da borda, como acontecia ao arrastar.
- Tela sensível ao toque: o arrastar com o dedo deixa de rolar a página. O produto ainda não tem suporte a toque (pinça de touchpad e toque ficam nos portões de plataforma).

## Fora de escopo

- Listas da Biblioteca e do índice, que também são `Flickable`; se o arrasto com o botão esquerdo atrapalhar ali, vira outro desvio.
- Mover o card arrastando a moldura ou o corpo: o 04 §5 define que o texto se move pela alça e que o corpo seleciona caracteres.

## Esclarecimentos

- O dono do produto pediu "por enquanto somente mouse3". Espaço e a ferramenta Mão continuam movendo a tela porque são escolhas explícitas, já aprovadas no 02 e no 03; nenhum dos dois acontece por acidente.

## Critérios de sucesso

Suíte completa passando com os novos casos em `tests/qml/tst_editor.qml`; dono do produto confirma no editor que o botão esquerdo não move a tela e que a alça move o card.
