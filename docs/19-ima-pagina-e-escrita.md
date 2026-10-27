# 19 — Ímã, escrita e bloco de código

**25 de outubro de 2026.** Plano, sem implementação neste passo. A caixa de texto que já está na galeria e no editor não muda de modelo por causa deste documento. O comportamento visual atual do card está no [13](13-estudo-visual.md) e no [17](17-plano-e4-card-de-texto.md).

## 1. Escrever sem a caneta

A ferramenta Texto é suficiente para uma página inteira de anotação.

- Clique no vazio cria uma caixa e põe o caret. Não há diálogo e não há troca para a caneta.
- Arrastar dentro do texto seleciona letras. A caixa só se move pela alça superior, ou pelas setas com o foco nessa alça.
- A largura muda pela alça direita, ou por Alt com setas na alça de mover. A altura segue o texto. Não há rolagem dentro da caixa.
- Enquanto se digita, duplicar e excluir ficam na margem acima da borda, fora da primeira linha, para o ponteiro não cair neles ao selecionar.
- `Esc` sai da edição e deixa o objeto selecionado. Tab então alcança mover, duplicar, excluir, texto e largura. `Delete` com o objeto selecionado remove a caixa; durante a edição, apaga caractere. Isso já é a regra do [03](03-atalhos-e-acessibilidade.md).
- Caneta, borracha e marcador não capturam tecla com o texto em foco.

O incômodo a evitar é arrastar o parágrafo sem querer e ver um controle em cima da linha que se está lendo.

## 2. Bloco de código

O bloco de código, quando existir, usa o mesmo card: move-se pela alça superior, a largura muda pela alça direita, a altura segue o conteúdo. Não é uma ferramenta que coloque o usuário no modo caneta.

- Fonte JetBrains Mono, já embarcada. Ligaduras desligadas, como no [05](05-configuracoes-e-portabilidade.md).
- É um `TextContainer` com estilo de código, não um segundo tipo de alça.
- A moldura, as alças e os botões não entram no PDF. O arquivo guarda o texto e a geometria.
- Quebra de linha ou rolagem horizontal fica para a implementação. Não se decide isso agora.

## 3. Ímã

Pauta, grade, margem vertical, pontilhado e, no futuro, pauta musical são fundo da página. Não são objetos. O [04](04-comportamento-editor-e-organizacao.md) §2.1 e o [05](05-configuracoes-e-portabilidade.md) já guardam esse fundo por página, em pontos. A4, A3, tamanho livre e infinito usam a mesma unidade.

O ímã é opcional e nasce desligado. A página lisa não gruda em nada.

Observação externa, não medida copiada: o Xournal++ oferece grade e snap que a pessoa liga; editores vetoriais como o Affinity soltam o snap com uma tecla durante o gesto; no OneNote a pauta é visual e a caixa não gruda sozinha. A comunidade reclama quando a caixa nasce fora do lugar, não quando falta um ímã sempre ligado. A decisão local é o ímã desligado por padrão, em pontos de página.

Regras:

- As guias saem do preset da página e acompanham o zoom. Não são gravadas como conteúdo.
- Pauta: linhas horizontais e a margem vertical. Grade: as duas direções. Pontilhado: as interseções. Pauta musical: as linhas do pentagrama. Liso: nenhuma guia.
- Com o ímã ligado, mover a caixa e o clique que cria a caixa aproximam a borda de cima da guia mais próxima, dentro de uma tolerância curta. Soltar fora dela deixa a posição livre.
- Uma tecla modificadora desliga o ímã naquele gesto.
- Caret, digitação e seleção de letras não saltam de linha. O ímã não entra no parágrafo.
- Mudar o tamanho ou o fundo da página não regrava caixas já colocadas.
- Um gesto de mover ou de largura continua sendo um único desfazer, como no 17.
