import QtQuick

// Shared face of the handles drawn on the paper around a card (move, width,
// object actions). Paper colors keep it identical in every interface theme;
// the radius matches the app's icon buttons.
Rectangle {
    id: face
    property bool hovered: false
    property bool pressed: false
    property bool keyFocus: false

    radius: Theme.radius.sm
    color: pressed ? Theme.paper.pasteboard : hovered ? Theme.paper.warm : Theme.paper.white
    border.width: 1
    border.color: hovered || pressed ? Theme.paper.selection : Theme.paper.rule
    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

    FocusRing {
        visible: face.keyFocus
        controlRadius: face.radius
        border.color: Theme.paper.focus
    }
}
