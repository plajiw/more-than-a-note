# 10 — Plano técnico do aplicativo desktop

**Status:** proposta executável de arquitetura. **Plataforma de entrega inicial:** Windows 11. **Plataformas planejadas:** Linux e macOS, preservadas no desenho do núcleo e validadas em marcos próprios. Complementa `06-arquitetura-e-stack.md` e detalha a ordem técnica de `09-roadmap-beta.md`; não altera os requisitos de produto de 01–05.

## 1. Decisões e limites

- **C++20, Qt 6, CMake e Ninja.** Fixar uma versão Qt 6 suportada no início do código e atualizá-la por ciclo, após testes; não acoplar o formato de arquivo à versão de Qt. Aplicativo local, sem conta ou serviço obrigatório.
- **Qt Quick/QML** para Biblioteca, índice, barras e diálogos; **núcleo C++** para documento, comandos, geometria, tinta, renderização, busca e armazenamento. O HTML em `preview/` é referência visual, não runtime.
- **Uma página é um espaço de coordenadas lógico** contendo objetos identificados por UUID: `TextContainer`, `InkStroke`, `Image`, `Shape`, `Connector`, `PdfPageReference` e `Group`. Título, seção, papel e ordem são metadados, não widgets persistidos. Páginas não são “camadas”; os objetos dentro delas têm ordem de desenho.
- **Windows primeiro é uma estratégia de entrega, não uma dependência arquitetural.** Isolar APIs específicas atrás de adaptadores. Compilar periodicamente em Linux/macOS quando houver infraestrutura; a publicação nesses sistemas exige validação própria de caneta, fontes, acessibilidade, PDF e empacotamento.
- **Código aberto e forks:** selecionar a licença do aplicativo antes de aceitar contribuições; manter especificação pública do formato, fixture de migração, inventário de dependências/licenças e builds reproduzíveis na medida prática. Não presumir que licença do Qt obriga uma licença específica do produto.

## 2. Fronteiras de módulos

```text
apps/desktop          bootstrap, janelas, menus do SO, QML e tema
core/model            caderno, seção, página, IDs, objetos, relações e invariantes
core/commands         operações reversíveis, transações e undo/redo
core/geometry         transformações, seleção espacial, conectores, índice espacial
core/ink              amostras de caneta, pressão, borracha e tesselação
core/text             documento rico e ponte para edição/IME
core/render           cena, cache por região/zoom, prévia do traço
core/storage          SQLite, recursos, migrações, backup e recuperação
core/import_export    PDF, imagens, pacote editável e impressão
platform/windows      integração Windows e empacotamento
platform/linux        integração Linux futura
platform/macos        integração macOS futura
tests                 domínio, formato, falhas, regressão visual e dispositivos
```

`core/model` não conhece QML, janelas, DPI ou caminho de arquivo. UI solicita **comandos** (`MoveObjects`, `EditText`, `AddStroke`, `AttachInkToPdf`); comandos validam invariantes, alteram o modelo e publicam mudanças mínimas à cena. A mesma operação alimenta undo/redo, persistência e acessibilidade. IDs estáveis sobrevivem a mover/reordenar. Relações explícitas de grupo/conector e vínculo com PDF são gravadas por ID; nunca inferir vínculo durável apenas por sobreposição visual.

## 3. Experimento que decide a tecnologia do canvas

Criar um *vertical slice* antes da Biblioteca completa: uma página A4 e uma infinita, duas caixas de texto rico, tinta por Wacom CTL-672, seleção mista, zoom ancorado, pan, undo/redo, salvar/reabrir e PDF simples. Medir entrada ponta→prévia, tempo de quadro durante gesto, memória e erro geométrico após zoom/DPI. Testar IME, foco e leitor de tela. Fixar orçamento de desempenho com equipamento de referência e dados reais; evitar números arbitrários antes da medição.

**Candidatos de composição:** (A) `QQuickItem` próprio e nós do scene graph para cena/traços, com camada de edição de texto; (B) canvas Qt Widgets com `QPainter`/editor embutido se A comprometer IME, acessibilidade ou latência. `QQuickPaintedItem` serve como protótipo ou área pequena, mas não deve ser assumido como renderizador final de página extensa: seu caminho por textura tem custos que precisam ser medidos. `QTextDocument` é candidato para conteúdo rico; testar cursor, seleção, composição IME, listas, hyperlinks e desenho em várias escalas. **Decisão registrada por benchmark e testes de interação**, mantendo o modelo independente da tecnologia de exibição.

**Sondagem E4.1, Linux (25/10/2026):** a opção `--editor-probe` compõe dois `TextEdit` do Qt Quick com tinta de mouse produzida por um `QQuickItem` e nós `QSGGeometryNode`. Na sessão Wayland/OpenGL, a captura mostrou tinta acima do texto, e foi possível voltar à edição sem selecionar o traço. Um evento sintético de pré-edição/commit de IME e a proteção dos atalhos de tecla única passaram no Qt Quick Test. Isso favorece provisoriamente o candidato A; ainda faltam texto rico estruturado, IME real, 2.000 traços com medição de quadro, acessibilidade dos objetos e ensaios Windows para decidir EX1. O teste `offscreen` valida eventos, mas sua captura omitiu a geometria personalizada; usar a sessão gráfica real para evidência visual.

**O que é provisório:** Qt Quick já compõe a janela, os menus, o índice e a toolbar. A decisão em aberto é a tecnologia da **superfície de edição da página**. A sobreposição de dois campos e um traço prova composição básica, mas não prova que o caret e o IME se comportem bem com texto rico em várias escalas, que 2.000 traços mantenham a meta de quadro, nem que cada objeto seja navegável e anunciado por leitor de tela. EX2, EX4 e EX7 são os portões para tornar A definitivo. O modelo v2 guarda texto e tinta em tipos e coordenadas independentes do renderizador, de modo que um eventual canvas Widgets pode usar os mesmos dados.

Entrada de `QTabletEvent` passa por um adaptador com tipo de dispositivo, pressão, coordenadas lógicas e tempo; perder foco encerra gesto de forma determinística. A prévia é temporária; ao levantar a caneta, um único comando grava o traço vetorial. Amostras originais persistidas não devem ser alteradas de forma visível por suavização posterior. Borracha parcial será decidida pelo teste de aula previsto em 09; o formato aceita substituir um traço por segmentos com IDs novos e relação de origem.

## 4. Persistência e portabilidade do conteúdo

**Proposta inicial:** um diretório de trabalho por caderno com `notebook.sqlite` (metadados, objetos, texto estruturado, relações e índices), `assets/` com nomes por hash e um manifesto de esquema; exportação portátil em pacote versionado. SQLite via Qt SQL `QSQLITE`, transações curtas e um único escritor por caderno. Guardar pontos de tinta em blob binário com versão, precisão definida e teste de ida e volta; não usar HTML de `QTextDocument` como formato canônico sem provar fidelidade e compatibilidade. Preferir representação rica própria (parágrafos, spans, marcas e links) com adaptador de edição Qt.

Autosave agrupa comandos em transações; a UI só mostra “Salvo” depois de commit confirmado. Escolher e testar modo de journaling, checkpoint e política de backup contra encerramento abrupto, disco cheio e recuperação após falha. Não copiar apenas o arquivo principal enquanto houver journal/WAL ativo: usar mecanismo de backup consistente. Fechar caderno drena operações pendentes ou apresenta erro acionável. Lixeira preserva páginas/objetos removidos até retenção explícita. Migrações são incrementais, testadas contra fixtures de todas as versões publicadas; abrir versão futura não suportada em modo seguro, sem regravar.

Pacote editável carrega manifesto, banco consistente e recursos internos, com validação de caminhos, tamanho e hash antes de importar. Recursos externos ficam marcados como externos e geram aviso ao exportar. Configurações `.cfg` de `05` são preferências do aplicativo, separadas dos dados de caderno. Documentar o formato para leitores e forks; exportar PDF não substitui backup editável.

## 5. Bibliotecas, recursos visuais e licenças

| Área                             | Escolha inicial                                                       | Regra de adoção                                                                                                                             |
| -------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| UI, entrada, SVG, SQL, impressão | Módulos Qt 6 necessários, sob licença open source aplicável           | Auditar cada módulo e obrigação de distribuição do build concreto; evitar módulos GPL/comerciais não aprovados.                             |
| PDF importado                    | `Qt PDF` / `QPdfDocument`, sujeito à auditoria de licença e qualidade | Preservar PDF original como recurso e transformação de página estável; renderizar cache para tela, nunca converter a única cópia em bitmap. |
| PDF exportado                    | `QPdfWriter` + pipeline de renderização compartilhado com tela/prévia | Testar fontes, vetores, tinta e paginação A4/infinita; não usar screenshot como saída final.                                                |
| Dados locais                     | SQLite por driver `QSQLITE`                                           | Confirmar binário/versão fornecido no pacote e validar backup transacional.                                                                 |
| Ícones                           | Phosphor Icons SVG locais, subconjunto versionado                     | Licença MIT e aviso incluídos; mapear ícone por função, peso consistente e variante de estado. Não baixar em runtime.                       |
| Fontes                           | IBM Plex Sans para UI, conjunto local versionado                      | OFL 1.1 e aviso incluídos; texto do usuário permite outras fontes instaladas. Testar fallback e acentos.                                    |

Não escolher biblioteca de gráficos nativos antes de definir edição de dados; na beta, gráficos importados como imagem/SVG são objetos. Não integrar código ou formato de Xournal++ como dependência presumida. Estudar suas soluções de caneta/PDF e interoperabilidade depois de verificar licença, limites e escopo. O projeto Xournal++ demonstra suporte real a Windows, Linux e macOS, mas usa GTK, não Qt; a lição aqui é validar hardware e distribuição em cada sistema, sem copiar sua arquitetura.

## 6. Entrega por portões verificáveis

| Portão                | Entrega                                                                                                 | Saída obrigatória                                                                                                                       |
| --------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| T0 — base             | Repositório CMake, CI Windows, convenções, licença, SBOM simples, fixtures de documento                 | Build limpo, testes de modelo e pacote de desenvolvimento.                                                                              |
| T1 — prova do editor  | Vertical slice da seção 3                                                                               | Texto+tinta sobrepostos editáveis, IME, Wacom, zoom/DPI, latência medida, salvar/reabrir sem deslocar. Registrar escolha Quick/Widgets. |
| T2 — domínio e espaço | Biblioteca e índice do 01, páginas A4/infinita, comandos/undo, busca textual                            | Fluxo local completo sem conta; muitos itens e nomes longos; teclado e leitor de tela nos comandos essenciais.                          |
| T3 — aula             | Imagens, formas/conectores, grupos, PDF como base bloqueável, anotação vinculada                        | Importar slides, escrever, mover grupo, reabrir e manter alinhamento; seleção mista e undo.                                             |
| T4 — confiança        | Autosave, backup, lixeira, pacote editável, PDF com prévia                                              | Testes de interrupção/disk full, restauração em outra máquina Windows e exportação sem cortes silenciosos.                              |
| T5 — beta Windows     | Instalador, assinatura se disponível, documentação, telemetria apenas opt-in, testes aluno/professor    | Cenário integrado do 09 sem defeito conhecido de perda de dados.                                                                        |
| P1 — Linux            | CI + teste real em distribuições escolhidas, tablet/IME/acessibilidade, empacotamento                   | Mesmas fixtures e cenário integrado; diferenças documentadas.                                                                           |
| P2 — macOS            | CI + hardware real, menu do sistema, trackpad/tablet, acessibilidade, bundle/notarização conforme canal | Mesmas fixtures e cenário integrado; pacote instalável e teste de abertura.                                                             |

P1/P2 são **portões de publicação**, não promessa implícita da beta Windows. Desde T0, evitar `#ifdef` de plataforma no domínio e adicionar compilação cruzada/nativa quando viável. Se Linux/macOS surgirem antes, só anunciar suporte após os respectivos testes.

## 7. Riscos que precisam de prova

1. **IME/acessibilidade em texto livre sobre cena:** maior risco de composição. Se Qt Quick exigir ponte frágil, adotar editor interno Widgets sem refazer domínio/UI externa.
2. **Tinta densa e PDF grande:** usar índice espacial e cache em ladrilhos/regiões, invalidar só o necessário; perfilar antes de otimizar. Evitar milhares de itens QML individuais para cada ponto de caneta.
3. **Consistência tela↔PDF:** compartilhar coordenadas e primitivas de renderização; ensaio com fontes faltantes, escalas e conteúdo fora de A4.
4. **Recuperação:** SQLite transacional ajuda, mas não garante sozinho backup seguro, recursos coerentes e correção de bugs de modelo. Testes de falha e migração são gates.
5. **Portabilidade:** diferenças de tablet, IME, fontes, menu e distribuição são trabalho real. Windows inicial reduz simultaneidade, sem eliminar esse investimento.

## 8. Fontes técnicas consultadas

- [Qt — `QTabletEvent`](https://doc.qt.io/qt-6/qtabletevent.html), [`QTextDocument`](https://doc.qt.io/qt-6/qtextdocument.html), [`QQuickPaintedItem`](https://doc.qt.io/qt-6/qquickpainteditem.html), [desempenho Qt Quick](https://doc.qt.io/qt-6/qtquick-performance.html).
- [Qt PDF](https://doc.qt.io/qt-6/qtpdf-index.html), [`QPdfWriter`](https://doc.qt.io/qt-6/qpdfwriter.html), [Qt SQL / SQLite](https://doc.qt.io/qt-6/sql-driver.html), [`QSaveFile`](https://doc.qt.io/qt-6/qsavefile.html), [obrigações LGPL](https://www.qt.io/development/open-source-lgpl-obligations).
- [Xournal++ — repositório e plataformas](https://github.com/xournalpp/xournalpp), [Phosphor — licença MIT](https://github.com/phosphor-icons/core/blob/main/LICENSE), [IBM Plex — OFL 1.1](https://github.com/IBM/plex/blob/master/LICENSE.txt).

**Nota:** as fontes confirmam capacidades e licenças dos projetos citados, não certificam a adequação do conjunto final de binários. A auditoria de dependências deve usar as versões realmente empacotadas.
