# Tarefas — M2 Revisão arquitetural do editor visual unificado

Base: HEAD `25f20a2`, Windows, 30/10/2026. Evidências de execução anteriores pertencem à M1; não são novas medições da M2.

## Fase 1 — Preparação

- [x] T001 Ler governança e situação da M1; abrir atividade sem conflito → Get-Content de AGENTS, constituição, workflow e M1/tasks; git status --porcelain=v1 vazio; script new-activity.sh criou 002 após execução autorizada, saída 0. M1 T030 preservada.
- [x] T002 [US1] Investigar documentos obrigatórios e código → Get-Content -Encoding utf8 dos documentos/código e rg dos símbolos em core/model, apps/desktop e tests; 22 §1 registra F01–F15, testes existentes e divergências (lote já presente, Z, infinito, pressão e limites). Leitura estática, sem atribuir execução aos testes.

## Fase 2 — US1 Arquitetura

- [x] T003 [US1] Consultar fontes primárias → navegação web oficial e github_fetch de Excalidraw/types.ts em 30/10/2026; 22 §9 registra fontes, observação, problema, aplicabilidade e limites; Qt/SQLite complementados em EX1/21. Sem inferir arquitetura interna proprietária nem benchmark.
- [x] T004 [US1] Definir contratos, decisões e cenários A–D → Get-Content e rg -n '^##|^###' docs/22-arquitetura-editor-visual-unificado.md; conferidos I01–I09, cinco ADRs com campos exigidos, coordenadas/gestos/seleção/render/operações e cenários A–D completos. Decisões permanecem propostas.

## Fase 3 — US2 Plano derivado

- [x] T005 [US2] Especificar Marco 3 → Get-Content do 20 e conferência com 22/04/16/19: objetos, rótulos, portas, grupos, clipboard, exemplos semânticos e dez cortes com dependências/escopo/aceitação/testes/galeria/riscos. M3.x são rótulos de plano, não atividades abertas; nenhum formato aplicado.
- [x] T006 [US2] Criar protocolo EX1 → Get-Content docs/experiments/EX1.md e comparação com 14 §6; hipótese/protocolo/medições/decisão/consequências presentes, cargas pequenas/médias/grandes, métricas/proxies e matriz A/B/C. Todas as medições novas permanecem não executadas; teto visual explicitado.
- [x] T007 [US2] Auditar persistência → Get-Content do 21 e rastreamento commit/persist/dropSessionAfterFailure, savePageChanges/loadPageContent, aboutToChangeSelection e migrations; R01–R12 com cenários, impacto/condição, gravidade, mitigação e testes; matriz de interrupções e D5/DX1/DX3/DX4/RX1–3/QX6. Nenhuma falha injetada.

## Fase 4 — US3 Convergência e validação

- [x] T008 [US3] Atualizar documentos donos → git diff --numstat e leitura do diff: 02/03/06/10/13/14/16, índice, 12, ideias e roadmap contêm referências explícitas de proposta; 16 corrige descrição histórica de lote com evidência de código. M1 intacta; não aprovada revisão de contrato.
- [x] T009 [US3] Tentar suíte completa → cmake --workflow --preset release: código 1, CommandNotFoundException (cmake não encontrado). Test-Path nos caminhos usuais CMake/MSYS2 e em cmake/local.cmake/build/release/CMakeCache.txt não encontrou ferramentas/configuração reutilizável. Nenhuma dependência instalada, compilação ou teste iniciado; aprovação da suíte permanece pendente no checklist.
- [x] T010 [US3] Avaliar galeria → leitura de BUILDING e diff: só documentos, sem alteração visual; roteiro de revisão e não aplicabilidade registrados em checklists/validation.md. evidence não executado (apaga/regenera pasta); gallery sem novo cenário; capturas do 20/22 são propostas futuras, não artefatos existentes.
- [x] T011 [US3] Executar .specify/scripts/check.sh após inspeção de seus efeitos; conferir diff e links locais → `.specify/scripts/check.sh` saída 0 (`ok: regras verificáveis da constituição atendidas.`); `git diff --check` saída 0; checagem de links locais do Codex sem destinos ausentes e caminhos alterados restritos a docs/, specs/002, ROADMAP e feature.json.
- [x] T012 [US3] Revisar critérios, deixar em validação, sincronizar roadmap e feature.json com pendências explícitas → spec.md e validation.md em "em validação"; ROADMAP linha 9 com M2 em validação e M1 preservada; feature.json aponta para specs/002. Respostas do dono do produto às sete decisões registradas em 22 §12.1 e alternativa do Tab em ideias.md (Claude, 30/10/2026). Suíte completa segue pendente: esta máquina (Windows 10 Pro) não tem CMake nem MSYS2.

## Aprovação e pendências

- [x] T013 [US3] Dono do produto: revisar decisões e checklist documental → aprovada pelo dono do produto em 30/10/2026; itens de aprovação marcados por ele em checklists/validation.md; decisões no 22 §12.1.

M1 T030 e validação Windows continuam na M1. EX1 experimental, Wacom, leitores de tela, DPI misto e testes de falha E6 dependem de atividades futuras; sua descrição não é execução.
