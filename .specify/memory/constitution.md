# Constituição do more-than-a-note

**Versão 1.1.0 · ratificada em 29/10/2026 · última emenda em 29/10/2026**

Princípios que toda atividade, de qualquer sessão ou agente, cumpre. Os planos (`specs/*/plan.md`) passam pela **verificação da constituição** antes de implementar e de novo antes de pedir validação. Os princípios I, V, VI e VII já valiam nos documentos [09](../../docs/09-roadmap-beta.md), [13](../../docs/13-estudo-visual.md) e [14](../../docs/14-plano-de-evolucao-e-experimentos.md) e no `AGENTS.md`; II, III e IV foram adotados pelo dono do produto com o Spec Kit.

## I. Só conta o que sobrevive a fechar e reabrir

Uma função visualmente pronta que perde conteúdo, posição ou histórico não está entregue. Preservação de dados, posição estável da tinta, fluxo de PDF de aula e exportação fiel nunca saem do escopo da beta para dar lugar a outra coisa ([09](../../docs/09-roadmap-beta.md), regra de priorização).

## II. Nenhum código sem atividade registrada

Todo trabalho acontece dentro de uma atividade em `specs/NNN-<id>-<slug>/`, criada por `.specify/scripts/new-activity.sh`, com `spec.md`, `plan.md`, `tasks.md` e `checklists/validation.md`. A atividade ativa está em `.specify/feature.json`. O fluxo e os portões estão em [`.specify/workflow.md`](../workflow.md).

- **Roadmap** (`E4.8`, `E5.1`…) segue a ordem do [14](../../docs/14-plano-de-evolucao-e-experimentos.md) e do plano da etapa.
- **Desvio** (`C1`, `C2`…) é uma correção visual ou de comportamento surgida durante o uso. Ganha atividade própria, curta, ligada à atividade de origem. Não se corrige “de passagem” dentro de outra.
- **Manutenção** (`M1`, `M2`…) cuida de estrutura, build, testes ou documentação, sem mudar o produto.

O `tasks.md` é o registro vivo: cada tarefa é marcada ao terminar, com a evidência ao lado. Uma sessão nova retoma pelo `feature.json` e pela primeira tarefa aberta, nunca por memória de conversa.

O [roadmap vivo](../../specs/ROADMAP.md) é atualizado **em texto, checklist e gráfico** sempre que uma atividade abre, conclui uma fase, passa a **em validação**, fecha, é bloqueada ou descartada. No gráfico, o roadmap é o tronco; manutenções e desvios são ramos que saem do ponto de origem e voltam ao fechar.

## III. A galeria é o ambiente de validação do dono do produto

Toda mudança visível, seja componente, tela, estado ou comportamento de interface, aparece na galeria antes de ser declarada pronta. A galeria é aberta por **um único comando documentado** no `BUILDING.md`, e cada atividade lista no `checklists/validation.md` a seção da galeria e os passos para conferir.

- O agente roda seus próprios testes sempre que quiser, e os testes automatizados continuam obrigatórios. O que é fixo é o **caminho comum**, usado igualmente pelo agente e pelo dono do produto:
  1. a suíte automatizada pelo preset;
  2. a captura de evidências por um único comando, que grava em `build/<preset>/evidence/`;
  3. a galeria pelo comando documentado.

  Capturas e confirmações saem desse caminho, nunca de um comando improvisado na sessão. Até a M1 criar os comandos 2 e 3, valem `./build/release/more_than_a_note --gallery` e `MTN_E2_CAPTURE_DIR=build/release/evidencias ./build/release/workspace_quick_tests`.
- Somente o dono do produto marca `[x]` nos itens de aprovação. O agente marca apenas os itens técnicos que ele mesmo verificou.
- Nenhuma atividade de interface passa a **aprovada** sem esses itens marcados.
- É proibido criar flags de linha de comando, variáveis de ambiente, janelas ou modos de demonstração paralelos para validar uma atividade. Um cenário novo vira uma seção ou um preset da galeria. Exceções exigem justificativa no `plan.md` e emenda desta constituição.

## IV. Um caminho de build, teste e artefato

- Configurar, compilar e testar usam somente os presets de `CMakePresets.json` e os comandos do `BUILDING.md`. Não se cria diretório de build fora de `build/<preset>`; uma necessidade nova, como sanitizador, vira preset.
- O teste automatizado de uma atividade é a suíte completa do preset (`ctest --preset <preset>`). Um teste isolado serve para depurar, não como evidência de conclusão.
- Saídas temporárias (capturas, logs, perfis XDG) ficam dentro de `build/`. Uma captura aprovada que precise ser preservada é copiada para `specs/NNN-…/evidence/`, com nome estável e referência no `tasks.md`.
- Comandos e caminhos registrados como evidência devem ser reproduzíveis por outra pessoa a partir do `BUILDING.md`.

## V. Linguagem visual registrada antes de implementada

Antes de criar ou alterar um componente de interface, consultar o [13](../../docs/13-estudo-visual.md), o [01](../../docs/01-layout-refeito.md), o [02](../../docs/02-ferramentas-e-interacoes.md) e o plano da etapa. Estudar as referências Apple, Adobe e Affinity para o tipo de componente, separando observação externa de decisão do produto. Registrar no 13 a geometria, os estados, a tipografia, as cores, o foco, o teclado, a acessibilidade e o comportamento em temas e escalas. Usar os tokens aprovados; mudar um padrão exige justificativa registrada.

## VI. Evidência honesta e portões reais

O relatório diz o que foi verificado, onde e como, e o que ficou pendente. Teste que falha é relatado com a saída. Hardware real é portão, não simulação: caneta só é aceita com a Wacom; DPI misto, leitor de tela e Windows só são aceitos quando executados de fato. Pendências de plataforma ficam visíveis no `tasks.md` e no [roadmap](../../specs/ROADMAP.md).

## VII. Escopo protegido e mudança de rumo explícita

Ideias novas vão para [docs/ideias.md](../../docs/ideias.md) e são triadas ao fim da atividade, conforme o [14](../../docs/14-plano-de-evolucao-e-experimentos.md) §10. Quando uma descoberta contradiz uma decisão registrada, a decisão antiga é marcada como **revista** no documento dono, e tudo o que depende dela é atualizado na mesma atividade. Se afetar escopo, dados do usuário ou a beta, o dono do produto aprova antes do código.

## Governança

- Esta constituição prevalece sobre preferências de sessão ou de agente. O `AGENTS.md` é o resumo operacional e aponta para cá.
- Emendas são feitas por atividade de manutenção (`M<n>`), com o motivo registrado. A versão segue SemVer: **maior** quando remove ou inverte um princípio, **menor** quando acrescenta um princípio ou uma regra, **correção** quando só esclarece o texto.
- Histórico: 1.0.0 adoção do Spec Kit (M1); 1.1.0 roadmap vivo obrigatório em texto, checklist e gráfico (M1).
- Documentos donos continuam valendo para o assunto deles: produto em 01–05, arquitetura em 06 e 10, visual em 13 e ordem das etapas em 14. A pasta `specs/` registra **o trabalho** e não substitui esses documentos; cada atividade leva suas decisões ao documento dono.
