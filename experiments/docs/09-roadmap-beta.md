# 09 — Roadmap da versão beta

**Objetivo:** entregar uma alternativa desktop local ao OneNote para alunos e professores, capaz de criar uma aula com texto, tinta, imagens, diagramas e PDF anotado, preservar os dados e exportar o resultado. A stack escolhida é C++ com Qt 6 para Windows e Linux. Este roadmap define entregas e critérios de saída, sem prometer datas antes da validação técnica do editor.

## Princípio de execução

Cada marco termina com uma demonstração reproduzível nas duas plataformas. A prioridade é concluir um fluxo de aula confiável antes de ampliar a lista de recursos. Os requisitos funcionais estão nos documentos 01–06; as lacunas e evidências de uso estão em 07–08.

## Marco 1 — Fundação do aplicativo

**Entregas:** projeto Qt/C++ compilável; janela e menus desktop; Biblioteca separada; índice de seções e páginas do caderno aberto; temas claro/grafite; modelo local versionado de caderno, seção e página; instalação de desenvolvimento em Windows e Linux.

**Critério de saída:** criar, fechar e reabrir um caderno local com seções/páginas preservadas nas duas plataformas. O título da janela e a navegação identificam o caderno aberto. Não há dependência de conta ou internet para abrir dados.

## Marco 2 — Núcleo do editor

**Entregas:** página A4 e canvas infinito; coordenadas lógicas; `TextContainer` rico e livre; tinta vetorial com pressão; prévia imediata de traço; zoom ancorado, pan temporário, foco e histórico de texto/tinta. Teste com Wacom CTL-672 real em Windows e Linux.

**Critério de saída:** digitar e desenhar na mesma área, inclusive com sobreposição, sem que tinta bloqueie a edição do texto; salvar/reabrir sem deslocamento; undo/redo coerente; caneta, mouse e teclado não trocam ferramentas durante digitação. Medir latência, estabilidade do cursor, IME e páginas densas.

**Decisão vinculada:** validar borracha parcial com escrita manuscrita de aula. Se apagar traços inteiros prejudicar correções comuns, borracha parcial torna-se requisito antes da beta.

## Marco 3 — Objetos e seleção espacial

**Entregas:** imagens incorporadas; formas básicas, linhas/setas e conectores; gráficos importados como imagem/SVG; seleção mista; mover, redimensionar, agrupar/desagrupar, alinhar/distribuir, duplicar e ordenar frente/trás; clipboard e histórico dessas operações.

**Critério de saída:** selecionar e mover juntos texto, tinta e imagem; mover formas mantendo conectores ligados; redimensionar gráfico importado; desfazer/refazer a transformação do conjunto; fechar/reabrir preservando posições, IDs, grupos e ativos.

## Marco 4 — Fluxo de aula

**Entregas:** importar páginas de PDF como base estável de anotação; bloquear a base contra movimento acidental; vínculo/grupo explícito entre base e tinta; busca por títulos e texto digitado no caderno, com escopo claro e salto ao resultado; links internos entre páginas; configurações de papel por página.

**Critério de saída:** importar slides de aula, anotar com caneta, acrescentar texto/figura, fechar e reabrir com a tinta no mesmo lugar relativo ao slide. Buscar uma expressão e chegar ao contêiner certo. Testar A4 e canvas infinito.

## Marco 5 — Confiança, recuperação e saída

**Entregas:** autosave transacional, checkpoints, recuperação após falha, lixeira para exclusões, pacote editável de caderno com recursos internos, backup/restauração e PDF com prévia de paginação, escala e área imprimível.

**Critério de saída:** interromper gravação e recuperar a última versão íntegra; restaurar backup em outra máquina e no outro sistema operacional; exportar A4 e canvas infinito para PDF sem cortar silenciosamente texto, tinta, imagens ou diagramas. O estado “Salvo” só aparece após gravação durável.

## Marco 6 — Beta fechada

**Entregas:** correções de desempenho, acessibilidade, foco, empacotamento e documentação; roteiros de teste para aluno e professor; relatório de problemas e critérios de severidade para publicação.

**Critério de saída:** um aluno e um professor concluem sem assistência o cenário integrado: criar caderno, inserir slides, digitar/desenhar, mover grupo, buscar, exportar PDF, fechar/reabrir e restaurar backup. Nenhum defeito conhecido pode causar perda de conteúdo ou desalinhamento silencioso. Fluxos essenciais funcionam com teclado; objetos visuais têm descrição acessível.

## Escopo deliberadamente posterior à beta

- Gráficos nativos editáveis a partir de tabelas de dados; na beta, gráficos importados são objetos selecionáveis e redimensionáveis.
- OCR/busca no manuscrito; a busca beta cobre títulos e texto digitado e comunica esse limite.
- Sincronização em nuvem, edição simultânea, aplicativos móveis e compartilhamento em tempo real.
- Reconhecimento automático de formas, ancoragem automática de toda tinta ao texto e edição avançada de imagens.

## Dependências e estimativa

O marco 2 é o principal risco técnico. A escolha interna entre Qt Quick, componente próprio e eventual uso de Qt Widgets para a área de edição será fechada pelos resultados desse protótipo, sem mudar a decisão por C++/Qt 6. **Não fixar calendário externo antes do critério de saída do marco 2.** Após essa medição, estimar os marcos restantes considerando desempenho, acessibilidade e empacotamento reais em Windows e Linux.

## Regra de priorização

Se houver pressão de prazo, reduzir primeiro recursos posteriores e polimento não essencial. Não retirar da beta: preservação de dados, recuperação, posição estável da tinta, fluxo de PDF de aula, seleção básica dos objetos prometidos e exportação fiel. Uma função visualmente pronta, mas incapaz de sobreviver a fechar/reabrir, não conta como entregue.
