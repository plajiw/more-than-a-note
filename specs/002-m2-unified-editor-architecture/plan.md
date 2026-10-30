# Plano — M2 Revisão arquitetural do editor visual unificado

**Spec:** [spec.md](spec.md) · **Data:** 2026-10-30

## Método

Ler governança e documentos donos; rastrear operações do QML ao núcleo e SQLite; confrontar testes existentes; consultar fontes primárias externas. Separar fato observado, inferência técnica e proposta MTAN. Registrar arquitetura em 22 e derivar 20, 21 e EX1; usar links nos documentos vigentes para evitar contratos duplicados.

## Fontes e arquivos afetados

Leitura: AGENTS, constituição, workflow, M1, roadmap, BUILDING; documentos 01–04, 06, 10, 12–19, README, ideias e experiments; core/model, apps/desktop, tests, CMake e cmake. Escrita limitada a docs/, specs/002-m2-unified-editor-architecture/, specs/ROADMAP.md e .specify/feature.json.

## Verificação da constituição

| Princípio | Antes da redação | Aplicação |
| --- | --- | --- |
| I | Atende no escopo documental | Contratos de reabertura e falha explicitados; nenhuma migração |
| II | Atende | Script oficial criou 002, após repetição autorizada fora do sandbox; tarefas próprias |
| III | Sem mudança visível | Revisão documental; cenários futuros apontam para galeria existente. Não editar pendingReviews, pois seria produção fora do escopo |
| IV | Parcial; impedimento registrado | Workflow tentado, código 1: cmake não encontrado, nenhum teste iniciado. check.sh inspecionado e executado: saída 0. Não instalar dependências nesta atividade |
| V | Atende no escopo | Ler estudo visual; somente implicações arquiteturais, sem componente implementado |
| VI | Atende | Sem medir hardware nem inventar benchmarks; pendências explícitas |
| VII | Atende | Propostas não substituem contratos; nenhuma correção incidental |

## Validação

Inspecionar diff e referências; conferir cobertura US1–US3. Executar check.sh e tentar suíte completa exclusivamente pelo BUILDING. Galeria e evidence não comprovam documentos: nenhum novo teste visual ou cenário será implementado. Se o ambiente não permitir esses alvos, registrar a limitação. O estado final pedido é em validação documental, não aprovação técnica integral; divergências dos portões permanecem no checklist.

## Riscos e limites

Documentos desatualizados podem ocultar recursos já presentes (por exemplo lote de persistência); ler implementação antes de recomendar. Fontes externas demonstram apenas o que publicam. A revisão estática não prova ausência de corridas, durabilidade física ou desempenho. A M1 conserva todas as pendências e sua aprovação original.
