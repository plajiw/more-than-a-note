# Ideias

Caixa de entrada de ideias e alternativas que surgem durante as atividades. Nenhuma entra direto no código: ao fim de cada atividade, cada entrada é triada em **agora**, **experimento**, **depois da beta** ou **descartada**, conforme o [14](14-plano-de-evolucao-e-experimentos.md) §10. Uma entrada triada sai daqui e vai para o lugar de destino (tarefa, catálogo de experimentos ou roadmap), com o motivo.

Modelo de entrada:

```markdown
## AAAA-MM-DD · título curto
- **Origem:** atividade ou situação em que surgiu
- **Problema que resolve:** …
- **Triagem:** pendente
```

## 2026-10-29 · Nomes de produto para a superfície do editor
- **Origem:** M1, ao remover a sondagem E4.1
- **Problema que resolve:** `EditorProbe`, `InkProbeItem`, `editorProbe*` e `PageEditorAdapter.demoEnabled` ainda carregam nomes de experimento, embora sejam o editor real
- **Triagem:** pendente

## 2026-10-29 · Botão “Salvar textos” e dica de Ctrl+S depois da gravação em rajadas
- **Origem:** M1, revisão do `EditorProbe`
- **Problema que resolve:** desde a E4.7 a digitação é gravada sozinha; o botão e a dica “Ctrl+S salva o texto” podem confundir. Decisão de produto, não de limpeza
- **Triagem:** pendente

## 2026-10-30 · Encaminhamentos da revisão M2

Registro de destinos, sem inserir funcionalidades no MVP. As duas entradas da M1 acima conservam sua pendência de produto; a auditoria do indicador de salvamento oferece contexto para a segunda, sem decidir remover o botão.

| Ideia / problema | Triagem e destino | Motivo |
| --- | --- | --- |
| Unificar geometria, captura e operações de conteúdo misto | Agora, somente investigação/documentação: [22](22-arquitetura-editor-visual-unificado.md); execução nos cortes do [20](20-plano-marco3-objetos-e-diagramas.md) | Completar responsabilidades existentes, sem refatoração nesta manutenção |
| Índice espacial e troca do motor | Experimento: [EX1](experiments/EX1.md) | Necessidade e ganho dependem de perfil, cargas completas e acessibilidade |
| Elevar só overlays, rótulo incorporado e criação conectada por teclado | Experimento/validação de uso: 22 §12 e 20, apoiados em EX2/EX7/MX2/MX3 | Afetam interação aprovada; não converter hipótese de Tab em atalho |
| Preservar pendente em erro e distinguir Salvo de edição local | Agora, auditoria: [21](21-auditoria-confiabilidade-e6.md); implementação em E6 | Risco de perda já observável no fluxo do código, sem correção incidental |
| OCR, sincronização/CRDT, plugins genéricos e auto-layout avançado | Depois da beta: limites de extensão no 22 §11 | Não necessários para validar texto+tinta+diagramas; exigem problemas e atividades próprios |

Nenhuma ideia dessa tabela foi aprovada como mudança de produto pela M2.

### Modo rápido de diagrama por Tab (alternativa à decisão 3 do 22 §12.1)

- **Ideia:** um modo que o usuário liga explicitamente; dentro dele, Tab cria a próxima caixa já ligada à atual e Esc sai do modo. Fora dele, Tab continua navegando o foco.
- **Origem:** M2, 30/10/2026. O dono do produto escolheu a ação nomeada e pediu para guardar esta alternativa caso a ação não agrade no uso.
- **Triagem:** experimento, no corte M3.10 do [20](20-plano-marco3-objetos-e-diagramas.md), comparando com a ação nomeada (erros de criação, retorno de foco, leitor de tela).

### Desfazer que sobrevive a reiniciar o app

- **Ideia:** gravar a pilha de desfazer no caderno para desfazer passos de uma sessão anterior.
- **Origem:** M2, decisão 7; a [M3](../specs/003-m3-constitution-undo-scope/spec.md) esclareceu na constituição 1.2.1 que o desfazer é de sessão (30/10/2026).
- **Triagem:** depois da beta. Aumenta o arquivo, complica a migração de formato e é raro nas referências (OneNote, Excalidraw, Xournal).

## 2026-10-30 · Pedidos do dono do produto para caneta e gravação

### Sensação de caneta próxima à do Krita

- **Ideia:** o traço com a Wacom deve ter sensação próxima à do Krita: curva de pressão configurável (e calibrável pela força do usuário), estabilizador/suavização ajustável, inclinação quando o dispositivo expõe, latência baixa com prévia imediata e escolha da API de tablet no Windows (Windows Ink ou WinTab), como o Krita oferece.
- **Por que é viável:** o Krita também é feito em Qt e lê a caneta por `QTabletEvent`, a mesma base deste app. O formato MTNI v1 já guarda por ponto a pressão, o tempo relativo e a inclinação originais, e a suavização é só visual (16), então ajustar a curva ou o estabilizador nunca estraga traços antigos.
- **Origem:** dono do produto, 30/10/2026.
- **Triagem:** E5 Caneta real. Entra na spec da E5 como requisito de sensação: PX1 (dados), PX2 (latência) e um experimento novo para curva de pressão e estabilizador, comparado lado a lado com o Krita na mesma mesa.

### Gravar e reproduzir a construção da página

- **Ideia:** reproduzir a página sendo construída, como um "stop motion" do que foi escrito, desenhado e diagramado; opcionalmente exportar em vídeo.
- **Base existente:** cada ponto da tinta já guarda o tempo relativo dentro do traço (MTNI v1), e o histórico unificado (E4.7) já expressa toda mudança como comando. Faltam a hora de cada comando/objeto e um registro que sobreviva a fechar o app.
- **Duas formas:** (a) **replay de comandos**: guardar a sequência de comandos com hora e reexecutá-la; arquivo pequeno, nítido em qualquer zoom, mas exige registro durável do histórico (próximo do "desfazer persistente" acima). (b) **gravação de tela**: capturar quadros da janela; simples e independente do formato, mas pesado e preso à resolução.
- **Cuidado para não fechar a porta:** ao desenhar o formato do Marco 3 e o autosave da E6, prever espaço para hora de criação/alteração por objeto e não descartar o tempo relativo dos pontos.
- **Origem:** dono do produto, 30/10/2026.
- **Triagem:** depois da beta, com o lembrete acima levado à M3.1 (formato) e à E6.
