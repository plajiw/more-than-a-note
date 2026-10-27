import QtQuick
import QtQuick.Templates as T

T.AbstractButton {
    id: control
    objectName: "quickColor_" + slot
    property color inkColor: "#2B2B2B"
    property string colorName: ""
    property int slot: 0
    property bool selected: false
    // 32 in menus and panels, 24 in the toolbar; the rings scale with it.
    property int size: Theme.size.controlMd

    implicitWidth: size
    implicitHeight: size
    hoverEnabled: true
    focusPolicy: Qt.TabFocus

    Accessible.role: Accessible.RadioButton
    Accessible.name: (slot > 0 ? "Cor " + slot + ", " : "Cor ") + colorName + ", " + inkColor.toString().toUpperCase()
    Accessible.checked: selected

    contentItem: Item {
        opacity: control.enabled ? 1 : 0.35
        Rectangle {
            anchors.centerIn: parent
            width: control.size - 6; height: width; radius: width / 2
            color: "transparent"
            border.width: control.selected ? 2 : control.hovered ? 1 : 0
            border.color: control.selected ? Theme.color.textPrimary : Theme.color.borderStrong
        }
        Rectangle {
            anchors.centerIn: parent
            width: control.size - 14 + (control.size < Theme.size.controlMd ? 4 : 0); height: width; radius: width / 2
            color: control.inkColor
            // A translucent edge keeps dark inks visible on graphite and light inks on white.
            border.width: 1
            border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(0, 0, 0, 0.20)
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
