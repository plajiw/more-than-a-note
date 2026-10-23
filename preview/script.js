const sections = [
  { id: 'pipeline', title: 'Pipeline', icon: 'ph-git-branch', color: '#d5a572', pages: ['Conceitos fundamentais', 'Hazards', 'Superpipeline', 'Desempenho e ciclos'] },
  { id: 'superescalares', title: 'Superescalares', icon: 'ph-cpu', color: '#9ab7aa', pages: ['Múltipla emissão', 'Dependências de dados', 'Execução fora de ordem'] },
  { id: 'memoria', title: 'Memória', icon: 'ph-hard-drives', color: '#bba2cd', pages: ['Hierarquia de memória', 'Cache e localidade', 'Memória virtual'] },
  { id: 'entrada', title: 'Entrada e saída', icon: 'ph-plugs-connected', color: '#8faed0', pages: ['Barramentos', 'Dispositivos', 'Interrupções'] },
  { id: 'revisao', title: 'Revisão', icon: 'ph-check-circle', color: '#c69a98', pages: ['Mapa de conceitos', 'Exercícios', 'Resumo final'] }
];

const state = { view: 'library', section: 'pipeline', page: 0, mode: 'text', notebook: 'Arquitetura de Computadores', zoom: 100, pagesCollapsed: false };
const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];
let toastTimer;

function toast(message) {
  const element = $('#toast');
  element.textContent = message;
  element.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => element.classList.remove('show'), 2700);
}

function showView(view) {
  state.view = view;
  history.replaceState(null, '', view === 'workspace' ? '#caderno' : '#biblioteca');
  $('#library-view').classList.toggle('is-hidden', view !== 'library');
  $('#workspace-view').classList.toggle('is-hidden', view !== 'workspace');
  document.title = view === 'workspace' ? `Orla — ${state.notebook}` : 'Orla — Biblioteca';
  if (view === 'workspace') {
    $('#workspace-book-name').textContent = state.notebook;
    renderWorkspace();
    if (innerWidth <= 800) togglePages(true);
  }
}

function activeSection() { return sections.find(section => section.id === state.section) || sections[0]; }

function renderSections() {
  $('#section-tabs').innerHTML = sections.map(section => `<div class="section-item ${section.id === state.section ? 'active' : ''}" style="--section-color:${section.color}"><button class="section-tab ${section.id === state.section ? 'active' : ''}" data-section="${section.id}" aria-current="${section.id === state.section ? 'true' : 'false'}"><span class="section-dot"></span><i class="ph ${section.icon}" aria-hidden="true"></i><span>${section.title}</span></button>${section.id === state.section ? '<button class="item-action section-settings" data-tooltip="Configurações da seção" aria-label="Configurações da seção"><i class="ph ph-gear-six"></i></button><button class="item-action section-delete" data-tooltip="Excluir seção" aria-label="Excluir seção"><i class="ph ph-trash"></i></button>' : ''}</div>`).join('');
  $$('.section-tab').forEach(button => button.addEventListener('click', () => {
    state.section = button.dataset.section;
    state.page = 0;
    renderWorkspace();
  }));
  $$('.section-settings').forEach(button => button.addEventListener('click', () => toast('Configurações da seção: nome, cor e ícone — painel ilustrativo')));
  $$('.section-delete').forEach(button => button.addEventListener('click', () => toast('Excluir seção — ação ilustrativa')));
}

function renderPages() {
  const section = activeSection();
  $('#active-section-title').textContent = section.title;
  $('#active-section-dot').style.background = section.color;
  $('#page-list').innerHTML = section.pages.map((page, index) => `<div class="page-row ${index === state.page ? 'active' : ''}"><button class="page-item ${index === state.page ? 'active' : ''}" data-page="${index}" ${index === state.page ? 'aria-current="page"' : ''}><i class="ph ph-file-text" aria-hidden="true"></i><span>${page}</span></button>${index === state.page ? '<button class="page-settings" aria-label="Configurações desta página" data-tooltip="Configurações da página"><i class="ph ph-gear-six"></i></button><button class="item-action page-delete" data-tooltip="Excluir página" aria-label="Excluir página"><i class="ph ph-trash"></i></button>' : ''}</div>`).join('');
  $$('.page-item').forEach(button => button.addEventListener('click', () => {
    state.page = Number(button.dataset.page);
    renderPages();
    renderPaper();
    if (innerWidth <= 800) togglePages(true);
  }));
  $$('.page-settings').forEach(button => button.addEventListener('click', () => toast('Configurações da página — painel ilustrativo')));
  $$('.page-delete').forEach(button => button.addEventListener('click', () => toast('Excluir página — ação ilustrativa')));
  $('#page-count').textContent = `Página ${state.page + 1} de ${section.pages.length}`;
}

function renderPaper() {
  const section = activeSection();
  const title = section.pages[state.page];
  $('#crumb-section').textContent = section.title;
  $('#crumb-page').textContent = title;
  $('#paper-title').textContent = title;
  $('.paper-content').style.opacity = state.section === 'pipeline' && state.page === 0 ? '1' : '.55';
}

function renderTools() {
  const tools = $('#mode-tools');
  const templates = {
    text: `<button class="field-tool">IBM Plex Serif <i class="ph ph-caret-down"></i></button><button class="field-tool small">15 <i class="ph ph-caret-down"></i></button><button class="format-tool" title="Negrito"><b>B</b></button><button class="format-tool italic" title="Itálico">I</button><button class="format-tool underline" title="Sublinhado">U</button><button class="format-tool secondary-tool" title="Realce"><i class="ph ph-highlighter"></i></button><button class="format-tool secondary-tool" title="Cor do texto"><i class="ph ph-text-aa"></i></button><button class="format-tool secondary-tool" title="Lista"><i class="ph ph-list-bullets"></i></button>`,
    draw: `<span class="tool-caption">FERRAMENTA</span><button class="format-tool active" title="Caneta"><i class="ph ph-pen-nib"></i></button><button class="format-tool" title="Borracha"><i class="ph ph-eraser"></i></button><button class="format-tool secondary-tool" title="Régua"><i class="ph ph-ruler"></i></button><span class="tool-caption">ESPESSURA</span><button class="field-tool small">2 px <i class="ph ph-caret-down"></i></button><span class="tool-caption">COR</span><button class="swatch-tool active" style="background:#202020" title="Grafite"></button><button class="swatch-tool" style="background:#af6956" title="Terracota"></button><button class="swatch-tool" style="background:#648e9c" title="Azul"></button><button class="swatch-tool" style="background:#9d8a60" title="Ocre"></button><button class="format-tool secondary-tool" title="Paleta completa"><i class="ph ph-palette"></i></button>`,
    select: `<span class="tool-caption">SELEÇÃO</span><button class="format-tool active" title="Selecionar objeto"><i class="ph ph-cursor"></i></button><button class="format-tool" title="Seleção por laço"><i class="ph ph-selection"></i></button><span class="toolbar-divider"></span><button class="tool-labeled secondary-tool"><i class="ph ph-arrows-out-cardinal"></i>Mover</button><button class="tool-labeled secondary-tool"><i class="ph ph-copy"></i>Duplicar</button>`
  };
  tools.innerHTML = templates[state.mode];
  $$('.mode-button').forEach(button => { const active = button.dataset.mode === state.mode; button.classList.toggle('active', active); button.setAttribute('aria-pressed', String(active)); });
  const names = { text: 'Texto', draw: 'Caneta', select: 'Seleção' };
  const icons = { text: 'ph-text-t', draw: 'ph-pen-nib', select: 'ph-cursor' };
  $('#effective-tool-name').textContent = names[state.mode];
  $('.effective-tool i').className = `ph ${icons[state.mode]}`;
  tools.querySelectorAll('button').forEach(button => button.addEventListener('click', () => toast('Ferramenta ilustrativa — protótipo de layout')));
  prepareTooltips();
}

function renderWorkspace() { renderSections(); renderPages(); renderPaper(); renderTools(); }

function togglePages(forceCollapsed) {
  state.pagesCollapsed = typeof forceCollapsed === 'boolean' ? forceCollapsed : !state.pagesCollapsed;
  $('#pages-panel').classList.toggle('is-collapsed', state.pagesCollapsed);
  $('#reopen-pages').style.display = state.pagesCollapsed ? 'flex' : '';
}

function setTheme(theme) {
  document.body.dataset.theme = theme;
  $$('.theme-toggle i').forEach(icon => icon.className = `ph ${theme === 'dark' ? 'ph-moon' : 'ph-sun'}`);
  try { localStorage.setItem('orla-prototype-theme', theme); } catch (_) {}
}

function setZoom(value) {
  state.zoom = Math.min(150, Math.max(70, value));
  $('#zoom-reset').textContent = `${state.zoom}%`;
  $('#paper').style.transform = `scale(${state.zoom / 100})`;
}

function prepareDesktopWorkspace() {
  $('.canvas-actions').remove();
  $('.mini-brand').remove();
  $('.tiny-caret').remove();
  $('.workspace-top-actions').remove();
  $('.toolbar-trailing').remove();
  const panel = $('#pages-panel');
  const heading = $('.pages-heading');
  heading.innerHTML = `<div><span class="panel-overline">NAVEGAÇÃO</span><div class="pages-section-name"><strong>Índice do caderno</strong></div></div><button class="icon-button" id="collapse-pages" aria-label="Recolher índice" title="Recolher índice"><i class="ph ph-sidebar-simple"></i></button>`;
  const group = document.createElement('nav');
  group.className = 'sections-group';
  group.setAttribute('aria-label', 'Seções do caderno');
  group.innerHTML = `<div class="nav-group-heading"><span>SEÇÕES</span><div class="nav-group-actions"></div></div>`;
  const oldRow = $('.section-row');
  group.appendChild($('#section-tabs'));
  group.querySelector('.nav-group-actions').append($('#add-section'), $('#all-sections'));
  oldRow.remove();
  heading.after(group);
  const header = $('.pages-actions');
  header.querySelector('span').textContent = 'PÁGINAS DA SEÇÃO';
  header.before(document.createElement('div'));
  header.previousElementSibling.className = 'section-context';
  header.previousElementSibling.innerHTML = `<span class="active-section-dot" id="active-section-dot"></span><strong id="active-section-title">Pipeline</strong><i class="ph ph-caret-down"></i>`;
  $('#collapse-pages').addEventListener('click', () => togglePages(true));
  $('.toolbar-common').setAttribute('aria-label', 'Histórico');
  $$('.mode-button').forEach(button => {
    button.title = ({ text: 'Texto', draw: 'Desenho', select: 'Selecionar' })[button.dataset.mode];
    button.setAttribute('aria-label', button.title);
    button.setAttribute('aria-pressed', String(button.classList.contains('active')));
  });
}

function prepareLibrary() {
  $('.library-topbar').remove();
  $('.library-heading h1').textContent = 'Biblioteca';
  $('.section-label span:first-child').textContent = 'Cadernos';
  $('.section-label span:last-child').textContent = '3 itens';
  const importButton = $('#import-notebook');
  importButton.innerHTML = `<i class="ph ph-file-arrow-up"></i> Importar`;
  importButton.classList.add('library-import-button');
  $('.library-heading').append(importButton);
  $$('.book-dots,.book-footer i').forEach(element => element.remove());
  $$('.book-meta strong br').forEach(element => element.replaceWith(document.createTextNode(' ')));
  $('.library-bottom').remove();
  const libraryGrid = $('#notebook-grid');
  const gridButton = $('.view-options .icon-button[title="Grade"]');
  const listButton = $('.view-options .icon-button[title="Lista"]');
  const setLibraryView = (view) => {
    libraryGrid.classList.toggle('list-layout', view === 'list');
    gridButton.classList.toggle('selected', view === 'grid');
    listButton.classList.toggle('selected', view === 'list');
    gridButton.setAttribute('aria-pressed', String(view === 'grid'));
    listButton.setAttribute('aria-pressed', String(view === 'list'));
  };
  gridButton.addEventListener('click', () => setLibraryView('grid'));
  listButton.addEventListener('click', () => setLibraryView('list'));
  setLibraryView('list');
}

function prepareTooltips() {
  const hints = [
    ['#back-library', 'Voltar à biblioteca'], ['#collapse-pages', 'Recolher índice'],
    ['#reopen-pages', 'Mostrar índice'], ['#zoom-out', 'Reduzir zoom', 'Ctrl + −'],
    ['#zoom-in', 'Ampliar zoom', 'Ctrl + +'], ['#zoom-reset', 'Zoom de 100%', 'Ctrl + 0'],
    ['#add-section', 'Nova seção'], ['#all-sections', 'Todas as seções'],
    ['#add-page', 'Nova página'],
    ['.toolbar-common .tool-square:first-child', 'Desfazer', 'Ctrl + Z'],
    ['.toolbar-common .tool-square:last-child', 'Refazer', 'Ctrl + Shift + Z'],
    ['.mode-button[data-mode="text"]', 'Ferramenta Texto', 'T'],
    ['.mode-button[data-mode="draw"]', 'Ferramenta Desenho', 'P'],
    ['.mode-button[data-mode="select"]', 'Ferramenta Selecionar', 'V']
  ];
  for (const [selector, label, shortcut] of hints) {
    const element = $(selector);
    if (!element) continue;
    element.dataset.tooltip = label;
    if (shortcut) element.dataset.shortcut = shortcut;
    element.removeAttribute('title');
  }
  const shortcuts = { 'Negrito': 'Ctrl + B', 'Itálico': 'Ctrl + I', 'Sublinhado': 'Ctrl + U', 'Caneta': 'P', 'Borracha': 'E', 'Paleta completa': '0' };
  $$('#mode-tools button').forEach(button => {
    if (!button.title) return;
    button.dataset.tooltip = button.title;
    if (shortcuts[button.title]) button.dataset.shortcut = shortcuts[button.title];
    button.removeAttribute('title');
  });
}

function installTooltipLayer() {
  const tip = document.createElement('div');
  tip.className = 'desktop-tooltip';
  tip.setAttribute('role', 'tooltip');
  document.body.append(tip);
  function show(target) {
    if (!target?.dataset.tooltip) return;
    tip.innerHTML = `<span>${target.dataset.tooltip}</span>${target.dataset.shortcut ? `<kbd>${target.dataset.shortcut}</kbd>` : ''}`;
    tip.classList.add('show');
    const rect = target.getBoundingClientRect();
    const left = Math.min(innerWidth - tip.offsetWidth - 8, Math.max(8, rect.left + rect.width / 2 - tip.offsetWidth / 2));
    const below = rect.top < 55;
    tip.style.left = `${left}px`;
    tip.style.top = `${below ? rect.bottom + 8 : rect.top - tip.offsetHeight - 8}px`;
  }
  function hide() { tip.classList.remove('show'); }
  document.addEventListener('pointerover', event => show(event.target.closest('[data-tooltip]')));
  document.addEventListener('pointerout', event => { if (event.target.closest('[data-tooltip]')) hide(); });
  document.addEventListener('focusin', event => show(event.target.closest('[data-tooltip]')));
  document.addEventListener('focusout', hide);
  document.addEventListener('scroll', hide, true);
}

function prepareApplicationMenus() {
  const definitions = {
    Arquivo: ['Novo caderno', 'Abrir caderno…', 'Importar caderno…', 'Exportar caderno…', 'Exportar página como PDF…', 'Imprimir…', 'Fechar caderno', 'Preferências…'],
    Editar: ['Desfazer', 'Refazer', 'Recortar', 'Copiar', 'Colar', 'Selecionar tudo', 'Buscar neste caderno…'],
    Exibir: ['Mostrar ou ocultar índice', 'Zoom 100%', 'Ajustar página'],
    Inserir: ['Nova seção', 'Nova página', 'Caixa de texto'],
    Ajuda: ['Atalhos de teclado', 'Sobre o Orla']
  };
  for (const view of [$('#library-view'), $('#workspace-view')]) {
    const bar = document.createElement('nav');
    bar.className = 'application-menu';
    bar.setAttribute('aria-label', 'Menu do aplicativo');
    bar.innerHTML = `<span class="menu-app-name">Orla</span>${Object.entries(definitions).map(([name, items]) => `<div class="menu-group"><button class="menu-trigger" aria-haspopup="true" aria-expanded="false">${name}</button><div class="menu-popover" role="menu">${items.map(item => `<button role="menuitem">${item}</button>`).join('')}</div></div>`).join('')}`;
    view.prepend(bar);
  }
  $$('.menu-trigger').forEach(trigger => trigger.addEventListener('click', event => {
    event.stopPropagation();
    const group = trigger.parentElement;
    $$('.menu-group').forEach(item => { if (item !== group) { item.classList.remove('open'); item.querySelector('.menu-trigger').setAttribute('aria-expanded', 'false'); } });
    group.classList.toggle('open');
    trigger.setAttribute('aria-expanded', String(group.classList.contains('open')));
  }));
  $$('.menu-popover button').forEach(button => button.addEventListener('click', () => {
    const label = button.textContent;
    $$('.menu-group').forEach(group => { group.classList.remove('open'); group.querySelector('.menu-trigger').setAttribute('aria-expanded', 'false'); });
    if (label === 'Mostrar ou ocultar índice' && state.view === 'workspace') togglePages();
    else if (label === 'Zoom 100%' && state.view === 'workspace') setZoom(100);
    else if (label === 'Tema claro/escuro') setTheme(document.body.dataset.theme === 'dark' ? 'light' : 'dark');
    else toast(`${label} — comando ilustrativo`);
  }));
  document.addEventListener('click', event => { if (!event.target.closest('.menu-group')) $$('.menu-group').forEach(group => { group.classList.remove('open'); group.querySelector('.menu-trigger').setAttribute('aria-expanded', 'false'); }); });
}

$$('.notebook-card').forEach(card => card.addEventListener('click', () => {
  state.notebook = card.dataset.notebook;
  showView('workspace');
}));
$('#back-library').addEventListener('click', () => showView('library'));
$$('.theme-toggle').forEach(button => button.addEventListener('click', () => setTheme(document.body.dataset.theme === 'dark' ? 'light' : 'dark')));
$$('.mode-button').forEach(button => button.addEventListener('click', () => { state.mode = button.dataset.mode; renderTools(); }));
$('#reopen-pages').addEventListener('click', () => togglePages(false));
$('#all-sections').addEventListener('click', () => toast('Todas as seções — visualização ilustrativa'));
$('#add-section').addEventListener('click', () => toast('Nova seção — visualização ilustrativa'));
$('#add-page').addEventListener('click', () => toast('Nova página — visualização ilustrativa'));
$('#new-notebook').addEventListener('click', () => toast('Novo caderno — visualização ilustrativa'));
$('#import-notebook').addEventListener('click', () => toast('Importar caderno — visualização ilustrativa'));
$('#paper-button').addEventListener('click', () => toast('Propriedades do papel — visualização ilustrativa'));
$('#search-trigger').addEventListener('click', () => toast('Busca no caderno — visualização ilustrativa'));
$('#zoom-out').addEventListener('click', () => setZoom(state.zoom - 10));
$('#zoom-in').addEventListener('click', () => setZoom(state.zoom + 10));
$('#zoom-reset').addEventListener('click', () => setZoom(100));
$('#notebook-search').addEventListener('input', event => {
  const query = event.target.value.trim().toLocaleLowerCase('pt-BR');
  $$('.notebook-card').forEach(card => card.hidden = !card.dataset.notebook.toLocaleLowerCase('pt-BR').includes(query));
});
document.addEventListener('keydown', event => {
  if (event.ctrlKey && event.key.toLowerCase() === 'k' && state.view === 'library') { event.preventDefault(); $('#notebook-search').focus(); }
  if (event.key === 'Escape' && state.view === 'workspace' && innerWidth <= 800 && !state.pagesCollapsed) togglePages(true);
});
$$('button').filter(button => !button.id && !button.dataset.mode && !button.dataset.notebook && !button.classList.contains('theme-toggle')).forEach(button => {
  if (!button.closest('.notebook-card') && !button.closest('.mode-tools') && !button.closest('.section-tabs')) button.addEventListener('click', () => {
    if (!button.closest('.workspace-view') || !button.classList.contains('icon-button')) return;
    if (button.title && !['Alternar tema', 'Recolher páginas'].includes(button.title)) toast(`${button.title} — visualização ilustrativa`);
  });
});
prepareDesktopWorkspace();
prepareLibrary();
prepareApplicationMenus();
installTooltipLayer();
try { setTheme(localStorage.getItem('orla-prototype-theme') || 'dark'); } catch (_) { setTheme('dark'); }
renderWorkspace();
if (location.hash === '#caderno') showView('workspace');
