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

    Gallery { id: gallery; visible: startWithGallery; palette: window.palette }

    Settings {
        id: workspaceSettings
        category: "workspace"
        property int indexWidth: Theme.size.indexWidth
        property bool indexCollapsed: false
    }

    property bool editorProbeEnabled: startWithEditorProbe

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

    menuBar: MenuBar {
        Menu {
            title: "Arquivo"
            MenuItem { text: "Novo caderno"; onTriggered: newNotebookDialog.open() }
            MenuItem { text: "Voltar à Biblioteca"; enabled: notebookStore.activeNotebookId !== ""; onTriggered: notebookStore.closeNotebook() }
            MenuSeparator {}
            MenuItem { text: "Sair"; onTriggered: window.close() }
        }
        Menu { title: "Editar"; MenuItem { text: "Preferências"; enabled: false } }
        Menu {
            title: "Exibir"
            MenuItem { text: "Tema grafite"; checkable: true; checked: Theme.dark; onTriggered: Theme.dark = checked }
            MenuItem { text: "Mostrar índice"; enabled: notebookStore.activeNotebookId !== ""; checkable: true; checked: window.indexShown; onTriggered: window.toggleIndex() }
        }
        Menu { title: "Inserir"; MenuItem { text: "Nova seção"; enabled: notebookStore.activeNotebookId !== ""; onTriggered: window.startIndexEdit("section/create", "", "") }
                           MenuItem { text: "Nova página"; enabled: notebookStore.activeSectionId !== ""; onTriggered: window.startIndexEdit("page/create", "", "") } }
        Menu { title: "Ajuda"; MenuItem { text: "Galeria visual"; onTriggered: { gallery.show(); gallery.raise() } }
                         MenuItem { text: "Sobre"; onTriggered: aboutDialog.open() } }
    }

    Dialog {
        id: newNotebookDialog
        title: "Novo caderno"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: { notebookName.text = ""; notebookName.forceActiveFocus() }
        onAccepted: notebookStore.createNotebook(notebookName.text)
        onClosed: Qt.callLater(() => notebookStore.activeNotebookId !== "" ? sectionHeader.focusAdd() : newNotebookButton.forceActiveFocus())
        TextField {
            id: notebookName
            objectName: "newNotebookName"
            width: 300
            placeholderText: "Nome do caderno"
            onAccepted: newNotebookDialog.accept()
        }
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
        onClosed: window.focusActiveIndex(window.pendingDeleteKind)
        background: Rectangle {
            radius: Theme.radius.lg
            color: Theme.color.overlay
            border.width: 1
            border.color: Theme.color.border
        }
        contentItem: Column {
            spacing: Theme.space.md
            Text {
                text: "Excluir " + (window.pendingDeleteKind === "section" ? "seção" : "página") + "?"
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.titleSm.size
                font.weight: Font.DemiBold
                color: Theme.color.textPrimary
            }
            Text {
                width: 288
                wrapMode: Text.WordWrap
                text: window.pendingDeleteKind === "section"
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
                    text: "Excluir"
                    danger: true
                    onClicked: {
                        const removed = window.pendingDeleteKind === "section"
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

        Rectangle {
            visible: notebookStore.error !== ""
            Layout.fillWidth: true
            implicitHeight: visible ? 40 : 0
            color: Theme.color.danger
            Label { anchors.centerIn: parent; text: notebookStore.error; color: Theme.color.accentOn }
        }

        Item {
            visible: notebookStore.activeNotebookId === ""
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Biblioteca"; font.pixelSize: 24; font.bold: true; color: Theme.color.textPrimary }
                    Item { Layout.fillWidth: true }
                    ActionButton {
                        id: newNotebookButton
                        objectName: "newNotebookButton"
                        variant: "primary"
                        text: "Novo caderno"
                        toolTip: "Criar caderno"
                        keys: ["Ctrl", "N"]
                        onClicked: newNotebookDialog.open()
                    }
                }
                SearchBox {
                    id: notebookSearch
                    objectName: "notebookSearch"
                    Layout.preferredWidth: 320
                    fieldHeight: Theme.size.controlLg
                    placeholderText: "Buscar cadernos"
                    keys: ["Ctrl", "K"]
                }
                Shortcut { sequence: "Ctrl+K"; enabled: notebookStore.activeNotebookId === ""; onActivated: notebookSearch.forceActiveFocus() }
                Shortcut { sequence: "Ctrl+N"; onActivated: newNotebookDialog.open() }
                Label { text: "Cadernos"; font.bold: true; color: Theme.color.textSecondary }
                ListView {
                    id: libraryList
                    objectName: "libraryList"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    Accessible.role: Accessible.List
                    Accessible.name: "Cadernos"
                    model: notebookStore.notebooks.filter(function(item) {
                        return item.title.toLowerCase().includes(notebookSearch.text.toLowerCase())
                    })
                    delegate: Button {
                        id: libraryNotebookButton
                        required property var modelData
                        objectName: "libraryNotebook_" + modelData.id
                        width: libraryList.width
                        height: 64
                        text: modelData.title
                        Accessible.name: modelData.title
                        Keys.onReturnPressed: libraryNotebookButton.clicked()
                        Keys.onEnterPressed: libraryNotebookButton.clicked()
                        font.pixelSize: 16
                        onClicked: {
                            if (notebookStore.openNotebook(modelData.id)) Qt.callLater(() => sectionHeader.focusAdd())
                        }
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: libraryList.count === 0
                        text: notebookSearch.text === "" ? "Nenhum caderno ainda. Crie o primeiro para começar." : "Nenhum caderno encontrado."
                        color: Theme.color.textSecondary
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
                Layout.preferredHeight: Theme.size.notebookBar + Theme.space.island * 2
                Island {
                    anchors.fill: parent
                    anchors.margins: Theme.space.island
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.sm
                        anchors.rightMargin: Theme.space.md
                        spacing: Theme.space.sm
                        ActionButton {
                            objectName: "backToLibrary"
                            text: "Biblioteca"
                            variant: "subtle"
                            toolTip: "Voltar à Biblioteca"
                            onClicked: {
                                notebookStore.closeNotebook()
                                Qt.callLater(() => newNotebookButton.forceActiveFocus())
                            }
                        }
                        Rectangle { width: 1; height: 18; color: Theme.color.borderSubtle }
                        Label {
                            Layout.fillWidth: true
                            text: notebookStore.activeNotebookName
                            elide: Text.ElideRight
                            color: Theme.color.textPrimary
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.type.body.size
                            font.weight: Font.DemiBold
                            Accessible.name: "Caderno aberto: " + text
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.size.toolbar + Theme.space.island
                EditorToolbar {
                    id: editorToolbar
                    objectName: "editorToolbar"
                    pageAdapter: pageTestAdapter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: Theme.space.island
                    anchors.rightMargin: Theme.space.island
                    height: Theme.size.toolbar
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
                            Layout.preferredHeight: 38
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
                                    visible: !window.indexShown && window.activeSectionTitle !== ""
                                    text: window.activeSectionTitle
                                    elide: Text.ElideRight
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.type.caption.size
                                    color: Theme.color.textSecondary
                                    Layout.maximumWidth: 180
                                }
                                Text {
                                    visible: !window.indexShown && window.activeSectionTitle !== "" && notebookStore.activePageId !== ""
                                    text: "/"
                                    color: Theme.color.textTertiary
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: window.indexShown ? (window.activeSectionTitle || "Nenhuma seção") :
                                          (notebookStore.activePageId !== "" ? notebookStore.activePageTitle :
                                           notebookStore.activeSectionId !== "" ? "Nenhuma página" : "Nenhuma seção")
                                    elide: Text.ElideRight
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.type.caption.size
                                    font.weight: Font.Medium
                                    color: Theme.color.textSecondary
                                }
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.color.borderSubtle }
                        }
                        Flickable {
                            id: pageScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: Math.max(width, canvasArea.width + Theme.space.xxl * 2)
                            contentHeight: canvasArea.height + Theme.space.xxl * 2
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ThinScrollBar {}
                            ScrollBar.horizontal: ThinScrollBar {}
                            Connections {
                                target: notebookStore
                                function onSelectionChanged() {
                                    pageScroll.contentX = 0
                                    pageScroll.contentY = 0
                                }
                            }
                            Rectangle {
                                x: canvasArea.x + 2
                                y: canvasArea.y + 4
                                width: canvasArea.width
                                height: canvasArea.height
                                color: Theme.color.shadow
                                radius: Theme.radius.sm
                            }
                            Rectangle {
                                id: canvasArea
                                objectName: "canvasArea"
                                x: Math.round((pageScroll.contentWidth - width) / 2)
                                y: Theme.space.xxl
                                width: Math.min(794, Math.max(480, pageScroll.width - Theme.space.xxl * 2))
                                height: Math.round(width * 1.414)
                                color: Theme.paper.warm
                                border.width: 1
                                border.color: Theme.paper.rule
                                activeFocusOnTab: true
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
                                Column {
                                    x: 48
                                    y: 120
                                    spacing: Theme.space.xs
                                    visible: pageTestAdapter.demoEnabled && !window.editorProbeEnabled && pageTestAdapter.pageId !== ""
                                    Text {
                                        text: "Teste do modelo — temporário, sem salvar"
                                        color: Theme.paper.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.type.caption.size
                                    }
                                    Row {
                                        spacing: Theme.space.xs
                                        ActionButton {
                                            objectName: "pageDemoAdd"
                                            text: "Adicionar texto"
                                            onClicked: pageTestAdapter.createTextAt(48, 180, "Texto de teste")
                                        }
                                        ActionButton {
                                            objectName: "pageDemoMove"
                                            text: "Mover primeiro"
                                            enabled: pageTestAdapter.objects.length > 0
                                            onClicked: {
                                                const first = pageTestAdapter.objects[0]
                                                pageTestAdapter.moveObject(first.id, first.xPt + 30, first.yPt + 20)
                                            }
                                        }
                                    }
                                    Text {
                                        visible: pageTestAdapter.error !== ""
                                        text: pageTestAdapter.error
                                        color: Theme.color.danger
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.type.caption.size
                                    }
                                }
                                Repeater {
                                    model: pageTestAdapter.demoEnabled && !window.editorProbeEnabled ? pageTestAdapter.objects : []
                                    delegate: Rectangle {
                                        required property var modelData
                                        x: Math.round(modelData.xPt * 4 / 3)
                                        y: Math.round(modelData.yPt * 4 / 3)
                                        width: Math.round(modelData.widthPt * 4 / 3)
                                        height: 64
                                        radius: Theme.radius.sm
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Theme.color.accent
                                        Text {
                                            anchors.fill: parent
                                            anchors.margins: Theme.space.sm
                                            text: parent.modelData.preview
                                            color: Theme.paper.text
                                            font.family: Theme.paperFont
                                            font.pixelSize: Theme.type.body.size
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                                EditorProbe {
                                    objectName: "editorProbe"
                                    anchors.fill: parent
                                    visible: window.editorProbeEnabled && notebookStore.activePageId !== ""
                                    pageId: notebookStore.activePageId
                                    penEnabled: editorToolbar.penActive && editorToolbar.penMode === "pen"
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
                        Rectangle { width: 1; height: 14; color: Theme.color.borderSubtle }
                        IconButton { size: Theme.size.controlXs; iconName: "minus"; toolTip: "Reduzir zoom"; enabled: false }
                        Text { text: "Zoom"; font.family: Theme.uiFont; font.pixelSize: Theme.type.caption.size; color: Theme.color.textTertiary }
                        IconButton { size: Theme.size.controlXs; iconName: "add"; toolTip: "Ampliar zoom"; enabled: false }
                    }
                }
            }
        }
    }
}
