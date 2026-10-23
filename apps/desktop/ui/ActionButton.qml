import QtQuick
import QtQuick.Templates as T

// Text-only button. variant: "primary" (accent, one per screen), "secondary"
// (raised with border) or "subtle" (no background until hovered).
// Buttons are either text or icon (IconButton), never both (docs/13 §6.4).
T.Button {
    id: control

    property string variant: "secondary"
    property bool danger: false
    property string toolTip
    property var keys: []
    // Forces a visual state in the gallery: "", "hover", "pressed" or "focus".
    property string previewState: ""

    readonly property bool primary: variant === "primary"
    readonly property bool subtle: variant === "subtle"
    readonly property bool showHover: previewState === "hover" || hovered
    readonly property bool showPressed: previewState === "pressed" || down
    readonly property color foreground: !enabled ? Theme.color.textDisabled
                                      : primary ? Theme.color.accentOn
                                      : danger ? Theme.color.danger
                                      : Theme.color.textPrimary

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Theme.size.controlMd
    leftPadding: Theme.space.md
    rightPadding: Theme.space.md
    hoverEnabled: true

    font.family: Theme.uiFont
    font.pixelSize: Theme.type.control.size
    font.weight: Theme.type.control.weight

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 64
        radius: Theme.radius.md
        color: {
            if (control.primary) {
                if (!control.enabled) return Theme.color.raised
                return control.showPressed ? Theme.color.accentPressed
                     : control.showHover ? Theme.color.accentHover : Theme.color.accent
            }
            if (!control.enabled) return control.subtle ? "transparent" : Theme.color.raised
            if (control.showPressed) return Theme.color.pressed
            if (control.showHover) return control.subtle ? Theme.color.raised : Theme.color.hover
            return control.subtle ? "transparent" : Theme.color.raised
        }
        border.width: control.variant === "secondary" ? 1 : 0
        border.color: control.showHover && control.enabled ? Theme.color.borderStrong : Theme.color.border
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        FocusRing { visible: control.visualFocus || control.previewState === "focus"; controlRadius: Theme.radius.md }
    }

    HintToolTip {
        id: tip
        text: control.toolTip
        keys: control.keys
        visible: control.hovered && control.toolTip !== "" && !control.down
    }
    onHoveredChanged: if (hovered) tip.delay = Theme.tipDelay()
}
