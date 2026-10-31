# C2 — Microinterações do editor e página vazia

- **Tipo:** desvio
- **Estado:** fechada (aprovada em 31/10/2026)
- **Aberta em:** 2026-10-30
- **Origem:** uso do editor pelo dono do produto no Windows, 30/10/2026
- **Documentos donos:** [04](../../docs/04-comportamento-editor-e-organizacao.md) §5 e [17](../../docs/17-plano-e4-card-de-texto.md) (limites do card), [13](../../docs/13-estudo-visual.md) §6.1 (microinterações do card), [20](../../docs/20-plano-marco3-objetos-e-diagramas.md) §2 (sobreposição), [02](../../docs/02-ferramentas-e-interacoes.md) (cursores das ferramentas)

## Problema e objetivo

O dono do produto relatou, no uso:

1. Não dá para tirar um card de texto do papel; ele deve poder ser arrastado para fora.
2. Caderno novo, sem seção ou página, mostra papel com "Crie uma seção" pixelado; deve mostrar só o fundo.
3. A fonte do projeto parece não ser aplicada no Windows.
4. O traço da caneta fica por cima do contorno, das alças e dos botões do card.
5. O hover do card às vezes fica preso.
6. Com a ferramenta Texto, o cursor vira mira sobre o card e não aparece o cursor de texto piscando.

E pediu uma investigação das microinterações para resolvê-las juntas.

## Investigação (causas encontradas)

| Sintoma | Causa no código |
| --- | --- |
| Card preso ao papel | `clampXPt`/`clampWidthPt` (QML) e `validTextGeometry` (adaptador) limitavam o card às margens horizontais do A4, conforme a decisão anterior do 17 e do 04 §5 |
| "Crie uma seção" pixelado | Texto de estado vazio dentro da cena com zoom, desenhado pelo rasterizador nativo, que não escala |
| Fonte no Windows | Inter e IBM Plex carregam e resolvem (verificado com `qml.exe`). Mas a fonte padrão do app continuava a do sistema (`main.cpp` só mudava o hinting); e o executável de testes **nunca registrava** as fontes, então testes e capturas de evidência usavam a fonte de reserva |
| Caneta sobre os controles | Alças, contorno e ações eram filhos do card (z 1–2); a tinta (`InkProbeItem`) fica em z 2 e a área da caneta em z 3, acima de tudo |
| Mira sobre o card com a ferramenta Texto | A área da caneta (z 3, cursor de mira) só ficava `enabled: false`; o Qt mantém o cursor de um `MouseArea` desabilitado. O mesmo valia para a área de texto (cursor I) e para a área de pan, que depois do primeiro uso de Espaço deixava uma seta sobre tudo |
| Sem cursor piscando | Clique na margem do card (12 px em volta do texto) só selecionava; o foco não ia para o texto |
| Hover preso | Sem reprodução determinística. Candidatos: alças "fantasma" de cards removidos permanecendo na cena; foco por ponteiro na alça mantendo o contorno; cursor sobreposto. Os dois primeiros foram corrigidos; o comportamento entra no roteiro |

## Histórias

### US1 — Card fora do papel (P1)

1. **Dado** um card em página A4, **quando** o usuário arrasta para a direita ou para baixo além do papel, **então** o card fica onde foi solto, sobre o fundo, e a área rolável cresce para alcançá-lo.
2. Pela esquerda e por cima, o card para na borda do papel (origem da página).
3. A largura fica entre 120 e 500 pt, sem depender da borda do papel.

### US2 — Caderno sem página mostra só o fundo (P1)

1. **Dado** um caderno sem seção ou uma seção sem página, **então** a área da página mostra só o fundo, sem papel, texto ou botão.

### US3 — Inter como fonte da interface, também nos testes (P1)

1. Texto da interface sem família explícita usa Inter.
2. Testes e capturas de evidência usam as mesmas fontes do app.

### US4 — Controles do card acima da tinta (P1)

1. Contorno, alças e ações do card ficam acima de traços de tinta.
2. Selecionar um card não muda a ordem de pintura do conteúdo (decisão de 30/10/2026 no 20 §2, antecipada): só os controles do card selecionado ficam acima dos de outros cards.

### US5 — Cursores e cursor de texto (P1)

1. Com a ferramenta Texto, o cursor sobre o card é o I de texto, inclusive na margem; nunca a mira.
2. Clicar no card, inclusive na margem, coloca o cursor de texto piscando no ponto mais próximo.
3. Com a Caneta, a mira vale sobre toda a página, inclusive sobre cards.
4. Clicar fora do card em edição encerra a edição e não cria outro card; o clique seguinte cria.

### US6 — Hover que não fica preso (P2)

1. Passar o ponteiro sobre um card não selecionado mostra o contorno; sair esconde contorno e alças.
2. Controles de um card removido (troca de página, desfazer, excluir) somem no mesmo instante.

### US7 — Card volta ao papel (P1)

Relatado depois da primeira entrega. Causa: o Qt só entrega clique e hover a itens dentro dos limites do item que os contém; com o card além do papel, a alça e o próprio card ficavam fora da área do editor (`EditorProbe`, do tamanho do papel) e não recebiam o clique. Agora o editor cobre o papel e todos os cards; papel, superfícies de ferramenta e tinta continuam do tamanho do papel.

1. **Dado** um card fora do papel, **quando** o usuário arrasta a alça de volta, **então** o card volta ao papel.

### US8 — Caneta só no papel (P1)

1. **Dado** um traço que começa no papel e é arrastado para fora, **então** ele aparece só até a borda do papel (a tinta é recortada no papel).

### US9 — Hover e dicas dos botões Duplicar e Excluir (P1)

Relatado com captura: dois botões em hover ao mesmo tempo e dicas sobrepostas. **Substituída pela C3** (30/10/2026): o dono do produto decidiu retirar os botões Duplicar/Excluir (card no estilo Excalidraw). A investigação foi interrompida; nada dela entrou no código.

## Casos de borda

- Exportação em PDF (Marco 5): conteúdo fora do papel A4 não sai na folha; a decisão sobre aviso fica para MX7.
- Duplicar um card fora do papel recoloca a cópia dentro do papel (regra de `duplicateText`).
- O card é transparente: fora do papel, a borda do papel aparece através dele.
- Hover preso sem reprodução: se reaparecer, registrar o passo a passo no checklist.

## Fora de escopo

- Arrastar o card para a esquerda ou para cima do papel (exige deslocar a origem da cena durante o gesto).
- Painel de papel e modelo de página: etapa própria do roadmap.

## Critérios de sucesso

Testes novos em `tests/qml/tst_editor.qml` passando; suíte completa sem regressão no editor; roteiro aprovado pelo dono do produto no app.
