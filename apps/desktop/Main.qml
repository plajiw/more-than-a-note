import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    property string indexEditKind: ""
    property string indexEditTargetId: ""
    property string indexEditTitle: ""
    property string pendingDeleteKind: ""
    property string pendingDeleteId: ""
    property string pendingDeleteTitle: ""

    function startIndexEdit(kind, id, title) {
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
        Menu { title: "Exibir"; MenuItem { text: "Tema grafite"; checkable: true; checked: Theme.dark; onTriggered: Theme.dark = checked } }
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
        TextField { id: notebookName; width: 300; placeholderText: "Nome do caderno"; onAccepted: newNotebookDialog.accept() }
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
                        variant: "primary"
                        text: "Novo caderno"
                        toolTip: "Criar caderno"
                        keys: ["Ctrl", "N"]
                        onClicked: newNotebookDialog.open()
                    }
                }
                SearchBox {
                    id: notebookSearch
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
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: notebookStore.notebooks.filter(function(item) {
                        return item.title.toLowerCase().includes(notebookSearch.text.toLowerCase())
                    })
                    delegate: Button {
                        required property var modelData
                        width: libraryList.width
                        height: 64
                        text: modelData.title
                        font.pixelSize: 16
                        onClicked: notebookStore.openNotebook(modelData.id)
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
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: Theme.color.surface
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    Button { text: "Biblioteca"; onClicked: notebookStore.closeNotebook() }
                    Label { text: notebookStore.activeNotebookName; font.bold: true; font.pixelSize: 17; color: Theme.color.textPrimary; leftPadding: 12 }
                    Item { Layout.fillWidth: true }
                    Label { text: "Caderno local"; color: Theme.color.textSecondary; font.pixelSize: 12 }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.size.toolbar + Theme.space.island * 2
                EditorToolbar {
                    id: editorToolbar
                    anchors.fill: parent
                    anchors.margins: Theme.space.island
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                Island {
                    Layout.preferredWidth: Theme.size.indexWidth
                    Layout.fillHeight: true
                    Layout.leftMargin: Theme.space.island
                    Layout.bottomMargin: Theme.space.island
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.space.sm
                        spacing: Theme.space.xs
                        IndexHeader {
                            id: sectionHeader
                            Layout.fillWidth: true
                            title: "Seções"
                            addTooltip: "Nova seção"
                            onAddRequested: window.startIndexEdit("section/create", "", "")
                        }
                        IndexCreate {
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
                                    width: parent.width
                                    kind: "section"
                                    title: modelData.title
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
                                    width: parent.width
                                    kind: "page"
                                    title: modelData.title
                                    selected: modelData.id === notebookStore.activePageId
                                    visible: !(window.indexEditKind === "page/rename" && window.indexEditTargetId === modelData.id)
                                    onClicked: notebookStore.selectPage(modelData.id)
                                    onNavigationRequested: key => window.focusListItem(pageList, key, index)
                                    onRenameRequested: window.startIndexEdit("page/rename", modelData.id, modelData.title)
                                    onDeleteRequested: window.askDelete("page", modelData.id, modelData.title)
                                }
                                IndexCreate {
                                    id: pageRename
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
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.color.base
                    Rectangle {
                        id: canvasArea
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 72, 690)
                        height: Math.min(parent.height - 48, 850)
                        color: Theme.paper.warm
                        activeFocusOnTab: true
                        focus: notebookStore.activePageId !== ""
                        TapHandler { onTapped: canvasArea.forceActiveFocus() }
                        Label {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 44
                            text: notebookStore.activePageId === "" ?
                                  (notebookStore.activeSectionId === "" ? "Crie uma seção" : "Crie uma página") : notebookStore.activePageTitle
                            color: Theme.paper.text
                            font.pixelSize: 26
                            font.bold: true
                        }
                        Label {
                            visible: notebookStore.activePageId !== ""
                            anchors.centerIn: parent
                            text: "O editor de conteúdo será desenvolvido no Marco 2."
                            color: "#687078"
                        }
                    }
                }
            }
        }
    }
}
