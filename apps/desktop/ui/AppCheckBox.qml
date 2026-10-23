import QtQuick
import QtQuick.Templates as T

// A compact desktop checkbox. The inset fill carries the checked state without a tick.
T.CheckBox {
    id: control

    property string previewState: ""
    readonly property bool showHover: previewState === "hover" || hovered
    readonly property bool showPressed: previewState === "pressed" || down

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Theme.size.controlMd
    leftPadding: 0
    rightPadding: 0
    spacing: Theme.space.sm
    focusPolicy: Qt.TabFocus
    hoverEnabled: true
    font.family: Theme.uiFont
    font.pixelSize: Theme.type.control.size
    font.weight: Theme.type.control.weight

    indicator: Item {
        implicitWidth: 20
        implicitHeight: 20
        x: control.leftPadding
        y: (control.height - height) / 2

        Rectangle {
            id: frame
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: Theme.radius.sm
            color: !control.enabled ? Theme.color.base
                 : control.showPressed ? Theme.color.pressed
                 : control.showHover ? Theme.color.hover : Theme.color.raised
            border.width: 1
            border.color: control.visualFocus || control.previewState === "focus" ? Theme.color.focus
                        : control.showHover && control.enabled ? Theme.color.borderStrong : Theme.color.border

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: Theme.radius.xs
                visible: control.checked || control.checkState === Qt.PartiallyChecked
                color: control.enabled ? Theme.color.accent : Theme.color.textDisabled
                opacity: control.checkState === Qt.PartiallyChecked ? 0.55 : 1
            }
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: control.enabled ? Theme.color.textPrimary : Theme.color.textDisabled
        leftPadding: control.indicator.width + control.spacing
    }

    background: Item {
        implicitHeight: Theme.size.controlMd
    }
}
