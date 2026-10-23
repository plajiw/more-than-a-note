import QtQuick
import QtQuick.Templates as T

T.AbstractButton {
    id: root
    property bool danger: false
    implicitHeight: 30
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    Accessible.role: Accessible.MenuItem
    Accessible.name: text
    contentItem: Text {
        leftPadding: Theme.space.sm
        verticalAlignment: Text.AlignVCenter
        text: root.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.control.size
        color: root.danger ? Theme.color.danger : Theme.color.textPrimary
    }
    background: Rectangle {
        radius: Theme.radius.sm
        color: root.down ? Theme.color.pressed : root.hovered ? Theme.color.hover : "transparent"
        FocusRing { visible: root.visualFocus; controlRadius: Theme.radius.sm }
    }
}
