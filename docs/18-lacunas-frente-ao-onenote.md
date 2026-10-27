# 18 — Lacunas do plano diante do OneNote

**25 de outubro de 2026.** Este registro não repete a pesquisa. A evidência de elogios e críticas está no [08](08-pesquisa-de-campo-onenote.md). Aqui só se marca o que os planos posteriores fecharam e o que continua sem contrato, olhando o [04](04-comportamento-editor-e-organizacao.md), o [05](05-configuracoes-e-portabilidade.md), o [15](15-plano-e3-modelo-de-conteudo.md) e o [17](17-plano-e4-card-de-texto.md).

“Fechado” significa regra escrita e testável. “Aberto” significa que a intenção existe, mas ainda não há contrato suficiente para implementar sem inventar o comportamento.

## O que já está protegido

Estes elogios da comunidade não precisam de decisão nova:

- Canvas livre, sem transformar a página num documento linear.
- Texto digitado e caneta na mesma página. Quem só digita não depende da caneta: o clique com Texto cria a caixa e o arrasto interno seleciona letras, como no 04 §3.1 e no card do 17.
- Caderno, seção e página, com a Biblioteca separada da edição.
- Abrir e escrever sem diálogo obrigatório e sem conta.

## O que segue aberto

| Tema do 08 | Situação agora | O que falta |
| --- | --- | --- |
| Tinta que perde o lugar quando o texto muda | O 04 não reposiciona tinta com o texto. Grupo manual está previsto para o Marco 3, ainda sem prova no editor. | Contrato de agrupar texto, tinta e imagem, e de mover esse grupo como um comando. Dizer na interface que texto livre não arrasta o resto. |
| PDF e impressão cortam conteúdo | O 17 exige aviso antes de exportar o que ficou fora do A4. A prévia e a paginação do infinito não estão especificadas. | Prévia obrigatória, área exportada e teste de tela, PDF e impressão com texto, imagem e tinta. |
| Perda de notas e sync | O app é local. Autosave e recuperação ainda não têm o ensaio de queda no meio da gravação. | Commit durável, status “Salvo” só depois dele, lixeira, backup portátil e restauração em outra máquina. |
| Conta e formato fechado | A direção offline está no 04, no 05 e no 06. O formato editável existe para o texto no 16; o caderno inteiro portátil ainda não é um fluxo de usuário. | Abrir, editar e restaurar sem serviço. Não prometer importar `.one`. |
| Busca e tags | Busca por título e texto está prevista; o escopo ainda conflita no 03. Tags não existem. | Um escopo só, salto até a caixa, e pontuação literal. Tags só depois de haver modelo e índice. |
| Manuscrito na busca | Fora da v1, de propósito. | A busca não pode anunciar tinta como pesquisável. Descrição manual de um grupo de tinta pode existir antes de OCR. |
| Atalhos e troca de ferramenta | O 02 e o 03 definem teclas fora do texto. O card não muda isso. | Tooltip com atalho, remapeamento e teste com IME. Caneta, borracha e marcador não capturam tecla com o texto em foco. |
| Latência da caneta | Intenção, sem meta medida. | Prova com mesa digitalizadora. O traço não muda depois de soltar a ponta, salvo opção explícita. |
| Caixa que nasce torta | O 17 fecha mover, largura e altura pelo texto. O alinhamento às pautas não estava fechado. | O contrato do ímã opcional está no [19](19-ima-pagina-e-escrita.md). Não é o modo normal da página. |
| PDF de aula como base | Continua proposta. O 04 não tem página importada com tinta vinculada. | Inserir o PDF com tamanho estável, poder travar a base e exportar a tinta no mesmo lugar. |
| Checklist e divisor | O 04 tem lista com marcador e número. Não tem checkbox nem fio horizontal. | Acrescentar os dois como texto simples, depois do editor básico. Prioridade média. |

Nenhuma linha desta tabela autoriza copiar a interface do OneNote. Onde a comunidade elogia liberdade e reclama de desalinhamento, a resposta combinada é caixa opcional, ímã desligado por padrão e grupo manual quando a pessoa pede para mover texto e tinta juntos.
