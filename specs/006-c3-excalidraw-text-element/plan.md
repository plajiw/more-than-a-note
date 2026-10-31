# Plano — C3 Card de texto no estilo Excalidraw

**Spec:** [spec.md](spec.md) · **Data:** 2026-10-30

## Resumo

Três fatias, cada uma fechada com testes: (1) modelo, formato SQLite v5 e comandos do adaptador; (2) caixa de seleção com oito alças e rotação na camada de controles; (3) ferramentas Seleção e Texto por clique, com Alt+arrastar. Depois, documentos donos, galeria e roteiro.

## Documentos consultados

| Documento | Seção | O que restringe |
| --- | --- | --- |
| [04](../../docs/04-comportamento-editor-e-organizacao.md) | §3.1, §3.2, §5 | Edição, dimensionamento, `zOrder`/`readingOrder` (revistos) |
| [17](../../docs/17-plano-e4-card-de-texto.md) | §1 | Mover, largura, ações e acessibilidade do card (revistos) |
| [13](../../docs/13-estudo-visual.md) | §6.1 | Camada de controles (C2), tokens de papel |
| [16](../../docs/16-formato-conteudo-v2.md) | SQLite | Migração transacional, recusa de versão futura sem escrita |
| [20](../../docs/20-plano-marco3-objetos-e-diagramas.md) | Fora/§2 | Rotação de texto antes vetada; sobreposição |
| [03](../../docs/03-atalhos-e-acessibilidade.md) | §2 | `Ctrl+D` duplica, `Delete` exclui |

## Verificação da constituição

| Princípio | Atende? | Como |
| --- | --- | --- |
| I. Sobrevive a fechar e reabrir | Sim | Altura, largura fixa e rotação gravadas no v5; testes de reabertura C++ e QML |
| II. Atividade registrada | Sim | C3 aberto pelo script; tarefas com evidência |
| III. Galeria, sem flags novas | Sim | Entrada em "Em validação"; capturas nos testes; roteiro de 16 passos |
| IV. Presets e suíte | Sim | `cmake --workflow --preset release` 8/8; `evidence` sem falha |
| V. Estudo visual no 13 | Sim | Síntese C3 no 13 §6.1 |
| VI. Evidência honesta | Sim | IME/leitor de tela com texto girado e 150% físico ficam no roteiro e nos portões |
| VII. Escopo protegido | Sim | Menu de contexto, copiar/colar de objetos e escala da letra fora |

## Desenho

- **Modelo e formato:** `TextContainer.height_pt`/`fixed_height`; `migrateNotebookSchemaV5` (`ALTER TABLE` + caixas antigas com largura fixa); `validate_page` aceita rotação em texto.
- **Adaptador:** `setTextBox`, `rotateText` (a vista gira em torno do centro e envia a origem correspondente; a transformação gravada continua a única descrição), `duplicateTextTo`; mínimo 24 pt, sem máximo.
- **Interface:** `TextSelectionBox.qml` (novo); `EditorTextCard.qml` reescrito (gestos em pixels do pai convertidos para os eixos da caixa girada; prévia e um commit por gesto); `EditorProbe.qml` com superfície de Seleção e sinal `textToolFinished`; `Main.qml` liga `selectEnabled` e devolve a ferramenta.

## Validação

- **Automática:** `tst_text_element.qml` (novo), `tst_editor.qml`, `tst_page_bounds.qml`, testes C++ de esquema, repositório e modelo.
- **Galeria e roteiro:** `checklists/validation.md`.
- **Plataforma:** IME e leitor de tela com texto girado; caneta real; 150% físico.

## Riscos e alternativas descartadas

- **Escalar a letra pelos cantos:** recusado pelo dono do produto; conflitaria com texto rico de tamanhos por trecho.
- **Largura automática para cards antigos:** mudaria a aparência de anotações existentes; a migração as fixa.
- **Pivô da rotação no canto:** guardaria a mesma transformação, mas o gesto pareceria errado; o pivô no centro é calculado na vista.
