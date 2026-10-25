# 05 — Configurações, temas, papéis e portabilidade

**Objetivo:** aplicação configurável offline, com preferências compartilháveis entre instalações e defaults legíveis. O usuário pediu um arquivo `.cfg`; recomendamos um formato textual com extensão `.cfg` e gramática documentada (por exemplo, TOML ou INI estendido), sem inventar parser próprio desnecessariamente.

## 1. Escopos de configuração

| Escopo | Exemplos | O que deve afetar |
|---|---|---|
| Aplicativo/global | Idioma, tema, escala de UI, layout, atalhos, paletas, defaults de caneta | Todas as janelas; novas páginas quando cabível |
| Caderno | Nome, cor, futura capa, metadados/referências, eventual override de default | Apenas o caderno |
| Página | A4/infinita, papel, fundo, grade/pauta, margens | **Apenas aquela página**, mesmo após mudar defaults globais |
| Sessão/dispositivo | Janela, monitor, DPI, viewport/zoom, último arquivo aberto | Dispositivo atual; não necessariamente exportável |

**Regra central:** configurar o tipo de página padrão não converte páginas já existentes. A página guarda um **snapshot de seus parâmetros essenciais** na criação.

## 2. Proposta de configuração base

Exemplo **ilustrativo de sintaxe TOML** em arquivo chamado `app.cfg`, não implementação já aprovada:

```toml
schema_version = 1

[appearance]
theme = "system" # light | dark | system
ui_scale = 1.0
code_ligatures = false # liga != → ≠ etc. nos blocos de código (JetBrains Mono)

[layout]
library_visible = true
ink_toolbar_side = "left" # left | right
show_status_bar = true

[page_defaults]
kind = "infinite" # infinite | finite
paper_size = "A4" # quando kind=finite
orientation = "portrait"
background = "dark" # white | dark | custom
pattern = "ruled_margin" # blank | ruled | ruled_margin | grid | dots
ruling_spacing = 24.0 # pontos de página (pt)
margin_line_position = 72.0 # pontos de página (pt)

[pen]
base_width = 2.0 # pontos de página (pt)
pressure_enabled = true
# valores internos de smoothing não são expostos no MVP

[input]
pen_and_mouse_tools_independent = true
space_pan_temporary = true
middle_mouse_pan = true

[palette.light]
colors = ["#202020", "#2367A1", "#A63A32", "#21805C", "#6F4DA0", "#AD6C22", "#676767", "#C05E8C", "#146D77"]

[palette.dark]
colors = ["#F0F0F0", "#7EB6F2", "#FF8581", "#79D3A2", "#BE9EF7", "#FFC27A", "#B9B9B9", "#F49CCC", "#74CFD7"]

[shortcuts]
tool_text = "T"
tool_pen = "P"
tool_select = "V"
toggle_eraser = "E"
color_1 = "1"
color_2 = "2"
color_3 = "3"
color_4 = "4"
color_5 = "5"
color_6 = "6"
color_7 = "7"
color_8 = "8"
color_9 = "9"
open_palette = "0"
zoom_in = "Ctrl++"
zoom_out = "Ctrl+-"
zoom_reset = "Ctrl+0"
```

**Nota importante:** o exemplo possui nove cores rápidas, porque `0` é reservado para abrir paleta, conforme pedido. Os códigos de cor são sugestões preliminares e exigem teste de contraste contra fundos e realces. E3.1 definiu pontos de página (`1/72 pol.`) para `ruling_spacing`, `margin_line_position` e `base_width`; esses valores são ilustrativos e não dependem de pixels físicos, zoom ou DPI. Pan temporário por espaço e botão central são comandos de entrada que podem permanecer nativos, com opção de desativação.

## 3. Preferências de papel

Oferecer predefinições em painel lateral não modal, mostrando resultado na página: tamanho **infinito, A4 e personalizável**; retrato/paisagem; papel branco/escuro/custom; padrões **liso, pautado, pautado com linha de margem vertical, quadriculado, pontilhado**; espaçamento, intensidade/cor das linhas e margem. Configuração de visualização da página é distinta da tinta desenhada: mudar pauta não altera os objetos.

O usuário pode salvar uma combinação como **preset de página** e escolher um preset como padrão. Presets devem ter IDs estáveis (para renomeação) e nomes legíveis. Predefinições internas nunca são apagadas pelo usuário; presets próprios podem ser exportados.

## 4. Paletas e relação com temas

- Inicializar com duas paletas legíveis: uma para papel claro, outra para escuro.
- A UI também possui tema claro/escuro, mas **tema da UI ≠ fundo do papel**. O aplicativo pode recomendar paleta conforme fundo da página, nunca mudar retroativamente cor dos traços salvos.
- Teclas `1–9` selecionam amostras rápidas, e `0` abre paleta completa; cada cor possui nome acessível e valor RGBA/HEX persistido.
- Uma cor de tinta pouco contrastante num papel recebe aviso de legibilidade, não alteração forçada de cor.
- Importar e exportar paletas separadamente seria útil; os nomes de cores e posições devem acompanhar a exportação.

## 5. Exportação/importação de configurações

Fluxo proposto: `Arquivo → Configurações → Exportar preferências` e `Importar preferências`. Exportar arquivo `.cfg` UTF-8 com versão de schema, presets, atalhos, aparência e paletas. **Não exportar por padrão:** caminhos absolutos, histórico de arquivos recentes, IDs de dispositivo, estado de janela/monitor, identificadores locais e informações sensíveis. Cadernos são exportados por fluxo próprio e **não** embutidos no `.cfg`.

Importação exige prévia das diferenças antes de aplicar, opções `mesclar` / `substituir preferências`, validação por schema, relatório de incompatibilidades e recuperação do estado anterior se falhar. Nunca executar comandos ou carregar plugins a partir do `.cfg`. Importação não deve sobrescrever páginas existentes nem modificar seus fundos. Compatibilidade entre versões exige migrações explícitas com defaults seguros para campos novos.

## 6. Validação e recuperação de falhas

- Se arquivo estiver ausente: criar defaults consistentes, sem bloquear inicialização.
- Se inválido: apresentar mensagem explicativa, preservar cópia do arquivo problemático e iniciar com preferências anteriores ou defaults; nunca apagar o original silenciosamente.
- Se atalho conflitar com outro: mostrar conflito e impedir duplicidade ambígua no mesmo contexto; conflitos em contextos mutuamente exclusivos são permitidos se documentados.
- Configuração salva atomicamente (arquivo temporário + substituição segura, quando cabível), com cópia anterior recuperável.
- Separar `schema_version` do número de versão do aplicativo.
- Caso uma cor/papel predefinido deixe de existir em versão futura, usar fallback preservando os valores explícitos da página.

## 7. Acessibilidade e preferências adicionais

Escala de UI, destaque de foco, contraste aumentado, tamanho de alvos, posicionamento da barra para destros/canhotos, desativação de animações dispensáveis e tooltips; todas as preferências operáveis por teclado e com leitores de tela. Não exigir clique em um quadrado de cor sem nome para saber qual cor está ativa.

## 8. Critérios de aceitação

1. Escolher papel A4 quadriculado como padrão; criar página A4; trocar padrão para infinito; a página anterior continua A4.
2. Criar página escura pautada com linha vertical de margem, com tinta legível; mudar tema da UI sem alterar tinta/papel.
3. Exportar `.cfg`, importar em outra instalação e recuperar atalhos, paletas e presets sem copiar cadernos.
4. Importar configuração com atalho duplicado e mostrar conflito sem corromper preferências.
5. Reconfigurar `E`, cores e ações de zoom sem quebrar digitação de texto.
6. Remover/corromper `app.cfg` e garantir inicialização segura com recuperação.

## 9. Decisões abertas

Escolher gramática oficial (TOML recomendado por legibilidade e tipagem simples), comportamento de importação por escopo, sincronização manual versus exportação por arquivo, presets padrão e teclas configuráveis para régua, laço e tamanho de pincel. As unidades de pautas, margens e largura de tinta foram fechadas em E3.1 no [04](04-comportamento-editor-e-organizacao.md) §2.
