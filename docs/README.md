# Documentos do projeto

Estes documentos descrevem o caderno desktop planejado e são os **donos das decisões**: produto, arquitetura e linguagem visual. O trabalho em si (o que está em andamento, o que foi feito e com que evidência) fica em [`specs/`](../specs/ROADMAP.md), seguindo a [constituição](../.specify/memory/constitution.md) e o [fluxo](../.specify/workflow.md). Cada atividade leva suas decisões ao documento dono correspondente.

## Produto e experiência

- [01 — Layout atual](01-layout-refeito.md), que substitui o [rascunho de layout](01-layout.md)
- [02 — Ferramentas e interações](02-ferramentas-e-interacoes.md)
- [03 — Atalhos e acessibilidade](03-atalhos-e-acessibilidade.md)
- [04 — Comportamento do editor e organização](04-comportamento-editor-e-organizacao.md)
- [05 — Configurações e portabilidade](05-configuracoes-e-portabilidade.md)

## Arquitetura, pesquisa e planos

- [06 — Arquitetura e stack](06-arquitetura-e-stack.md): C++ e Qt 6
- [07 — Revisão especializada dos requisitos](07-revisao-especializada-dos-requisitos.md) e [08 — Pesquisa de campo OneNote](08-pesquisa-de-campo-onenote.md): lacunas e prioridades
- [09 — Roadmap da beta](09-roadmap-beta.md): marcos de produto e critérios de saída
- [10 — Plano técnico desktop](10-plano-tecnico-desktop.md): portões de plataforma e riscos
- [11 — Tarefas de implementação](11-tarefas-de-implementacao.md) e dívida técnica
- [12 — Registro de implementação](12-registro-de-implementacao.md): resumo de cada etapa concluída, com evidência
- [13 — Estudo visual](13-estudo-visual.md): referências Apple, Adobe e Affinity, tokens e padrões aprovados
- [14 — Plano de evolução e experimentos](14-plano-de-evolucao-e-experimentos.md): etapas e catálogo de experimentos, com resultados em [experiments/](experiments/)
- [15 — Plano E3: modelo de conteúdo](15-plano-e3-modelo-de-conteudo.md) e [16 — Formato de conteúdo v2](16-formato-conteudo-v2.md)
- [17 — Plano E4: caixa de texto](17-plano-e4-card-de-texto.md)
- [18 — Lacunas frente ao OneNote](18-lacunas-frente-ao-onenote.md) e [19 — Ímã de página e escrita](19-ima-pagina-e-escrita.md)
- [Ideias](ideias.md): caixa de entrada, triada ao fim de cada atividade

As imagens citadas pelos documentos ficam em [images/](images/). Capturas de trabalho são geradas em `build/<preset>/evidence/` (veja o [BUILDING.md](../BUILDING.md)); uma captura aprovada vai para a pasta da atividade, em `specs/NNN-…/evidence/`.

Estes são documentos de desenho e planejamento. Escolhas que dependem de caneta, desempenho do canvas, acessibilidade e recuperação de dados ainda exigem validação técnica.


## M2 — revisão em validação

A [M2](../specs/002-m2-unified-editor-architecture/tasks.md) acrescenta quatro documentos de proposta. Não substituem contratos aprovados; implementação, experimentos e aprovação têm portões próprios.

- [20 — Plano do Marco 3: objetos e diagramas](20-plano-marco3-objetos-e-diagramas.md): cortes implementáveis, derivados da arquitetura.
- [21 — Auditoria de confiabilidade E6](21-auditoria-confiabilidade-e6.md): riscos observados, contrato de salvamento e ensaios futuros.
- [22 — Arquitetura do editor visual unificado](22-arquitetura-editor-visual-unificado.md): mapa do código, contratos, cinco ADRs e cenários integrados.
- [EX1 — Estratégia de renderização](experiments/EX1.md): protocolo e comparação Quick/Widgets, sem medições novas ou decisão definitiva.
