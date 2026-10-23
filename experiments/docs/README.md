# Especificações — Aplicativo de anotações desktop open source

Coleção de especificações funcionais e uma decisão de arquitetura. **A stack escolhida é C++ com Qt 6**; os arquivos ainda não são código do aplicativo. Os documentos distinguem requisitos confirmados de detalhes a validar.

1. [01 — Layout e navegação, versão vigente](01-layout-refeito.md): Biblioteca separada, índice do caderno, barras, temas e editor. `01-layout.md` é o histórico anterior.
2. [02 — Ferramentas e interações](02-ferramentas-e-interacoes.md): caneta, mouse, teclado, prioridade de entrada e tinta digital.
3. [03 — Atalhos e acessibilidade](03-atalhos-e-acessibilidade.md): mapa, conflitos, foco, teclado exclusivo e tecnologias assistivas.
4. [04 — Comportamento do editor](04-comportamento-editor-e-organizacao.md): caderno/seção/página, contêineres, canvas, texto/tinta, histórico e armazenamento.
5. [05 — Configurações](05-configuracoes-e-portabilidade.md): `.cfg`, temas, paletas, página A4/infinita, importação/exportação.
6. [06 — Arquitetura e stack](06-arquitetura-e-stack.md): decisão C++/Qt 6, divisão inicial e protótipo técnico obrigatório.
7. [07 — Revisão especializada dos requisitos](07-revisao-especializada-dos-requisitos.md): lacunas e mudanças propostas para os documentos 02–05, com foco na primeira versão para alunos e professores.
8. [08 — Pesquisa de campo documental sobre OneNote](08-pesquisa-de-campo-onenote.md): elogios e críticas de usuários, comparação com os requisitos do Orla e critérios de validação.
9. [09 — Roadmap da versão beta](09-roadmap-beta.md): seis marcos com entregas, critérios de saída e escopo posterior.

## Invariantes entre documentos

- Arquitetura local, offline, desktop para Windows e Linux; código-fonte aberto e livre para uso (licença ainda a definir).
- Caderno → Seção → Página; metadados e referências pertencem ao domínio local do caderno.
- Primeira caixa abaixo do título é um contêiner normal, criado preguiçosamente ao digitar; título é metadado e não caixa livre.
- Canvas absoluto com texto rico e traços vetoriais independentes; suporta página finita ou infinita.
- Entrada de caneta responsiva sem ajustes técnicos iniciais obrigatórios.
- Temas claro/escuro para UI; fundos e paletas por contexto de página.
- Ferramentas por teclado só funcionam como tecla simples quando não há edição de texto.
- Autosave, histórico único de operações de conteúdo e ferramentas temporárias previsíveis.

## Ordem recomendada de validação

Fluxo de edição e foco → protótipo técnico Qt/C++ de escrita com caneta/zoom → comportamento de canvas finito/infinito → layout e acessibilidade → formato local e exportação `.cfg`. Desempenho e semântica acessível devem ser testados antes de fixar a composição interna do editor.
