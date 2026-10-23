import QtQuick
import QtQuick.Templates as T

// Single-line text field. Focus shows as a `focus` border: unlike buttons, a
// field shows it after a click too, because it receives typing.
T.TextField {
    id: control

    property int fieldHeight: Theme.size.controlMd
    // Forces a visual state in the gallery: "", "hover" or "focus".
    property string previewState: ""

    readonly property bool showHover: previewState === "hover" || hovered
    readonly property bool showFocus: previewState === "focus" || activeFocus

    implicitWidth: 240
    implicitHeight: fieldHeight
    leftPadding: Theme.space.md - 2
    rightPadding: Theme.space.md - 2
    verticalAlignment: TextInput.AlignVCenter
    hoverEnabled: true

    font.family: Theme.uiFont
    font.pixelSize: Theme.type.body.size
    color: enabled ? Theme.color.textPrimary : Theme.color.textDisabled
    placeholderTextColor: Theme.color.textTertiary
    selectionColor: Qt.rgba(Theme.color.focus.r, Theme.color.focus.g, Theme.color.focus.b, Theme.dark ? 0.35 : 0.22)
    selectedTextColor: Theme.color.textPrimary

    Accessible.name: placeholderText

    Text {
        x: control.leftPadding
        width: control.width - control.leftPadding - control.rightPadding
        height: control.height
        verticalAlignment: Text.AlignVCenter
        visible: control.length === 0 && !control.preeditText
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Theme.radius.md
        color: control.enabled ? Theme.color.raised : Theme.color.base
        border.width: 1
        border.color: control.showFocus ? Theme.color.focus
                    : control.showHover && control.enabled ? Theme.color.borderStrong
                    : Theme.color.border
        Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }
    }
}
