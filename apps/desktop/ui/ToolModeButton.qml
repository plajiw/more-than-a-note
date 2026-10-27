import QtQuick
import QtQuick.Templates as T

// Exclusive tool selector. Amber belongs to the active icon only.
T.AbstractButton {
    id: control

    property string iconName
    property string toolTip
    property var keys: []
    property bool active: false
    // The toolbar draws one sliding pill for the active tool instead.
    property bool showActiveFill: true

    implicitWidth: Theme.size.controlSm
    implicitHeight: Theme.size.controlSm
    focusPolicy: Qt.TabFocus
    hoverEnabled: true

    Accessible.role: Accessible.RadioButton
    Accessible.name: toolTip
    Accessible.checked: active

    contentItem: Icon {
        anchors.centerIn: parent
        name: control.iconName
        size: Theme.size.iconList
        filled: control.active
        color: !control.enabled ? Theme.color.textDisabled
             : control.active ? Theme.color.accent
             : control.hovered ? Theme.color.textPrimary
             : Theme.color.textSecondary
    }

    background: Rectangle {
        radius: Theme.radius.sm
        color: control.down ? Theme.color.pressed
             : control.active ? (control.showActiveFill ? Theme.color.hover : "transparent")
             : control.hovered ? Theme.color.hover
             : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.motion.base } }
        FocusRing { visible: control.visualFocus; controlRadius: Theme.radius.sm }
    }

    HintToolTip {
        id: tip
        text: control.toolTip
        keys: control.keys
        visible: control.hovered && !control.down
    }
    onHoveredChanged: if (hovered) tip.delay = Theme.tipDelay()
}
