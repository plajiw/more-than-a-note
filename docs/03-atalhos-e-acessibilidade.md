# 03 — Atalhos, foco e acessibilidade

**Perfis:** (a) Wacom + teclado + mouse, (b) somente teclado e mouse, (c) navegação somente teclado, (d) tecnologias assistivas. **Princípio:** todos os comandos visuais precisam de alternativa acessível, sem exigir caneta, pressão, botão lateral ou gesto.

## 1. Regras de despacho de atalhos

Ordem de precedência: editor com foco → diálogo/menu ativo → operações temporárias → seleção do canvas → comandos globais. Atalhos de **uma tecla** só são processados quando o foco está no canvas fora de campos de texto, nomes, pesquisa e formulários. Com IME/composição textual ativa, nenhuma tecla simples deve trocar ferramenta. `Esc` percorre os estados: cancelar operação → sair da edição → limpar seleção → fechar painel temporário quando aplicável.

**Definido pelo produto:** `E` alterna caneta/borracha; `1..9` selecionam cores; `0` abre paleta; espaço segurado ativa Mão temporariamente; botão do meio do mouse (mouse3) + arrasto faz pan. **Proposta adicional:** `V` seleciona objetos, `T` texto, `P` caneta; estes devem ser reconfiguráveis e apresentados como sugestão inicial, não decisões anteriores do usuário.

## 2. Mapa proposto

| Ação | Atalho inicial | Contexto/observação |
|---|---|---|
| Desfazer / refazer | `Ctrl+Z` / `Ctrl+Y` ou `Ctrl+Shift+Z` | Histórico coordenado da página |
| Texto | `T` | Somente canvas sem digitação |
| Caneta | `P` | Somente canvas sem digitação |
| Alternar caneta/borracha | `E` | Somente canvas sem digitação; retornar à última caneta |
| Seleção | `V` | Somente canvas sem digitação |
| Mão temporária | `Espaço` pressionado + arrastar | Restaurar ferramenta ao soltar |
| Pan com mouse | Botão central segurado + arrastar | Independente da ferramenta |
| Cores rápidas | `1` a `9` | Nove amostras configuráveis |
| Abrir paleta | `0` | Seletor acessível e fechável com `Esc` |
| Ampliar / reduzir | `Ctrl++` / `Ctrl+-` | Admite combinações físicas de teclado ABNT2 e numérico |
| Zoom 100% | `Ctrl+0` | **Conflito potencial:** `0` sozinho abre paleta; `Ctrl+0` é distinto |
| Zoom com roda | `Ctrl+roda` | Zoom ancorado no ponteiro |
| Selecionar tudo (texto) | `Ctrl+A` | Cursor dentro de contêiner: apenas texto daquele contêiner |
| Selecionar tudo (canvas) | `Ctrl+A` | Foco na superfície/objetos: todos os objetos da página |
| Negrito / itálico / sublinhado | `Ctrl+B` / `Ctrl+I` / `Ctrl+U` | Edição de texto |
| Copiar / recortar / colar | `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | Texto ou objetos, conforme foco |
| Colar texto sem formatação | `Ctrl+Shift+V` | Edição de texto |
| Remover objeto | `Delete` | Apenas objetos selecionados; em edição, apaga texto |
| Sair do modo ativo | `Esc` | Desempilhar contextos, sem perder documento |
| Próximo controle | `Tab` / `Shift+Tab` | Menus, árvore, barra e controles acessíveis |
| Abrir menu de contexto | `Shift+F10` | Objeto ou região com foco |
| Busca | `Ctrl+F` | Buscar na página; ampliar para caderno no futuro |
| Configurações | via Arquivo e busca de comandos | Evitar combinação global sem necessidade |

### 2.1 Notas sobre conflito de atalhos

- `1..9`, `0`, `E`, `P`, `T`, `V` nunca têm efeito sobre ferramentas enquanto o usuário edita texto ou renomeia objetos.
- `Espaço` durante edição insere espaço. Fora da edição, pan temporário. Ao dar foco para outro programa enquanto segura espaço, restaurar modo anterior.
- `Ctrl+0` pode ser interceptado por políticas de teclado/desktop; validar nas plataformas suportadas e deixar reconfigurável.
- `Ctrl+roda` pode colidir com zoom de sistemas assistivos; disponibilizar botões e comandos alternativos.
- `Ctrl+A` prioriza conteúdo textual quando o caret está ativo; no canvas seleciona objetos, com feedback claro.
- Com layout ABNT2 e dispositivos que emitem códigos diferentes, mapear pela intenção da tecla, exibir combinação resolvida pela plataforma e permitir remapeamento.

## 3. Perfis de uso

### Mesa + teclado + mouse

Mão dominante desenha na mesa; outra acessa cores `1..9`, `E` e espaço. Pan deve poder acontecer também via mouse3. Zoom disponível nos botões da barra de status ou com teclas, sem exigir touch. UI não deve interceptar traços quando os menus estão recolhidos. Acesso às cores visível na coluna vertical, com preview de cor/espessura efetivas.

### Teclado e mouse

Clicar para criar/editar contêiner; arrastar alça para mover; ativar Caneta para desenhar com mouse; `Ctrl+roda` amplia; espaço + arrastar desloca. Não exigir detecção de hardware de caneta nem pressão para habilitar desenho.

### Somente teclado

Árvore de cadernos/seções/páginas deve usar padrões de navegação por setas, Enter e comandos de contexto. Canvas deve oferecer um modo de **navegação de objetos por foco**, sem depender de clicar coordenadas: Tab/Shift+Tab percorrem componentes da interface, e comandos dedicados percorrem objetos da página (por exemplo `Alt+↑/↓`, a validar contra sistema); Enter inicia edição de texto, setas movem seleção espacial apenas quando apropriado. O usuário deve poder inserir um contêiner na posição padrão e navegar por objetos sem apontador.

## 4. Acessibilidade: requisitos verificáveis

- **Operável por teclado:** nenhuma ação essencial exige apontador; incluir criação, edição, movimentação, zoom e exclusão.
- **Foco visível:** indicador inequívoco e contrastante em menu, botão, árvore, contêiner e seleção; foco não fica atrás de barra ou painel.
- **Leitores de tela:** nomes, papéis, estados e descrições acessíveis; caderno/seção/página com hierarquia comunicada; ações anunciar resultados relevantes (`Página movida`, `Salvo`). Canvas vetorial exige uma **árvore semântica de objetos** para navegação alternativa.
- **Sem dependência apenas de cor:** amostras indicam nome/código e posição; ferramentas ativas têm borda/símbolo e rótulo acessível.
- **Contrastabilidade:** texto, ícones funcionais, foco e controles validados nos temas claro/escuro, inclusive estados desabilitados com semântica apropriada.
- **Tamanho de alvo:** áreas de interação suficientes para mouse/caneta e opção de escala de UI; não exigir precisão milimétrica.
- **Redução de movimento:** animações dispensáveis são desativáveis; não animar traços ou foco de modo que prejudique acompanhamento.
- **Preferência de mão:** reposicionar barra de ferramentas, evitando oclusão de popovers.
- **Feedback não intrusivo:** anúncio de salvamento/erro sem roubar foco; não usar tooltip como único meio de explicar controle.
- **Conteúdo manuscrito:** não é acessível semanticamente como texto; permitir adicionar descrição textual alternativa a desenhos/áreas selecionadas no futuro, sem afirmar acessibilidade plena por OCR inexistente.

## 5. Testes essenciais

1. Digitar `1234567890 e p t v` em texto não altera ferramentas.
2. `Espaço` desloca canvas fora de texto e insere caractere dentro do editor.
3. Usar `Ctrl+A` com caret em texto e com foco no canvas produz seleções diferentes e corretas.
4. Percorrer árvore, barra, canvas e seus objetos apenas com teclado.
5. Leitor de tela identifica funções, hierarquia e objeto selecionado.
6. Zoom e desenho continuam disponíveis sem caneta digitalizadora.
7. Foco recupera-se após fechar paleta, menus e painéis.

## 6. Referências e diretrizes

- Atalhos oficiais do OneNote, úteis como referência de convenções, **não** como contrato de cópia: https://support.microsoft.com/pt-br/accessibility/onenote/keyboard-shortcuts-in-onenote
- WCAG 2.2, critérios para operação por teclado, foco e alvos: https://www.w3.org/TR/WCAG22/
- WAI-ARIA Authoring Practices (padrões de interação; adaptar à API de acessibilidade desktop): https://www.w3.org/WAI/ARIA/apg/

**Decisões pendentes:** atalhos finais de seleção/laço, régua, espessura, navegação de objetos e compatibilidade com atalhos globais do Windows/Linux; a camada de atalhos deve ser configurável por ação, não hardcoded.


## M2 — proposta de fluxo conectado, pendente

A arquitetura de [roteamento do 22](22-arquitetura-editor-visual-unificado.md#4-roteamento-de-entrada-e-estados) identifica a divergência da precedência do §1 com o 02 §3 e recomenda diálogo/menu modal antes da edição textual. A mudança deve ser aprovada e aplicada aos dois documentos antes da implementação; IME e campos textuais continuam protegidos de atalhos simples.

Para diagramas, o [20](20-plano-marco3-objetos-e-diagramas.md) recomenda ações nomeadas de inserir forma, criar conectado e navegar objetos, com rótulo editável por Enter e saída por Esc. **Tab continua navegação de controles.** Criar outro nó com Tab é hipótese de uso, não atalho aprovado. Ordem acessível segue readingOrder, mesmo para objetos fora da viewport; seleção, rótulo e conexões precisam de semântica independente dos nós gráficos. A prova requer leitor de tela real, foco restaurado e IME; captura de tela não comprova fala.
