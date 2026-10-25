# Project documents

The documents describe the planned desktop notebook. They are currently written in Portuguese. The [current layout](01-layout-refeito.md) replaces the earlier [layout draft](01-layout.md). The [interaction specification](02-ferramentas-e-interacoes.md), [shortcuts and accessibility](03-atalhos-e-acessibilidade.md), [editor behavior](04-comportamento-editor-e-organizacao.md), and [settings and portability](05-configuracoes-e-portabilidade.md) describe the intended user experience.

The [architecture decision](06-arquitetura-e-stack.md) selects C++ and Qt 6. The [requirements review](07-revisao-especializada-dos-requisitos.md) and [OneNote field research](08-pesquisa-de-campo-onenote.md) identify gaps and priorities. The [beta roadmap](09-roadmap-beta.md) and [desktop technical plan](10-plano-tecnico-desktop.md) describe the proposed implementation sequence, including a Windows beta and later Linux and macOS validation.

These are design and planning documents. Implementation choices that depend on pen input, canvas performance, accessibility and data recovery still require technical validation.

The [implementation tasks](11-tarefas-de-implementacao.md) track the next deliverables and required experiments.

The [implementation record](12-registro-de-implementacao.md) connects the current code to the specifications and its acceptance checks.

The [visual language study](13-estudo-visual.md) compares Apple, Adobe and Affinity interfaces and proposes fonts, icons, design tokens and an implementation sequence. Its proposals are validated step by step in the app before they replace the visual system in the current layout.

The [evolution plan](14-plano-de-evolucao-e-experimentos.md) orders the work into stages, lists every planned experiment with its decision criterion, and explains how results are recorded in [experimentos/](experimentos/).

The [E3 content model plan](15-plano-e3-modelo-de-conteudo.md) defines the next implementation sequence for page objects, geometry, commands, persistence boundaries and cross-platform verification.

The [v2 content format](16-formato-conteudo-v2.md) specifies the canonical text and ink codecs, asset metadata, and the explicit SQLite v1-to-v2 migration prepared in E3.4.
