# Experimento de layout — Orla

Abra `index.html` diretamente no navegador. A tela inicial é a Biblioteca; clique em um caderno para ver o espaço de edição. Para abrir o editor diretamente, use `index.html#caderno`.

Este é um protótipo visual em HTML, CSS e JavaScript, baseado em `../01-layout-refeito.md`. Há interações apenas para inspecionar o layout: abrir/voltar da Biblioteca, escolher seção e página, trocar o grupo de ferramentas, recolher a lista de páginas e ajustar a escala visual do papel. O documento e os comandos de edição são demonstrativos e não salvam dados.

O protótipo carrega **IBM Plex** pelo Google Fonts e **Phosphor Icons** pelo jsDelivr. É necessário acesso à internet para essas fontes e ícones; o restante da interface é local. A versão final do aplicativo deverá empacotar seus próprios arquivos de fonte e ícones.

As imagens `preview-library.png`, `preview-caderno.png` e `preview-compact.png` preservam a **primeira versão** para comparação. As imagens com sufixo `-v2` mostram a revisão desktop: seções e páginas no índice do caderno e ferramentas em botões compactos.

Nesta revisão, a Biblioteca manteve as capas dos cadernos e recebeu espaçamento mais compacto. Páginas são itens de navegação dentro de uma seção, não camadas de composição do conteúdo.

As capturas `preview-library-v3.png` e `preview-caderno-v3.png` mostram o ajuste seguinte: seleção sem barra colorida na borda, menos divisórias verticais e Biblioteca com cabeçalho funcional em vez de apresentação promocional. As capturas anteriores permanecem para comparação.

As capturas `preview-library-v4.png` e `preview-caderno-v4.png` mostram a revisão por dois especialistas de UI/UX desktop: barra de menus Arquivo/Editar/Exibir/Inserir/Ajuda, exportação no menu Arquivo, Importar junto de Novo caderno, remoção de ícones com semântica de link ou compartilhamento e alinhamento dos controles. Os menus demonstram localização e hierarquia; seus comandos de arquivo não executam operações reais.

`preview-caderno-v5.png` mostra o ajuste de polimento seguinte: nome do aplicativo removido do segundo cabeçalho, busca/tema/Papel retirados das barras e botão de Configurações no item da página selecionada. Passe o mouse ou foque uma ferramenta para ver a dica com seu atalho, quando houver.

`preview-library-v5.png` mostra a Biblioteca como janela de documentos: lista compacta inicial, capas em miniatura, nome e contagem de seções/páginas por linha, com Novo e Importar próximos ao título. A barra de menus continua no topo; busca, ordenação e alternância Lista/Grade ficam juntas. O botão Grade permite rever as capas em cartões. Esta captura substitui a composição anterior como referência para a Biblioteca.
