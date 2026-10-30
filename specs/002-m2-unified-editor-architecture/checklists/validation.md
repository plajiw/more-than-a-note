# Validação — M2 Revisão arquitetural do editor visual unificado

Estado: **aprovada** pelo dono do produto em 30/10/2026. Revisão documental em 30/10/2026 sobre a base `25f20a2`; propostas não são recursos entregues. [Spec](../spec.md), [tarefas](../tasks.md) e [BUILDING](../../../BUILDING.md).

## Qualidade da especificação (agente)

- [x] US1–US3 têm critérios, tarefas e entregas correspondentes; spec sem esclarecimento obrigatório aberto. Verificação: leitura de spec/tasks/22/20/21/EX1.
- [x] Plano registra constituição, escopo documental, limites e aplicabilidade dos alvos; nenhuma aprovação presumida.
- [x] Fatos do código têm arquivos/símbolos; inferências, propostas e fontes externas são identificadas no 22 e no 21.
- [x] Contratos conflitantes e documentos donos estão identificados abaixo; propostas não substituem aprovações anteriores.

## Verificação técnica (agente)

- [x] `.specify/scripts/check.sh` executado pelo Git Bash, saída 0: `ok: regras verificáveis da constituição atendidas.`
- [x] Tentativa do comando comum registrada: `cmake --workflow --preset release`, código 1, `CommandNotFoundException` para cmake. Não há CMake no PATH, nem nos dois caminhos usuais conferidos; nenhum teste foi iniciado.
- [ ] Suíte completa aprovada nesta sessão: **pendente por ambiente**, não equivaler à tentativa acima nem aos resultados anteriores da M1.
- [x] Aplicabilidade visual examinada: nenhum componente/tela/cenário implementado ou alterado. Galeria, capturas, temas, escalas e teclado não têm nova evidência M2; testes de interface permanecem futuros.

`evidence` apaga e regenera sua pasta segundo o BUILDING; não foi executado numa atividade documental que proíbe comandos destrutivos. `gallery` não foi aberta: não há mudança visível a validar. Não alterar `Gallery.pendingReviews` evita modificar produção fora do escopo. Isso não dispensa galeria nas atividades futuras de interface.

A M2 está em validação do conteúdo documental, com a indisponibilidade da suíte explícita; não é declaração de cumprimento integral de todos os portões de conclusão. Diff, referências e restrição de caminhos são conferidos em T011/T012.

## Roteiro de revisão documental

| Passo | Onde conferir | Evidência / resultado esperado |
| --- | --- | --- |
| 1 | 22 §1 e arquivos/símbolos F01–F15 | Distinguir modelo disponível de UI/storage ausentes, resultado anterior de execução atual |
| 2 | 22 §§2–8 | Coordenadas, captura, seleção, Z, dependências e cinco ADRs sem necessidade de reescrita total |
| 3 | 22 §10, cenários AVL, fluxo de autenticação, Wacom e falha | Cada cenário explicita invariantes, operações, contradição atual e prova futura |
| 4 | 20 §§3–6 | Referências ao remover/duplicar, grupos planos, formato proposto e dez cortes com aceitação/testes |
| 5 | EX1 | Cargas reproduzíveis; métricas reais versus proxies; nenhum benchmark ou motor aprovado pela redação |
| 6 | 21 R01–R12 e §§3–6 | Riscos rastreáveis, “Salvo” confirmado, falhas/recuperação e prioridade de E6 |
| 7 | Documentos donos, roadmap e M1 | Notas de proposta, ordem preservada e pendências M1 intactas |

Nenhuma captura comprova os passos acima. As provas futuras de interface têm pontos de captura propostos no 20 §7 e cenários no 22 §10; deverão entrar nos testes/galeria e no checklist da atividade que os implementar.

## Mudanças de contrato que dependem de aprovação

| Assunto | Documento/seção vigente | Recomendação M2 a revisar |
| --- | --- | --- |
| Sobreposição do card selecionado | 13 §6.1 versus 04 §5 e 02 §5 | Elevar apenas overlays, conservando Z do conteúdo |
| Modal/texto e troca de ferramenta durante gesto | 02 §§3/6 e 03 §1 | Modal primeiro; concluir/cancelar gesto por transição explícita, adiar troca durante contato |
| Rótulos, relações e formato | 04 §2.2, 15 e 16 | Conteúdo rico incorporado ao dono; próximo esquema livre após E6; bytes completos antes do codec |
| Criação conectada e seleção regional | 03 §§2/3, 02 e 04 | Ação nomeada sem Tab global; interseção e borracha de traço inteiro a validar |
| Salvamento e condições de suporte | 10, 14 E6 e constituição I | Retenção do pendente, confirmação de saída/revisão e política para nuvem/removível após ensaio |
| Retenção de histórico após reinício | Constituição I e histórico de sessão E4.7 | Explicitar alcance com o dono do produto; não dispensar exigência nem prometer pilha durável inexistente |
| Desempenho/engine | 10 §7.1 e 14 EX1/EX4/EX7 | Aprovar hardware/metas após baseline; Quick permanece candidato, sem migração autorizada por este documento |

## Aprovação (somente o dono do produto marca)

- [x] Diagnóstico e cinco ADRs revisados; recomendações aceitas ou ajustes registrados.
- [x] Conflitos e mudanças de contrato acima decididos explicitamente.
- [x] Recortes do Marco 3 e prioridade dos riscos E6 aprovados para detalhamento nas atividades futuras.
- [x] Protocolo EX1 revisado; máquina-alvo e critérios quantitativos encaminhados, sem confundir com resultado experimental.
- [x] Pendências técnicas e de plataforma reconhecidas; aprovação documental não aprova interface, hardware ou durabilidade.
- [x] Observações registradas abaixo, ou nenhuma.

**Observações do dono do produto:** respostas às sete decisões dadas em 30/10/2026 e registradas no [22 §12.1](../../../docs/22-arquitetura-editor-visual-unificado.md#121-respostas-do-dono-do-produto-30102026). Texto que não cabe: a forma cresce para baixo (20 §2). Sobreposição: opção 2 (o card selecionado não sobe), aplicada no corte M3.2. Máquinas da EX1: PC Windows (referência) e notebook Samsung Linux (pior caso), EX1 §2. Desfazer: constituição 1.2.1 esclarece que é de sessão (atividade M3). Nenhuma decisão aberta.
