# 12 — Registro de implementação orientada por especificações

Este registro liga cada decisão de código aos contratos de produto. A referência de aceite é o [Marco 1 do roadmap](09-roadmap-beta.md), complementado pelo [plano técnico](10-plano-tecnico-desktop.md). **Status do Marco 1: concluído na implementação de desenvolvimento Windows; ainda sem instalador público.**

## Contexto e interpretação do marco

O usuário autorizou iniciar o desenvolvimento até concluir o marco. O trabalho atual toma “o marco” como **Marco 1 — Fundação do aplicativo**, pois é o primeiro marco ainda aberto. A beta inicial é Windows; Linux e macOS continuam no desenho técnico, com validação posterior. A caneta não é necessária para este marco: sua prova real pertence ao Marco 2. Não simular pressão de mouse como evidência de funcionamento de caneta.

## Decisões aplicadas

| Decisão                                             | Especificação     | Por quê                                                                                  |
| --------------------------------------------------- | ----------------- | ---------------------------------------------------------------------------------------- |
| `core/model` em C++20 sem Qt                        | 04 §1; 10 §2      | IDs e hierarquia devem sobreviver a mudanças de UI e de plataforma.                      |
| Aplicativo Qt Quick/QML sobre backend C++           | 06 §2; 10 §1–2    | Biblioteca e índice podem seguir o layout desktop enquanto dados ficam fora do QML.      |
| Biblioteca e caderno como telas distintas           | 01 §2.1–2.2       | Outros cadernos não aparecem durante a edição.                                           |
| Lista de páginas filtrada pela seção ativa          | 01 §4; 04 §1      | Preserva a hierarquia caderno → seção → página.                                          |
| Um diretório e SQLite por caderno, esquema versão 1 | 10 §4             | Deixa o conteúdo local e prepara um formato versionado, sem guardar posições de widgets. |
| Última seção/página no banco do caderno             | 01 §2.1           | Reabrir restaura o contexto de navegação.                                                |
| Estado vazio de seção e página                      | 01 §1.1, regra 11 | O usuário vê a próxima ação sem dados artificiais criados automaticamente.               |

## Trabalho realizado nesta etapa

- Criados `CMakeLists.txt`, modelo C++ e teste de invariantes de IDs.
- Criados o backend Qt de cadernos/seções/páginas e a janela QML com menus, Biblioteca, índice, tema grafite/claro e criação local.
- O editor de conteúdo ainda é uma superfície de indicação; texto, tinta, PDF e ferramentas pertencem aos marcos seguintes.
- O ambiente inicialmente não continha CMake, Ninja ou Qt. Foram instalados em MSYS2 UCRT64: Qt Base/Declarative 6.12.0, CMake 4.4.4, Ninja 1.13.2 e GCC 16.2.0. O build fixa Qt 6.8 como mínimo de API; o ciclo de desenvolvimento validado aqui usa 6.12.0.
- Adicionado workflow Windows de build e testes; a execução remota da CI depende de envio do repositório ao GitHub e não foi usada como evidência de aceite local.

## Verificação exigida antes de encerrar o Marco 1

1. **Aprovado:** CMake configurou e compilou o executável Qt e os testes. O executável iniciou em modo offscreen sem erros QML e permaneceu ativo até o encerramento controlado. O runtime usa recursos locais dos pacotes Qt; o HTML de `preview/` não é carregado.
2. **Aprovado por teste de integração:** criar caderno, seção e página; destruir o backend e instanciá-lo novamente; confirmar títulos, IDs e última seleção. `ctest` passou 2/2 testes.
3. **Aprovado por teste de integração e estrutura da UI:** outro caderno abre sem seções/páginas do primeiro; a Biblioteca é uma tela separada e o índice consulta apenas o caderno ativo.
4. **Aprovado por teste de integração:** versão futura do esquema é recusada com erro, sem regravação.
5. **Implementado e iniciado sem erro QML:** menus Arquivo/Editar/Exibir/Inserir/Ajuda, grafite/claro e nomes acessíveis para as ações de criação. Avaliação com leitor de tela e revisão visual em diferentes DPI continuam para os portões de acessibilidade e editor.

**Comandos locais usados:** `cmake -S . -B build/qt -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=C:/msys64/ucrt64`, `cmake --build build/qt --parallel 4` e `ctest --test-dir build/qt --output-on-failure`, com `C:\msys64\ucrt64\bin` no início de `PATH`. O teste de queda durante gravação, backup consistente e recuperação pertencem ao Marco 5; por isso a interface atual mostra “Caderno local” em vez de prometer um estado de salvamento durável para o editor futuro.

## Índice visual para avaliação — 23 de outubro de 2026

Aplicados os passos 6 e 7 do documento 13 ao índice do caderno: cabeçalhos compactos, linhas próprias para seções e páginas, ações contextuais, menu estilizado e criação/renomeação inline. O backend agora persiste renomeação e cor de seção e exclusão confirmada de seções/páginas; ao excluir o item ativo, a seleção vai para o vizinho lógico. A posição de novos itens usa `MAX(position)+1`, evitando colisão após exclusão. A galeria inclui o cenário `--gallery-index`, com captura em `preview/index-v1.png`.

Verificação local: build Release, `ctest --preset release` (2/2), teste de criar/renomear/recolorir/excluir/reabrir e captura Qt sem erro QML. A avaliação visual do dono do produto ainda decide o acabamento. Configuração de papel, ícones personalizados de seção e editor de conteúdo permanecem nas etapas correspondentes do plano.

## Decisão de continuidade — 23 de outubro de 2026

Após a avaliação positiva do layout, a rodada de componentes visuais se encerra com `AppCheckBox` e `SelectList` na galeria Qt. O checkbox marcado usa preenchimento colorido interno, separado do contorno, sem marca em “V”. A captura está em `preview/controls-v1.png`; build Release, `ctest --preset release` (2/2) e abertura da galeria passaram.

**Próximo caminho acordado:** montar a moldura completa do caderno no aplicativo (E2): índice recolhível, toolbar, página e barra de status. Em paralelo, definir os objetos de conteúdo (E3). Depois, realizar a prova do editor (E4) com texto, tinta, seleção e salvamento. A ordem e os critérios de saída são os de [14 — Plano de evolução e experimentos](14-plano-de-evolucao-e-experimentos.md). Novos detalhes visuais devem responder a necessidades dessas etapas, sem abrir outra rodada geral de polimento antes do editor.
