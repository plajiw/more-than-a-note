# 06 — Arquitetura e stack de implementação

**Decisão:** desenvolver o aplicativo desktop em **C++ com Qt 6**, com beta inicial em Windows e Linux/macOS como plataformas futuras sujeitas aos portões de `10-plano-tecnico-desktop.md`. Esta decisão substitui a indefinição de stack mencionada nos documentos anteriores. O protótipo HTML/CSS/JS que ficava em `preview/` serviu de referência visual e de interação; não é a base de execução do produto. Ele foi retirado na M1 e continua no histórico do git (commit `be9e29a`).

## 1. Motivo da escolha

O requisito mais exigente é um editor local que combina texto rico, tinta vetorial, entrada de caneta com pressão, zoom e seleção na mesma superfície. Qt oferece entrada de tablet por `QTabletEvent`, um modelo de documento rico em `QTextDocument`, renderização própria e suporte às plataformas alvo. C++ permite controlar coordenadas, histórico, persistência e desempenho do canvas sem interpor uma WebView entre os dispositivos e o editor.

Esta é uma escolha de engenharia para o Orla, não uma promessa de desempenho automático. Latência da caneta, comportamento de texto sobre tinta e acessibilidade precisam ser medidos primeiro em Windows e depois em cada plataforma antes da respectiva publicação.

## 2. Divisão inicial de responsabilidades

| Área | Direção inicial |
|---|---|
| Interface do aplicativo | Qt Quick/QML para Biblioteca, índice do caderno, menus, barras, painéis e temas; componentes próprios seguindo `01-layout-refeito.md` |
| Núcleo do editor | C++ para modelo da página, coordenadas, entrada, traços, seleção, histórico e persistência |
| Texto rico | Avaliar `QTextDocument` integrado a contêineres posicionados no canvas; validar caret, seleção, IME e acessibilidade antes de fixar a implementação |
| Tinta e canvas | Renderização vetorial com prévia imediata; escolher a técnica concreta de Qt após medir latência, zoom e custo de muitos objetos |
| Armazenamento | Formato local versionado e transacional a definir; separar o modelo de domínio da UI e do formato de arquivo |
| Configurações | `.cfg` textual versionado conforme `05-configuracoes-e-portabilidade.md`; parser e esquema serão escolhidos na implementação |

Qt Quick é o ponto de partida para a moldura visual. Se a integração entre texto rico e canvas mostrar limitações materiais, um componente de editor baseado em Qt Widgets ou outra composição interna de Qt pode ser usado nessa área, sem mudar a stack do aplicativo. Não pressupor que QML, por si só, resolva o editor.

## 3. Primeiro protótipo técnico obrigatório

Antes de implementar a Biblioteca completa, construir uma página de teste com:

1. Um `TextContainer` rico editável e um `InkStroke` vetorial que atravessa o texto.
2. Wacom CTL-672 em Windows: pontos, pressão, borracha quando exposta, hover, perda de foco e baixa latência percebida; repetir em Linux/macOS nos portões posteriores.
3. Mouse e caneta com ferramentas efetivas independentes, pan temporário e zoom ancorado no ponteiro.
4. Seleção de caracteres sob tinta, seleção de traços, movimento de objetos e undo/redo único.
5. Alteração de DPI, zoom e tamanho da janela sem mudar coordenadas persistidas.
6. Foco por teclado, IME, leitor de tela e anúncio dos objetos acessíveis do canvas.
7. Salvamento e reabertura de uma página de teste sem perda de posição, pressão ou formatação.

**Critério de saída:** escolher o componente de renderização/editor após resultados reais em Windows. Repetir a matriz em Linux/macOS antes de anunciar suporte. Registrar latência observada, falhas de foco/IME, problemas de acessibilidade e custo de páginas com muitos traços e caixas. A decisão de Qt/C++ continua; o protótipo resolve a composição interna do editor.

## 4. Estrutura de módulos proposta

```text
app/           inicialização, janelas, menus e integração com sistema
ui/            componentes Qt Quick/QML, temas e navegação
domain/        caderno, seção, página, objetos e operações
editor/        canvas, texto, tinta, seleção, ferramentas e histórico
storage/       serialização, autosave, migrações, backup e índices
platform/      diferenças de entrada, distribuição e integração por SO
tests/         testes do domínio e cenários de integração críticos
```

As fronteiras são conceituais; a organização exata de arquivos será definida ao iniciar o repositório de código. O domínio não deve depender diretamente de QML. A UI envia operações ao editor/domínio e recebe estado observável. Objetos persistidos usam IDs e coordenadas lógicas, não posições de widgets ou pixels de tela.

## 5. Distribuição, licença e dependências

- Distribuir pacote inicial para Windows e, após validação, pacotes próprios para Linux/macOS, com fontes e ícones locais, sem dependência de CDN. O antigo protótipo em `preview/` usava CDN apenas para visualização.
- Escolher uma versão concreta de Qt 6 e mantê-la fixa por ciclo de desenvolvimento; testar as distribuições Linux suportadas e suas dependências.
- Definir a licença open source do Orla e conferir **a licença de cada módulo Qt usado**, além das obrigações de distribuição. A decisão por Qt não determina automaticamente a licença do aplicativo.
- Empacotar e creditar IBM Plex Sans e Phosphor Icons conforme suas licenças, se forem mantidos na interface final.
- Não introduzir Electron, Tauri ou WebView para reproduzir o layout HTML. Reavaliar essa regra apenas diante de uma necessidade concreta demonstrada pelo protótipo técnico.

## 6. Referências oficiais

- [Qt — plataformas suportadas](https://doc.qt.io/qt-6/supported-platforms.html)
- [Qt — eventos de tablet](https://doc.qt.io/qt-6/qtabletevent.html)
- [Qt — texto rico e `QTextDocument`](https://doc.qt.io/qt-6/richtext.html)
- [Qt — renderização do Qt Quick](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph-renderer.html)
- [Qt — obrigações de licenciamento open source](https://www.qt.io/development/open-source-lgpl-obligations)



## M2 — revisão arquitetural proposta, pendente

O [22](22-arquitetura-editor-visual-unificado.md) mapeia a implementação real em 30/10/2026 e propõe completar o modelo tipado e o histórico existentes, com geometria, seleção e roteamento comuns. Domínio, sessão transitória, projeção renderizada e confirmação persistente têm autoridades separadas; não se propõe reescrita, ECS ou três editores independentes. Os cinco ADRs do 22 são os registros donos dessas recomendações.

Qt Quick permanece candidato A, condicionado ao [protocolo EX1](experiments/EX1.md); não há benchmark M2 nem decisão definitiva entre Quick, Widgets e híbrido. O armazenamento real já usa SQLite v4, codecs MTNT v2/MTNI v1 e transação de lote; a [auditoria E6](21-auditoria-confiabilidade-e6.md) distingue essa base das garantias ainda ausentes. A [evolução de objetos](20-plano-marco3-objetos-e-diagramas.md) exige formato versionado aprovado antes de qualquer escrita. Estas notas atualizam o diagnóstico, sem aprovar as extensões.
