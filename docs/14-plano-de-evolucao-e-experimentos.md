# 14 — Plano de evolução e experimentos

**Status:** plano vigente de execução, revisado a cada etapa concluída. **Data:** 23 de outubro de 2026.

Os documentos anteriores dizem **o que** construir e **como verificar**. Este documento diz **em que ordem**, **o que testar antes de decidir** e **onde registrar o resultado**. Ele não substitui nenhum deles:

| Documento                                                                                                                                                                                                                                                      | Papel                                   | Relação com este plano                      |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- | ------------------------------------------- |
| [09 — Roadmap](09-roadmap-beta.md)                                                                                                                                                                                                                             | Marcos 1–6 e critérios de saída da beta | As etapas abaixo levam aos marcos           |
| [10 — Plano técnico](10-plano-tecnico-desktop.md)                                                                                                                                                                                                              | Arquitetura, portões T0–T5 e P1–P2      | Os experimentos de editor vêm da §3 e da §7 |
| [11 — Tarefas](11-tarefas-de-implementacao.md)                                                                                                                                                                                                                 | Tarefas T*, dívida técnica D*           | Cada etapa aponta as tarefas que fecha      |
| [12 — Registro](12-registro-de-implementacao.md)                                                                                                                                                                                                               | O que foi implementado e verificado     | Recebe o resumo de cada etapa concluída     |
| [13 — Estudo visual](13-estudo-visual.md)                                                                                                                                                                                                                      | Linguagem visual e padrões aprovados    | Fonte dos experimentos visuais              |
| [02](02-ferramentas-e-interacoes.md), [03](03-atalhos-e-acessibilidade.md), [04](04-comportamento-editor-e-organizacao.md), [05](05-configuracoes-e-portabilidade.md), [07](07-revisao-especializada-dos-requisitos.md), [08](08-pesquisa-de-campo-onenote.md) | Requisitos, revisão e evidência de uso  | Fonte dos cenários de teste                 |

## 1. Onde estamos

- **Marco 1 concluído** (T0.1, T0.2): app Qt compila, Biblioteca e índice funcionam, cadernos são salvos em SQLite e reabertos.
- **Entrega reproduzível:** presets CMake, build Linux em Docker com testes, pacote ZIP portátil para Windows. Ainda não testado num PC Windows limpo (PL1).
- **Dívida técnica:** D1 e D4 resolvidos; D2, D3 e D5 abertos ([11](11-tarefas-de-implementacao.md)).
- **Linguagem visual:** passos 1–4 do [13](13-estudo-visual.md) concluídos e regras de botão, ilhas e rolagem aprovadas. Galeria visual em **Ajuda → Galeria visual**.
- **Editor:** ainda não existe. É o maior risco do projeto (Marco 2).

## 2. Princípios de evolução

1. **Risco primeiro.** O que pode invalidar outras decisões é testado antes. A prova do editor pode mudar a tecnologia da área da página; por isso, o acabamento das telas não avança muito além da moldura antes dela.
2. **Tudo no app real.** A galeria é a bancada onde um componente nasce e é aprovado; em seguida ele é usado nas telas. Não existe "versão de galeria" separada do app.
3. **Fatias verticais.** Cada etapa termina com algo que funciona de ponta a ponta no app, mesmo que pequeno, em vez de camadas completas isoladas.
4. **Experimento antes de decisão.** Toda escolha com dúvida técnica ou de uso vira um experimento com pergunta, protocolo, medida e critério de decisão (§5). Nada é decidido "no olho" quando pode ser medido.
5. **Decisão registrada.** Toda decisão tomada aponta o experimento que a sustentou e vai para o documento dono do assunto (§6).
6. **Só conta o que sobrevive a fechar e reabrir.** Uma função visualmente pronta que perde dados ou posição não está entregue ([09](09-roadmap-beta.md), regra de priorização).
7. **Hardware real é portão, não simulação.** Pressão, hover e latência da caneta só são aceitos com a Wacom CTL-672; o mouse permite desenvolver, nunca aprovar.

## 3. Trilhas de trabalho

O trabalho corre em quatro trilhas. Elas avançam juntas, mas cada etapa tem uma trilha principal.

| Trilha         | Conteúdo                                                           | Documentos donos |
| -------------- | ------------------------------------------------------------------ | ---------------- |
| **Interface**  | Componentes, telas, layout em ilhas, teclado, acessibilidade da UI | 01, 03, 13       |
| **Editor**     | Canvas, texto rico, tinta, seleção, zoom, undo/redo                | 02, 04, 06, 10   |
| **Dados**      | Modelo de objetos, SQLite, autosave, backup, migrações             | 04, 05, 10 §4    |
| **Plataforma** | Build, pacote, licenças, Linux, macOS, hardware                    | 05, 10 §5–6      |

## 4. Etapas

Cada etapa lista entrada, entregas, experimentos e critério de saída. Os IDs de experimento estão no catálogo (§5).

```text
E0 Fundação ──► E1 Linguagem visual ──► E2 Moldura do caderno ─┐
                                                                ├─► E4 Prova do editor ──► E6 Conteúdo persistente ──► E7 Telas e acabamento ──► Marcos 3–6
                 E3 Contrato do modelo (em paralelo a E1/E2) ───┘          │
                                                                E5 Caneta real (quando houver Wacom)
```

### E0 — Fundação · concluída

Marco 1, portão T0, tarefas T0.1 e T0.2. Toolchain, modelo inicial, persistência da hierarquia, presets, Docker e pacote portátil.

### E1 — Linguagem visual base · em andamento

- **Trilha:** Interface. **Referência:** [13](13-estudo-visual.md) §6, passos 1–7.
- **Entregas:** tokens, fontes e ícones (feito); componentes primitivos (feito); ilhas e rolagem (feito); grupo de ferramentas Texto/Caneta/Seleção e área de ajustes (passo 5); linhas de lista e cabeçalhos de grupo (passo 6); menus estilizados e criação inline no lugar dos diálogos (passo 7).
- **Experimentos:** VX2, VX3, VX9.
- **Saída:** componentes dos passos 5–7 aprovados na galeria; padrões registrados no 13 §6.

### E2 — Moldura do caderno no app real

- **Trilha:** Interface. **Referência:** [13](13-estudo-visual.md) passos 9–11; [01](01-layout-refeito.md) §3.2.
- **Entregas:** espaço do caderno montado em ilhas: faixa do caderno, toolbar com o grupo de ferramentas (estado visual, sem edição), índice lateral redimensionável e recolhível, área da página com papel e rolagem, barra de status. A área da página fica vazia, pronta para receber o editor.
- **Experimentos:** VX3 (ilhas no uso real), VX4, VX6 (início), VX10, VX13, QX1, QX2, QX4, PL1.
- **Saída:** navegar Biblioteca → caderno → seção → página na nova moldura, com teclado; nenhum componente do estilo padrão do Qt visível.

### E3 — Contrato do modelo de conteúdo · em paralelo

- **Trilha:** Dados/Editor. **Referência:** [07](07-revisao-especializada-dos-requisitos.md) §6 itens 1–2; [04](04-comportamento-editor-e-organizacao.md).
- **Entregas:** decisão da família `PageObject` v1 (texto, tinta, imagem, forma, conector, grupo, gráfico importado); propriedades comuns (id, transformação, limites, `zOrder`, bloqueio, descrição acessível); lista de comandos reversíveis; formato inicial dos pontos de tinta. Atualizar 02 e 04 com essas regras.
- **Decisões do dono do produto:** o que "gráfico" significa na v1 (imagem importada, proposta do 07) e a semântica de diagrama (conectores ligados ou não).
- **Saída:** 04 descreve os objetos e comandos que o editor vai implementar; o modelo C++ (`core/model`) ganha os tipos básicos com testes, e D3 tem plano.

### E4 — Prova do editor (Marco 2 com mouse e teclado)

- **Trilha:** Editor. **Referência:** [10](10-plano-tecnico-desktop.md) §3 e §7; [06](06-arquitetura-e-stack.md) §3; tarefas T1.1 e T1.3.
- **Entregas:** dentro da moldura de E2, uma página A4 e uma infinita com dois contêineres de texto rico, tinta desenhada com mouse atravessando o texto, seleção, mover, zoom ancorado, pan temporário, undo/redo único e salvar/reabrir.
- **Experimentos:** EX1 a EX9, QX5.
- **Decisão central:** EX1 escolhe a composição da área da página (Qt Quick com item próprio ou Qt Widgets embutido). Registrar no 10 §3.
- **Saída:** critério do Marco 2 em [09](09-roadmap-beta.md), exceto o que depende de caneta real, aprovado com medições registradas.

### E5 — Caneta real · quando houver Wacom

- **Trilha:** Editor/Plataforma. **Referência:** T1.2; [02](02-ferramentas-e-interacoes.md) §3–4.
- **Entregas:** adaptador de `QTabletEvent` com pressão, hover, borracha quando exposta e encerramento determinístico do gesto; ferramentas separadas para mouse e caneta.
- **Experimentos:** PX1 a PX4, VX15.
- **Saída:** Marco 2 completo. Pode acontecer em qualquer momento depois de E4 começar; não bloqueia E6, mas bloqueia a beta.

### E6 — Conteúdo persistente e confiável

- **Trilha:** Dados. **Referência:** T2.1; [10](10-plano-tecnico-desktop.md) §4; D5.
- **Entregas:** esquema versionado dos objetos, autosave por transação, status "Salvo" honesto, migração do esquema 1, posições sem duplicar (D5).
- **Experimentos:** DX1, DX3, DX4, RX1, RX2, RX3, QX6.
- **Saída:** fechar, matar o processo e reabrir preserva o conteúdo; "Salvo" só aparece após gravação confirmada.

### E7 — Telas finais e acabamento

- **Trilha:** Interface. **Referência:** [13](13-estudo-visual.md) passos 8, 12 e 13; T2.2; D2.
- **Entregas:** Biblioteca final (lista e grade, capas, ordenação, estados vazios), janela estreita, teclado de ponta a ponta, tooltips com atalho em todos os comandos, animações com "reduzir movimento", revisão de contraste. **Reescrever o [01](01-layout-refeito.md)** a partir dos padrões aprovados no 13.
- **Experimentos:** VX4, VX5, VX6, VX7, VX10–VX16, QX2, QX3, UX1. Cada tela passa pela lista de polimento (§9).
- **Saída:** portão T2 do [10](10-plano-tecnico-desktop.md) (domínio e espaço) aprovado.

### Depois de E7 — Marcos 3 a 6

Seguem o [09](09-roadmap-beta.md) sem mudança, com os experimentos MX1–MX9, DX2, RX4 e RX5: objetos e seleção espacial (Marco 3, T3.1), fluxo de aula com PDF (Marco 4, T3.2, T2.3), confiança e saída (Marco 5, T4.1, DX2) e beta fechada (Marco 6, T5.1, UX2). Linux e macOS seguem os portões P1 e P2 (PL2, PL3). A estimativa de datas só é feita depois de E4, como o 09 determina.

## 5. Catálogo de experimentos

**Status:** ⏳ a fazer · 🔬 em andamento · ✅ decidido.

### 5.1 Interface (VX)

| ID  | Pergunta                                                 | Como testar                                           | Critério de decisão                                                             | Etapa | Status                                             |
| --- | -------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------- | ----- | -------------------------------------------------- |
| VX1 | Qual fonte, ícones e renderização de texto?              | Galeria, A/B no Windows                               | Escolha do dono do produto                                                      | E1    | ✅ Inter, JetBrains Mono, Phosphor, renderização Qt |
| VX2 | A toolbar de 32 px é confortável com mouse e caneta?     | Toolbar real, tarefas de troca de ferramenta          | Sem cliques errados; alvo de 32 px aceito ou subir para 36                      | E1    | ⏳                                                  |
| VX3 | Ilhas: 6 px de separação e raio 8 funcionam no uso real? | Moldura do caderno nos dois temas                     | Aprovação visual; separação legível no tema claro                               | E1/E2 | 🔬                                                  |
| VX4 | Bordas de 1 px ficam nítidas a 125% e 150%?              | Capturas ampliadas em cada escala                     | Sem bordas borradas; senão, linha ajustada ao pixel físico                      | E2/E7 | ⏳                                                  |
| VX5 | Os tokens passam no contraste WCAG 2.2?                  | Medir pares texto/fundo e foco nos dois temas         | ≥ 4,5:1 texto; ≥ 3:1 ícones, foco e bordas de campo                             | E7    | ⏳                                                  |
| VX6 | Como a janela estreita se reorganiza?                    | Larguras 1100, 800 e 600 px                           | Mesmo modelo mental; nada essencial inacessível ([01](01-layout-refeito.md) §8) | E2/E7 | ⏳                                                  |
| VX7 | Barra de título nativa ou integrada?                     | Comparar no Windows; no Mac exige Qt 6.9              | Ganho visual compensa custo de QA?                                              | E7    | ⏳                                                  |
| VX8 | Nome exibido: "Orla" ou "more-than-a-note"?              | Decisão de produto; 07, 08 e o preview já usam "Orla" | Escolha do dono do produto                                                      | E1    | ⏳                                                  |
| VX9 | Menus in-window estilizados se comportam bem?            | `Popup.Window`, teclado, monitores múltiplos          | Sem corte na borda; teclado e foco corretos                                     | E1    | ⏳                                                  |

### 5.2 Editor (EX) — mouse e teclado

| ID  | Pergunta                                                        | Como testar                                                                                                           | Critério de decisão                                                                                 | Etapa | Status |
| --- | --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ----- | ------ |
| EX1 | A área da página fica em Qt Quick (item próprio) ou Qt Widgets? | Mesmo cenário nos dois candidatos, se A falhar em EX2, EX4 ou EX7                                                     | Escolher A, salvo falha de IME, acessibilidade ou latência ([10](10-plano-tecnico-desktop.md) §7.1) | E4    | ⏳      |
| EX2 | Texto rico livre funciona?                                      | `QTextDocument` em contêiner: caret, seleção, acentos (´ + e), teclas mortas, listas, links, várias escalas           | Nenhuma falha de composição ou caret                                                                | E4    | ⏳      |
| EX3 | Dá para editar texto com tinta por cima?                        | Seta desenhada sobre a frase, ferramenta Texto, clicar e editar ([04](04-comportamento-editor-e-organizacao.md) §8.4) | Edita sem selecionar a tinta                                                                        | E4    | ⏳      |
| EX4 | A tinta com mouse tem prévia imediata e fluida?                 | Medir tempo de quadro durante o gesto; página com 2.000 traços                                                        | Quadro ≤ 16 ms em máquina de referência; orçamento final fixado com dados                           | E4    | ⏳      |
| EX5 | Zoom, pan e DPI preservam a geometria?                          | Zoom ancorado, mudar escala do Windows, salvar e reabrir                                                              | Erro geométrico zero nas coordenadas persistidas                                                    | E4    | ⏳      |
| EX6 | Undo/redo misto é coerente?                                     | Sequência digitar, traço, mover, excluir, desfazer e refazer tudo (T1.3)                                              | Reverte e reaplica preservando IDs e amostras                                                       | E4    | ⏳      |
| EX7 | O canvas é acessível?                                           | Narrator e NVDA percorrendo objetos; foco por teclado                                                                 | Objetos anunciados com nome e papel; entrada e saída do canvas por teclado                          | E4    | ⏳      |
| EX8 | Salvar e reabrir preserva tudo?                                 | Round-trip dos pontos de tinta (blob versionado) e do texto rico                                                      | Igualdade exata de posição, pressão e formatação                                                    | E4    | ⏳      |
| EX9 | Atalhos de tecla única não atrapalham a digitação?              | Digitar `1234567890 e p t v` e espaço em texto ([03](03-atalhos-e-acessibilidade.md) §5)                              | Nenhuma troca de ferramenta                                                                         | E4    | ⏳      |

### 5.3 Caneta (PX) — exige Wacom CTL-672

| ID  | Pergunta                                              | Como testar                                                    | Critério de decisão                                                                                        | Etapa | Status |
| --- | ----------------------------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ----- | ------ |
| PX1 | O `QTabletEvent` entrega pressão, hover e borracha?   | Registro de eventos no Windows; perda de foco no meio do traço | Dados completos; gesto sempre encerrado sem meio traço                                                     | E5    | ⏳      |
| PX2 | Qual a latência ponta → prévia?                       | Timestamps do evento ao quadro; filmagem se necessário         | Orçamento definido e cumprido ([10](10-plano-tecnico-desktop.md) §3)                                       | E5    | ⏳      |
| PX3 | Borracha de traço inteiro basta?                      | Aula real com anotação densa e correções                       | Se atrapalhar correções comuns, borracha parcial vira requisito da beta ([09](09-roadmap-beta.md) Marco 2) | E5    | ⏳      |
| PX4 | Ferramentas separadas para mouse e caneta são claras? | Uso híbrido: caneta desenha, mouse edita texto                 | Usuário identifica a ferramenta efetiva sem confusão                                                       | E5    | ⏳      |

### 5.4 Dados (DX)

| ID  | Pergunta                                         | Como testar                                                         | Critério de decisão                                 | Etapa   | Status |
| --- | ------------------------------------------------ | ------------------------------------------------------------------- | --------------------------------------------------- | ------- | ------ |
| DX1 | O autosave sobrevive a falhas?                   | Matar o processo durante gravação; disco cheio; modos de journaling | Última versão íntegra sempre recuperável            | E6      | ⏳      |
| DX2 | Backup e restauração funcionam em outra máquina? | Backup consistente com o banco aberto; restaurar em outro Windows   | Caderno idêntico, com assets                        | Marco 5 | ⏳      |
| DX3 | Migrações de esquema são seguras?                | Fixtures de cada versão publicada                                   | Migra sem perda; versão futura abre em modo seguro  | E6      | ⏳      |
| DX4 | O app escala com muitos itens?                   | 100 cadernos, 50 seções, 1.000 páginas; nomes longos                | Abrir e trocar seção sem atraso perceptível (medir) | E6      | ⏳      |

### 5.5 Plataforma (PL) e uso (UX)

| ID  | Pergunta                                                         | Como testar                                                                                                         | Critério de decisão                                     | Etapa                           | Status |
| --- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | ------------------------------- | ------ |
| PL1 | O ZIP portátil abre num Windows limpo?                           | VM ou PC sem Qt, MSYS2 nem ferramentas de dev                                                                       | Abre e salva cadernos                                   | E2                              | ⏳      |
| PL2 | O app funciona num Linux real?                                   | Build Docker já passa; rodar a interface numa distribuição escolhida                                                | Mesmo cenário da beta (P1)                              | Pós-beta                        | ⏳      |
| PL3 | O app funciona no macOS?                                         | Hardware real, menu do sistema, bundle                                                                              | Mesmo cenário (P2)                                      | Pós-beta                        | ⏳      |
| PL4 | Licenças estão em ordem?                                         | Inventário dos módulos Qt e ativos empacotados                                                                      | Todas as obrigações atendidas; licença do app escolhida | Antes de contribuições externas | ⏳      |
| UX1 | Quanto tempo leva de abrir a página à primeira palavra ou traço? | Cronometrar ([08](08-pesquisa-de-campo-onenote.md) §1)                                                              | Nenhum diálogo obrigatório no caminho                   | E7                              | ⏳      |
| UX2 | Aluno e professor concluem a aula sem ajuda?                     | Cenário integrado do [07](07-revisao-especializada-dos-requisitos.md) §7 e [08](08-pesquisa-de-campo-onenote.md) §4 | Sem perda de dados nem desalinhamento                   | Marco 6                         | ⏳      |

### 5.6 Interface — validações adicionais (VX)

| ID   | Pergunta                                                  | Como testar                                                          | Critério de decisão                                                         | Etapa | Status |
| ---- | --------------------------------------------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------------- | ----- | ------ |
| VX10 | Menus, listas e Biblioteca funcionam com leitor de tela?  | Narrator e NVDA em todo o fluxo Biblioteca → página                  | Nome, papel e estado anunciados; hierarquia caderno/seção/página comunicada | E2/E7 | ⏳      |
| VX11 | O app respeita o alto contraste do Windows?               | Ativar temas de contraste do sistema                                 | Terceiro conjunto de tokens ou paleta do sistema; nada some                 | E7    | ⏳      |
| VX12 | "Reduzir movimento" é respeitado?                         | Desligar animações no Windows e na preferência do app                | Todas as durações vão a zero                                                | E7    | ⏳      |
| VX13 | Mudar de monitor com escala diferente quebra algo?        | Arrastar a janela entre monitores de 100% e 150% com a página aberta | Sem borrão, salto de layout ou coordenada alterada                          | E2/E4 | ⏳      |
| VX14 | Nomes longos, listas grandes e estados vazios ficam bons? | Fixtures com nomes de 120 caracteres, 1.000 páginas, caderno vazio   | Elisão com nome completo acessível; layout não quebra                       | E7    | ⏳      |
| VX15 | Destros e canhotos são atendidos?                         | Popovers e painéis com a caneta na mão esquerda                      | Nada abre sob a mão que escreve ([01](01-layout-refeito.md) §8)             | E5/E7 | ⏳      |
| VX16 | Os textos da interface podem ser traduzidos?              | Envolver textos em `qsTr()`; gerar tradução de teste                 | Nenhum texto fixo; layout aguenta textos 30% maiores                        | E7    | ⏳      |

### 5.7 Marcos 3 a 6 (MX)

| ID  | Pergunta                                | Como testar                                                                       | Critério de decisão                                                                                                | Etapa   | Status |
| --- | --------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------- | ------ |
| MX1 | Imagens grandes e numerosas pesam?      | Página com 30 fotos de 12 MP                                                      | Rolagem fluida; memória limitada por cache                                                                         | Marco 3 | ⏳      |
| MX2 | Seleção mista e grupos são previsíveis? | Selecionar texto, tinta, imagem e forma; agrupar, alinhar, desfazer               | Um undo por gesto; IDs preservados                                                                                 | Marco 3 | ⏳      |
| MX3 | Conectores continuam ligados?           | Mover nós, reabrir, copiar entre páginas                                          | Nenhum conector solto; senão, não anunciar diagrama editável ([07](07-revisao-especializada-dos-requisitos.md) §4) | Marco 3 | ⏳      |
| MX4 | O Qt PDF serve para importar slides?    | PDFs reais de aula (fontes embutidas, imagens, 200 páginas); auditoria de licença | Qualidade e licença aprovadas; original preservado                                                                 | Marco 4 | ⏳      |
| MX5 | A tinta fica alinhada ao slide?         | Anotar, mudar zoom, reabrir, exportar                                             | Erro geométrico zero em relação à base                                                                             | Marco 4 | ⏳      |
| MX6 | A busca acha o que promete?             | Títulos e texto digitado em 1.000 páginas; acentos e maiúsculas                   | Resultado leva ao contêiner certo; manuscrito declarado não pesquisável                                            | Marco 4 | ⏳      |
| MX7 | O PDF exportado é fiel à tela?          | Comparar tela e PDF: fontes, tinta, A4 e infinito, objetos fora da borda          | Nada cortado em silêncio; prévia mostra a paginação                                                                | Marco 5 | ⏳      |
| MX8 | Importar pacote malformado é seguro?    | IDs duplicados, assets ausentes, caminhos maliciosos, esquema futuro              | Recusa clara sem sobrescrever nada                                                                                 | Marco 5 | ⏳      |
| MX9 | A lixeira recupera tudo?                | Excluir página, seção e caderno; restaurar com assets                             | Restauração completa                                                                                               | Marco 5 | ⏳      |

### 5.8 Qualidade de engenharia (QX)

| ID  | Pergunta                                    | Como testar                                                               | Critério de decisão                                     | Etapa | Status |
| --- | ------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------- | ----- | ------ |
| QX1 | O CI garante build e testes a cada mudança? | Pipeline Windows (MSYS2 ou MSVC) e Linux (Docker)                         | Nenhuma mudança entra com build ou teste quebrado       | E2    | ⏳      |
| QX2 | A interface tem testes automáticos?         | Qt Quick Test para componentes e fluxos (criar caderno, navegar, atalhos) | Fluxos essenciais cobertos                              | E2/E7 | ⏳      |
| QX3 | Regressões visuais são detectadas?          | Capturas da galeria e das telas comparadas a uma referência aprovada      | Diferença acima do limite falha o CI                    | E7    | ⏳      |
| QX4 | Quais são os números de base?               | Abertura do app, memória ociosa, tamanho do pacote, abertura de caderno   | Valores registrados; regressão acima de 20% investigada | E2    | ⏳      |
| QX5 | Há erro ou vazamento de memória?            | AddressSanitizer e LeakSanitizer nos testes (Linux)                       | Nenhum relato                                           | E4    | ⏳      |
| QX6 | O app aguenta uso longo?                    | Sessão automatizada de 2 h criando, editando e navegando                  | Memória estável, sem travamento                         | E6    | ⏳      |

### 5.9 Erro, diagnóstico e distribuição (RX)

| ID  | Pergunta                                | Como testar                                                                 | Critério de decisão                                                                      | Etapa   | Status |
| --- | --------------------------------------- | --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | ------- | ------ |
| RX1 | Como o usuário vê um erro?              | Forçar disco cheio, banco corrompido, permissão negada                      | Mensagem clara, contexto preservado, ação de recuperação ([01](01-layout-refeito.md) §7) | E6      | ⏳      |
| RX2 | Há log para diagnóstico?                | Log local rotativo, sem conteúdo do usuário                                 | Problema reproduzível pelo log; nada enviado sem consentimento                           | E6      | ⏳      |
| RX3 | O que acontece depois de um travamento? | Matar o processo com edição em curso                                        | Reabre oferecendo a versão recuperada                                                    | E6      | ⏳      |
| RX4 | Qual instalador usar?                   | Comparar ZIP, MSIX e instalador tradicional                                 | Instala e desinstala sem sobras, de preferência sem administrador                        | Marco 6 | ⏳      |
| RX5 | Assinatura digital e atualização        | Assinar o pacote; avaliar SmartScreen e verificação de atualização opcional | Canal de distribuição decidido                                                           | Marco 6 | ⏳      |

## 6. Como registrar um experimento

1. **Abrir:** criar `docs/experimentos/<ID>.md` com o modelo abaixo antes de começar.
2. **Executar:** anotar ambiente (máquina, Windows, escala, Qt), passos e medições brutas.
3. **Decidir:** escrever a decisão e o motivo; marcar ✅ no catálogo (§5).
4. **Propagar:** levar a decisão ao documento dono (visual → 13; editor e arquitetura → 10; modelo → 04; preferências → 05) e o resumo da etapa ao 12.

```markdown
# <ID> — <pergunta>

- Etapa: E<n> · Data: AAAA-MM-DD · Status: em andamento | decidido
- Ambiente: máquina, sistema, escala da tela, versão do Qt, build

## Hipótese
## Protocolo
## Medições
## Decisão e motivo
## Consequências (documentos e tarefas atualizados)
```

## 7. Próximas ações, em ordem

1. **VX8:** decidir o nome exibido no app.
2. **E1, passo 5:** grupo Texto/Caneta/Seleção com âmbar só no ícone ativo e área de ajustes da ferramenta; avaliar VX2.
3. **E1, passos 6 e 7:** linhas de lista, cabeçalhos de grupo e menus estilizados; avaliar VX9.
4. **QX1 e QX4:** ligar o CI e medir os números de base antes que o app cresça.
5. **E3 (em paralelo):** decidir o significado de "gráfico" e de diagrama na v1; propor a família `PageObject` e atualizar o 04.
6. **E2:** montar a moldura do caderno em ilhas no app real; fazer PL1 com o novo pacote.
7. **E4:** abrir os registros de EX1 a EX9 e construir a prova do editor dentro da moldura.
8. **E5:** assim que houver Wacom, executar PX1 a PX4.

## 8. O que não fazer agora

- Polir a Biblioteca final, grade de capas ou animações antes de E4: podem mudar com a prova do editor e com a reescrita do 01.
- Criar componentes que nenhuma tela ainda usa (paleta de cores, controle de espessura, painel de papel). Eles nascem quando E4 pedir.
- Prometer datas antes da saída de E4 ([09](09-roadmap-beta.md)).
- Aceitar comportamento de caneta testado só com mouse.

## 9. Polimento: lista de verificação por tela

Uma tela só está pronta quando passa por todos os itens, nos dois temas e em 100% e 150%:

1. **Estados:** vazio, carregando, erro, um item, muitos itens, nomes longos.
2. **Interação:** hover, pressionado, foco por teclado, desabilitado e selecionado distintos entre si.
3. **Teclado:** todas as ações alcançáveis; ordem de Tab lógica; `Esc` fecha o que abriu; o foco volta à origem.
4. **Acessibilidade:** nomes e papéis anunciados; nada comunicado só por cor; contraste dentro dos tokens.
5. **Geometria:** alinhado à grade de 4 px; bordas nítidas; nada cortado até a largura mínima.
6. **Texto:** escala tipográfica do [13](13-estudo-visual.md) §3.3; elisão com nome completo no tooltip; dígitos tabulares em números.
7. **Atalhos:** tooltip e menu mostram o atalho em `Kbd`, coerente com o mapa do [03](03-atalhos-e-acessibilidade.md).
8. **Movimento:** transições dentro dos tokens; "reduzir movimento" respeitado.
9. **Regras aprovadas:** botão é ícone ou texto; ilhas; rolagem sobreposta; âmbar só onde significa algo.
10. **Fechar e reabrir:** o estado volta igual (seleção, índice, largura do painel).

## 10. Ideias, alternativas e mudanças de rumo

Ideias e alternativas vão surgir durante os experimentos. Elas não entram direto no código.

1. **Anotar:** toda ideia vai para a [caixa de ideias](ideias.md), com data, origem e o problema que resolve.
2. **Triar**, ao fim de cada etapa, em uma de quatro saídas:
   - **Agora:** pequena, dentro da etapa atual e sem risco; vira tarefa.
   - **Experimento:** tem dúvida técnica ou de uso; ganha ID no catálogo (§5).
   - **Depois da beta:** útil, mas fora do escopo do [09](09-roadmap-beta.md).
   - **Descartada:** com o motivo anotado, para não voltar à discussão.
3. **Mudança de rumo:** quando um experimento contradiz uma decisão registrada:
   - marcar a decisão antiga como **revista** no documento dono, com link para o experimento;
   - listar o que depende dela (etapas, componentes, documentos) e atualizar tudo na mesma mudança;
   - se afetar a beta (escopo, prazo ou dados do usuário), obter aprovação do dono do produto antes do código.
4. **Proteção do escopo:** nenhuma ideia entra no lugar de preservação de dados, posição estável da tinta, fluxo de PDF de aula ou exportação fiel ([09](09-roadmap-beta.md), regra de priorização).
