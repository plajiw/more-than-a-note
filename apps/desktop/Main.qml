import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

ApplicationWindow {
    id: window
    width: 1100
    height: 720
    minimumWidth: 720
    minimumHeight: 480
    visible: true
    title: notebookStore.activeNotebookId === "" ? "more-than-a-note — Biblioteca" :
           "more-than-a-note — " + notebookStore.activeNotebookName

    color: Theme.color.base
    font.family: Theme.uiFont
    font.pixelSize: Theme.type.body.size
    palette: Palette {
        window: Theme.color.base
        windowText: Theme.color.textPrimary
        base: Theme.color.raised
        text: Theme.color.textPrimary
        button: Theme.color.surface
        buttonText: Theme.color.textPrimary
        highlight: Theme.color.hover
        highlightedText: Theme.color.textPrimary
        placeholderText: Theme.color.textTertiary
        mid: Theme.color.border
        light: Theme.color.overlay
        dark: Theme.color.border
    }

    Gallery {
        id: gallery
        visible: startWithGallery
        palette: window.palette
        onOpenEditorRequested: window.openSampleEditor()
    }

    // The gallery's Editor section: a known notebook in the isolated profile,
    // created on first use, so validation never touches real notebooks.
    readonly property string sampleNotebookTitle: "Caderno de amostra"
    function openSampleEditor() {
        if (!isolatedProfile) return
        const sample = notebookStore.notebooks.find(notebook => notebook.title === sampleNotebookTitle)
        if (sample) {
            notebookStore.openNotebook(sample.id)
        } else if (notebookStore.createNotebook(sampleNotebookTitle)) {
            notebookStore.addSection("Aulas")
            notebookStore.addPage("Página 1")
            notebookStore.addPage("Página 2")
        }
        if (notebookStore.sections.length > 0 && notebookStore.activeSectionId === "")
            notebookStore.selectSection(notebookStore.sections[0].id)
        if (notebookStore.pages.length > 0 && notebookStore.activePageId === "")
            notebookStore.selectPage(notebookStore.pages[0].id)
        window.raise()
        window.requestActivate()
    }

    Settings {
        id: workspaceSettings
        category: "workspace"
        property int indexWidth: Theme.size.indexWidth
        property bool indexCollapsed: false
    }

    property real pageZoom: 1
    property bool spacePan: false
    property real infiniteWidth: 1800
    property real infiniteHeight: 2200
    readonly property bool panRequested: spacePan ||
        (editorToolbar.selectActive && editorToolbar.selectionMode === "hand")

    function zoomAt(value, anchorX = pageScroll.width / 2, anchorY = pageScroll.height / 2) {
        if (notebookStore.activePageId === "") return
        const next = Math.max(0.5, Math.min(3, Math.round(value * 100) / 100))
        if (next === pageZoom) return
        const pageX = (pageScroll.contentX + anchorX - pageScene.x) / pageZoom
        const pageY = (pageScroll.contentY + anchorY - pageScene.y) / pageZoom
        pageZoom = next
        pageScroll.contentX = Math.max(0, Math.min(pageScroll.contentWidth - pageScroll.width,
                                                 pageScene.x + pageX * next - anchorX))
        pageScroll.contentY = Math.max(0, Math.min(pageScroll.contentHeight - pageScroll.height,
                                                 pageScene.y + pageY * next - anchorY))
    }
    onActiveChanged: if (!active) spacePan = false

    property bool temporaryIndexOpen: false
    property var indexReturnFocusItem: null
    readonly property bool narrowWorkspace: width < 900
    onNarrowWorkspaceChanged: {
        temporaryIndexOpen = false
        if (narrowWorkspace && activeFocusItem === indexResize)
            showIndexButton.forceActiveFocus()
    }
    readonly property bool dockedIndex: !narrowWorkspace && !workspaceSettings.indexCollapsed
    readonly property bool indexShown: dockedIndex || (narrowWorkspace && temporaryIndexOpen)
    readonly property string activeSectionTitle: {
        for (const section of notebookStore.sections)
            if (section.id === notebookStore.activeSectionId) return section.title
        return ""
    }

    function showIndex() {
        if (narrowWorkspace) {
            indexReturnFocusItem = window.activeFocusItem
            temporaryIndexOpen = true
        }
        else workspaceSettings.indexCollapsed = false
    }
    function hideIndex() {
        indexEditKind = ""
        if (narrowWorkspace) temporaryIndexOpen = false
        else workspaceSettings.indexCollapsed = true
        const target = narrowWorkspace && indexReturnFocusItem && indexReturnFocusItem.visible
                     ? indexReturnFocusItem : showIndexButton
        Qt.callLater(() => target.forceActiveFocus())
    }
    function toggleIndex() {
        if (indexShown) hideIndex()
        else showIndex()
    }

    property string indexEditKind: ""
    property string indexEditTargetId: ""
    property string indexEditTitle: ""
    property string pendingDeleteKind: ""
    property string pendingDeleteId: ""
    property string pendingDeleteTitle: ""
    // Library view state for this session only (docs/05 §1): "recent" or "name".
    property string librarySort: "recent"
    readonly property var notebookCovers: ["#C58E61", "#BF6B67", "#B99B56", "#709A76", "#6A91B8", "#967DB0"]

    // Provisional cover color until notebooks store one: stable per id.
    function notebookCover(id) {
        let hash = 0
        for (let i = 0; i < id.length; ++i) hash = (hash * 31 + id.charCodeAt(i)) | 0
        return notebookCovers[Math.abs(hash) % notebookCovers.length]
    }
    function folded(text) {
        return text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
    }
    function createNotebookPrompt() {
        newNotebookDialog.openFor("", "", window.activeFocusItem)
    }
    function focusLibraryRow(index) {
        if (libraryList.count === 0) { newNotebookButton.forceActiveFocus(); return }
        libraryList.currentIndex = Math.max(0, Math.min(libraryList.count - 1, index))
        libraryList.positionViewAtIndex(libraryList.currentIndex, ListView.Contain)
        Qt.callLater(() => { if (libraryList.currentItem) libraryList.currentItem.forceActiveFocus() })
    }
    function openLibraryMenu(row, notebook, x, y) {
        libraryMenu.notebook = notebook
        libraryMenu.returnFocusItem = row
        libraryMenu.popup(row, x, y)
    }

    function startIndexEdit(kind, id, title) {
        if (!indexShown) showIndex()
        indexEditKind = kind
        indexEditTargetId = id
        indexEditTitle = title
    }
    function saveIndexEdit(title) {
        const editedKind = indexEditKind
        const editedId = indexEditTargetId
        let saved = false
        if (indexEditKind === "section/create") saved = notebookStore.addSection(title)
        else if (indexEditKind === "section/rename") saved = notebookStore.renameSection(indexEditTargetId, title)
        else if (indexEditKind === "page/create") saved = notebookStore.addPage(title)
        else if (indexEditKind === "page/rename") saved = notebookStore.renamePage(indexEditTargetId, title)
        if (saved) {
            indexEditKind = ""
            Qt.callLater(() => focusActiveIndex(editedKind.startsWith("section") ? "section" : "page",
                                               editedKind.endsWith("/rename") ? editedId : ""))
        }
    }
    function cancelIndexEdit() {
        const editedKind = indexEditKind
        const editedId = indexEditTargetId
        indexEditKind = ""
        if (editedKind === "section/create") sectionHeader.focusAdd()
        else if (editedKind === "page/create") pageHeader.focusAdd()
        else if (editedKind !== "") Qt.callLater(() => focusActiveIndex(editedKind.startsWith("section") ? "section" : "page", editedId))
    }
    function focusActiveIndex(kind, preferredId = "") {
        if (!indexShown) showIndex()
        const list = kind === "section" ? sectionList : pageList
        const entries = kind === "section" ? notebookStore.sections : notebookStore.pages
        const activeId = preferredId || (kind === "section" ? notebookStore.activeSectionId : notebookStore.activePageId)
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i].id === activeId) {
                list.currentIndex = i
                list.positionViewAtIndex(i, ListView.Contain)
                Qt.callLater(() => {
                    const item = list.itemAtIndex(i)
                    if (item && item.rowButton) item.rowButton.forceActiveFocus()
                })
                return
            }
        }
        if (kind === "section") sectionHeader.focusAdd()
        else pageHeader.focusAdd()
    }
    function askDelete(kind, id, title) {
        pendingDeleteKind = kind
        pendingDeleteId = id
        pendingDeleteTitle = title
        deletePopup.open()
    }
    function focusListItem(list, key, index) {
        if (list.count === 0) return
        const target = key === Qt.Key_Home ? 0
                     : key === Qt.Key_End ? list.count - 1
                     : Math.max(0, Math.min(list.count - 1, index + (key === Qt.Key_Down ? 1 : -1)))
        list.currentIndex = target
        list.positionViewAtIndex(target, ListView.Contain)
        Qt.callLater(() => {
            const item = list.itemAtIndex(target)
            if (item && item.rowButton && item.rowButton.visible) item.rowButton.forceActiveFocus()
        })
    }

    readonly property bool toolShortcutsEnabled: notebookStore.activePageId !== ""
        && window.activeFocusItem === canvasArea
        && !editorToolbar.paletteOpen
        && indexEditKind === "" && !deletePopup.opened && !newNotebookDialog.visible
    Shortcut { sequence: "Escape"; enabled: window.narrowWorkspace && window.temporaryIndexOpen && window.indexEditKind === ""; onActivated: window.hideIndex() }
    Shortcut { sequence: "T"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.activeTool = "text" }
    Shortcut { sequence: "P"; enabled: window.toolShortcutsEnabled; onActivated: { editorToolbar.activeTool = "pen"; editorToolbar.penMode = "pen" } }
    Shortcut { sequence: "V"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.activeTool = "select" }
    Shortcut { sequence: "E"; enabled: window.toolShortcutsEnabled; onActivated: { editorToolbar.activeTool = "pen"; editorToolbar.penMode = "eraser" } }
    Shortcut { sequence: "Ctrl+B"; enabled: window.toolShortcutsEnabled && editorToolbar.textActive; onActivated: editorToolbar.bold = !editorToolbar.bold }
    Shortcut { sequence: "Ctrl+I"; enabled: window.toolShortcutsEnabled && editorToolbar.textActive; onActivated: editorToolbar.italic = !editorToolbar.italic }
    Shortcut { sequence: "Ctrl+U"; enabled: window.toolShortcutsEnabled && editorToolbar.textActive; onActivated: editorToolbar.underline = !editorToolbar.underline }
    Shortcut { sequences: [StandardKey.ZoomIn, "Ctrl+="]; enabled: notebookStore.activePageId !== ""; onActivated: window.zoomAt(window.pageZoom + 0.25) }
    Shortcut { sequences: [StandardKey.ZoomOut]; enabled: notebookStore.activePageId !== ""; onActivated: window.zoomAt(window.pageZoom - 0.25) }
    Shortcut { sequence: "Ctrl+0"; enabled: notebookStore.activePageId !== ""; onActivated: window.zoomAt(1) }
    Shortcut { sequence: "1"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(0) }
    Shortcut { sequence: "2"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(1) }
    Shortcut { sequence: "3"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(2) }
    Shortcut { sequence: "4"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(3) }
    Shortcut { sequence: "5"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(4) }
    Shortcut { sequence: "6"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(5) }
    Shortcut { sequence: "7"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(6) }
    Shortcut { sequence: "8"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(7) }
    Shortcut { sequence: "9"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.selectQuickColor(8) }
    Shortcut { sequence: "0"; enabled: window.toolShortcutsEnabled; onActivated: editorToolbar.openPalette() }

    // Keeps the native title bar (Windows 11) in step with the theme.
    Binding { target: Qt.styleHints; property: "colorScheme"; value: Theme.dark ? Qt.ColorScheme.Dark : Qt.ColorScheme.Light }

    menuBar: AppMenuBar {
        AppMenu {
            title: "Arquivo"
            AppMenuItem { text: "Novo caderno"; shortcutText: "Ctrl+N"; onTriggered: window.createNotebookPrompt() }
            AppMenuItem { text: "Voltar à Biblioteca"; enabled: notebookStore.activeNotebookId !== ""; onTriggered: notebookStore.closeNotebook() }
            AppMenuSeparator {}
            AppMenuItem { text: "Sair"; onTriggered: window.close() }
        }
        AppMenu { title: "Editar"; AppMenuItem { text: "Preferências"; enabled: false } }
        AppMenu {
            title: "Exibir"
            AppMenuItem { text: "Tema grafite"; checkable: true; checked: Theme.dark; onTriggered: Theme.dark = checked }
            AppMenuItem { text: "Mostrar índice"; enabled: notebookStore.activeNotebookId !== ""; checkable: true; checked: window.indexShown; onTriggered: window.toggleIndex() }
            AppMenuSeparator {}
            AppMenuItem {
                text: "Página infinita"
                enabled: pageEditorAdapter.demoEnabled
                checkable: true
                checked: pageEditorAdapter.infiniteCanvas
                onTriggered: if (editorProbe.saveTexts()) pageEditorAdapter.setInfiniteCanvas(!pageEditorAdapter.infiniteCanvas)
            }
        }
        AppMenu { title: "Inserir"; AppMenuItem { text: "Nova seção"; enabled: notebookStore.activeNotebookId !== ""; onTriggered: window.startIndexEdit("section/create", "", "") }
                           AppMenuItem { text: "Nova página"; enabled: notebookStore.activeSectionId !== ""; onTriggered: window.startIndexEdit("page/create", "", "") } }
        AppMenu { title: "Ajuda"; AppMenuItem { text: "Galeria visual"; onTriggered: { gallery.show(); gallery.raise() } }
                         AppMenuItem { text: "Sobre"; onTriggered: aboutDialog.open() } }
    }

    NotebookNamePopup {
        id: newNotebookDialog
        onAccepted: name => {
            if (renaming) {
                if (notebookStore.renameNotebook(notebookId, name)) close()
                return
            }
            returnFocusItem = null
            if (notebookStore.createNotebook(name)) {
                close()
                Qt.callLater(() => sectionHeader.focusAdd())
            }
        }
    }
    AppMenu {
        id: libraryMenu
        property var notebook: ({})
        property var returnFocusItem: null
        onClosed: if (returnFocusItem && !newNotebookDialog.opened && !deletePopup.opened) returnFocusItem.forceActiveFocus()
        AppMenuItem { text: "Abrir"; shortcutText: "Enter"; onTriggered: if (notebookStore.openNotebook(libraryMenu.notebook.id)) Qt.callLater(() => sectionHeader.focusAdd()) }
        AppMenuItem { text: "Renomear…"; shortcutText: "F2"; onTriggered: newNotebookDialog.openFor(libraryMenu.notebook.id, libraryMenu.notebook.title, libraryMenu.returnFocusItem) }
        AppMenuSeparator {}
        AppMenuItem { text: "Mover para a lixeira…"; shortcutText: "Del"; danger: true; onTriggered: window.askDelete("notebook", libraryMenu.notebook.id, libraryMenu.notebook.title) }
    }
    Popup {
        id: deletePopup
        popupType: Popup.Window
        modal: true
        anchors.centerIn: parent
        width: 320
        padding: Theme.space.lg
        closePolicy: Popup.CloseOnEscape
        onOpened: cancelDelete.forceActiveFocus()
        onClosed: window.pendingDeleteKind === "notebook" ? window.focusLibraryRow(libraryList.currentIndex)
                                                       : window.focusActiveIndex(window.pendingDeleteKind)
        background: Rectangle {
            radius: Theme.radius.lg
            color: Theme.color.overlay
            border.width: 1
            border.color: Theme.color.border
        }
        contentItem: Column {
            spacing: Theme.space.md
            Text {
                text: window.pendingDeleteKind === "notebook" ? "Mover caderno para a lixeira?"
                    : "Excluir " + (window.pendingDeleteKind === "section" ? "seção" : "página") + "?"
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.titleSm.size
                font.weight: Font.DemiBold
                color: Theme.color.textPrimary
            }
            Text {
                width: 288
                wrapMode: Text.WordWrap
                text: window.pendingDeleteKind === "notebook"
                      ? "O caderno \"" + window.pendingDeleteTitle + "\" vai para a pasta trash dos dados do app e pode ser recuperado de lá."
                      : window.pendingDeleteKind === "section"
                      ? "A seção \"" + window.pendingDeleteTitle + "\" e suas páginas serão removidas."
                      : "A página \"" + window.pendingDeleteTitle + "\" será removida."
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.body.size
                color: Theme.color.textSecondary
            }
            Row {
                spacing: Theme.space.sm
                ActionButton { id: cancelDelete; text: "Cancelar"; onClicked: deletePopup.close() }
                ActionButton {
                    text: window.pendingDeleteKind === "notebook" ? "Mover para a lixeira" : "Excluir"
                    danger: true
                    onClicked: {
                        const removed = window.pendingDeleteKind === "notebook"
                                      ? notebookStore.deleteNotebook(window.pendingDeleteId)
                                      : window.pendingDeleteKind === "section"
                                      ? notebookStore.deleteSection(window.pendingDeleteId)
                                      : notebookStore.deletePage(window.pendingDeleteId)
                        if (removed) deletePopup.close()
                    }
                }
            }
        }
    }
    Dialog {
        id: aboutDialog
        title: "Sobre"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok
        Label { text: "more-than-a-note\nMarco 1 — Fundação do aplicativo"; padding: 16 }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            visible: notebookStore.error !== ""
            Layout.fillWidth: true
            implicitHeight: visible ? Theme.size.controlMd + Theme.space.island : 0
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: Theme.space.island
                anchors.rightMargin: Theme.space.island
                anchors.topMargin: Theme.space.island
                radius: Theme.radius.island
                color: Qt.rgba(Theme.color.danger.r, Theme.color.danger.g, Theme.color.danger.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(Theme.color.danger.r, Theme.color.danger.g, Theme.color.danger.b, 0.35)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.space.md
                    text: notebookStore.error
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.type.body.size
                    color: Theme.color.danger
                    Accessible.role: Accessible.AlertMessage
                    Accessible.name: text
                }
            }
        }

        Item {
            visible: notebookStore.activeNotebookId === ""
            Layout.fillWidth: true
            Layout.fillHeight: true

            Island {
                anchors.fill: parent
                anchors.margins: Theme.space.island
                Accessible.role: Accessible.Pane
                Accessible.name: "Biblioteca"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: Theme.space.s20
                    anchors.bottomMargin: Theme.space.sm
                    anchors.leftMargin: Math.max(Theme.space.xl, (parent.width - 960) / 2)
                    anchors.rightMargin: Math.max(Theme.space.xl, (parent.width - 960) / 2)
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.size.controlLg
                        Text {
                            text: "Biblioteca"
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.title.size
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.type.title.tracking
                            color: Theme.color.textPrimary
                            Accessible.role: Accessible.Heading
                            Accessible.name: text
                        }
                        Item { Layout.fillWidth: true }
                        ActionButton {
                            id: newNotebookButton
                            objectName: "newNotebookButton"
                            variant: "primary"
                            text: "Novo caderno"
                            toolTip: "Criar caderno"
                            keys: ["Ctrl", "N"]
                            onClicked: window.createNotebookPrompt()
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.space.lg
                        spacing: Theme.space.sm
                        visible: notebookStore.notebooks.length > 0
                        SearchBox {
                            id: notebookSearch
                            objectName: "notebookSearch"
                            Layout.preferredWidth: 320
                            Layout.maximumWidth: 360
                            Layout.fillWidth: true
                            fieldHeight: Theme.size.controlLg
                            placeholderText: "Buscar cadernos"
                            keys: ["Ctrl", "K"]
                            Keys.onDownPressed: window.focusLibraryRow(0)
                            Keys.onEscapePressed: event => { if (text !== "") { text = ""; event.accepted = true } else event.accepted = false }
                        }
                        Item { Layout.fillWidth: true }
                        FieldButton {
                            id: sortField
                            quiet: true
                            text: window.librarySort === "name" ? "Nome" : "Atividade recente"
                            toolTip: "Ordenar cadernos"
                            onClicked: sortMenu.popup(sortField, 0, sortField.height + Theme.space.xs)
                            AppMenu {
                                id: sortMenu
                                AppMenuItem { text: "Atividade recente"; checkable: true; checked: window.librarySort === "recent"; onTriggered: window.librarySort = "recent" }
                                AppMenuItem { text: "Nome"; checkable: true; checked: window.librarySort === "name"; onTriggered: window.librarySort = "name" }
                            }
                        }
                    }
                    Shortcut { sequence: "Ctrl+K"; enabled: notebookStore.activeNotebookId === ""; onActivated: notebookSearch.forceActiveFocus() }
                    Shortcut { sequence: "Ctrl+N"; onActivated: window.createNotebookPrompt() }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.space.s20
                        Layout.preferredHeight: 24
                        visible: notebookStore.notebooks.length > 0
                        Text {
                            text: "CADERNOS"
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.overline.size
                            font.weight: Theme.type.overline.weight
                            font.letterSpacing: Theme.type.overline.tracking
                            color: Theme.color.textTertiary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: notebookSearch.text === ""
                                  ? libraryList.count + (libraryList.count === 1 ? " caderno" : " cadernos")
                                  : libraryList.count + " de " + notebookStore.notebooks.length
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.caption.size
                            font.features: { "tnum": 1 }
                            color: Theme.color.textTertiary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.space.xs
                        Layout.bottomMargin: Theme.space.xs
                        implicitHeight: 1
                        color: Theme.color.borderSubtle
                        visible: notebookStore.notebooks.length > 0
                    }
                    ListView {
                        id: libraryList
                        objectName: "libraryList"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Theme.space.xxs
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationEnabled: false
                        currentIndex: 0
                        Accessible.role: Accessible.List
                        Accessible.name: "Cadernos"
                        Accessible.description: count + (count === 1 ? " caderno" : " cadernos")
                        ScrollBar.vertical: ThinScrollBar {}
                        model: {
                            const query = window.folded(notebookSearch.text.trim())
                            const list = notebookStore.notebooks.filter(item => window.folded(item.title).includes(query))
                            if (window.librarySort === "name")
                                list.sort((a, b) => a.title.localeCompare(b.title, "pt-BR", { sensitivity: "base" }))
                            else
                                list.sort((a, b) => (b.modified ? b.modified.getTime() : 0) - (a.modified ? a.modified.getTime() : 0))
                            return list
                        }
                        onCountChanged: if (currentIndex >= count) currentIndex = Math.max(0, count - 1)
                        delegate: LibraryRow {
                            id: libraryRow
                            required property var modelData
                            required property int index
                            objectName: "libraryNotebook_" + modelData.id
                            width: libraryList.width
                            title: modelData.title
                            sectionCount: modelData.sections || 0
                            pageCount: modelData.pages || 0
                            modified: modelData.modified
                            coverColor: window.notebookCover(modelData.id)
                            current: libraryList.currentIndex === index
                            focusPolicy: libraryList.currentIndex === index ? Qt.StrongFocus : Qt.ClickFocus
                            onActiveFocusChanged: if (activeFocus) libraryList.currentIndex = index
                            onClicked: if (notebookStore.openNotebook(modelData.id)) Qt.callLater(() => sectionHeader.focusAdd())
                            onNavigationRequested: key => {
                                const page = Math.max(1, Math.floor(libraryList.height / 58))
                                const target = key === Qt.Key_Up ? index - 1 : key === Qt.Key_Down ? index + 1
                                             : key === Qt.Key_Home ? 0 : key === Qt.Key_End ? libraryList.count - 1
                                             : key === Qt.Key_PageUp ? index - page : index + page
                                window.focusLibraryRow(target)
                            }
                            onMenuRequested: (x, y) => window.openLibraryMenu(libraryRow, modelData, x, y)
                            onRenameRequested: newNotebookDialog.openFor(modelData.id, modelData.title, libraryRow)
                            onDeleteRequested: window.askDelete("notebook", modelData.id, modelData.title)
                        }

                        LibraryEmptyState {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, 360)
                            visible: libraryList.count === 0
                            query: notebookSearch.text
                            onClearRequested: { notebookSearch.text = ""; notebookSearch.forceActiveFocus() }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            visible: notebookStore.activeNotebookId !== ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.size.toolbar + Theme.space.island * 2
                EditorToolbar {
                    id: editorToolbar
                    objectName: "editorToolbar"
                    notebookName: notebookStore.activeNotebookName
                    pageAdapter: pageEditorAdapter
                    textTarget: editorProbe.activeTextCard
                    anchors.fill: parent
                    anchors.margins: Theme.space.island
                    onLibraryRequested: {
                        notebookStore.closeNotebook()
                        Qt.callLater(() => newNotebookButton.forceActiveFocus())
                    }
                }
            }
            Item {
                id: workspaceBody
                Layout.fillWidth: true
                Layout.fillHeight: true
                Island {
                    id: indexPanel
                    x: Theme.space.island
                    y: 0
                    width: Math.min(Math.max(200, Math.min(320, workspaceSettings.indexWidth)), workspaceBody.width - Theme.space.island * 2)
                    height: workspaceBody.height
                    visible: window.indexShown
                    z: 2
                    Accessible.role: Accessible.Pane
                    Accessible.name: "Índice do caderno"
                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.space.sm
                        spacing: Theme.space.xs
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Índice do caderno"
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.type.caption.size
                                font.weight: Font.DemiBold
                                color: Theme.color.textSecondary
                            }
                            IconButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                size: Theme.size.controlSm
                                iconName: "sidebar"
                                toolTip: "Recolher índice"
                                onClicked: window.hideIndex()
                            }
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.borderSubtle }
                    }
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.space.sm
                        anchors.topMargin: 44
                        spacing: Theme.space.xs
                        IndexHeader {
                            id: sectionHeader
                            Layout.fillWidth: true
                            title: "Seções"
                            addTooltip: "Nova seção"
                            onAddRequested: window.startIndexEdit("section/create", "", "")
                        }
                        IndexCreate {
                            objectName: "sectionCreate"
                            Layout.fillWidth: true
                            visible: window.indexEditKind === "section/create"
                            kind: "section"
                            onVisibleChanged: if (visible) Qt.callLater(begin)
                            onSubmitted: title => window.saveIndexEdit(title)
                            onCanceled: window.cancelIndexEdit()
                        }
                        ListView {
                            id: sectionList
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 180)
                            clip: true
                            spacing: Theme.space.xxs
                            boundsBehavior: Flickable.StopAtBounds
                            model: notebookStore.sections
                            ScrollBar.vertical: ThinScrollBar {}
                            delegate: Column {
                                required property var modelData
                                required property int index
                                property alias rowButton: sectionRowControl
                                width: sectionList.width
                                height: window.indexEditKind === "section/rename" && window.indexEditTargetId === modelData.id
                                        ? sectionRename.implicitHeight : Theme.size.sectionRow
                                IndexRow {
                                    id: sectionRowControl
                                    objectName: "sectionRow_" + modelData.id
                                    width: parent.width
                                    kind: "section"
                                    title: modelData.title
                                    parentName: notebookStore.activeNotebookName
                                    sectionColor: modelData.color
                                    selected: modelData.id === notebookStore.activeSectionId
                                    visible: !(window.indexEditKind === "section/rename" && window.indexEditTargetId === modelData.id)
                                    onClicked: notebookStore.selectSection(modelData.id)
                                    onNavigationRequested: key => window.focusListItem(sectionList, key, index)
                                    onRenameRequested: window.startIndexEdit("section/rename", modelData.id, modelData.title)
                                    onColorRequested: value => notebookStore.setSectionColor(modelData.id, value)
                                    onDeleteRequested: window.askDelete("section", modelData.id, modelData.title)
                                }
                                IndexCreate {
                                    id: sectionRename
                                    objectName: "sectionRename"
                                    width: parent.width
                                    visible: window.indexEditKind === "section/rename" && window.indexEditTargetId === modelData.id
                                    kind: "section"
                                    initialText: modelData.title
                                    onVisibleChanged: if (visible) Qt.callLater(begin)
                                    onSubmitted: title => window.saveIndexEdit(title)
                                    onCanceled: window.cancelIndexEdit()
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.borderSubtle }
                        IndexHeader {
                            id: pageHeader
                            Layout.fillWidth: true
                            title: "Páginas"
                            addTooltip: "Nova página"
                            addEnabled: notebookStore.activeSectionId !== ""
                            onAddRequested: window.startIndexEdit("page/create", "", "")
                        }
                        IndexCreate {
                            objectName: "pageCreate"
                            Layout.fillWidth: true
                            visible: window.indexEditKind === "page/create"
                            kind: "page"
                            onVisibleChanged: if (visible) Qt.callLater(begin)
                            onSubmitted: title => window.saveIndexEdit(title)
                            onCanceled: window.cancelIndexEdit()
                        }
                        ListView {
                            id: pageList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: Theme.space.xxs
                            boundsBehavior: Flickable.StopAtBounds
                            model: notebookStore.pages
                            ScrollBar.vertical: ThinScrollBar {}
                            delegate: Column {
                                required property var modelData
                                required property int index
                                property alias rowButton: pageRowControl
                                width: pageList.width
                                height: window.indexEditKind === "page/rename" && window.indexEditTargetId === modelData.id
                                        ? pageRename.implicitHeight : Theme.size.pageRow
                                IndexRow {
                                    id: pageRowControl
                                    objectName: "pageRow_" + modelData.id
                                    width: parent.width
                                    kind: "page"
                                    title: modelData.title
                                    parentName: window.activeSectionTitle
                                    selected: modelData.id === notebookStore.activePageId
                                    visible: !(window.indexEditKind === "page/rename" && window.indexEditTargetId === modelData.id)
                                    onClicked: notebookStore.selectPage(modelData.id)
                                    onNavigationRequested: key => window.focusListItem(pageList, key, index)
                                    onRenameRequested: window.startIndexEdit("page/rename", modelData.id, modelData.title)
                                    onDeleteRequested: window.askDelete("page", modelData.id, modelData.title)
                                }
                                IndexCreate {
                                    id: pageRename
                                    objectName: "pageRename"
                                    width: parent.width
                                    visible: window.indexEditKind === "page/rename" && window.indexEditTargetId === modelData.id
                                    kind: "page"
                                    initialText: modelData.title
                                    onVisibleChanged: if (visible) Qt.callLater(begin)
                                    onSubmitted: title => window.saveIndexEdit(title)
                                    onCanceled: window.cancelIndexEdit()
                                }
                            }
                        }
                    }
                }
                Item {
                    id: indexResize
                    objectName: "indexResize"
                    x: indexPanel.x + indexPanel.width
                    y: 0
                    width: Theme.space.island
                    height: parent.height
                    visible: window.dockedIndex
                    z: 3
                    activeFocusOnTab: visible
                    Accessible.role: Accessible.Splitter
                    Accessible.name: "Ajustar largura do índice"
                    Accessible.description: "Largura " + workspaceSettings.indexWidth + " pixels. Use setas, Home ou End."
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                            const delta = event.key === Qt.Key_Left ? -8 : 8
                            workspaceSettings.indexWidth = Math.max(200, Math.min(320, workspaceSettings.indexWidth + delta))
                            event.accepted = true
                        } else if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                            workspaceSettings.indexWidth = event.key === Qt.Key_Home ? 200 : 320
                            event.accepted = true
                        }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.activeFocus ? 2 : 1
                        height: parent.activeFocus ? parent.height - 24 : 0
                        radius: 1
                        color: Theme.color.focus
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SplitHCursor
                        onPressed: indexResize.forceActiveFocus()
                        onPositionChanged: mouse => {
                            if (!pressed) return
                            const position = mapToItem(workspaceBody, mouse.x, mouse.y).x
                            workspaceSettings.indexWidth = Math.max(200, Math.min(320, Math.round(position - indexPanel.x)))
                        }
                    }
                }
                Island {
                    id: pageIsland
                    x: window.dockedIndex ? indexResize.x + indexResize.width : Theme.space.island
                    y: 0
                    width: workspaceBody.width - x - Theme.space.island
                    height: workspaceBody.height
                    color: Theme.color.base
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Theme.size.sectionRow
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.space.md
                                anchors.rightMargin: Theme.space.md
                                spacing: Theme.space.sm
                                IconButton {
                                    id: showIndexButton
                                    objectName: "showIndexButton"
                                    visible: !window.indexShown
                                    iconName: "sidebar"
                                    size: Theme.size.controlSm
                                    toolTip: "Mostrar índice"
                                    onClicked: window.showIndex()
                                }
                                Text {
                                    visible: window.activeSectionTitle !== "" && notebookStore.activePageId !== ""
                                    text: window.activeSectionTitle
                                    elide: Text.ElideRight
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.type.caption.size
                                    color: Theme.color.textSecondary
                                    Layout.maximumWidth: 180
                                }
                                Text {
                                    visible: window.activeSectionTitle !== "" && notebookStore.activePageId !== ""
                                    text: "/"
                                    color: Theme.color.textTertiary
                                }
                                Text {
                                    Layout.fillWidth: true
                                    // Section / page always, so the place is clear with the index open or closed.
                                    text: notebookStore.activePageId !== "" ? notebookStore.activePageTitle
                                          : notebookStore.activeSectionId !== "" ? "Nenhuma página" : "Nenhuma seção"
                                    elide: Text.ElideRight
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.type.caption.size
                                    font.weight: Font.DemiBold
                                    color: notebookStore.activePageId !== "" ? Theme.color.textPrimary : Theme.color.textSecondary
                                }
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.color.borderSubtle }
                        }
                        Flickable {
                            id: pageScroll
                            objectName: "pageScroll"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: Math.max(width, pageScene.width + Theme.space.xxl * 2)
                            contentHeight: Math.max(height, pageScene.height + Theme.space.xxl * 2)
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ThinScrollBar {}
                            ScrollBar.horizontal: ThinScrollBar {}
                            onContentXChanged: {
                                if (pageEditorAdapter.infiniteCanvas &&
                                    contentX > 0 && contentX + width > contentWidth - 96)
                                    window.infiniteWidth += 600 / window.pageZoom
                            }
                            onContentYChanged: {
                                if (pageEditorAdapter.infiniteCanvas &&
                                    contentY > 0 && contentY + height > contentHeight - 96)
                                    window.infiniteHeight += 600 / window.pageZoom
                            }
                            Connections {
                                target: notebookStore
                                function onSelectionChanged() {
                                    window.pageZoom = 1
                                    window.infiniteWidth = 1800
                                    window.infiniteHeight = 2200
                                    pageScroll.contentX = 0
                                    pageScroll.contentY = 0
                                }
                            }
                            Rectangle {
                                width: pageScroll.contentWidth
                                height: pageScroll.contentHeight
                                color: Theme.paper.pasteboard
                            }
                            Item {
                                id: pageScene
                                objectName: "pageScene"
                                x: Math.round((pageScroll.contentWidth - width) / 2)
                                y: Theme.space.xxl
                                width: canvasArea.width * window.pageZoom
                                height: Math.max(canvasArea.height, editorProbe.contentExtentBottom + 32) * window.pageZoom
                                Item {
                                    id: pageCoordinates
                                    width: canvasArea.width
                                    height: pageScene.height / window.pageZoom
                                    scale: window.pageZoom
                                    transformOrigin: Item.TopLeft
                                Rectangle {
                                    x: 2
                                    y: 4
                                    width: canvasArea.width
                                    height: canvasArea.height
                                    color: Theme.color.shadow
                                    radius: Theme.radius.sm
                                }
                                Rectangle {
                                id: canvasArea
                                objectName: "canvasArea"
                                x: 0
                                y: 0
                                width: pageEditorAdapter.infiniteCanvas ?
                                       Math.max(window.infiniteWidth, editorProbe.contentExtentRight + 160) : 794
                                height: pageEditorAdapter.infiniteCanvas ?
                                        Math.max(window.infiniteHeight, editorProbe.contentExtentBottom + 160) :
                                        Math.round(width * 1.414)
                                color: Theme.paper.warm
                                border.width: pageEditorAdapter.infiniteCanvas ? 0 : 1
                                border.color: Theme.paper.rule
                                activeFocusOnTab: true
                                Keys.onPressed: event => {
                                    if (event.key !== Qt.Key_Space ||
                                        window.activeFocusItem && window.activeFocusItem.objectName === "editorTextCardBody") return
                                    window.spacePan = true
                                    event.accepted = true
                                }
                                Keys.onReleased: event => {
                                    if (event.key === Qt.Key_Space && window.spacePan) {
                                        window.spacePan = false
                                        event.accepted = true
                                    }
                                }
                                Accessible.role: Accessible.Pane
                                Accessible.name: notebookStore.activePageId !== "" ? "Página " + notebookStore.activePageTitle : "Página vazia"
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Theme.color.focus
                                    visible: canvasArea.activeFocus
                                }
                                TapHandler { onTapped: canvasArea.forceActiveFocus() }
                                Text {
                                    x: 48
                                    y: 48
                                    width: parent.width - 96
                                    text: notebookStore.activePageId !== "" ? notebookStore.activePageTitle :
                                          (notebookStore.activeSectionId === "" ? "Crie uma seção" : "Crie uma página")
                                    wrapMode: Text.WordWrap
                                    color: Theme.paper.text
                                    font.family: Theme.paperFont
                                    font.pixelSize: 28
                                    font.weight: Font.Medium
                                }
                                EditorProbe {
                                    id: editorProbe
                                    objectName: "editorProbe"
                                    anchors.fill: parent
                                    visible: notebookStore.activePageId !== ""
                                    pageId: notebookStore.activePageId
                                    penEnabled: editorToolbar.penActive && editorToolbar.penMode === "pen"
                                    textEnabled: editorToolbar.textActive
                                    viewScale: window.pageZoom
                                    editorModel: pageEditorAdapter
                                }
                                ActionButton {
                                    x: 48
                                    y: 112
                                    visible: notebookStore.activePageId === ""
                                    variant: "primary"
                                    text: notebookStore.activeSectionId === "" ? "Nova seção" : "Nova página"
                                    onClicked: window.startIndexEdit(notebookStore.activeSectionId === "" ? "section/create" : "page/create", "", "")
                                }
                            }
                            // A pointer handler inside a MouseArea makes it accept every
                            // button, which would swallow left clicks meant for the page.
                            // Ctrl+wheel zoom therefore lives on a sibling item.
                            Item {
                                width: panSurface.width
                                height: panSurface.height
                                z: panSurface.z + 1
                                WheelHandler {
                                    enabled: panSurface.enabled
                                    acceptedModifiers: Qt.ControlModifier
                                    target: null
                                    onWheel: event => {
                                        const anchor = parent.mapToItem(pageScroll, event.x, event.y)
                                        window.zoomAt(window.pageZoom * (event.angleDelta.y > 0 ? 1.125 : 1 / 1.125),
                                                      anchor.x, anchor.y)
                                        event.accepted = true
                                    }
                                }
                            }
                            MouseArea {
                                id: panSurface
                                objectName: "pagePanSurface"
                                width: pageScroll.contentWidth
                                height: pageScroll.contentHeight
                                z: 10
                                enabled: pageEditorAdapter.demoEnabled
                                acceptedButtons: window.panRequested ? Qt.LeftButton | Qt.MiddleButton : Qt.MiddleButton
                                cursorShape: window.panRequested ? Qt.OpenHandCursor : Qt.ArrowCursor
                                preventStealing: true
                                property real startX: 0
                                property real startY: 0
                                property real startContentX: 0
                                property real startContentY: 0
                                onPressed: mouse => {
                                    const point = mapToItem(pageScroll, mouse.x, mouse.y)
                                    startX = point.x
                                    startY = point.y
                                    startContentX = pageScroll.contentX
                                    startContentY = pageScroll.contentY
                                    cursorShape = Qt.ClosedHandCursor
                                }
                                onPositionChanged: mouse => {
                                    if (!pressed) return
                                    const point = mapToItem(pageScroll, mouse.x, mouse.y)
                                    pageScroll.contentX = Math.max(0, Math.min(pageScroll.contentWidth - pageScroll.width,
                                                                             startContentX + startX - point.x))
                                    pageScroll.contentY = Math.max(0, Math.min(pageScroll.contentHeight - pageScroll.height,
                                                                             startContentY + startY - point.y))
                                }
                                onReleased: cursorShape = window.panRequested ? Qt.OpenHandCursor : Qt.ArrowCursor
                                onCanceled: cursorShape = window.panRequested ? Qt.OpenHandCursor : Qt.ArrowCursor
                            }
                            Text {
                                x: canvasArea.width - width - 12
                                y: canvasArea.height + 8
                                visible: !pageEditorAdapter.infiniteCanvas
                                text: "FIM DO A4"
                                color: Theme.paper.selection
                                font.family: Theme.uiFont
                                font.pixelSize: 10
                                Accessible.ignored: true
                            }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.size.statusBar + Theme.space.island * 2
                Island {
                    anchors.fill: parent
                    anchors.margins: Theme.space.island
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.md
                        anchors.rightMargin: Theme.space.sm
                        spacing: Theme.space.md
                        Text {
                            text: "Caderno local"
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.caption.size
                            color: Theme.color.textSecondary
                        }
                        Rectangle { width: 1; height: 14; color: Theme.color.borderSubtle }
                        Text {
                            text: "Modo: " + (editorToolbar.textActive ? "Texto" : editorToolbar.penActive ? "Caneta" : "Seleção")
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.caption.size
                            color: Theme.color.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: notebookStore.activePageId !== ""
                            text: "Página " + (notebookStore.pages.findIndex(page => page.id === notebookStore.activePageId) + 1) + " de " + notebookStore.pages.length
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.caption.size
                            color: Theme.color.textSecondary
                        }
                        Text {
                            visible: notebookStore.activePageId !== ""
                            text: pageEditorAdapter.infiniteCanvas ? "Infinita" : "A4"
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.caption.size
                            color: Theme.color.textSecondary
                            Accessible.name: pageEditorAdapter.infiniteCanvas ? "Página infinita" : "Página A4"
                        }
                        Rectangle { width: 1; height: 14; color: Theme.color.borderSubtle }
                        IconButton {
                            objectName: "pageZoomOut"
                            size: Theme.size.controlXs; iconName: "minus"; toolTip: "Reduzir zoom"
                            enabled: notebookStore.activePageId !== "" && window.pageZoom > 0.5
                            onClicked: window.zoomAt(window.pageZoom - 0.25)
                        }
                        Text {
                            objectName: "pageZoomLabel"
                            text: Math.round(window.pageZoom * 100) + "%"
                            font.family: Theme.uiFont; font.pixelSize: Theme.type.caption.size
                            color: Theme.color.textTertiary
                            Accessible.role: Accessible.StaticText
                            Accessible.name: "Zoom " + text
                        }
                        IconButton {
                            objectName: "pageZoomIn"
                            size: Theme.size.controlXs; iconName: "add"; toolTip: "Ampliar zoom"
                            enabled: notebookStore.activePageId !== "" && window.pageZoom < 3
                            onClicked: window.zoomAt(window.pageZoom + 0.25)
                        }
                    }
                }
            }
        }
    }
}
