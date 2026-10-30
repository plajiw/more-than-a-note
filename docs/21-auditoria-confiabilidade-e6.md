# 21 — Auditoria de confiabilidade para E6

**M2 · 30/10/2026 · auditoria estática, proposta em validação.** Base `25f20a2`. Nenhuma falha foi injetada em documentos, nenhum banco foi migrado e nenhum resultado de crash/power-cut é alegado. [Arquitetura](22-arquitetura-editor-visual-unificado.md), [atividade](../specs/002-m2-unified-editor-architecture/tasks.md) e [contrato vigente](16-formato-conteudo-v2.md).

## 1. O que existe de fato

O armazenamento é um diretório por caderno com `notebook.sqlite`, criado em v1 e migrado na primeira escrita válida até v4. `NotebookStore::openDatabase` abre QSQLITE e solicita `PRAGMA foreign_keys=ON`; o retorno desse PRAGMA não é conferido. Não define nem consulta política de `journal_mode`, `synchronous`, checkpoint, busy/retry ou geração do arquivo. Portanto a política efetiva do binário/arquivo não foi determinada nesta auditoria.

O caminho de conteúdo é:

```text
QTextDocument temporário / prévia do gesto
  → PageEditorAdapter::commit
  → PageSession::execute ou execute_merged (muda memória)
  → persist / savePageChanges
  → prepareObject / codecs / schemaStatus
  → transação SQL: upserts + deletes → commit
  → atualização da projeção e sinais QML
```

Pontos fortes confirmados por leitura:

- [page_history.cpp](../core/model/page_history.cpp), `PageSession::apply`: valida a página final e reverte lotes inválidos; inversão explícita, orçamento e IDs preservados.
- [page_repository.cpp](../apps/desktop/page_repository.cpp), `savePageChanges`: **lote transacional já implementado**; prepara codecs antes de iniciar a transação e faz rollback se a escrita/commit falhar. Não é gravação de arquivo inteiro por ponto de caneta.
- [notebook_schema.cpp](../apps/desktop/notebook_schema.cpp): versão e DDL avançam na mesma transação em cada salto. v1→v4 é uma sequência de transações, não uma transação única de ponta a ponta.
- `loadPageContent` recusa tipo/versão desconhecido, valida codecs e página, limita alocações por contagem/tamanho e limpa o resultado em erro reconhecido.
- [content_codec.cpp](../core/model/content_codec.cpp): bytes explícitos, finitude/contagens/UTF-8/flags verificados; nenhuma estrutura Qt nativa persistida.
- [tests/page_repository_tests.cpp](../tests/page_repository_tests.cpp): reabertura, pressão pelo codec, geometria/rich text, legado sem escrita e futura versão recusada com hash preservado. [tests/notebook_schema_tests.cpp](../tests/notebook_schema_tests.cpp) cobre migrações e esquema. Esses testes não são ensaios de energia, disco cheio ou concorrência.

Ausências delimitadas à busca em `apps/desktop`, `core` e `tests`: não foi encontrado escritor de autosave com fila/revisões confirmadas, backup consistente automático, recuperação de pendências, lock de escritor da aplicação, teste de queda de processo/energia nem ponte de fechamento que receba resultado do flush. Há log Qt opcional em `main.cpp::writeQtMessage`, mas não log rotativo estruturado de persistência.

## 2. Riscos encontrados e cenários reproduzíveis a implementar

Gravidade expressa impacto, não frequência medida: **crítica** = perda de conteúdo/abertura inviável; **alta** = proteção ou diagnóstico insuficiente sob condição concreta; **média** = incoerência/retrabalho recuperável. Probabilidade não foi quantificada. Os cenários abaixo devem rodar em fixtures/perfis descartáveis dentro de `build/<preset>`, nunca em cadernos reais.

### R01 — Falha de gravação descarta a sessão editada

- **Fato/evidência:** [page_editor_adapter.cpp](../apps/desktop/page_editor_adapter.cpp), `commit` altera `PageSession` antes de `persist`; falha chama `dropSessionAfterFailure`, que reseta a sessão, elimina seu cache/histórico e relê o banco. `saveRichTextDocuments` pode estar nessa pilha enquanto a projeção é recarregada.
- **Cenário:** confirmar um conteúdo A; editar para B; provocar falha de UPDATE ou commit na próxima gravação; observar modelo, texto visível, histórico e reabertura. Comparar A/B por DTO, não só mensagem.
- **Impacto/condição:** se B só existe na sessão/UI e ela é substituída por A, trabalho recente pode desaparecer. O banco anterior pode continuar íntegro; isso não equivale a preservar B. **Crítica**, condicionada a erro de armazenamento; sem reprodução nesta sessão.
- **Mitigação proposta:** conservar snapshot confirmado e edição pendente; não recarregar sobre o documento modificado. Expor erro e opções de repetir/recuperar em cópia; impedir publicação de Salvo.
- **Teste de correção:** falhar em preparação, primeiro/último UPDATE e commit; B continua acessível após erro, A permanece confirmada; repetir confirma B uma única vez, sem história duplicada.

### R02 — Flush não veta navegação; fechamento não tem confirmação explícita

- **Fato/evidência:** `NotebookStore::selectPage`, `selectSection`, `openNotebook`, `closeNotebook` em [notebook_store.cpp](../apps/desktop/notebook_store.cpp) emitem `aboutToChangeSelection()` e prosseguem. O adaptador emite `flushRequested()`; [EditorProbe.qml](../apps/desktop/ui/EditorProbe.qml)::`onFlushRequested` chama `saveTexts()` sem devolver seu bool ao store. [EditorTextCard.qml](../apps/desktop/ui/EditorTextCard.qml)::`typingIdle` usa 800 ms. Não há `onClosing` em Main nem `aboutToQuit` conectado a flush em [main.cpp](../apps/desktop/main.cpp).
- **Cenário:** digitar antes da pausa e trocar página/caderno enquanto a gravação falha; separadamente, digitar e encerrar janela antes da pausa, tanto por menu quanto por fechamento do SO. Eventos de perda de foco podem salvar em alguns caminhos; não são contrato de drain.
- **Impacto/condição:** deixar para trás texto pendente ou erro invisível após troca; perder última rajada no fechamento. **Crítica**, com falha de save ou janela de tempo/evento de fechamento. Não se afirma que todo fechamento normal perde texto.
- **Mitigação:** `requestLeave` com resultado explícito e estado de transição; drenar texto confirmado pelo IME, resolver gesto, aguardar confirmação ou manter página/erro. Preedit não deve ser tratado como texto confirmado sem negociação com o método de entrada.
- **Teste:** falhar flush e exigir página/foco/conteúdo preservados; fechar normalmente imediatamente após digitar e reabrir; repetir com IME, menu, Alt+F4 e troca de caderno. Crash continua sujeito ao último conteúdo confirmado, não à semântica do fechamento normal.

### R03 — Escrita pode ultrapassar limites que impedem a leitura

- **Fato/evidência:** `loadPageContent` recusa mais de 100.000 objetos, soma de payloads acima de 256 MiB ou payload individual acima de 32 MiB. `savePageChanges`/`prepareObject` verificam objetos/codec individualmente, sem validar a contagem/soma final da página. `PageSession` não impõe esses limites agregados. Teto de histórico não é teto do conteúdo acumulado.
- **Cenário:** fixture perto do limite agregado; acrescentar um objeto individual válido que cruza a soma/contagem; fechar/reabrir. Pode ser preparado no nível do repositório, sem desenhar 100.001 objetos na UI. Não executar na M2.
- **Impacto/condição:** sucesso de save seguido de `TooLarge` ao abrir; dados permanecem no banco, mas ficam inacessíveis pelo editor. **Crítica**, condicionada a volume; prioridade aumenta com diagramas e escrita longa.
- **Mitigação:** orçamento compartilhado de leitura/escrita, aplicado ao estado final na transação, incluindo substituições/exclusões. Contabilizar conteúdo lógico e memória de projeção separadamente. Rejeição mantém pendente recuperável.
- **Teste:** limite−1/limite/limite+1 em quantidade e bytes; substituir payload grande por pequeno e excluir+inserir no mesmo lote; toda confirmação deve reabrir. Verificar concorrência na contagem para não confiar só em leitura prévia fora da transação.

### R04 — Duas instâncias podem sobrescrever conteúdo desatualizado

- **Fato/evidência:** `openDatabase` não estabelece dono de escrita da aplicação; `writeObject` faz UPSERT condicionado à página, sem revisão esperada. `syncSelection` compara cache com disco ao navegar, não antes de toda escrita.
- **Cenário:** A e B abrem a mesma página; A modifica texto e confirma; B, com cópia antiga, muda o mesmo texto e confirma. Repetir com edição/undo e substituição externa do arquivo.
- **Impacto/condição:** última escrita pode sobrescrever mudanças anteriores sem conflito, apesar da serialização física do SQLite. **Crítica**, requer duas instâncias/editor externo; não é prova de corrupção SQLite.
- **Mitigação:** primeiro escritor exclusivo por caderno com identificação e recuperação de lock obsoleto; adicionar revisão esperada de documento/página na mesma transação. Mudança externa exige recarga segura/abrir cópia, não merge automático.
- **Teste:** duas conexões/instâncias, commit com revisão obsoleta recusado sem perder pendência; lock abandonado não bloqueia para sempre nem permite dois donos ativos.

### R05 — Durabilidade e power-cut não têm política verificada

- **Fato/evidência:** `openDatabase` configura apenas FK, sem conferir; `savePageChanges` retorna Ok após `db.commit`, sem registrar modo efetivo ou verificar ambiente. Não existe ensaio de corte de energia no conjunto inspecionado.
- **Cenário:** registrar SQLite/VFS/PRAGMAs reais; interromper processo antes/depois do commit e, em ensaio separado, VM/energia no caminho de flush em filesystem descartável.
- **Impacto/condição:** nível de garantia indeterminado em desligamento/disco/controlador; **alta**, não se afirma que SQLite esteja sem journal ou necessariamente corrompa.
- **Mitigação/teste:** escolher política com medições (§4); checar valores efetivos; declarar pressupostos de FS local/flush confiável. Confirmado reabre ou é recuperado conforme contrato documentado; distinguir perda de último commit e corrupção estrutural.

### R06 — Migração por etapas e backup ainda não formam recuperação de produto

- **Fato/evidência:** `schemaStatus` pode migrar até v4 antes de iniciar a transação de conteúdo; cada função de migração tem commit próprio. `inspectNotebookSchema` verifica colunas/version, não integridade completa/FKs de todas as linhas. Backup pré-migração não foi encontrado.
- **Cenário:** falhar DDL, cópia de linhas ou commit de cada salto; interromper entre v2/v3 e v3/v4 e antes do primeiro objeto; reabrir fixture.
- **Impacto/condição:** terminar numa versão intermediária válida é esperado, não corrupção; recuperação/diagnóstico insuficientes em I/O/arquivo malformado. **Alta**, em falha de migração.
- **Mitigação/teste:** backup consistente antes de migração publicada, migrações retomáveis, checagens estrutural/semântica e documentação da transição; fixtures por versão, hash antes/depois, migração repetida e futura versão recusada. Não exigir rollback de todas as etapas já confirmadas como se fosse contrato atual.

### R07 — Backup, nuvem, unidade externa e substituição de arquivo

- **Fato/evidência:** `databasePath` aponta arquivo local; não há protocolo de exportação/backup SQLite consistente ou detecção de geração/substituição externa. `deleteNotebook` usa `QDir::rename` para trash e trata retorno falso; salvamento de conteúdo não usa rename.
- **Cenário:** em sandbox de teste, bloquear destino de trash; remover unidade durante commit; sincronizador substituir arquivo enquanto aberto; copiar apenas arquivo principal enquanto houver journal/WAL. Falha de rename de backup é cenário futuro, não operação existente a atribuir ao app.
- **Impacto/condição:** backup incompleto, edição sobre geração antiga, erro de I/O; **alta**, exige ambiente externo/conflito. Não assumir suporte a banco ao vivo em pasta de nuvem/rede.
- **Mitigação/teste:** oferecer pacote consistente de snapshot para transporte, detectar arquivo trocado e congelar escrita; backup temporário validado e publicado preservando último backup íntegro. Reabrir backup em processo separado; simular rename negado/IOERR/unplug e comprovar que original e versão anterior não foram removidos.

### R08 — Exclusões têm níveis diferentes de recuperação

- **Fato/evidência:** `deleteNotebook` move pasta para trash; `deletePage` executa DELETE e `deleteSection` remove páginas/seção em transação, com conteúdo em cascata. A confirmação de exclusão em Main existe, mas não há lixeira de página/seção ou undo de hierarquia.
- **Cenário:** excluir página com texto/tinta, fechar/reabrir e buscar recuperação; falhar rename ao excluir caderno.
- **Impacto/condição:** exclusão confirmada de página/seção não é restaurável pelo fluxo atual; **alta** para exclusão equivocada, sem alegar que ocorra sem confirmação.
- **Mitigação/teste:** tombstone ou lixeira transacional por unidade com retenção explícita; restauração conserva IDs/recursos/ordem. Injetar falha durante exclusão/restauração; nada fica parcialmente removido e os dependentes continuam íntegros.

### R09 — “Salvo” não é revisão confirmada do documento

- **Fato/evidência:** EditorProbe mostra “Alterações salvas.” se não há `dirty` de cards, erro do adapter ou falha de carga visual. Não cobre revisão de tinta ativa, saída, erro do store ou fila global; não existe revisão de confirmação. `saveRichTextDocuments` captura vários documentos, mas faz um commit por entrada, não um lote de todos os textos.
- **Cenário:** iniciar traço sem soltá-lo; editar duas caixas e falhar a segunda gravação; falhar metadado; observar mensagem e revisão que reabre.
- **Impacto/condição:** status pode ser interpretado como confirmação de tudo que está visível; **alta**, especialmente combinado com R01/R02. Não dizer que todos os saves já confirmados são falsos.
- **Mitigação/teste:** contrato §3, status agregador com erro dominante e confirmação de revisão; teste de ordem de acknowledgements, pendência nova durante save e falha parcial entre comandos independentes.

### R10 — Diagnóstico, erro SQL e leitura incompleta

- **Fato/evidência:** `storageError` reduz maioria dos erros a mensagem genérica; `main.cpp` escreve log opcional sem rotação. `loadPageContent` usa consultas separadas de bounds e dados sem snapshot explícito; após `while(query.next())` não distingue exaustão normal de erro de iteração por `lastError`.
- **Cenário:** provocar erro de leitura após algumas linhas; concorrente modifica página entre consulta de limites e dados. Não há evidência de que driver específico retorne página parcial nesse cenário; reproduzir antes de afirmar ocorrência.
- **Impacto/condição:** diagnóstico insuficiente e risco de aceitar resultado parcial/limites incoerentes; **alta** em falha de leitura/concorrência.
- **Mitigação/teste:** leitura numa transação/snapshot coerente, conferir erro final do cursor, números de linhas/limites e validação; preservar original. Log com categoria/código SQL, operação, versão e duração, sem texto/pontos/paths pessoais; ensaio garante que erro não publica página parcial.

### R11 — Ordem e memória em uso longo

- **Fato/evidência:** `NotebookStore::addSection/addPage` já usam MAX(position)+1, corrigindo a origem de D5 na hierarquia. `PageEditorAdapter::createTextAt/duplicateText/addInk` usam `objects.size()` para Z/leitura, criando empates após exclusões. `rebuildVisual` reconstrói todas as listas; até quatro sessões recentes são retidas além da ativa. `execute_merged` estima o comando novo mas não atualiza a reserva da entrada fundida; no uso atual a fusão atende geometria, não justificar genericamente payload crescente sem teste.
- **Cenário:** criar três objetos, remover o segundo, criar outro; comparar Z/leitura antes/depois de reabrir; sessão de duas horas alternando páginas densas; testar fusão de payload crescente diretamente no núcleo em atividade própria.
- **Impacto/condição:** ordem inesperada, memória alta, orçamento estimado inadequado em extensão futura; **média/alta** conforme carga, sem benchmark nesta revisão.
- **Mitigação/teste:** contrato de ordem por ID determinístico, alocação/normalização deliberada; budget global e cache liberável; QX6 mede patamar, picos e tendência; teste de contabilidade após fusão/poda/undo.

### R12 — Relações de diagrama e ativos ampliam o perímetro transacional

- **Fato/evidência:** `validate_page` já recusa referência órfã; `prepareObject` hoje recusa grupos/tipos além de texto/tinta e valida objeto isolado. Não existe transação de ativo importado mais referência no editor atual.
- **Cenário futuro:** excluir nó e falhar após escrever um conector; migrar grupo com child_ids divergentes; crash entre salvar ativo e inserir sua referência.
- **Impacto/condição:** referência quebrada ou ativo ausente; **alta**, dependente da futura extensão, não bug alegado em recurso ausente.
- **Mitigação/teste:** lote da página final, validação de relações, recurso publicado antes de vínculo; órfão de arquivo é coletável, vínculo a arquivo ausente não é aceitável. Testar revisão completa ou anterior, nunca grupo/aresta pela metade.

## 3. Contrato proposto do indicador “Salvo”

Adotar revisão monotônica por unidade de persistência. `workingRevision` é o último conteúdo aceito para edição, `confirmedRevision` o último commit reconhecido no armazenamento desta geração. Uma prévia de drag não aumenta revisão; uma rajada textual modificada ainda não capturada também precisa sinalizar pendência na UI. Preedit tem estado separado de composição.

| Estado interno | Mensagem/condição | O que se pode prometer |
| --- | --- | --- |
| Modificado | “Editando…”: texto/gesto visível ainda em elaboração, ou revisão nova sem escrita iniciada | Há trabalho local não confirmado; não anunciar salvo |
| Escrita pendente/em andamento | “Salvando…”: lote aceito e preparado/na fila/escrevendo | Conteúdo retido em memória; não prometer sobrevivência à queda |
| Escrita confirmada | “Salvo”: revisões iguais, sem texto modificado, sem lote/erro pendente e sem gesto de edição ativo | Commit confirmado sob política/FS suportados; não equivale a backup nem sync |
| Erro | “Erro ao salvar”: categoria e ação acessíveis, sem roubar foco | Conteúdo pendente conservado; repetir ou recuperar cópia |
| Confirmação incerta | “Verificando salvamento…” após falha ambígua | Consultar revisão/operação em conexão segura antes de repetir |

Confirmação de revisão R não pode apagar indicador de R+1 pendente. Erro persiste até resolução efetiva, não some por mudar foco/ferramenta. Estado agregado do caderno inclui metadados e página ativa; navegação/preferences só entram no mesmo status se o produto disser que ele as cobre. Nome acessível deve indicar escopo (“Página salva localmente”) e anúncio ser moderado, sem falar a cada ponto.

Janela de debounce não é SLA: os 800 ms atuais são timer de inatividade e a digitação contínua pode adiar save. E6 deve definir tempo máximo de conteúdo confirmado ainda não enviado e orçamento de perda aceitável, medidos com I/O real. Não vender “nenhuma perda” de prévia/IME ainda não confirmados.

## 4. Autosave transacional incremental

### 4.1 Primeiro corte: corrigir sem trocar threading

1. Construtor de operação captura estado necessário e IDs/referências afetados; codecs e limites são verificados antes da aceitação.
2. Sessão conserva snapshot confirmado e trabalho pendente recuperável. Enquanto o commit síncrono roda, não publicar outra operação reentrante sobre a mesma base.
3. Repositório verifica geração/revisão esperada, limites finais e dependências na mesma transação; aplica upserts/deletes/metadados necessários e revisão/operação.
4. Sucesso confirma revisão e libera pendências correspondentes; erro mantém trabalho e histórico coerentes, sem `dropSessionAfterFailure` destrutivo. Commit incerto exige reler revisão antes de repetir.
5. Saída/undo/redo/troca de documento usam resultado de flush. Undo enquanto há falha pendente precisa regra explícita: desfazer pode remover a operação local pendente; não supor que ela foi gravada.

Esse corte permite testar R01–R04 antes de adicionar uma fila. Não chamar apenas `undo()` em erro se isso apaga texto que o usuário quer recuperar ou modifica o histórico confirmado de modo invisível.

### 4.2 Se o perfil justificar escritor assíncrono

Uma conexão SQLite pertence exclusivamente à thread do escritor; não passar `QSqlDatabase`, `QTextDocument` ou objetos QML entre threads. Enviar payloads/DTOs imutáveis ou mudanças preparadas, com revisão e ID de operação. Escritor serial por caderno, acknowledgements ordenados e idempotência. Fila limitada em bytes e revisões; ao atingir limite, informar atraso/erro e pausar novas mutações de forma recuperável, não consumir RAM sem limite. Somente rajadas compatíveis podem ser compactadas antes de gravar, sem alterar semântica de undo.

Salvar várias operações numa transação reduz I/O, mas todas precisam de confirmação conjunta; falhar não pode confirmar metade. Recuperação de conteúdo e retenção de undo são políticas diferentes: o alcance da preservação de histórico exigida pela constituição I precisa ser explicitado pelo dono do produto (22 §12), sem dispensá-la nesta revisão. Journal de recuperação de pendências deve ter formato/versionamento/checksum próprios e testes de truncamento; não instalar um segundo banco/journal na M2 por antecipação.

### 4.3 Atomicidade, durabilidade e escolha de journal

SQLite fornece atomicidade condicionada a hipóteses do SO/disco; `COMMIT` não é prova contra hardware que mente sobre flush ([Atomic Commit](https://sqlite.org/atomiccommit.html)). Distinguir crash do processo, crash do SO e falta de energia. O ensaio de kill testa apenas o primeiro.

| Opção experimental | Benefício | Custo / limite |
| --- | --- | --- |
| Rollback journal + política synchronous verificada | Simples para um escritor e menos arquivos vivos para transporte | Locks/leitores e custo de flush devem ser medidos; avaliar FULL/EXTRA conforme FS |
| WAL + FULL | Leitura concorrente e confirmação com sincronização por commit | Checkpoints, arquivos auxiliares e requisitos de FS local; medir caudas e crescimento |
| WAL + NORMAL | Menos custo de sync em alguns fluxos | Últimos commits podem ser perdidos após energia; não escolher se contradiz “Salvo” aprovado |

Esses comportamentos são descritos em [PRAGMA synchronous](https://sqlite.org/pragma.html#pragma_synchronous) e [WAL](https://sqlite.org/wal.html); a versão SQLite embarcada e os valores efetivos precisam ser registrados. Recomendação preliminar: medir política conservadora que preserve commits confirmados nas condições suportadas; não ativar WAL só por reputação de desempenho. WAL não elimina concorrência lógica nem é solução para sincronizar banco aberto por nuvem.

### 4.4 Backup, recuperação e ativos

Criar snapshot por mecanismo consistente, como [SQLite Online Backup API](https://sqlite.org/backup.html), cuja integração concreta com o driver deve ser avaliada na E6. Não copiar apenas arquivo principal de banco em uso. Verificar backup em nova conexão, incluir manifesto/versões/hashes e recursos, publicar nome final somente após validação; falha de rename preserva backup anterior. Durabilidade da publicação depende também de sincronizar diretório conforme plataforma; registrar limites, não prometer rename universalmente seguro.

Na abertura: verificar versão → tratar recuperação do próprio SQLite → verificar integridade estrutural e referências de domínio → comparar revisão/manifesto → oferecer recuperação quando necessário, em cópia, mantendo original. `integrity_check` e FK não substituem codec/UUID/relação de grupo; são verificações complementares. Não “reparar” silenciosamente removendo linhas desconhecidas.

Ativos futuros: escrever original numa área temporária controlada, validar tamanho/hash, publicar por hash, só então confirmar vínculo SQL. Crash anterior ao vínculo pode deixar arquivo órfão coletável; o inverso (referência confirmada antes do arquivo durável) não é aceito. Exclusão de ativo usa retenção e referência de snapshots/lixeira antes de coleta.

## 5. Matriz de interrupção e resultado esperado

| Ponto de interrupção | Estado aceitável ao reabrir | Evidência exigida |
| --- | --- | --- |
| Antes de capturar texto/preedit | Última revisão confirmada; perda pendente declarada conforme contrato | Reprodução de fechamento normal deve drenar; crash mede janela real |
| Depois de preparar, antes de BEGIN | Revisão anterior; pendência só recuperável se journal de recovery confirmado existir | DTO/hash da revisão e indicador de pendência |
| Durante N upserts/deletes | Revisão anterior inteira após rollback/recovery | Sem objeto/aresta/grupo parcial; integridade SQL + domínio |
| Após COMMIT, antes do ack UI | Revisão nova inteira ou resultado permitido pela política de energia explicitada | Ler revisão/ID de operação, repetir sem duplicar objetos |
| Entre saltos de migração | Versão anterior ou intermediária confirmada, íntegra e retomável | user_version consistente com schema e fixtures |
| Durante backup/publicação | Backup anterior íntegro; temporário não anunciado como backup pronto | Hash e reabertura de ambas as gerações; rename negado |
| Durante publicação de ativo | Sem vínculo confirmado a bytes ausentes; órfão detectável | Manifesto/FK/hash e coleta segura |
| Substituição externa/unplug | Escrita bloqueada/erro com pendência conservada | Geração identificada, sem sobrescrever arquivo novo ou original de recuperação |

Testar falta de espaço tanto na escrita quanto no journal/checkpoint/backup; escrita parcial e IOERR devem ser injetadas na camada de teste/VFS quando possível, não por truncar caderno real. Power-cut em VM/storage descartável exige procedimento próprio aprovado na atividade E6. Não foi criado novo script, flag, variável ou modo de demonstração nesta revisão.

## 6. Mapeamento ao roadmap e cortes de E6

| Item | Diagnóstico atual | Trabalho futuro e aceitação |
| --- | --- | --- |
| D5 | Hierarquia usa MAX(position)+1; não repetir dívida como se ainda usasse contagem. Objetos usam count para Z/leitura | Testar excluir/inserir/reordenar na hierarquia e objetos; resolver ordem sem empate indesejado e sem alterar leitura ao mover |
| DX1 | Lote SQL existe; R01–R05 e R09 não resolvidos | Flush com resultado, retenção, limites e revisão; matriz de crash/FULL/IOERR com reabertura |
| DX3 | Saltos v1–v4 presentes, futura recusada | Fixtures de toda versão, backup antes de migração publicada, interrupção/reentrada e S_obj do Marco 3 |
| DX4 | Biblioteca abre bancos para listar, páginas/seções em listas; conteúdo carregado inteiro | Cenário do catálogo: 100 cadernos, 50 seções, 1.000 páginas, especificando distribuição; medir cold/warm e memória, sem inferir índice necessário |
| RX1 | Erro genérico e recarga da sessão | Erro acionável mantém contexto; categoria correta para FULL/BUSY/IOERR/versão; galeria com estado de erro |
| RX2 | Log Qt opcional, arquivo aberto com w, sem rotação | Log local limitado e sem conteúdo; testes de sanitização/rotação e correlação por operação sem dados pessoais |
| RX3 | Nenhuma recuperação de pendência identificada | Reinício distingue confirmado/recuperável e oferece cópia; original preservado |
| QX6 | Cache recente + rebuild integral; sem medição de sessão longa | 2 h de criar/editar/navegar, incluindo falhas/retentativas; memória estabiliza após descarte de caches, sem perda de conteúdo |

**Sequência proposta, dentro de E6:**

1. **Preservação e saída:** R01/R02/R09; adapter/store/status, sem worker ou formato de diagrama. Aceite: falha conserva texto e veta transição; fechamento normal drena. Evidência de UI pela seção Editor e suíte completa.
2. **Limites e concorrência:** R03/R04/R10; repository/revisões/dono de escrita, sem sync colaborativo. Aceite: save sempre reabrível, revisão obsoleta recusada, leitura parcial nunca publicada; fixtures e dois processos de teste isolados.
3. **Durabilidade/migração/recuperação:** R05–R08; comparar políticas, backup/restauração e lixeira; sem prometer hardware não testado. Aceite pela matriz §5, versões/FS/hardware declarados.
4. **Carga e diagnósticos:** R11, DX4, RX2, QX6; medir e otimizar gargalo confirmado, sem reescrita de engine. Aceite por baseline/objetivo aprovado e ausência de crescimento injustificado; logs e capturas dos estados de erro.
5. **Extensão para relações/ativos:** R12 antes dos cortes dependentes do Marco 3; validar lote inteiro e publicar recursos sem vínculos quebrados. Nenhuma migração de formas acontece como correção incidental de E6.

Cada corte deve declarar testes automatizados, seção/capturas e aprovação da atividade correspondente. As tarefas M2 apenas entregam esta auditoria e seu plano.

## 7. Limites da conclusão

Os três bloqueios prioritários efetivamente encontrados são R01 (recarga destrói a sessão editada), R02 (flush sem resultado/fechamento sem drain explícito) e R03 (limites assimétricos de save/load). R04 é igualmente grave em uso concorrente. Há caminhos concretos no código; ainda faltam ensaios para caracterizar a manifestação em cada plataforma.

Não há base para afirmar que SQLite atual perde commits por energia, que a instalação usa WAL, que rename já participa do autosave ou que há corrupção observada. Também não há base para garantir durabilidade absoluta. O resultado correto da E6 será uma garantia delimitada por política, versão, filesystem e ensaios, com estado de UI honesto e recuperação acionável.
