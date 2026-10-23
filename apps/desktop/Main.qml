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

    readonly property bool toolShortcutsEnabled: notebookStore.activePageId !== ""
        && window.activeFocusItem === canvasArea
        && !editorToolbar.paletteOpen
        && !newNotebookDialog.visible && !newSectionDialog.visible && !newPageDialog.visible
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
        Menu { title: "Inserir"; MenuItem { text: "Nova seção"; enabled: notebookStore.activeNotebookId !== ""; onTriggered: newSectionDialog.open() }
                           MenuItem { text: "Nova página"; enabled: notebookStore.activeSectionId !== ""; onTriggered: newPageDialog.open() } }
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
    Dialog {
        id: newSectionDialog
        title: "Nova seção"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: { sectionName.text = ""; sectionName.forceActiveFocus() }
        onAccepted: notebookStore.addSection(sectionName.text)
        TextField { id: sectionName; width: 300; placeholderText: "Título da seção"; onAccepted: newSectionDialog.accept() }
    }
    Dialog {
        id: newPageDialog
        title: "Nova página"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: { pageName.text = ""; pageName.forceActiveFocus() }
        onAccepted: notebookStore.addPage(pageName.text)
        TextField { id: pageName; width: 300; placeholderText: "Título da página"; onAccepted: newPageDialog.accept() }
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
                Rectangle {
                    Layout.preferredWidth: 265
                    Layout.fillHeight: true
                    color: Theme.color.surface
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "SEÇÕES"; font.bold: true; color: Theme.color.textSecondary }
                            Item { Layout.fillWidth: true }
                            Button { text: "+"; Accessible.name: "Nova seção"; onClicked: newSectionDialog.open() }
                        }
                        ListView {
                            id: sectionList
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 180)
                            clip: true
                            model: notebookStore.sections
                            delegate: Button {
                                required property var modelData
                                width: sectionList.width
                                text: modelData.title
                                highlighted: modelData.id === notebookStore.activeSectionId
                                onClicked: notebookStore.selectSection(modelData.id)
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "PÁGINAS"; font.bold: true; color: Theme.color.textSecondary }
                            Item { Layout.fillWidth: true }
                            Button { text: "+"; enabled: notebookStore.activeSectionId !== ""; Accessible.name: "Nova página"; onClicked: newPageDialog.open() }
                        }
                        ListView {
                            id: pageList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: notebookStore.pages
                            delegate: Button {
                                required property var modelData
                                width: pageList.width
                                text: modelData.title
                                highlighted: modelData.id === notebookStore.activePageId
                                onClicked: notebookStore.selectPage(modelData.id)
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
