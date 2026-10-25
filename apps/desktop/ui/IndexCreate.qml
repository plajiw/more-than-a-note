import QtQuick

Item {
    id: root
    property string kind: "page"
    property string initialText: ""
    property alias value: nameField.text
    signal submitted(string title)
    signal canceled()

    implicitHeight: errorText.visible ? 52 : 36
    function begin() {
        errorText.visible = false
        nameField.text = initialText
        nameField.forceActiveFocus()
        nameField.selectAll()
    }
    function submit() {
        const value = nameField.text.trim()
        if (value === "") {
            errorText.visible = true
            nameField.forceActiveFocus()
            return
        }
        root.submitted(value)
    }

    Row {
        id: fieldRow
        anchors.left: parent.left
        anchors.right: parent.right
        y: 2
        spacing: Theme.space.xxs
        InputField {
            id: nameField
            objectName: "indexNameField"
            width: Math.max(80, root.width - confirmButton.width - cancelButton.width - Theme.space.xxs * 2)
            placeholderText: root.kind === "section" ? "Nome da seção" : "Título da página"
            fieldHeight: Theme.size.controlMd
            onAccepted: root.submit()
            onTextChanged: errorText.visible = false
            Keys.onEscapePressed: root.canceled()
        }
        IconButton {
            id: confirmButton
            size: Theme.size.controlMd
            iconName: "check"
            toolTip: "Confirmar"
            onClicked: root.submit()
        }
        IconButton {
            id: cancelButton
            size: Theme.size.controlMd
            iconName: "close"
            toolTip: "Cancelar"
            onClicked: root.canceled()
        }
    }
    Text {
        id: errorText
        visible: false
        anchors.left: parent.left
        anchors.top: fieldRow.bottom
        anchors.topMargin: Theme.space.xxs
        text: "Informe um título."
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
        color: Theme.color.danger
    }
}
