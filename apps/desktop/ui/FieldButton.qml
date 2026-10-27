import QtQuick
import QtQuick.Templates as T

// Looks like a field, opens a choice (font family, size, sort order).
T.Button {
    id: control

    property string toolTip
    property var keys: []
    // Quiet: toolbar picker with no fill or border until hovered (docs/13 §6.3).
    property bool quiet: false
    // Forces a visual state in the gallery: "", "hover", "pressed" or "focus".
    property string previewState: ""

    readonly property bool showHover: previewState === "hover" || hovered
    readonly property bool showPressed: previewState === "pressed" || down

    implicitWidth: Math.max(quiet ? 40 : 96, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: quiet ? Theme.size.controlSm : Theme.size.controlMd
    leftPadding: quiet ? Theme.space.sm : Theme.space.md - 2
    rightPadding: quiet ? Theme.space.s6 : Theme.space.sm
    focusPolicy: Qt.TabFocus
    hoverEnabled: true

    font.family: Theme.uiFont
    font.pixelSize: Theme.type.control.size
    font.weight: Theme.type.control.weight

    Accessible.name: toolTip !== "" ? toolTip + ": " + text : text

    contentItem: Item {
        implicitWidth: label.implicitWidth + Theme.space.s6 + Theme.size.iconList
        implicitHeight: label.implicitHeight
        Text {
            id: label
            anchors.left: parent.left
            anchors.right: caret.left
            anchors.rightMargin: Theme.space.s6
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font: control.font
            elide: Text.ElideRight
            color: control.enabled ? Theme.color.textPrimary : Theme.color.textDisabled
        }
        Icon {
            id: caret
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            name: "chevronDown"
            size: control.quiet ? 12 : Theme.size.iconStatus
            color: !control.enabled ? Theme.color.textDisabled
                 : control.quiet ? Theme.color.textTertiary : Theme.color.textSecondary
        }
    }

    background: Rectangle {
        radius: control.quiet ? Theme.radius.sm : Theme.radius.md
        color: control.quiet ? (!control.enabled ? "transparent"
                                : control.showPressed ? Theme.color.pressed
                                : control.showHover ? Theme.color.hover : "transparent")
             : !control.enabled ? Theme.color.base
             : control.showPressed ? Theme.color.pressed
             : control.showHover ? Theme.color.hover : Theme.color.raised
        border.width: control.quiet ? 0 : 1
        border.color: control.showHover && control.enabled ? Theme.color.borderStrong : Theme.color.border
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        FocusRing { visible: control.visualFocus || control.previewState === "focus"; controlRadius: control.quiet ? Theme.radius.sm : Theme.radius.md }
    }

    HintToolTip {
        id: tip
        text: control.toolTip
        keys: control.keys
        visible: control.hovered && control.toolTip !== "" && !control.down
    }
    onHoveredChanged: if (hovered) tip.delay = Theme.tipDelay()
}
