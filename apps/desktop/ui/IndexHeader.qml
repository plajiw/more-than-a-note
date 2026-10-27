import QtQuick

Item {
    id: root
    property string title: ""
    property string addTooltip: ""
    property bool addEnabled: true
    signal addRequested()
    function focusAdd() { addControl.forceActiveFocus() }

    implicitHeight: 32
    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.title.toUpperCase()
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.overline.size
        font.weight: Theme.type.overline.weight
        font.letterSpacing: Theme.type.overline.tracking
        color: Theme.color.textTertiary
    }
    IconButton {
        id: addControl
        objectName: "add" + root.title
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        size: Theme.size.controlSm
        iconName: "add"
        toolTip: root.addTooltip
        enabled: root.addEnabled
        onClicked: root.addRequested()
    }
}
