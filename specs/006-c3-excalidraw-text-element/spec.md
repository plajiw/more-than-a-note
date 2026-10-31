# C3 — Card de texto no estilo Excalidraw

- **Tipo:** desvio (mudança de rumo do componente, decidida pelo dono do produto)
- **Estado:** em validação
- **Aberta em:** 2026-10-30
- **Origem:** uso do editor e avaliação de arquitetura de 30/10/2026 (agente especializado, só leitura)
- **Documentos donos:** [04](../../docs/04-comportamento-editor-e-organizacao.md) §3.1, §3.2 e §5; [17](../../docs/17-plano-e4-card-de-texto.md) §1; [13](../../docs/13-estudo-visual.md) §6.1; [02](../../docs/02-ferramentas-e-interacoes.md) §2; [03](../../docs/03-atalhos-e-acessibilidade.md) §2; [16](../../docs/16-formato-conteudo-v2.md) (altura); [20](../../docs/20-plano-marco3-objetos-e-diagramas.md) (rotação de texto antecipada)

## Problema e objetivo

O card de texto tem moldura arredondada, uma cápsula de mover acima da borda, uma alça de largura e dois botões (Duplicar, Excluir) no hover, com largura limitada a 120–500 pt. O dono do produto quer menos interface e mais flexibilidade, próximo ao elemento de texto do Excalidraw: caixa fina de seleção, alças em todas as direções, rotação, duplicar e excluir pelo teclado e por Alt+arrastar, sem limite de tamanho.

## Decisões do dono do produto (30/10/2026)

| # | Tema | Decisão |
| --- | --- | --- |
| D1 | Ferramenta Texto | Funciona por clique: o clique põe o cursor de texto piscando no ponto; o card (a entidade) só nasce quando a pessoa digita. Ao terminar o texto, a ferramenta volta para Seleção |
| D2 | Alças | Oito alças (quatro cantos e quatro lados): direita, esquerda, cima, baixo e diagonais. **Todas mudam só a caixa**; o tamanho da letra não muda (como no Figma). O cursor do mouse mostra a direção de cada alça |
| D3 | Rotação | Alça de rotação acima da caixa, **agora** (não no Marco 3) |
| D4 | Limites | Mínimo de 24 pt; **sem máximo**. Ao digitar, a largura cresce até onde a pessoa quiser, mesmo além da tela ou do papel; depois ela ajusta a caixa ou o tamanho do papel |
| D5 | Teclado | `Ctrl+D` duplica; `Delete` exclui. Menu de contexto (botão direito) virá depois |
| D6 | Alt+arrastar | Dentro do app, duplica e move a cópia |
| D7 | Botões | Somem a cápsula de mover e os botões Duplicar/Excluir |

## Contrato de interação

| Contexto | Gesto | Resultado |
| --- | --- | --- |
| Seleção (V) | Clique no texto | Seleciona: contorno fino de 1 px, oito alças e alça de rotação |
| | Arrastar o corpo | Move; um passo de desfazer ao soltar; `Esc` durante o gesto cancela |
| | `Alt+arrastar` o corpo | Duplica e move a cópia; um passo de desfazer |
| | Duplo clique ou `Enter` | Edita, com o cursor no ponto clicado (ou no fim) |
| | Alça de lado | Muda a largura (esquerda/direita) ou a altura (cima/baixo) da caixa; esquerda e cima também movem a origem, num só comando |
| | Alça de canto | Muda largura e altura juntas; `Shift` mantém a proporção |
| | Alça de rotação | Gira em torno do centro; `Shift` prende em passos de 15° |
| | Setas / `Shift+setas` | Movem 1 / 10 pt |
| | `Ctrl+D` / `Delete` | Duplica / exclui |
| | Clique no vazio | Limpa a seleção |
| Texto (T) | Clique no vazio | Cursor piscando no ponto, sem criar objeto; digitar cria o card em largura automática |
| | Clique num card | Edita aquele card com o cursor no ponto |
| | Terminar (`Esc` ou clique fora) | Card fica selecionado; a ferramenta volta para Seleção. Cursor sem texto não deixa objeto |
| Editando | Arrastar no texto | Seleciona caracteres; nunca move |
| | `Ctrl+C`/`Ctrl+V`/`Delete` | Valem para o texto, não para o objeto |
| Caneta | Qualquer gesto | Desenha por cima; o card não reage |

**Tamanho.** Largura automática: cresce com o texto, sem quebra além do `Enter`, sem limite. Ao puxar uma alça de lado ou canto, a largura vira fixa e o texto quebra nela. A altura acompanha o conteúdo; puxar para cima/baixo fixa uma altura maior, e a caixa nunca fica menor que o texto. Mínimo de 24 pt em cada eixo.

**Cursores.** Cada alça mostra o cursor da sua direção, ajustado à rotação da caixa (o cursor de canto de uma caixa a 45° é o de lado). Corpo com Seleção, selecionado ou não: cursor de mover. Rotação: cursor próprio de girar (ou o mais próximo disponível no Qt). Nenhuma superfície transparente (pan da página, clique no vazio) pode cobrir esses cursores.

**Espaço.** Segurar `Espaço` desloca a página com o foco no papel, num card selecionado ou no índice; só não vale enquanto se digita. A repetição automática da tecla não interrompe o gesto.

**Contorno (rodada final).** Moldura de 1 px com raio `radius.sm`; alças de canto redondas de 9 px; alças de lado em pílula de 14×6 px ao longo da borda; alça de rotação de 10 px ligada à moldura por uma haste de 1 px. Hover das alças em `paper.warm`. Alvos de 16 px inalterados.

## Histórias

### US1 — Caixa fina e oito alças (P1)
1. Selecionar mostra contorno de 1 px e oito alças quadradas em tamanho de tela, em qualquer zoom, acima da tinta.
2. Cada alça redimensiona na sua direção, com o cursor certo; esquerda e cima movem a origem no mesmo comando; `Esc` cancela; um passo de desfazer.
3. Não existem mais a cápsula de mover nem os botões Duplicar/Excluir.

### US2 — Rotação (P1)
1. A alça acima da caixa gira em torno do centro; `Shift` prende em 15°.
2. Texto girado continua editável (cursor e seleção corretos); fechar e reabrir mantém o ângulo.

### US3 — Ferramenta Seleção (P1)
1. Clique seleciona, arrastar o corpo move, duplo clique ou `Enter` edita.
2. `Alt+arrastar` duplica e move a cópia.
3. `Ctrl+D` duplica, `Delete` exclui, setas movem.

### US4 — Ferramenta Texto por clique (P1)
1. Clique no vazio mostra o cursor piscando sem criar objeto; digitar cria o card.
2. Ao terminar, a ferramenta volta para Seleção e o card fica selecionado.
3. A largura cresce sem limite enquanto se digita.

### US5 — Tamanho sem máximo (P1)
1. Largura e altura com mínimo de 24 pt e sem máximo, no modelo, no adaptador e na interface; persistem ao reabrir.

### US6 — Página limpa (P1)

Pedido do dono do produto em 31/10/2026, dentro da C3: o papel não mostra título "Prova do editor", dica, botão "Salvar textos" nem status ("Alterações salvas", "Editando…"). Uma falha de gravação ou de leitura aparece só na barra de status, em vermelho. `Ctrl+S` continua gravando o pendente. A área da caneta passa a cobrir o papel inteiro.

## Casos de borda

- Texto girado: a janela de candidatos do IME (acentos compostos no Windows e no Linux) pode aparecer fora do lugar; verificar no portão da plataforma.
- Caixa fixa menor que o texto após mudar a fonte: a altura cresce para caber.
- `Alt` no Windows ativa a barra de menus ao ser solto sozinho; com arrasto, não deve.
- PDF (Marco 5): conteúdo fora do A4 não sai; rotação deve ser fiel.

## Fora de escopo

- Escalar a letra pelas alças (decisão D2).
- Menu de contexto (depois, por decisão D5).
- Copiar/colar de objetos com `Ctrl+C`/`Ctrl+V` fora da edição: próxima atividade, junto com o menu.
- Seleção múltipla e retângulo de seleção (Marco 3, M3.3).

## Critérios de sucesso

Testes automáticos de cada gesto da tabela (mover, oito alças, rotação, `Esc`, desfazer, reabrir, Alt+arrastar, ferramenta Texto por clique, limites); capturas na galeria nos dois temas; roteiro aprovado pelo dono do produto.
