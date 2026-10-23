# VX1 — Qual fonte, ícones e renderização de texto?

- Etapa: E1 · Data: 2026-10-23 · Status: decidido
- Ambiente: Windows 11, escala 100%, Qt 6.12.0 (MSYS2 UCRT64), build release

## Hipótese

Inter ou IBM Plex Sans servem à interface; Phosphor ou Fluent System Icons servem aos ícones; a renderização nativa do Windows pode ser mais nítida que a do Qt em tamanhos pequenos.

## Protocolo

Galeria visual com seletores que trocam fonte, ícones e renderização no app inteiro. Amostras com textos reais do app, ícones em 14/16/20 px com estado ativo, papel em IBM Plex Serif. Comparação ampliada (2×) dos mesmos textos em renderização Qt e nativa.

## Medições

- Fontes: as duas resolvem pesos 400/500/600 e acentos sem falha.
- Ícones: Phosphor fill vira glifo vazado em quadrado preenchido em vários ícones (+, T, B); Fluent é mais fino.
- Renderização: diferença mínima a 100%; a nativa fica levemente mais nítida.

## Decisão e motivo

- Interface em **Inter**; **JetBrains Mono** para código e teclas de atalho; papel em IBM Plex Serif.
- Ícones **Phosphor** (regular; fill no estado ativo).
- Renderização **Qt**: diferença mínima, e ela acompanha zoom e animação e é igual em todos os sistemas.

## Consequências

13 §6.2 atualizado; IBM Plex Sans e Fluent removidos dos ativos; componente `Kbd` criado.
