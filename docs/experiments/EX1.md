# EX1 — Qual composição sustenta o editor visual unificado?

- Etapa: E4.8, com revalidação no Marco 3 e portão de caneta em E5 · Data: 2026-10-30 · Status: em andamento (protocolo documental; execução pendente)
- Ambiente: nenhum ambiente experimental novo medido na M2. Base de código inspecionada: `25f20a2`; Qt mínimo 6.8. Registrar versões concretas ao executar.
- Origem: [M2](../../specs/002-m2-unified-editor-architecture/spec.md). Donos: [10 §3](../10-plano-tecnico-desktop.md), [14 §5.2](../14-plano-de-evolucao-e-experimentos.md) e [arquitetura 22](../22-arquitetura-editor-visual-unificado.md).

## Hipótese

**Preliminar:** manter Qt Quick/QML + QQuickItem/QSG na página, reaproveitando texto rico e histórico existentes. As falhas potenciais são custos da projeção/tesselação integral e integração de foco/acessibilidade, não uma inadequação demonstrada de Quick. Medir antes de escolher outro motor. O candidato B é canvas Widgets se A falhar EX2, EX4 ou EX7 após investigação localizada, como previsto no catálogo.

O experimento compara comportamento equivalente: texto rico, tinta com amostras preservadas, formas/conectores, seleção/overlays, zoom/pan, reabertura e acessibilidade. Não compara só linhas sem texto contra um editor completo.

### Baseline real e lacunas

- [InkProbeItem::updatePaintNode](../../apps/desktop/ink_probe_item.cpp) mantém nós ativo/confirmado; alteração de conteúdo e escala pode tesselar novamente todo o conjunto confirmado. Malha float, cor/largura fixas; pressão não é renderizada.
- [PageEditorAdapter::rebuildVisual](../../apps/desktop/page_editor_adapter.cpp) reconstrói listas e limita exibição a **50.000 pontos totais**; `addInk` e `InkProbeItem` também limitam entrada. Um ensaio que ultrapassa isso e mede só os traços restantes é inválido como benchmark do documento inteiro.
- Cards são TextEdit em Repeater; `TextCardModel::sync` evita recriar linhas sem alteração, mas não virtualiza todos os documentos de texto.
- `PageSession::apply` valida página inteira; persistência síncrona ocorre antes da notificação QML. Medir separadamente validação, codec, SQL e projeção.
- Não foram localizados medidores de quadro/ponta→tela. `QElapsedTimer mergeClock_` mede apenas janela de fusão de comandos.
- Formas, conectores, seleção mista, caneta e borracha reais ainda não chegam ao editor; linhas desses cenários permanecem **não executáveis na base atual**. Fixture só de desenho de formas não prova edição/undo/persistência de diagramas.

## Protocolo

### 1. Governança e bancada

Implementar instrumentação/cenários somente em atividade de engenharia própria. Nada de protótipo nesta M2. Usar testes existentes/novos casos registrados na suíte e seções da galeria, sem nova janela, flag ou variável. Saídas em `build/release/evidence/` com metadados e dados brutos; temporários sempre no preset. Executar pelo caminho comum:

```sh
cmake --workflow --preset release
cmake --build --preset release --target evidence
cmake --build --preset release --target gallery
.specify/scripts/check.sh
```

Esses alvos **ainda não produzem** a instrumentação proposta. Uma atividade futura deve integrá-la e documentar pontos de captura; não alegar medição só porque `evidence` passou. Perfis nativos devem executar apenas os casos que exigem sessão gráfica, com SKIP explícito onde faltarem dispositivo/compositor/medidor. Nenhuma ausência de métrica vira zero.

### 2. Matriz de ambiente

Registrar CPU/modelo/cores, RAM, GPU/driver/API gráfica realmente usada, armazenamento e filesystem, alimentação/estado térmico, Windows/Linux/kernel/compositor, Qt/compilador/build/SQLite, fonte/fallback, resolução, DPR, tamanho lógico da janela, frequência real dos monitores e dispositivo/driver de caneta. A máquina de referência e seu orçamento são decisão do produto antes do aceite quantitativo.

**Máquinas escolhidas pelo dono do produto (30/10/2026):**

| Papel | Máquina | Configuração conhecida | Falta registrar |
| --- | --- | --- | --- |
| Referência principal (Windows) | PC desktop do dono do produto | Intel Core i5-7400 (4c/4t, 3,0 GHz), 24 GB RAM, placa-mãe Gigabyte H110M-S2V, NVIDIA GeForce GTX 1660, um monitor 1920×1080 a 74 Hz, Windows 10 Pro 10.0.19045 | Driver NVIDIA, armazenamento, escala do Windows; instalar CMake/MSYS2 antes da E4.8 |
| Pior caso (Linux, vídeo integrado) | Notebook Samsung com Linux | A levantar | CPU, RAM, GPU integrada, distribuição, compositor (Wayland/X11), tela e escala |

As metas de quadro e latência valem para a referência principal; o notebook mede o pior caso esperado do público (estudante com vídeo integrado). A GTX 1660 é mais forte que a média do público: um resultado aprovado só nela não basta para aceitar a carga.

| Linha | Condição e objetivo | Portão |
| --- | --- | --- |
| Windows nativo | GPU/driver identificados, tela única 100% e 150% simulados | Baseline funcional e de render; simulação não comprova DPI misto |
| Linux Wayland nativo | Compositor/oclusão registrados; janela visível em posição reproduzível | Perfil próprio; não extrapolar do Windows |
| Linux X11 | Executar se fizer parte da matriz de suporte escolhida | Resultado separado, nunca presumido pelo Wayland |
| Dois monitores físicos | Escalas diferentes; mover janela em repouso, composição IME e gesto quando possível | Conferir geometria, DPR, caret e latência; não aceito por screenshot escalado |
| Wacom CTL-672 | Modelo/driver/eventos enumerados; pressão real quando exposta | Ponta→tela e PX; não presumir borracha traseira/touch |
| Offscreen/software | Testes lógicos e capturas compatíveis | Não comparar desempenho GPU ou aprovar tinta cuja captura seja omitida |

Não misturar backend software e GPU na mesma distribuição estatística. Se oclusão suspender quadros, registrar trecho como tal; não excluí-lo silenciosamente para melhorar P99. APIs posteriores ao Qt 6.8 precisam de compatibilidade explícita, não atualização de requisito nesta revisão.

### 3. Fixtures reproduzíveis

Os números seguintes são **cargas de ensaio propostas**, não metas de produto nem resultados. Gerador futuro determinístico, seed `20261030`, versão/checksum e número exato de amostras registrados. Guardar documento e sequência de input reproduzíveis, sem depender de dados pessoais.

| Fixture | Traços × pontos | Cards de texto | Formas / conectores | Distribuição |
| --- | ---: | ---: | ---: | --- |
| small-mixed | 100 × 32 | 10 | 20 / 20 | Todos visíveis; alternar Z entre modalidades |
| medium-mixed | 2.000 × 64 | 100 | 300 / 400 | 25% dentro da viewport inicial, restante fora; regiões esparsas e densas |
| large-mixed | 10.000 × 128 | 500 | 1.000 / 1.500 | 5% visível, cluster denso para sobreposição e laço |
| current-ink-control | 2.000 × 16 | 20 | 0 / 0 | 32.000 pontos, controle que cabe no teto atual; não substitui medium-mixed |
| rich-text-heavy | 100 × 32 | 100 | 0 / 0 | Cards com textos curtos e longos, listas, estilos, links, acentos, emoji, RTL |
| single-long-stroke | Um traço com carga progressiva | 10 | 20 / 20 quando disponíveis | Crescer duração/amostras até limite publicado, sem descartar pontos para caber |

Texto padrão: sequência determinística de parágrafos em 1, 10 e 100 linhas por card, distribuídos ciclicamente; usar fontes embarcadas e conjunto explícito de runs/estilos na fixture. Guardar texto exato, não gerar conteúdo variável. Traços: mix de retas, curvas, pontos isolados, cantos, sobrepostos, pressão ausente e variável; os rótulos de pressão só podem ser medidos quando renderer/entrada suportarem. Portas/rotas: metade reta, metade ortogonal quando esse corte existir; não desenhar “conectores” sem relações e chamá-los de prova funcional.

Na base atual executar apenas parcelas suportadas, rotuladas por nome/sufixo e contagem real. **medium/large não passam** até superar de forma correta os limites de representação visual ou redefinir o limite do produto com aprovação. A M2 não altera o teto. Em E4.8 medir texto+tinta; em Marco 3 repetir fixture completa, evitando dependência circular de exigir diagramas implementados para começar E4.8.

### 4. Sequência por fixture/candidato

1. Verificar hash e round-trip do DTO; confirmar contagens carregadas/renderizadas e ausência de objetos omitidos. Falha de integridade invalida comparação de desempenho.
2. Abrir documento em processo novo; medir abertura até conteúdo utilizável, não só até retorno da consulta. Fazer rodada cold claramente descrita (processo novo não garante cache de disco frio) e warm separada; não esvaziar caches do SO por comandos improvisados.
3. Proposta de coleta: 10 s de aquecimento e 60 s por interação, cinco repetições independentes; gravar quantidade de amostras, eventos e quadros. Durações podem mudar no piloto, antes de analisar resultados, com motivo registrado.
4. Executar roteiro determinístico de zoom ancorado 50→100→300→50%, pan sobre regiões visíveis/invisíveis, digitação e IME, escrita contínua, seleção de 1/10/100 elementos, drag/cancelamento, reconexão, undo/redo e mudança de página. Medir tinta ativa enquanto o restante da cena exige atualização; gestos simultâneos só nos dispositivos/contextos permitidos pelo roteador.
5. Repetir drag em borda, sobre texto/portas e cluster sobreposto; testar hit-testing positivo e vazio, laço cruzando traços sem vértice interno e objetos bloqueados.
6. Fechar/reabrir e comparar conteúdo/IDs/relações; depois registrar memória após limpar seleção, sair da página e evictar caches. Para uso longo, seguir QX6 (2 h) em E6, sem trocar esse teste por uma rodada de 60 s.
7. Alternar ordem A/B entre repetições para reduzir viés térmico/cache. Mesma fidelidade de desenho, dados, hardware e tamanho de janela. Registrar tarefas concorrentes e interferências; não apresentar somente melhor execução.

### 5. Métricas e método de medição

| Métrica | Como medir | Limitação / interpretação |
| --- | --- | --- |
| Processamento do evento | Relógio monotônico na entrada e saída do handler, com ID da amostra | Não mede espera anterior na fila nem apresentação; timestamp de dispositivo pode ter outro domínio de relógio |
| Evento→submissão de quadro | Correlacionar ID da amostra incluída na malha com sinais de sincronização/render/submissão | Buffer thread-safe, sem tocar QObject GUI do render thread; sinal não comprova fóton |
| Ponta→visual real | Filmagem de alta velocidade sincronizada mostrando contato na mesa e resposta da tela, ou medidor físico apropriado; repetir posições/direções | Para CTL-672 sem tela, câmera deve enquadrar mesa e monitor/usar sincronização verificável; reportar resolução temporal (1/fps), erro e atraso de scanout; sem equipamento, marcar não medido |
| Quadro P50/P95/P99 | Tempos CPU de update/sync/render separados de intervalos de apresentação; dados brutos e quantis por rodada | `frameSwapped` é quadro enfileirado para apresentar; não é tempo GPU nem conclusão de scanout |
| Quadros perdidos | Em animação contínua conhecida, comparar intervalos apresentados com período do monitor; reportar contagem de slots perdidos e percentual | Janela idle não tem “quadros perdidos”; com VRR/compositor sem timestamp de apresentação confiável, indicar proxy e não equiparar a medida física |
| Memória | RSS/working set e memória privada/commit do processo, pico e patamar após navegação; buffers GPU quando ferramenta do SO expuser | RSS não inclui toda VRAM e cache do SO; registrar o que a ferramenta mede e não somar métricas incompatíveis |
| Abertura/restauração | Separar open SQL, decode, validate, layout, projeção e primeiro conteúdo utilizável; confirmar contagens | Nova instância não implica cache frio; primeiro paint vazio não conta como pronto |
| Hit-testing | Tempo de consulta completa, broad/narrow, candidatos e hits; corpus de posições fixas | Microbenchmark isolado não demonstra responsividade durante layout/drag |
| Commit/undo | Tempo de comando, codec, SQL commit e atualização da UI, separadamente | Latência de disco não é renderização; pode exigir corte E6 em vez de trocar engine |
| Responsividade | Ação identificada→feedback de seleção/caret/menu; medir maior intervalo sem atender input e resultado funcional | P99 de quadro bom pode esconder pausa na thread GUI; observar IME e teclado |

API confirmada: [QQuickWindow 6.8](https://doc.qt.io/qt-6.8/qquickwindow.html#frameSwapped) define `frameSwapped` como enfileiramento para apresentação; `afterFrameEnd` indica submissão. Usar relógio monotônico comum e correlacionar amostra/revisão para não confundir um quadro antigo com resposta ao input. Capturas `grabToImage` são evidência visual, não medidor de latência: seu custo deve ficar fora da janela de benchmark e ser registrado.

Ferramentas propostas: instrumentação C++ de relógio monotônico nos testes e pontos do editor; profiler de CPU/QML do ambiente Qt quando disponível no build documentado; contadores de processo do Windows/Linux; captura física para ponta→tela. Ferramenta externa e opção de profiling devem ser registradas na atividade antes do uso, respeitando a lista fechada de execução; não adicionar flags ad hoc. Resultado de GPU só é aceito se a ferramenta expuser timestamps válidos para o backend efetivo.

### 6. Critérios de aceitação e de decisão

**Contrato já registrado:** o catálogo EX4 cita quadro ≤16 ms em máquina de referência, com orçamento final fixado por dados. Isso é referência provisória de planejamento, não P99 já aprovado ou medido. Para monitor de frequência H, período de apresentação é 1000/H ms; a 60 Hz é cerca de 16,67 ms. Medir trabalho CPU/GPU e apresentação separadamente; não reprovar intervalo de vsync de 16,67 ms por confundi-lo com orçamento CPU de 16 ms.

Antes de rodar aceite final, o dono do produto e a engenharia registram hardware mínimo, cargas representativas (a partir de caderno de aula/diagramas), meta de quantil e limite de regressão obtido com baseline repetida. **Nenhum limite novo de milissegundos/MB é aprovado pela M2.**

Portões funcionais independentes de números:

- Texto/IME e caret corretos, teclado sem troca indevida de ferramenta, leitura por tecnologia assistiva real (EX2/EX7).
- Conteúdo inteiro visível, sem reduzir pontos/pressão ou contagem para esconder limite; coordenadas/IDs/relações conservados ao reabrir.
- Sem regressão de mistura e ordem Z; captura/cancelamento e seleção determinísticos; erro de armazenamento não perde trabalho.

Método para fechar números: medir baseline e variabilidade → correlacionar atraso com tarefas de escrita/edição → fixar orçamento do dispositivo e quantil/percentual de perda aceitável → repetir → avaliar melhoria/regressão com intervalos de confiança ou distribuição por repetição. Não escolher limite depois de ver o candidato vencedor. Se hardware ou meta ainda estiverem indefinidos, resultado permanece diagnóstico, não decisão.

**Regra de escolha:** se A cumprir fidelidade/IME/acessibilidade e orçamento aprovado, manter A pelo menor custo de migração. Se falhar, localizar custo: projeção/validação/SQLite não se resolvem automaticamente em Widgets. Fazer melhoria incremental limitada e repetir a mesma fixture. Persistindo falha material da composição, implementar B em atividade própria com modelo/comandos idênticos e exigir ganho mensurado sem regressões. Se nenhum cumprir, registrar bloqueio técnico e novo experimento, não reduzir escopo de dados silenciosamente.

## Medições

**Nenhuma medição executada na M2.** Evidências anteriores: 10 §3 e 12 relatam composição Quick no Linux e IME sintético; M1 registra suíte completa Windows/Linux, capturas e limitações Wayland. Não há dados brutos de P50/P95/P99, ponta→tela, carga mista ou comparação Widgets disponíveis nesta revisão.

Tabela a preencher na execução, uma linha por rodada e ambiente:

| Commit / Qt / backend / máquina | Fixture e hash / contagem real | Interação / repetição | Evento / quadro / apresentação (P50/P95/P99) | Slots perdidos | RAM/VRAM | Abertura / hit-test | Integridade / EX2 / EX7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Não executado | — | — | — | — | — | — | — |

Guardar dados brutos com unidades, relógio usado, número de amostras, warm/cold, outliers e razão de cada exclusão; agregação não deve ocultar uma rodada ruim. Média sozinha é insuficiente para escrita.

## Decisão e motivo

### Matriz comparativa preliminar

| Critério | A — Qt Quick + QSG/texto atual | B — Widgets QPainter / Graphics View | C — Híbrido entre superfícies |
| --- | --- | --- | --- |
| Desempenho | Retenção/GPU já usadas; reconstrução global candidata a gargalo, sem carga medida | Dirty regions/controlar pintura, mas custo CPU/texto/cena densa desconhecido; Graphics View é opção retida distinta | Passes/composição extras e sincronização; nenhum ganho comprovado |
| Complexidade | Menor mudança imediata; exige projeção por ID e gestão de texto | Reconstruir editor, eventos/overlays e ponte com moldura QML | Maior fronteira de foco, janelas, input e clipping |
| Acessibilidade | Cards têm nomes; árvore completa/voz pendentes | Widgets não fornecem semântica automática de objetos customizados | Duas árvores/contextos a integrar; risco de navegação |
| IME | Caminho atual e teste sintético existem; prova nativa pendente | QTextEdit/QTextDocument são candidatos; comportamento na composição deve ser testado | Foco e posição de preedit cruzam fronteiras |
| Windows/Linux/Wayland | Caminho corrente; backend/compositor/DPI precisam medir | Canvas isolado funciona como hipótese; integração de janelas muda portão | Restrições de stacking e embedding dependem da composição escolhida |
| Risco de migração | Baixo em dados, médio em input/ordem | Alto em UI/testes, baixo em formato se domínio preservado | Alto em integração e portabilidade |
| Manutenção | Um caminho existente, testes reaproveitados | Novo caminho de editor com paridade a demonstrar | Dois ciclos de vida; maior matriz de falhas |
| Confiança | Média na continuidade; baixa no desempenho sem ensaio | Baixa, sem protótipo comparável | Baixa, sem benefício demonstrado |

Distinções técnicas: `QQuickPaintedItem` usa pintura para textura na base 6.8 e não deve ser escolhido como aceleração garantida ([Qt](https://doc.qt.io/qt-6.8/qquickpainteditem.html)); `QQuickWidget` adiciona passe offscreen e desabilita render loop threaded ([Qt](https://doc.qt.io/qt-6.8/qquickwidget.html#performance-considerations)). Ele embute Quick em Widgets e não resolve automaticamente inserir um widget na ApplicationWindow existente. Não extrapolar esses custos para qualquer arquitetura híbrida sem especificar a composição.

**Recomendação:** continuar A e investigar custos locais. **Status da decisão:** preliminar, dependente de EX2/EX4/EX7, hardware-alvo e métricas aprovadas. Não há motivo demonstrado para migração integral.

## Consequências (documentos e tarefas atualizados)

M2 referencia este protocolo em 06, 10, 14, 20, 22 e roadmap, sem marcar EX1 como decidido. E4.8 mede a fatia realmente existente; E5 acrescenta caneta real; Marco 3 revalida carga com formas, conectores e seleção mista. Toda comparação que mudar um contrato aprovado volta ao documento dono e à validação antes de implementação.
