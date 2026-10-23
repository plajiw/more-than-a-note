import QtQuick

// Search box with a magnifier, its shortcut while empty, and a clear button
// once there is text. Not named SearchField: Qt Quick Controls 6.10+ has one.
InputField {
    id: control

    property var keys: []

    leftPadding: Theme.space.md - 2 + Theme.size.iconList + Theme.space.sm
    rightPadding: (clear.visible ? clear.width : shortcut.visible ? shortcut.width : 0) + Theme.space.md

    Icon {
        anchors.left: parent.left
        anchors.leftMargin: Theme.space.md - 2
        anchors.verticalCenter: parent.verticalCenter
        name: "search"
        size: Theme.size.iconList
        color: Theme.color.textTertiary
    }

    Kbd {
        id: shortcut
        anchors.right: parent.right
        anchors.rightMargin: Theme.space.sm
        anchors.verticalCenter: parent.verticalCenter
        visible: control.keys.length > 0 && control.length === 0 && !control.showFocus
        keys: control.keys
    }

    IconButton {
        id: clear
        anchors.right: parent.right
        anchors.rightMargin: Theme.space.xs
        anchors.verticalCenter: parent.verticalCenter
        visible: control.length > 0
        size: Theme.size.controlXs
        iconName: "close"
        toolTip: "Limpar busca"
        onClicked: { control.clear(); control.forceActiveFocus() }
    }
}
