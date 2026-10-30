# 20 — Plano do Marco 3: objetos e diagramas

**M2 · 30/10/2026 · proposta pendente de validação.** Derivado da [arquitetura 22](22-arquitetura-editor-visual-unificado.md), em especial I01–I09 e ADR-M2-01/02/03/05. Não é implementação nem alteração do contrato [16](16-formato-conteudo-v2.md). A ordem vigente E4.8 → E6 → E7 → Marco 3 permanece; E5 avança quando houver Wacom e bloqueia a beta.

## 1. Entrada e saída do marco

**Entrada:** EX1/EX2/EX4/EX7 avaliadas para a base existente; preservação de pendências e limites de reabertura tratados em E6; comando/seleção testáveis; aprovação das extensões de formato e das questões de produto abaixo. A carga de diagramas exige reavaliar EX1 quando os tipos existirem: o plano não presume que E4.8 já desenhe formas.

**Saída:** criar e editar diagrama ao lado de texto e tinta, mover/duplicar grupos, desfazer/refazer e reabrir conservando geometria/referências/estilos. Mouse e teclado alcançam as mesmas ações essenciais. Imagens/gráficos estáticos continuam no escopo do Marco 3 do 04; não desaparecem por esta revisão focar diagramas.

**Fora:** auto-layout de grafos, roteamento avançado por obstáculos, grupos aninhados, edição de dados de gráficos, reconhecimento de formas/escrita, colaboração, importação .one, PDF anotável e exportação final. Rotação/escala coletiva de tinta/texto depende de revisar o contrato atual, portanto não é ativada neste plano.

## 2. Objetos e apresentação

| Tipo | Semântica proposta | Geometria, edição e limites |
| --- | --- | --- |
| Retângulo, elipse, losango | `ShapeObject` com tipo e estilo; losango é extensão ainda ausente no enum | Dimensões positivas; criar por press/drag/release, Esc cancela; comando Inserir pelo teclado cria no centro útil da viewport, convertido a pt |
| Linha e seta livres | Formas sem vínculo; não confundir com conector | Comprimento não nulo; geometria local e transformação definem orientação; snap de ângulo opcional só depois de validação |
| Texto livre | `TextContainer` atual | Preservar alça superior e largura/reflow; corpo seleciona caracteres, não move |
| Rótulo de forma | `RichTextDocument` opcional incorporado ao payload do dono | Sem ID espacial próprio; edição pelo mesmo adaptador Qt; seleção textual separada da seleção da forma |
| Rótulo de conector | Texto incorporado, posição escalar ao longo da rota | Padrão central; offset em pt; recompor sem alterar vínculo; não criar caixa livre implicitamente |
| Grupo | `GroupObject` plano existente | Sem camada pintada nem transformação; bounds é união dos filhos; mover aplica delta uma vez em cada membro |
| Imagem/gráfico | Tipos existentes com ativo incorporado | Importador posterior do marco valida hash, dimensão, MIME e SVG sem referências externas; descrição acessível |

**Estilos:** contorno/preenchimento/cabeças de seta pertencem ao conteúdo, em pt e RGBA. Defaults partem dos tokens/paletas aprovados no 13, mas os valores escolhidos no documento não mudam quando o tema muda. Não persistir ponteiro ou nome mutável de token de UI como única cor de conteúdo. Molduras/portas/alças são overlays, não contorno exportável. Interface mantém Inter, papel usa as fontes atuais, foco usa token do papel; nenhum redesign é autorizado aqui.

**Rótulos, decidido pelo dono do produto em 30/10/2026:** centralizados na área interna da forma, com quebra de linha. Quando o texto não cabe, **a forma cresce para baixo**, como no Excalidraw e no FigJam: a largura fica fixa e a altura acompanha o conteúdo, do mesmo modo que o card de texto (13, aplicação E4.4). Nunca cortar, rolar dentro da forma ou encolher a fonte automaticamente; o usuário ajeita mudando o tamanho da fonte ou a largura. Redimensionar à mão não deixa a altura abaixo da do conteúdo. O crescimento faz parte do mesmo comando de edição do rótulo (um único passo de desfazer), as portas acompanham a geometria e os conectores se recompõem; vizinhos não são empurrados. Em losango e elipse a área útil é a inscrita na forma. O layout final exige estudo visual/galeria antes da implementação (M3.4). *Proposta anterior, substituída:* não crescer, mostrar o excesso e oferecer “Ajustar forma ao rótulo”. Alternativas avaliadas: caixa independente vinculada (mais flexível, mais referências e ambiguidades de seleção), string simples (menos fiel), payload rico incorporado (recomendado para reaproveitar DTO/IME). Labels não implicam suportar toda formatação na toolbar de imediato: não descartar estilos existentes ao limitar os controles.

**Sobreposição, decidida pelo dono do produto em 30/10/2026:** respeitar ordem Z de conteúdo; seleção não muda pintura. Só alças, contorno de seleção e caret sobem como overlay; o objeto selecionado continua na sua camada, inclusive durante a edição de texto, como no Excalidraw e no Figma. Para pô-lo por cima de verdade, o usuário usa "Trazer à frente". Isso resolve o conflito 13 §6.1 versus 04 §5 a favor do 04 §5: a promoção do card selecionado (13 §6.1) é retirada no corte M3.2, que também mostra o caso na galeria. Ferramenta Texto alcança rótulo/card mesmo sob tinta. Seleção escolhe o candidato elegível superior e permite escolher outro por lista/menu, sem reordenar.

## 3. Conectores como relações

### 3.1 Contrato de extremos

Um extremo livre guarda posição em pt da página. Um extremo ligado guarda `target_id` e porta; fallback também existe, mas não é autoridade enquanto ligado. Portas iniciais são as já existentes: Center, Top, Right, Bottom, Left. P: na UI de criação, apresentar as quatro bordas; Center continua legível e pode ser escolhido explicitamente. Não converter Center em auto-interseção sem mudar seu significado. Para retângulo/losango/elipse as portas laterais são pontos médios/extremos no espaço local, transformados para a página; rotação do alvo leva suas portas junto.

Alvos elegíveis conservam a regra do núcleo: texto, forma, imagem e gráfico da mesma página. Tinta e grupos não são alvos iniciais. Laço que liga um nó a si mesmo não é referência a si do conector; pode ser válido no modelo, mas a UI inicial deve recusar uma rota degenerada com explicação. Não desenhar silenciosamente uma aresta de comprimento zero.

| Ação | Resultado atômico esperado |
| --- | --- |
| Criar | Resolver alvo/porta de cada ponta ou posição livre; validar IDs; criar um objeto e uma entrada de histórico |
| Mover/redimensionar/rotacionar alvo | Rota derivada se atualiza na prévia e após commit; nenhuma nova operação de usuário só para atualizar desenho |
| Reconectar | Arrastar alça da ponta → prévia de candidato → release substitui attachment; vazio cria extremo livre; Esc restaura vínculo anterior |
| Excluir alvo | Calcular posição atual; substituir ponta ligada por livre nesse ponto e excluir alvo no mesmo comando |
| Desfazer exclusão | Restaurar nó, attachment e fallback anterior como conjunto; nenhuma referência órfã intermediária publicada |
| Duplicar seleção | Remapear attachments cujos alvos também foram copiados; demais viram livres na posição resolvida; conectores fora da seleção não são duplicados automaticamente |
| Mover conector com ambas as pontas ligadas | Não deslocar nós escondidamente; orientar usuário a mover nós ou reconectar. Pontas livres selecionadas podem receber delta |

### 3.2 Rota reta e ortogonal

Começar com segmento reto, após os testes de vínculo. Rota ortogonal é corte separado: algoritmo determinístico em pt, com saída por normal da porta quando aplicável e segmentos horizontais/verticais. Proposta inicial H–V ou V–H, com preferência persistida e eventualmente waypoints explícitos; evitar segmentos zero, validar finitude e recalcular segmentos derivados. Em colisão com outro objeto, conservar rota editável e permitir waypoints; não prometer desvio automático de obstáculos. Waypoints manuais não viram segunda identidade do conector; pertencem ao seu payload e ao mesmo histórico.

Linha livre usa geometria própria; conector usa extremos resolvidos. Um conector com pontas livres também é válido. Não converter linha em conector apenas por encostar num objeto. A observação de waypoints do [draw.io](https://www.drawio.com/docs/manual/connectors/waypoints-connectors/) sustenta edição explícita de caminhos, não impõe copiar seu algoritmo.

## 4. Seleção, teclado e coexistência

Adotar contrato de hit-testing do 22 §5. Seleção espacial é conjunto de UUIDs e ID principal; grupos expandem membros para a operação, sem aplicar duas vezes. Texto selecionado por caracteres não entra no mesmo conjunto de uma seleção espacial até sair da edição. Bloqueados continuam descobríveis; se uma transformação de grupo inclui membro bloqueado, recusar o conjunto com motivo, não mover os demais silenciosamente.

**Matriz de ações:**

| Ação | Fora da edição textual | Dentro de texto/rótulo |
| --- | --- | --- |
| Enter / Esc | Enter edita rótulo/card se disponível; Esc cancela gesto, depois limpa seleção | Enter cria parágrafo; Esc termina edição sem perder texto confirmado; composição IME tem tratamento próprio |
| Setas | Mover seleção quando no contexto de manipulação; passo em pt, com repetição fundida | Navegação textual |
| Tab / Shift+Tab | Percorrer controles conforme 03 | Navegação de foco atual; nunca cria forma globalmente |
| Ctrl+C/X/V | Serialização de seleção por IDs, com regras de remapeamento | Área de transferência textual do Qt |
| Ctrl+D / Delete | Duplicar/excluir seleção com dependências; menu oferece alternativa | Não duplicar/excluir objeto; Delete apaga caractere |
| Traço de caneta | Desenhar sobre quaisquer objetos quando Caneta efetiva | Não mover card; Texto para caneta só por escolha explícita |
| Pan / zoom | Somente viewport, fora do histórico | Preservar caret/IME e evitar atalhos de uma tecla que consumam texto |

### 4.1 Fluxo de diagrama com pouco mouse

1. Acionar Inserir → Forma → Retângulo pelo teclado; objeto aparece em posição útil e recebe foco.
2. Enter inicia rótulo; digitar; Esc retorna à forma selecionada.
3. Acionar “Criar objeto conectado…”; escolher direção/tipo por controle acessível, confirmar. P: criar nó e conector num único comando; foco vai ao novo rótulo.
4. Navegar por objetos em readingOrder por ações dedicadas; oferecer ação para seguir conexões sem alterar essa ordem global.
5. Mover nós por setas no contexto de manipulação, editar rótulos com Enter, desfazer/refazer como na página inteira.

**Tab cria conectado** é somente hipótese de uso. Testar em protótipo integrado futuro contra ação explícita, medindo erros de criação, retorno de foco e sucesso com leitor de tela. Recomendação: manter Tab para foco; se houver modo rápido opt-in, apresentá-lo claramente e permitir sair com Esc. Não reservar atalhos novos na M2.

### 4.2 Ímã e alinhamento

O [19](19-ima-pagina-e-escrita.md) é dono do ímã: desligado ao iniciar, página lisa sem guia, grade/pauta em pt, tecla modificadora suspende gesto. Estender a objetos do Marco 3 exige proposta explícita: snap na criação/movimento de formas e portas; nunca na coleta de tinta livre ou no caret. Tolerância visual deve ser convertida por zoom, sem persistir deslocamentos de pixel.

Alinhar usa bounds geométricos de conteúdo, não alças; seleção mista move objetos sem redimensioná-los. Distribuir três ou mais unidades usa extremos externos e espaçamento uniforme, preservando ordem relativa; desabilitar com motivo quando não aplicável. Grupo conta como unidade. Snap de página e alinhamento a objetos devem ter indicação distinta; não ativar um automaticamente ao ligar o outro.

### 4.3 Copiar e colar

Pacote de clipboard interno versionado com limite de bytes/objetos, payloads, relações e metadados necessários; conteúdo externo é validado como importação. Antes de criar, calcular mapa de IDs e desvincular pontas cujo alvo não está no pacote. Copiar grupo inclui seus membros; copiar filho isolado remove vínculo ao grupo. Preservar posições relativas com deslocamento único e readingOrder relativa. Recortar só remove após captura válida do pacote; colar falho não muda a página. Colagem entre cadernos com ativos precisa copiar e confirmar recursos antes do vínculo; transação entre dois cadernos não é resolvida por duas pilhas locais. A primeira entrega pode suportar copiar/colar sem recorte entre cadernos e informar essa limitação, sem perda silenciosa.

## 5. Evolução versionada do formato — proposta

### 5.1 Separar versões

O banco atual tem `user_version=4`; MTNT v2 e MTNI v1 continuam intactos. `page_objects.kind` e `prepareObject` recusam qualquer diagrama/grupo. Não armazenar JSON de forma no blob de texto nem remover a restrição SQL sem mudar versão. **S_obj** designa a próxima versão livre do esquema na atividade de implementação (seria 5 apenas se E6 não a consumir). Não reservar esse número unilateralmente.

| Camada proposta | Alteração / invariantes |
| --- | --- |
| SQL S_obj | Ampliar kinds para shape/connector/group e, no corte de ativos, image/graphic; relações de grupo e extremos em representação versionada; mesma FK de página |
| Forma | Tipo (incluindo Diamond), dimensões, estilo de contorno/preenchimento, rótulo opcional rico; rotação no transform comum |
| Conector | Dois extremos, modo straight/orthogonal, preferência de rota/waypoints, estilo/cabeças, rótulo/posição; transform identidade |
| Grupo | Lista de filhos em ordem estável; parent em campo comum; reciprocidade validada na página inteira |
| Relações | Payload do conector é autoridade para attachments; índice reverso em memória derivado; não manter segunda tabela de vínculo sem contrato de sincronização |
| Metadados de recuperação | Dependem de E6, com revisão/operação confirmada; não embutir versões do schema em MTNT |

**Escolha de encoding proposta:** novos blobs tipados determinísticos seguindo a disciplina do 16. Cabeçalho: magic próprio por família (`MTNS`, `MTNC`, `MTNG`, nomes candidatos), versão u16, marcador LE, flags reservadas zero, contagens u32; campos geométricos f64 LE finitos; strings UTF-8 com comprimento limitado; enum numérico com tabela documentada e desconhecido recusado. Rótulo contém subblob MTNT v2 com comprimento, reutilizando decoder e limites. Mapear explicitamente enum, não serializar layout de struct/variant. Tabelas byte a byte, limites por tipo e golden fixtures são saída obrigatória de M3.1 antes de qualquer escrita; esta proposta não se apresenta como codec executável.

Alternativas: JSON versionado facilitaria inspeção mas criaria nova regra de número/validação/canonicalização; colunas SQL de todos os campos facilitariam consultas, mas expandiriam migrações a cada estilo. Recomenda-se payload tipado + campos comuns já existentes, com relações validadas como conjunto. A escolha final do novo encoding exige revisão do 16, não se presume aprovada.

### 5.2 Exemplos semânticos de serialização

Estes JSONs são **visões explicativas do DTO futuro**, não bytes aceitos pelo app. Um serializador futuro usaria o envelope acima; `shape_id` é mostrado aqui como UUID completo, nunca índice.

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "page_id": "33333333-3333-4333-8333-333333333333",
  "kind": "shape",
  "transform": {"tx": 72, "ty": 144, "rotation_degrees": 0, "scale_x": 1, "scale_y": 1},
  "z_order": 10, "reading_order": 20, "locked": false,
  "accessible_description": "Validar credenciais",
  "group_id": null,
  "payload_version": 1,
  "payload": {
    "shape": "rectangle", "width_pt": 120, "height_pt": 60,
    "style": {"stroke_rgba": "#282B2EFF", "fill_rgba": "#FFFEFAFF", "stroke_width_pt": 1},
    "label": {"paragraphs": [{"kind": "Body", "runs": [{"utf8": "Validar", "style": {}}]}]}
  }
}
```

```json
{
  "id": "22222222-2222-4222-8222-222222222222",
  "page_id": "33333333-3333-4333-8333-333333333333",
  "kind": "connector",
  "transform": {"tx": 0, "ty": 0, "rotation_degrees": 0, "scale_x": 1, "scale_y": 1},
  "z_order": 11, "reading_order": 21, "locked": false, "group_id": null,
  "payload_version": 1,
  "payload": {
    "start": {"fallback": [192, 174], "attachment": {"target_id": "11111111-1111-4111-8111-111111111111", "port": "Right"}},
    "end": {"fallback": [300, 174], "attachment": null},
    "routing": "straight", "waypoints": [],
    "style": {"stroke_rgba": "#282B2EFF", "stroke_width_pt": 1, "end_head": "arrow"}
  }
}
```

Se o nó acima for removido, a ponta inicial vira `{"fallback":[192,174],"attachment":null}` no mesmo comando. Se antes ele se mover, congelar o valor resolvido novo, não 192/174. Undo restaura ambos os objetos.

Agrupar os dois objetos exige adicionar `GroupObject` com ID novo e `child_ids=[id_da_forma,id_do_conector]`, além de atribuir esse ID a ambos os `group_id`, num lote. Duplicar o grupo cria três IDs novos e remapeia attachment; o extremo livre recebe o mesmo delta da cópia. O exemplo demonstra que grupo não é transform pai acumulado.

### 5.3 Migração e compatibilidade

**Lembrete de 30/10/2026 (dono do produto):** o formato deve deixar espaço para a hora de criação e de alteração de cada objeto e nunca descartar o tempo relativo dos pontos de tinta, para não fechar a porta a uma futura reprodução da construção da página ([ideias](ideias.md), depois da beta).

1. Ler versões antigas sem escrever e preservar UUIDs, MTNT/MTNI, posições e ordens.
2. Validar versão/capacidades antes de migração; obter backup consistente segundo E6; falha de backup não pode ser silenciosa.
3. Migrar uma versão por transação: criar/reconstruir tabelas, copiar, validar contagens/FKs/domínio e publicar `user_version` no commit. Retomar de qualquer versão intermediária válida.
4. Gravar novo tipo somente depois de leitor e writer suportarem o mesmo contrato. Leitor antigo recusa versão futura sem regravar; não prometer downgrade nem abrir somente os textos descartando os demais.
5. Validar grupos e conectores na página final completa, não pelo `prepareObject` atual que valida objeto isolado; esse método não basta para dependências.
6. I08 aplica limites antes da escrita e da alocação na leitura; uma página gravada com sucesso deve ser reabrível. Relação inválida não é “consertada” apagando conteúdo; oferecer diagnóstico/recuperação numa cópia.

Testar fixtures v1–v4 e S_obj, arquivo futuro, payload desconhecido, UUID duplicado, grupo unilateral/cíclico, alvo removido e limites. Toda migração física pertence a atividade futura.

## 6. Cortes pequenos de implementação

**M3.1…M3.10 são rótulos de cortes deste plano, não IDs de manutenção a passar ao script.** Ao iniciar execução, registrar a atividade de roadmap conforme workflow e numeração vigente, referenciando o corte; não confundir Marco 3 com uma manutenção chamada M3. Cada corte escreve sua spec/tasks e só fecha após suíte completa, evidence/galeria, aprovação e reabertura quando há conteúdo.

| Corte / objetivo | Dependências e componentes | Escopo permitido / excluído | Aceitação, testes e evidência | Risco e condição de encerramento |
| --- | --- | --- | --- | --- |
| M3.1 — Contrato executável | E6/E7 e aprovação do §5; modelo, codec, schema/repository | Especificar bytes/limites, adicionar DTOs/codecs/fixtures e migração; sem UI de criação | Golden bytes, invalid/future, migração interrompida e round-trip com rótulos/relações; inspeção dos dados, suíte completa | Versão colide com E6; fechar só quando esquema escolhido/documentado e leitor antigo recusa sem escrita |
| M3.2 — Geometria e composição | M3.1 e EX1; projeção/renderer | Bounds, portas, ordem Z geral, overlays separados; formas de fixture; sem novo gesto | Sobrepostos texto/tinta/forma nos dois temas e zoom; inverter ordem mantém leitura; `objects-overlap` na seção Editor | Promoção de card conflita com padrão atual; exige aprovação específica |
| M3.3 — Seleção e movimento misto | M3.2; sessão de gesto/hit-test/PageSession | Clique/múltipla/retângulo, mover, Esc, teclado; sem grupo/rotação coletiva | Delta único, bloqueios, captura perdida, undo e reabrir; `mixed-selection-move` | Foco/IME e delta duplicado; fechar após testes de cancelamento e lote |
| M3.4 — Formas e rótulos | M3.1–3; toolbar/adapter/texto | Retângulo/elipse/losango/linha/seta, tamanho, estilos, rótulo; sem conector ligado | Criar por mouse e teclado, overflow explícito, editar sob tinta, histórico e reabertura; `shape-label-edit` | Layout de losango/rótulo; fechar após IME e teclado reais conforme portão da plataforma |
| M3.5 — Conector reto | M3.4; resolvedor de relações/comandos | Criar/vincular/reconectar/liberar/excluir alvo; sem rota ortogonal | Mover e redimensionar alvo, undo de exclusão, DB íntegro; `connector-reconnect`, `connector-delete-undo` | Ponta com fallback obsoleto; fechar com toda matriz §3.1 |
| M3.6 — Grupos e clipboard | M3.3–5; comandos/codec clipboard | Grupo plano, desagrupar, duplicar/colar subgrafo, Z/leitura; sem grupos aninhados/transação de recorte entre cadernos | Referências internas remapeadas, externas livres; uma operação/undo; `group-duplicate-reopened` | Filhos órfãos/dupla transformação; fechar cenários A/B parciais |
| M3.7 — Laço, snap e alinhamento | M3.3/6 e decisão do ímã; geometry/tools | Laço por interseção, guias opcionais, alinhar/distribuir; sem OCR/forma automática | Pontos isolados/traços cruzando polígono, zoom, snap desligado/modificador; `lasso-snap` | Escolha involuntária; fechar com roteiro de uso aprovado |
| M3.8 — Rota ortogonal simples | M3.5/6; geometry/connector codec | H–V/V–H, waypoints editáveis, rótulo de aresta; sem auto-route avançado | Determinismo, rota após resize, sem segmentos inválidos, round-trip; `orthogonal-route` | UI promete desvio automático; fechar explicitando limite |
| M3.9 — Ativos estáticos | E6 e M3.3/6; importer/assets/storage | Imagem/gráfico raster/SVG incorporado, descrição, mover/tamanho e clipboard com recursos; sem dados de gráfico editáveis | Hash/dimensão/caminho, SVG sem recurso externo, crash entre arquivo e vínculo, offline; `mixed-assets-reopened` | Recursos órfãos/consumo; fechar só com protocolo transacional de ativos |
| M3.10 — Produtividade e carga integrada | M3.4–9, E5 para prova com caneta; teclado/acessibilidade/EX1 | Ações conectadas por teclado, refinamento acessível e cenários A/B; sem Tab global nem mudança silenciosa de engine | A/B completos, C com Wacom em seu portão, EX1 carga mista, D em E6; `keyboard-flow-reopened` | Etapa virar polimento ilimitado; descobertas fora dos critérios viram desvios; fechar sem regressão de dados |

M3.10 integra contratos já aprovados em cortes pequenos; não concentra construção de todas as funções. A criação conectada pelo teclado pode ser antecipada ao M3.5 se os comandos básicos estiverem estáveis, mantendo o teste integrado ao final. Reordenação geral nasce em M3.2/6, não depende de laço. Imagens não bloqueiam a prova inicial AVL, mas são necessárias para encerrar o marco conforme o 04.

## 7. Roteiro futuro na galeria

Nomes abaixo são pontos de captura propostos, ainda inexistentes; as atividades futuras os implementam por `inputDriver.capture` e atualizam o checklist. Usar seção Editor e caderno de amostra em perfil isolado, com subseções se necessário, sem novo modo de execução.

1. Carregar cenário misto conhecido, conferir IDs/ordem e texto sob tinta; capturar `objects-overlap`.
2. Selecionar forma+card+traço, arrastar em 50%, 100% e 300%, cancelar e confirmar; capturar `mixed-selection-move`.
3. Ligar dois nós, mover/resize, reconectar, excluir alvo e desfazer; capturar `connector-delete-undo`.
4. Duplicar grupo com conector interno e outro externo; reabrir e conferir vínculos; capturar `group-duplicate-reopened`.
5. Percorrer criação/rótulo/conexão só por teclado e leitor real; capturar `keyboard-flow-reopened` e registrar fala/retorno de foco.
6. Ligar/desligar ímã, desenhar tinta livre, trocar tema e monitor; capturar `lasso-snap`; DPI físico continua teste separado.
7. Executar cenário de falha E6 em fixture isolada; erro mantém conteúdo e não afirma Salvo; capturar `save-error-pending`.

Conferir temas grafite/claro, escalas simuladas 100/150 e janela estreita. Simulação não substitui monitores físicos; mouse não substitui Wacom. Nenhum item deste roteiro é marcado aprovado na M2.

## 8. Pendências de aprovação e documentos donos

- Formato S_obj e rótulo incorporado: revisar 16 e famílias do 04 §2.2 após aprovação, antes do codec.
- Z de conteúdo versus promoção de card: resolver 13 §6.1/04 §5 antes de M3.2.
- Interseção no laço, borracha inteira, gestos e limites de transformação: 02/04; manter contratos atuais até decisão.
- Atalho de criação conectada: 03, sem substituir Tab por inferência.
- Rótulo que excede a forma, portas e sinais de seleção: estudo do 13 e galeria antes de implementar componentes.
- Critérios quantitativos de carga: EX1 após baseline; a existência deste plano não os aprova.
