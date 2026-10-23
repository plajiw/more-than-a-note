import QtQuick

// Keyboard focus ring: 2 px `focus` color, 2 px outside the control.
// Shown only for keyboard focus (visualFocus), never after a mouse click.
Rectangle {
    property real controlRadius: Theme.radius.md

    anchors.fill: parent
    anchors.margins: -4
    radius: controlRadius + 4
    color: "transparent"
    border.width: 2
    border.color: Theme.color.focus
}
