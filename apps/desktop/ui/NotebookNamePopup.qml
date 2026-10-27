import QtQuick
import QtQuick.Templates as T

// Name a new notebook or rename one. In-scene modal popup (offscreen tests and
// Wayland keep keyboard focus), inline error instead of the global banner.
T.Popup {
    id: root

    property string notebookId: ""          // empty: create
    property var returnFocusItem: null
    readonly property bool renaming: notebookId !== ""
    signal accepted(string name)

    function openFor(id, title, returnFocus) {
        notebookId = id
        returnFocusItem = returnFocus || null
        nameField.text = title || ""
        error.visible = false
        open()
    }
    function accept() {
        if (nameField.text.trim() === "") {
            error.visible = true
            nameField.forceActiveFocus()
            return
        }
        accepted(nameField.text.trim())
    }

    modal: true
    focus: true
    anchors.centerIn: T.Overlay.overlay
    width: 360
    padding: Theme.space.lg
    closePolicy: T.Popup.CloseOnEscape
    onOpened: { nameField.forceActiveFocus(); nameField.selectAll() }
    onClosed: if (returnFocusItem) Qt.callLater(() => returnFocusItem && returnFocusItem.forceActiveFocus())

    T.Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, Theme.dark ? 0.45 : 0.18) }
    background: PopupSurface { radius: Theme.radius.xl }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.motion.fast; easing.type: Easing.InCubic } }

    contentItem: Column {
        spacing: Theme.space.md
        Text {
            text: root.renaming ? "Renomear caderno" : "Novo caderno"
            font.family: Theme.uiFont
            font.pixelSize: Theme.type.titleSm.size
            font.weight: Font.DemiBold
            color: Theme.color.textPrimary
        }
        Column {
            width: parent.width
            spacing: Theme.space.xs
            InputField {
                id: nameField
                objectName: "newNotebookName"
                width: parent.width
                placeholderText: "Nome do caderno"
                onTextChanged: error.visible = false
                onAccepted: root.accept()
            }
            Text {
                id: error
                visible: false
                text: "Informe um nome."
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.caption.size
                color: Theme.color.danger
            }
        }
        Row {
            anchors.right: parent.right
            spacing: Theme.space.sm
            ActionButton { text: "Cancelar"; variant: "subtle"; onClicked: root.close() }
            ActionButton { text: root.renaming ? "Renomear" : "Criar caderno"; variant: "primary"; onClicked: root.accept() }
        }
    }
}
