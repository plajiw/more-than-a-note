# 07 — Revisão especializada dos requisitos 02–05

**Objetivo da revisão:** preparar o Orla como alternativa desktop local ao OneNote para alunos e professores: texto rico em contêineres livres, escrita manual, imagens, gráficos e diagramas inseríveis, selecionáveis, alinháveis e móveis. Quatro revisões independentes examinaram ferramentas/entrada, atalhos/acessibilidade, modelo do editor e configurações/portabilidade. Este documento registra propostas; não altera silenciosamente requisitos já aprovados.

## 1. Síntese e decisão de escopo proposta

O modelo atual detalha `TextContainer` e `InkStroke`, mas trata os outros conteúdos como `...`. Isso impede especificar seleção mista, ordem visual, clipboard, histórico, busca, acessibilidade e formato portátil. **A primeira decisão antes do código do editor é definir uma família comum de objetos de página.**

| Capacidade | Proposta para a primeira versão | Posterior ou sujeito a validação |
|---|---|---|
| Texto | Contêiner rico livre, editável, movível, redimensionável, com listas/links e formatação | Âncoras automáticas entre objetos |
| Tinta | Traços vetoriais com pressão, seleção e movimento; borracha parcial precisa de protótipo com escrita densa | OCR e reconhecimento de formas |
| Imagens | Inserir/colar imagem local, incorporar ao caderno, mover/redimensionar, texto alternativo | Edição avançada da imagem |
| Diagramas | Formas básicas, linhas/setas e conectores ligados a objetos; mover nós preserva ligação | Biblioteca ampla de formas, roteamento sofisticado |
| Gráficos | Inserir gráfico como imagem/SVG incorporado, selecionar, mover e dimensionar | Gráfico nativo editável a partir de tabela de dados |
| Organização espacial | Seleção mista, grupo, alinhamento/distribuição, duplicação, ordem frente/trás, undo/redo | Restrições e layout automático complexo |
| Ensino | PDF de leitura/impressão, caderno editável portável, pesquisa por título/texto, links internos e recuperação de exclusões | Sincronização/colaboração simultânea |

**Ponto que exige decisão de produto:** “gráfico” pode significar figura colada ou gráfico com dados editáveis. A proposta acima garante inserção e manipulação na primeira versão e reserva edição por dados para outra fase. O mesmo vale para importação de PDF: anexar/exibir como referência é um fluxo distinto de converter PDF em objetos plenamente editáveis.

## 2. Revisão de `02-ferramentas-e-interacoes.md` — entrada e ferramentas

### Problemas e incoerências

1. A matriz cobre quase só texto e tinta. Seleção deve operar também sobre imagens, formas, conectores, gráficos e grupos; cada tipo precisa regra de alça, transformação e edição interna.
2. Cor e espessura aparecem como “ferramentas”, mas são propriedades da ferramenta ativa ou de uma seleção explícita. Zoom e pan são controles de viewport; essa separação evita estados confusos.
3. A regra inicial de tinta sempre acima do texto conflita com `zOrder` no documento 04 e com trazer à frente/enviar atrás. Adotar ordem persistente entre objetos, com hit testing contextual para editar texto sob tinta.
4. Faltam regras para objetos sobrepostos: alvo inicial, alternância de alvo, laço versus retângulo, seleção mista com modificadores, alças, duplo clique, arrasto acidental e teclado.
5. “Finalizar ao evento de saída” pode registrar meio-traço acidental. Definir commit normal no pen-up, cancelamento explícito e política testada para perda de captura/foco.
6. Borracha de traço inteiro pode prejudicar anotações densas; validar cedo a borracha parcial e elevá-la a requisito se o teste de aula mostrar necessidade.

### Alterações recomendadas

- Reescrever §2 em **Ferramentas** (Texto, Caneta, Borracha, Seleção, Mão, inserção de forma/conector/imagem/gráfico), **propriedades contextuais** (cor, espessura, preenchimento etc.) e **viewport** (zoom/pan).
- Acrescentar tabela `dispositivo × ferramenta efetiva × alvo × gesto × resultado`, incluindo caneta sobre texto e mouse sobre tinta.
- Especificar mover, redimensionar, rotacionar onde fizer sentido, agrupar, alinhar, duplicar, bloquear e ordenar objetos; cada gesto deve produzir uma operação de undo coerente.
- Trocar a ordem visual fixa por ordem total persistente e regras de hit testing dependentes da ferramenta. Manter a possibilidade de selecionar o objeto sob outro objeto sem rearranjar a página.
- Testar uma página real de aula com parágrafos, imagem, gráfico importado, diagrama conectado e marcações manuscritas.

## 3. Revisão de `03-atalhos-e-acessibilidade.md` — teclado e acesso

### Problemas e incoerências

1. O texto ainda descreve uma árvore de cadernos/seções/páginas e cores numa coluna vertical. O layout vigente usa Biblioteca separada, índice do caderno e barra superior.
2. `Ctrl+F` ora busca página, ora caderno futuro; o layout já prevê busca no caderno aberto. Definir escopo inicial, seletor de escopo e anúncio ao usuário.
3. A navegação por objetos do canvas é vaga. Sem ordem de leitura estável e comandos para mover/redimensionar, “operável por teclado” ainda não é verificável.
4. Descrição textual de desenhos foi adiada, mas imagens e diagramas passam a ser conteúdo central. Objetos visuais v1 precisam campo de texto alternativo; tinta livre pode receber descrição no grupo de traços. Não prometer OCR inexistente.
5. Dicas de atalho do protótipo não podem ter texto fixo na versão final: devem refletir remapeamento, plataforma e foco/IME.

### Alterações recomendadas

- Definir entrada/saída do canvas por teclado, próximo/anterior objeto, ordem de leitura independente da ordem visual, seleção múltipla, movimento por passos, redimensionamento, propriedades, edição e exclusão recuperável.
- Atualizar `Ctrl+A`, Delete e clipboard para seleção mista de texto, tinta, imagem, diagrama e grupo; distinguir caret ativo de seleção espacial.
- Cobrir menus, configurações de seção/página, exclusão/recuperação e seleção mista em testes Windows e Linux com leitores de tela. Validar a árvore semântica produzida pelo componente Qt no protótipo técnico.
- Exigir que hover **e foco** mostrem nome e atalho, sem depender da dica como único nome acessível.

## 4. Revisão de `04-comportamento-editor-e-organizacao.md` — modelo e persistência

### Problemas e incoerências

1. `objects[]: TextContainer | InkStroke | ...` não é contrato suficiente para imagens, formas, conectores, gráficos e grupos.
2. Falta um conjunto comum de propriedades: `id`, `pageId`, transformação, limites, `zOrder`, bloqueio, descrição acessível e relação com grupo/asset quando cabível. Algumas propriedades podem ser calculadas; indicar quais são persistidas.
3. Seleção espacial e histórico são definidos para texto/tinta; não cobrem transformação e clipboard de objetos mistos nem grupos.
4. Ordem fixa fundo → texto → tinta contradiz reordenação de objetos. A ferramenta pode alterar o alvo de um clique sem alterar a ordem persistida.
5. Conectores de diagrama precisam pontos de ligação e comportamento ao mover nós. Se isso não existir, o produto não deve anunciar diagrama editável.
6. A4 e canvas infinito carecem de regra para objetos além da borda, escala física, recorte, impressão e exportação.
7. Persistência ainda é vaga para um editor offline: formato versionado, integridade de assets, gravação atômica, recuperação após falha e migração devem ser definidos antes da implementação do armazenamento.
8. A seção ainda precisa incorporar `iconId?`, aprovado no layout vigente.

### Alterações recomendadas

- Introduzir `PageObject` comum e tipos `TextContainer`, `InkStroke`, `ImageObject`, `ShapeObject`, `ConnectorObject`, `GroupObject` e `GraphicAssetObject` (gráfico incorporado sem dados editáveis).
- Definir operações em lote: selecionar, mover, dimensionar, agrupar/desagrupar, alinhar/distribuir, duplicar, ordem frente/trás, bloquear e copiar/colar entre páginas/cadernos. Preservar IDs conforme a operação: mover mantém; duplicar cria novos.
- Definir links internos entre páginas, busca de títulos/texto com salto ao contêiner e lixeira para página/seção/caderno. Texto manuscrito não entra na busca sem OCR.
- Especificar undo/redo para operações estruturais e transações que atravessam páginas/cadernos; “histórico por página” sozinho não cobre mover/excluir seção ou página.
- Testar recuperação após desligamento durante gravação e restauração offline de caderno com todos os assets.

## 5. Revisão de `05-configuracoes-e-portabilidade.md` — preferências e arquivos

### Problemas e incoerências

1. O exemplo `.cfg` ainda usa `library_visible` e `ink_toolbar_side`, referências ao layout abandonado. Substituir por visibilidade/largura do índice e separar preferência exportável de estado local de sessão.
2. “Arquivo → Configurações → Exportar preferências” não corresponde à barra de menus atual. Preferências devem abrir por comando consistente de aplicativo; importar/exportar preferências fica dentro delas. Arquivo → Exportar continua reservado a caderno/página.
3. O documento não distingue suficientemente **backup editável** de **PDF para leitura/entrega**. PDF não é formato de round-trip dos objetos.
4. Exportação de canvas infinito requer paginação, recorte, margens, escala e prévia; saída A4 precisa definir objetos fora da borda, pautas, fundo e fontes.
5. Importação deve tratar IDs duplicados, assets ausentes, esquema mais novo, pacote malformado e tamanho excessivo sem sobrescrever cadernos silenciosamente.
6. A configuração do papel abre pela engrenagem da página selecionada no índice, não por botão permanente Papel na barra. É necessário caminho por menu/teclado quando o índice estiver fechado.
7. Lixeira, versões/checkpoints e backup devem ter política de retenção e restauração, inclusive de assets associados.

### Alterações recomendadas

- Formalizar dois formatos/fluxos: **caderno portátil editável** com manifest, versão, IDs e assets internos; **PDF de páginas** com prévia e opções de paginação.
- Especificar round-trip Windows ↔ Linux, validação de importação e recuperação após falha; `.cfg` transporta somente preferências portáveis, nunca conteúdo do caderno nem caminhos absolutos por padrão.
- Separar defaults de páginas novas, configurações persistidas por página e estado de sessão/dispositivo. Traduzir atalhos dependentes de plataforma na importação.
- Priorizar backup/restauração, PDF e recuperação na primeira versão; sincronização e formatos adicionais podem vir depois.

## 6. Ordem de resolução recomendada

1. **Fechar a taxonomia v1 de objetos e a semântica de gráfico/diagrama.** Todos os quatro documentos dependem disso.
2. **Definir operações comuns de seleção, transformação, z-order, grupos e histórico.** Criar um cenário de aula como contrato de aceitação.
3. **Prototipar editor Qt/C++ com caneta, texto, imagem, forma/conector e acessibilidade.** A borracha parcial e o texto sob tinta são riscos de uso que devem ser observados cedo.
4. **Definir formato nativo, autosave, backup, lixeira e PDF** antes de expandir conteúdo real de usuários.
5. **Reescrever 02–05 em conjunto**, removendo referências ao layout antigo e adicionando testes Windows/Linux. A revisão deve manter uma única fonte de verdade para atalhos, escopo da busca e configurações de página.

## 7. Critério integrado de aceitação da primeira versão

Um professor cria um caderno e uma página A4; digita texto em dois contêineres; insere uma imagem e um gráfico estático; cria um diagrama de formas conectadas; anota por cima com caneta; seleciona texto, tinta, imagem e diagrama juntos para mover e alinhar; corrige parte da tinta; desfaz/refaz; salva, fecha e reabre offline; exporta PDF legível; faz backup editável e restaura em outro sistema operacional. Um aluno localiza a página por busca, navega e edita seus objetos por teclado, encontra descrições dos elementos visuais e recupera uma página excluída. Se esse cenário falhar, a promessa central do produto ainda não está completa.
