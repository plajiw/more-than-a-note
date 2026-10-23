# 02 — Ferramentas e relações entre dispositivos

**Objetivo:** formalizar ferramentas, alternância entre dispositivos, suas prioridades e os efeitos sobre texto, tinta e navegação.

## 1. Princípio

A ferramenta visível selecionada e a **ferramenta efetiva** podem diferir durante uma ação temporária (pan com espaço, pan com botão do meio) ou pela entrada da caneta. A UI indica ambas sem troca surpresa de preferência persistente.

## 2. Matriz de ferramentas

| Ferramenta | Mouse | Caneta digitalizadora | Teclado | Efeito persistido |
|---|---|---|---|---|
| Texto | Clique cria/edita contêiner; arrasto interno seleciona caracteres | Toque pode posicionar cursor apenas se Texto explicitamente ativo | Digita no contêiner focado | Documento rico |
| Caneta/pincel | Arrasto desenha, se ativa | Contato desenha, com pressão disponível | Atalho ativa/retorna | Traço vetorial |
| Borracha | Arrasto apaga tinta | Contato apaga tinta | `E` alterna com caneta | Operação de remoção/recorte de tinta |
| Seleção de objetos | Clique, Ctrl/Shift+clique, arrasto por região | Laço/seleção conforme subtipo | Atalho e navegação de objetos | Seleção é temporária; mover é persistente |
| Mão | Arrastar desloca viewport | Arrastar com mão ativa desloca viewport | Espaço pressionado (temporário) | Não altera conteúdo |
| Régua | Orienta desenho; pode ser movida/rotacionada | Desenha seguindo régua | Atalho configurável | Somente os traços gerados |
| Cor | Escolhe amostra para próximos traços | Escolhe amostra pela barra | `1..9`; `0` abre paleta | Cor do novo traço ou da seleção editada explicitamente |
| Espessura | Seleção visual | Afeta largura base; pressão pode modular | Atalho configurável | Propriedade do traço |
| Zoom | Ctrl+roda, botões status | Controles acessíveis; não pressupor gesto multitoque da CTL-672 | `Ctrl++`, `Ctrl+-`, `Ctrl+0` | Somente viewport |

## 3. Prioridade e captura de entrada

1. **Modais de sistema e menus abertos** capturam suas teclas relevantes; ao fechar, foco retorna ao controle anterior.
2. **Edição textual em foco:** caracteres, números, espaço, `E` e atalhos locais são tratados como texto/navegação, **nunca** como ferramentas globais de tecla simples.
3. **Navegação temporária:** pressionar espaço fora da digitação ativa Mão; soltar retorna exatamente à ferramenta anterior, mesmo após arrasto. Arrastar com mouse3/botão central desloca a viewport enquanto pressionado, sem alterar ferramenta selecionada.
4. **Caneta no canvas:** no modo padrão híbrido, evento da caneta pode efetivar Caneta/Borracha conforme botão ou ponta, preservando a ferramenta do mouse; com Texto explicitamente selecionado para caneta, permite editar texto. Não presumir que todos os modelos expõem borracha na extremidade oposta.
5. **Ferramenta selecionada:** processa mouse e eventos restantes quando nenhuma regra superior se aplica.

**Recomendação de política de entrada:** mouse e caneta mantêm preferências de ferramenta separadas (`mouseTool`, `penTool`) com indicação clara da efetiva. Modo simplificado de ferramenta compartilhada é uma opção configurável, não requisito do MVP.

## 4. Caneta e produção de tinta

- Entrada: coordenadas, contato, pressão quando disponível, tempo e identificação do dispositivo quando suportado.
- Renderização: prévia imediata do traço enquanto coleta pontos; commit como objeto vetorial no encerramento.
- Traço realmente livre: **não transformar automaticamente** em reta, círculo ou forma regular.
- Configuração inicial de sensibilidade e suavização é interna, com defaults adequados e testados; controles técnicos avançados ficam fora do MVP.
- Borracha: MVP pode usar modo **traço inteiro** com cursor de alcance visível; modo de apagar parcialmente exige segmentação consistente e fica como evolução. Esta é uma decisão de escopo a validar.
- Seleção de tinta: contorno/laço e movimentação de um ou vários traços; preservar precisão em diferentes níveis de zoom.
- A caneta não precisa tocar um widget especial para produzir tinta; traços passam por cima de contêineres sem ser cortados por bordas.

## 5. Texto e tinta na mesma superfície

O texto reside em `TextContainer` e desenhos em `InkStroke`, ambos com coordenadas da página e IDs independentes. Um traço pode atravessar vários contêineres. Alterar texto não reposiciona automaticamente tinta; futura associação/ancoragem é prevista no modelo, mas não implementada no MVP. Se um traço sobrepuser texto, **a ferramenta e o contexto determinam o alvo**, não simplesmente o pixel superior.

Ordem visual inicial: papel → texto/outros objetos → tinta → overlays temporários (seleção, cursor, régua). Futuras ações trazer à frente/enviar atrás podem alterar a ordem entre objetos sem degradar a interação contextual.

## 6. Estados temporários e cancelamento

- `Esc` cancela operação em andamento antes de desmarcar seleção; em edição, sai do texto sem descartar conteúdo já digitado.
- Ao soltar espaço após pan, voltar à ferramenta anterior; ao perder foco da janela, limpar estados de tecla pressionada para evitar Mão travada.
- Se soltar botão do meio fora da área, deve encerrar pan (captura de ponteiro com tratamento de perda).
- Alternar de ferramenta enquanto um traço está em curso: concluir ou cancelar de modo determinístico; proposta: finalizar ao receber evento de saída, nunca deixar meio-traço órfão.
- Operações temporárias (pan e zoom) não entram no histórico de desfazer do conteúdo.

## 7. Riscos e cenários de teste

- Pressionar `E`, espaço e números enquanto digita deve inserir esses caracteres, não trocar ferramenta.
- Pressionar espaço, arrastar canvas e soltar após perder foco não deve deixar ferramenta travada.
- Editar texto com um traço sobreposto deve funcionar após escolher Texto.
- Desenhar com caneta enquanto mouse está sobre caixa de texto não deve deslocar a caixa.
- Trocar cor e espessura altera próximos traços sem recolorir acidentalmente os anteriores.
- Testar Wacom CTL-672 sob Windows e Linux; nenhum fluxo essencial pode depender de touch.
