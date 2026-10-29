# Instruções para agentes neste repositório

Vale para qualquer agente (Claude, Codex ou outro) e qualquer sessão. As regras completas estão na [constituição](.specify/memory/constitution.md), e ela prevalece sobre este resumo.

## Antes de qualquer mudança

1. Leia a [constituição](.specify/memory/constitution.md) e o [fluxo](.specify/workflow.md).
2. Abra `.specify/feature.json` e o `tasks.md` da atividade ativa. Continue pela primeira tarefa aberta.
3. Sem atividade ativa, ou se o pedido não couber nela, abra uma nova com `.specify/scripts/new-activity.sh <id> <slug> "<título>" <tipo>`:
   - **roadmap:** `E4.8` e seguintes, na ordem de [`specs/ROADMAP.md`](specs/ROADMAP.md);
   - **desvio:** `C<n>`, para correção visual ou de comportamento surgida no uso;
   - **manutenção:** `M<n>`, para build, testes, estrutura ou documentação.

Não escreva código fora de uma atividade. Não corrija “de passagem” algo que pertence a outra atividade: abra um desvio ou anote em `docs/ideias.md`.

## Durante a atividade

- Marque cada tarefa `[x]` no `tasks.md` só depois de verificar, com a evidência na linha (comando e resultado).
- Se algo mudar o que foi especificado, atualize `spec.md` e `tasks.md` antes de seguir.
- Compile, teste e valide somente com os comandos do [BUILDING.md](BUILDING.md):

  ```sh
  cmake --workflow --preset release                  # suíte completa: a evidência de conclusão
  cmake --build --preset release --target evidence   # capturas roteirizadas em build/release/evidence/
  cmake --build --preset release --target gallery    # galeria num perfil isolado
  .specify/scripts/check.sh                          # regras verificáveis da constituição
  ```

- Rode testes à vontade durante o trabalho; um teste isolado serve para depurar, não como evidência.
- Saídas temporárias ficam em `build/`. Não crie diretórios de build fora de `build/<preset>` nem passe caminhos da máquina como `-D`: eles vão em `cmake/local.cmake`.
- **Todo teste visual é roteirizado:** pontos de captura nos testes ou seção da galeria, mais o roteiro no `checklists/validation.md`.
- **Não crie opções de linha de comando, variáveis de ambiente, janelas ou modos de demonstração.** A lista fechada está no `BUILDING.md`; um cenário novo vira seção da galeria.
- Comandos, pastas, scripts e identificadores em inglês; documentos e textos da interface em pt-BR.

## Validação na galeria

Toda mudança visível precisa aparecer na galeria, o ambiente de validação do dono do produto. Siga o `checklists/validation.md` da atividade, marque só os itens técnicos que você verificou e passe a atividade para **em validação**. Os itens de aprovação são marcados somente pelo dono do produto.

## Componentes de interface

Sempre que desenvolver ou alterar visualmente um componente de interface:

1. Antes de implementar, consulte `docs/13-estudo-visual.md` e os documentos de estilo e interação relacionados em `docs/` (especialmente `01-layout-refeito.md`, `02-ferramentas-e-interacoes.md` e o plano da etapa atual).
2. Faça um estudo de layout das referências Apple, Adobe e Affinity para o tipo de componente em questão. Consulte documentação oficial quando precisar confirmar um comportamento ou padrão atual; diferencie observação externa de decisão deste produto.
3. Registre no documento visual a síntese aplicada ao componente: geometria, estados, tipografia, cores, foco, teclado, acessibilidade e comportamento em temas e escalas. Use os tokens e as decisões já aprovadas; mudanças de padrão precisam de justificativa registrada.
4. Valide o componente na galeria antes de tratá-lo como concluído.

Para a caixa de texto, a pesquisa e as decisões existentes estão em `docs/13-estudo-visual.md` e `docs/17-plano-e4-card-de-texto.md`.

## Ao fechar

Leve as decisões aos documentos donos, resuma a atividade com link no `docs/12-registro-de-implementacao.md`, atualize o [roadmap](specs/ROADMAP.md) (texto, checklist e gráfico) e `.specify/feature.json`. Commits começam pelo ID da atividade (`E4.8: …`) e só são feitos quando o dono do produto pedir.
