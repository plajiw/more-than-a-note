import QtQuick
import QtQuick.Templates as T

// In-window menu bar on Windows and Linux (docs/13 §4 item 6): 28 px strip on
// the window base, menus as quiet text items.
T.MenuBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth, contentWidth + leftPadding + rightPadding)
    implicitHeight: Theme.size.menuBar
    leftPadding: Theme.space.s6
    topPadding: Theme.space.xxs
    bottomPadding: Theme.space.xxs

    delegate: T.MenuBarItem {
        id: item
        implicitWidth: implicitContentWidth + leftPadding + rightPadding
        implicitHeight: Theme.size.controlXs
        leftPadding: Theme.space.sm
        rightPadding: Theme.space.sm
        hoverEnabled: true
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.body.size
        contentItem: Text {
            text: item.text
            font: item.font
            verticalAlignment: Text.AlignVCenter
            color: item.enabled ? Theme.color.textPrimary : Theme.color.textDisabled
        }
        background: Rectangle {
            radius: Theme.radius.sm
            color: item.down || item.highlighted ? Theme.color.hover : "transparent"
        }
    }

    contentItem: Row {
        spacing: 0
        Repeater { model: control.contentModel }
    }

    background: Rectangle { color: Theme.color.base }
}
