# Atividades

Índice e estado de todo o trabalho a partir de 29/10/2026. O fluxo está em [`.specify/fluxo.md`](../.specify/fluxo.md) e as regras na [constituição](../.specify/memory/constitution.md). A atividade ativa é a apontada por [`.specify/feature.json`](../.specify/feature.json).

## Antes do Spec Kit

As etapas E0 a E4.7 foram registradas diretamente nos documentos e não ganham pasta retroativa. Valem como linha de base:

| Etapa | Estado | Registro |
| --- | --- | --- |
| E0 Fundação, E1 Linguagem visual | concluídas | [12](../docs/12-registro-de-implementacao.md), [13](../docs/13-estudo-visual.md) |
| E2 Moldura do caderno | Linux validado; Windows, Orca e DPI físico pendentes | [12](../docs/12-registro-de-implementacao.md) |
| E3.1–E3.6 Contrato do conteúdo | concluídas no CI Linux e Windows | [15](../docs/15-plano-e3-modelo-de-conteudo.md), [16](../docs/16-formato-conteudo-v2.md) |
| E4.1–E4.6 Prova do editor | implementação local; portões de plataforma pendentes | [17](../docs/17-plano-e4-card-de-texto.md), [12](../docs/12-registro-de-implementacao.md) |
| E4.7 Seleção e histórico unificado | implementação local, commit `96d024f` de 29/10/2026; a suíte completa ainda não foi executada | [12](../docs/12-registro-de-implementacao.md) §E4.7 |

## Próximas no roadmap

Em ordem, conforme o [14](../docs/14-plano-de-evolucao-e-experimentos.md) e o [17](../docs/17-plano-e4-card-de-texto.md). Cada uma vira atividade ao ser iniciada.

1. **M1** Limpeza e ambiente único de validação: planejada; T001 concluída.
2. **E4.8** Carga e acessibilidade: 2.000 traços, muitos cards, memória, latência e leitor de tela; decisão EX1.
3. **E5** Caneta real, quando o Linux enumerar a Wacom.
4. **E6** Conteúdo persistente e confiável.

## Registro

Uma linha por atividade, acrescentada por `.specify/scripts/nova-atividade.sh`. Ao mudar o estado, edite a coluna correspondente. Esta tabela deve ser a última seção do arquivo.

| Nº | ID | Atividade | Tipo | Estado | Aberta |
| --- | --- | --- | --- | --- | --- |
| 001 | M1 | [Limpeza e ambiente único de validação](001-m1-limpeza-e-validacao/spec.md) | manutencao | planejada | 2026-10-29 |
