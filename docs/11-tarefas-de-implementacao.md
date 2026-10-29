# 11 — Tarefas de implementação

Este quadro transforma os marcos de [09](09-roadmap-beta.md) e os portões de [10](10-plano-tecnico-desktop.md) em trabalho verificável. A beta inicial é Windows; Linux e macOS seguem depois. **Requisito** indica pesquisa, experimento, ferramenta ou decisão necessária para concluir a tarefa. Não há estimativa de data antes da prova do editor.

## Fundação e prova do editor

| ID   | Tarefa                                                   | Requisito                                                                                                                                           | Critério de aceite                                                                           |
| ---- | -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| T0.1 | Preparar CMake/C++20, testes e build Windows             | Instalar e fixar CMake, Ninja, compilador e Qt 6; auditar módulos/licenças; escolher licença do aplicativo antes de aceitar contribuições externas. | Build limpo e teste automatizado no Windows.                                                 |
| T0.2 | Modelar caderno, seção, página, IDs e invariantes sem UI | Revisar 04; criar fixtures; definir IDs estáveis e ordem.                                                                                           | Hierarquia válida, IDs repetidos rejeitados e testes sem Qt. **Iniciado neste repositório.** |
| T1.1 | Provar texto livre e tinta sobreposta                    | **Experimento:** comparar `QQuickItem`/scene graph com canvas Widgets e `QTextDocument`; testar caret, seleção, IME, foco e leitor de tela.         | Relatório com decisão Quick/Widgets e reprodução dos casos críticos.                         |
| T1.2 | Capturar caneta, pressão, zoom e pan                     | **Experimento:** Wacom CTL-672 real, DPI, perda de foco e página densa; medir latência, quadros, memória e erro geométrico.                         | Traço visível durante gesto e reabertura sem deslocamento, com medições.                     |
| T1.3 | Comandos de texto, tinta e seleção com undo/redo único   | Definir transações e gesto cancelado; provar seleção de texto sob tinta.                                                                            | Sequência mista reverte e reaplica preservando IDs e amostras.                               |

## Produto utilizável

| ID   | Tarefa                                           | Requisito                                                                                                            | Critério de aceite                                                       |
| ---- | ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| T2.1 | Armazenamento local versionado                   | **Experimento:** SQLite, journaling, backup consistente, disco cheio e interrupção; especificar esquema e migrações. | Fechar/reabrir preserva conteúdo; “Salvo” só após commit.                |
| T2.2 | Janela desktop, menus, Biblioteca e índice em Qt | T1.1 decide editor; empacotar IBM Plex e Phosphor localmente com avisos de licença.                                  | Navegação completa por mouse e teclado, offline.                         |
| T2.3 | Busca em títulos e texto digitado                | Definir indexação e atualização transacional com T2.1.                                                               | Resultado abre seção, página e contêiner corretos.                       |
| T3.1 | Imagens, SVG, formas, conectores e seleção mista | **Experimento:** desempenho de cena densa e SVG externo; vínculos por ID.                                            | Mover, redimensionar, agrupar, desfazer e reabrir sem perder relações.   |
| T3.2 | Importar PDF para anotar aulas                   | **Pesquisa:** confirmar licença do Qt PDF distribuído; testar PDFs reais; preservar original.                        | Slide e anotação continuam alinhados após zoom, reabertura e exportação. |
| T4.1 | Recuperação, lixeira, pacote editável e PDF      | **Experimento:** falhas de gravação, restauração em outra máquina e prévia A4/infinita.                              | Recuperar última versão íntegra e exportar sem corte silencioso.         |
| T5.1 | Beta fechada Windows                             | Instalação, acessibilidade, testes com aluno/professor e inventário de licenças.                                     | Cenário integrado de 09 sem defeito conhecido de perda de conteúdo.      |

## Portas posteriores

| ID  | Tarefa         | Requisito                                                                                     | Critério de aceite                                                |
| --- | -------------- | --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| P1  | Publicar Linux | CI e testes reais em distribuições escolhidas; caneta, IME, acessibilidade, fontes e pacotes. | Mesmo cenário e fixtures da beta Windows aprovados.               |
| P2  | Publicar macOS | Hardware real, menus do sistema, caneta/trackpad, acessibilidade e bundle.                    | Mesmo cenário e fixtures aprovados; pacote abre em máquina limpa. |

## Dívida técnica conhecida

Pontos levantados na revisão do Marco 1. Nenhum deles faz o aplicativo cair, mas devem ser resolvidos antes de virarem problema.

| ID | Problema               | Detalhe                                                                                                                                                             | Quando resolver                            |
| -- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| D1 | Desempenho             | Cada atualização da tela abre e fecha o arquivo SQLite várias vezes, e a lista de cadernos abre o banco de todos eles. Com muitos cadernos, a interface fica lenta. | **Resolvido.**                             |
| D2 | Erros silenciosos      | Adicionar seção ou página com nome vazio não faz nada e não mostra mensagem.                                                                                        | T2.2.                                      |
| D3 | Core não usado         | `notebook_model` é compilado e testado, mas o app não o usa; as regras estão duplicadas no SQL.                                                                     | T1.3, quando os comandos passarem a valer. |
| D4 | Gravação desnecessária | Abrir um caderno grava no banco, porque salva a última seção e página visitadas.                                                                                    | **Resolvido.**                             |
| D5 | Esquema do banco       | A posição dos itens é calculada pela contagem atual, o que gera posições repetidas quando existir exclusão.                                                         | T2.1, antes de implementar exclusão.       |

## Próxima sequência

A ordem das etapas e o catálogo de experimentos estão no [plano de evolução](14-plano-de-evolucao-e-experimentos.md); o estado atual e a fila de trabalho, no [roadmap vivo](../specs/ROADMAP.md). A licença do projeto continua sendo decisão necessária antes de contribuições externas ou publicação.
