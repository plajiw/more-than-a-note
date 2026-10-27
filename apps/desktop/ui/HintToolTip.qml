import QtQuick
import QtQuick.Templates as T

// Tooltip with the action name and its shortcut keys, shown below the control.
T.ToolTip {
    id: control

    property var keys: []

    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? parent.height + Theme.space.xs : 0
    margins: Theme.space.sm
    leftPadding: Theme.space.sm
    rightPadding: keys.length > 0 ? Theme.space.xs - 1 : Theme.space.sm
    topPadding: Theme.space.xs - 1
    bottomPadding: Theme.space.xs - 1
    timeout: -1
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent | T.Popup.CloseOnReleaseOutsideParent

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(22, implicitContentHeight + topPadding + bottomPadding)

    onClosed: Theme.tipClosedAt = Date.now()

    contentItem: Row {
        spacing: Theme.space.sm
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.type.caption.size
            font.weight: Font.Medium
            color: Theme.color.textPrimary
        }
        Kbd {
            anchors.verticalCenter: parent.verticalCenter
            visible: control.keys.length > 0
            keys: control.keys
        }
    }

    background: Rectangle {
        radius: Theme.radius.sm
        color: Theme.color.overlay
        border.width: 1
        border.color: Theme.color.border
    }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.motion.fast; easing.type: Easing.InCubic } }
}
