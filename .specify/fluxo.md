# Fluxo de uma atividade

Adaptação do [GitHub Spec Kit](https://github.com/github/spec-kit) 1.0 a este repositório. O Spec Kit organiza o trabalho em fases que produzem documentos Markdown, e cada documento alimenta a fase seguinte: *constitution → specify → clarify → plan → checklist → tasks → analyze → implement → converge*. Aqui as fases são executadas como passos descritos neste arquivo, sem depender da CLI `specify` nem de comandos de um agente específico. Assim, Claude, Codex ou uma pessoa seguem o mesmo caminho.

| Spec Kit | Aqui | Arquivo |
| --- | --- | --- |
| `.specify/memory/constitution.md` | Igual | Princípios obrigatórios |
| `.specify/feature.json` | Igual | Atividade ativa |
| `specs/NNN-nome/` | `specs/NNN-<id>-<slug>/` | Uma pasta por atividade |
| `checklists/requirements.md` | `checklists/validacao.md` | Qualidade da spec e aprovação na galeria |
| `/speckit.converge` | Passo 8, *convergir* | Divergências viram tarefas novas |

## Estados

`rascunho → especificada → planejada → em implementação → em validação → aprovada → fechada`, e também `bloqueada` ou `descartada`, sempre com motivo. O estado fica no cabeçalho do `spec.md` e na tabela do [`specs/README.md`](../specs/README.md). Somente o dono do produto move uma atividade de **em validação** para **aprovada**.

## Passos

**0. Retomar.** Toda sessão começa lendo `AGENTS.md`, a [constituição](memory/constitution.md), `.specify/feature.json` e o `tasks.md` da atividade ativa. Continue pela primeira tarefa aberta. Se não houver atividade ativa, a próxima vem do [`specs/README.md`](../specs/README.md) e do [14](../docs/14-plano-de-evolucao-e-experimentos.md).

**1. Abrir** (*specify*). `.specify/scripts/nova-atividade.sh <id> <slug> "<título>"` cria a pasta a partir dos modelos, aponta o `feature.json` para ela e acrescenta a linha no índice. Preencha o `spec.md` com o **quê** e o **porquê**: histórias, critérios de aceite verificáveis e fora de escopo, sem decisões de implementação. Um desvio (`C<n>`) registra a atividade de origem e o problema observado, com captura quando houver.

**2. Esclarecer** (*clarify*). Ambiguidades ficam marcadas `[PRECISA ESCLARECER: …]`, no máximo três, cada uma com a opção recomendada. Pergunte ao dono do produto e registre a resposta datada na seção *Esclarecimentos*. Não se planeja com marcas abertas que mudem escopo ou dados.

**3. Planejar** (*plan*). O `plan.md` diz **como**: documentos donos consultados, arquivos afetados, estudo visual (constituição V), estratégia de teste, seção da galeria onde a mudança será validada e a **verificação da constituição** preenchida. Pesquisas longas vão para `research.md`.

**4. Listar tarefas** (*tasks*). No `tasks.md`, uma linha por tarefa, no formato `- [ ] T001 [P] [US1] Descrição com caminho/do/arquivo`. `[P]` marca tarefas paralelizáveis e `[USn]` aponta a história atendida. Agrupe as tarefas em Preparação, uma fase por história e Fechamento. O Fechamento sempre inclui a suíte completa, a galeria e os documentos donos.

**5. Analisar** (*analyze*). Antes de codar, confira que cada critério de aceite tem tarefa e que cada tarefa serve a um critério. Confira também que spec, plano e tarefas não se contradizem e que a verificação da constituição passou. Corrija os documentos, não o entendimento de memória.

**6. Implementar** (*implement*). Execute as tarefas em ordem. Marque `[x]` só depois de verificar e anote a evidência na própria linha (comando, resultado, captura). Ao descobrir algo que mude a spec, atualize o `spec.md` e acrescente tarefas: o documento acompanha o código, não o contrário. Um problema fora do escopo vira desvio novo ou entrada em `docs/ideias.md`.

**7. Validar na galeria.** Rode a suíte completa do preset (constituição IV). Abra a galeria pelo comando do `BUILDING.md`, siga os passos do `checklists/validacao.md`, marque os itens técnicos que você verificou e passe a atividade para **em validação**. Peça ao dono do produto a conferência dos itens de aprovação. Nunca marque esses itens por ele.

**8. Convergir** (*converge*). Compare código, spec, plano e tarefas. Toda divergência ou reprovação na galeria vira tarefa nova no `tasks.md`, e o ciclo volta ao passo 6 até não restar diferença e o dono do produto aprovar.

**9. Fechar.** Leve as decisões aos documentos donos (13, 17, 10…) e acrescente o resumo com link no [12](../docs/12-registro-de-implementacao.md). Atualize o índice, faça o commit com o ID da atividade na mensagem (`E4.8: …`) e limpe o `feature.json` ou aponte-o para a próxima atividade. Triagem das ideias anotadas, conforme o 14 §10.

## Regras de commit

- Um commit pertence a uma atividade, e a mensagem começa pelo ID dela (`M1: …`, `C2: …`).
- Não misture mudanças de duas atividades no mesmo commit. Se a árvore tiver trabalho de outra atividade, ele é commitado ou guardado primeiro.
- Commit e push somente quando o dono do produto pedir.
