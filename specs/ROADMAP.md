# Roadmap vivo

Mostra onde o projeto está, o caminho percorrido, os desvios e o que vem a seguir. É atualizado **em texto, checklist e gráfico** a cada mudança de estado de uma atividade, conforme o [fluxo](../.specify/fluxo.md) e a [constituição](../.specify/memory/constitution.md) (II). Os marcos e critérios de produto continuam no [09](../docs/09-roadmap-beta.md), e a ordem e os experimentos no [14](../docs/14-plano-de-evolucao-e-experimentos.md). Este arquivo registra a **execução**.

Os gráficos são Mermaid. O GitHub os desenha; no VS Code, a prévia de Markdown precisa da extensão *Markdown Preview Mermaid Support*.

## Onde estamos

- **Atividade ativa:** [M1 — Limpeza e ambiente único de validação](001-m1-limpeza-e-validacao/tasks.md), em implementação: Fase 2 (build único) em andamento.
- **Linha principal parada em:** E4.7, commit `96d024f`.
- **Próxima no roadmap:** E4.8 Carga e acessibilidade, que só começa quando a M1 for aprovada.

## Caminho percorrido

O tronco `main` é a sequência do roadmap. Cada manutenção (`M`) ou desvio (`C`) é um ramo que sai do ponto onde surgiu e volta ao fechar. O destaque marca o ponto em andamento, e as etiquetas são commits.

```mermaid
gitGraph
  commit id: "E0 Fundação" tag: "Marco 1"
  commit id: "E1 Linguagem visual"
  commit id: "E2 Moldura do caderno"
  commit id: "E3.1–E3.6 Contrato do conteúdo"
  commit id: "E4.1 Sondagem texto e tinta"
  commit id: "E4.2 Repositório de página"
  commit id: "E4.3 Prova persistida"
  commit id: "E4.4 Geometria da caixa"
  commit id: "E4.5 Texto rico"
  commit id: "E4.6 Viewport"
  commit id: "E4.7 Histórico unificado" tag: "96d024f"
  branch M1-limpeza
  checkout M1-limpeza
  commit id: "Spec Kit adotado" tag: "4fe74d2"
  commit id: "T002 linha de base" tag: "c4700ed"
  commit id: "Fase 2 build único" tag: "d2218bb" type: HIGHLIGHT
```

## Caminho à frente

```mermaid
flowchart LR
  M1["M1 Limpeza e validação"]:::current --> E48["E4.8 Carga e acessibilidade<br/>decisão EX1"]:::next
  E48 --> E6["E6 Conteúdo persistente<br/>e confiável"]:::next
  E6 --> E7["E7 Telas finais<br/>e acabamento"]:::next
  E7 --> M3["Marcos 3–6<br/>objetos, aula, confiança, beta"]:::next
  M3 --> E8["E8 Distribuição final"]:::next
  E48 -. quando houver Wacom .-> E5["E5 Caneta real"]:::next
  E5 -. bloqueia a beta .-> M3
  classDef current fill:#F2C14E,stroke:#8A6512,color:#1F1A10
  classDef next fill:#D9DEE5,stroke:#6B7685,color:#1A1F26
```

## Checklist

### Concluído

- [x] **E0 Fundação:** toolchain, modelo inicial, persistência da hierarquia, presets, Docker e pacote portátil (Marco 1)
- [x] **E1 Linguagem visual base:** fontes, ícones, tokens e galeria ([VX1](../docs/experimentos/VX1.md))
- [x] **E2 Moldura do caderno:** validada no Linux
  - [ ] Fala com Orca confirmada
  - [ ] VX13 com dois monitores físicos
  - [ ] Windows: Narrator/NVDA, DPI misto e ZIP em PC limpo (PL1)
- [x] **E3.1–E3.6 Contrato do conteúdo:** núcleo, comandos, codecs, migração e CI Linux/Windows
- [x] **E4.1–E4.7 Prova do editor:** implementação local, de E4.1 (sondagem) a E4.7 (histórico unificado)
  - [ ] Validação manual no Windows, DPI físico, leitor de tela e pinça de touchpad
  - [ ] E4.7: histórico de seleção múltipla, comandos agrupados e leitor de tela anunciando o passo desfeito
  - [x] Suíte completa sobre E4.7: 8/8 e 12/12 casos de interface, em offscreen e Wayland (M1, T002)

### Em andamento

- [ ] **M1 Limpeza e ambiente único de validação** ([spec](001-m1-limpeza-e-validacao/spec.md), [tarefas](001-m1-limpeza-e-validacao/tasks.md))
  - [x] Fase 1: preparação e linha de base
  - [ ] Fase 2: build único. Presets, `desktop_core` e ambiente por máquina feitos; faltam perfil isolado, alvos e CI
  - [ ] Fase 3: testes independentes
  - [ ] Fase 4: galeria como ambiente único
  - [ ] Fase 5: pastas e artefatos
  - [ ] Fase 6: documentação e verificação automática. Roadmap vivo feito (T041); faltam `BUILDING.md`, docs 11/14 e `verificar.sh`
  - [ ] Fase 7: fechamento e aprovação na galeria

### Próximo

- [ ] **E4.8 Carga e acessibilidade**
  - [ ] Medir 2.000 traços, muitos cards, memória, latência e quadro (EX4, QX5)
  - [ ] Navegação e anúncios por leitor de tela (EX7)
  - [ ] Decidir entre Qt Quick e canvas Widgets (EX1, com EX2, EX4 e EX7) e fechar EX8
  - [ ] Validar a prova manualmente no Windows; critério de saída do Marco 2 sem caneta
- [ ] **E5 Caneta real**, quando o Linux enumerar a Wacom: PX1–PX4 e VX15; completa o Marco 2
- [ ] **E6 Conteúdo persistente e confiável:** autosave transacional, “Salvo” honesto, D5, DX1, DX3, DX4, RX1–RX3 e QX6
- [ ] **E7 Telas finais e acabamento:** Biblioteca final, janela estreita, teclado de ponta a ponta, atalhos nos tooltips, reduzir movimento, contraste, reescrita do 01 e QX3
- [ ] **Marco 3** Objetos e seleção espacial (T3.1)
- [ ] **Marco 4** Fluxo de aula com PDF, busca e links (T3.2, T2.3)
- [ ] **Marco 5** Confiança, recuperação e saída em PDF (T4.1, DX2, MX7)
- [ ] **Marco 6** Beta fechada Windows (T5.1, UX2)
- [ ] **E8 Distribuição final:** instaladores Windows e `.deb`, GitHub Releases, RX4 e RX5

### Pendências transversais

- [ ] QX1: checks obrigatórios na `main` (configuração do GitHub)
- [ ] VX8: nome exibido no app, antes de distribuição pública
- [ ] Licença do projeto, antes de contribuições externas

## Como atualizar

| Momento | Texto | Checklist | Gráfico |
| --- | --- | --- | --- |
| Abrir atividade | “Onde estamos” | Item novo em “Em andamento” | `branch` para M ou C, a partir do ponto de origem; roadmap no tronco |
| Concluir uma fase do `tasks.md` | “Onde estamos” | Marcar a fase | `commit` no ramo com o hash como `tag`; o ponto atual leva `type: HIGHLIGHT`, retirado do anterior |
| Passar a **em validação** | “Onde estamos” | — | Etiqueta “em validação” no último commit |
| Fechar (aprovada) | “Onde estamos” e próxima | Mover para “Concluído”, com pendências de plataforma como subitens abertos | `checkout` do ponto de origem e `merge` do ramo; atividade de roadmap vira `commit` no tronco |
| Descartar ou bloquear | Motivo | Riscar o item com o motivo | Ramo sem `merge`, com a etiqueta “descartada” ou “bloqueada” |

Um desvio que surge durante outra atividade sai do ramo dela e volta para ela:

```text
  checkout M1-limpeza
  branch C1-alca-desalinhada
  checkout C1-alca-desalinhada
  commit id: "C1 alça desalinhada" tag: "abc1234"
  checkout M1-limpeza
  merge C1-alca-desalinhada
```

## Registro

Uma linha por atividade, acrescentada por `.specify/scripts/nova-atividade.sh`. Ao mudar o estado, edite a coluna correspondente. Esta tabela deve ser a última seção do arquivo.

| Nº | ID | Atividade | Tipo | Estado | Aberta |
| --- | --- | --- | --- | --- | --- |
| 001 | M1 | [Limpeza e ambiente único de validação](001-m1-limpeza-e-validacao/spec.md) | manutencao | em implementação | 2026-10-29 |
