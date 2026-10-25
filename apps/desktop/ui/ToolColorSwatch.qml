import QtQuick
import QtQuick.Templates as T

T.AbstractButton {
    id: control
    objectName: "quickColor_" + slot
    property color inkColor: "#2B2B2B"
    property string colorName: ""
    property int slot: 0
    property bool selected: false

    implicitWidth: Theme.size.controlMd
    implicitHeight: Theme.size.controlMd
    hoverEnabled: true
    focusPolicy: Qt.TabFocus

    Accessible.role: Accessible.RadioButton
    Accessible.name: (slot > 0 ? "Cor " + slot + ", " : "Cor ") + colorName + ", " + inkColor.toString().toUpperCase()
    Accessible.checked: selected

    contentItem: Item {
        opacity: control.enabled ? 1 : 0.35
        Rectangle {
            anchors.centerIn: parent
            width: 26; height: 26; radius: 13
            color: "transparent"
            border.width: control.selected ? 2 : control.hovered ? 1 : 0
            border.color: control.selected ? Theme.color.textPrimary : Theme.color.borderStrong
        }
        Rectangle {
            anchors.centerIn: parent
            width: 18; height: 18; radius: 9
            color: control.inkColor
            border.width: 1
            border.color: Theme.color.borderStrong
        }
    }
    background: Item {
        FocusRing { visible: control.visualFocus; controlRadius: Theme.radius.sm }
    }
    HintToolTip {
        id: tip
        text: (control.slot > 0 ? "Cor " + control.slot + " · " : "Cor ") + control.colorName + " · " + control.inkColor.toString().toUpperCase()
        keys: control.slot > 0 ? [String(control.slot)] : []
        visible: control.hovered && !control.down
    }
    onHoveredChanged: if (hovered) tip.delay = Theme.tipDelay()
}
