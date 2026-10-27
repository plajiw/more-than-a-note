import QtQuick
import QtQuick.Templates as T

// Compact menu row (docs/13 §6.3): check column, label, shortcut in grey on the
// right. The check column is always reserved so labels line up in every menu.
T.MenuItem {
    id: control

    property string shortcutText: ""
    property bool danger: false

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Theme.size.menuItem
    leftPadding: Theme.space.sm
    rightPadding: Theme.space.md
    hoverEnabled: true

    font.family: Theme.uiFont
    font.pixelSize: Theme.type.body.size

    contentItem: Item {
        implicitWidth: check.width + Theme.space.s6 + label.implicitWidth
                       + (shortcut.visible ? Theme.space.xl + shortcut.implicitWidth : 0)
        implicitHeight: label.implicitHeight
        Icon {
            id: check
            anchors.verticalCenter: parent.verticalCenter
            name: "check"
            size: Theme.size.iconStatus
            visible: control.checked
            color: control.enabled ? Theme.color.textPrimary : Theme.color.textDisabled
        }
        Text {
            id: label
            x: check.width + Theme.space.s6
            width: parent.width - x - (shortcut.visible ? shortcut.implicitWidth + Theme.space.xl : 0)
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font: control.font
            elide: Text.ElideRight
            color: !control.enabled ? Theme.color.textDisabled
                 : control.danger ? Theme.color.danger : Theme.color.textPrimary
        }
        Text {
            id: shortcut
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: control.shortcutText !== ""
            text: control.shortcutText
            font.family: Theme.uiFont
            font.pixelSize: Theme.type.caption.size
            color: control.enabled ? Theme.color.textTertiary : Theme.color.textDisabled
        }
    }

    // On graphite, `hover` is too close to `overlay`; rows step one level up.
    background: Rectangle {
        implicitWidth: 160
        radius: Theme.radius.sm
        color: !control.enabled ? "transparent"
             : control.down ? (Theme.dark ? Theme.color.borderStrong : Theme.color.pressed)
             : control.highlighted ? (Theme.dark ? Theme.color.pressed : Theme.color.hover) : "transparent"
    }
}
