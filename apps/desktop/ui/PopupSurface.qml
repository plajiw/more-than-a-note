import QtQuick

// Surface for menus and popovers (docs/13 §3.4): overlay fill, 1 px border and a
// soft shadow (y 8, blur ~24) layered with plain rectangles, no extra modules.
// A popup in its own window (Popup.Window) clips the shadow to the window.
Item {
    id: root

    property int radius: Theme.radius.island

    Repeater {
        model: 4
        Rectangle {
            required property int index
            anchors.fill: parent
            anchors.leftMargin: -(index + 1) * 3
            anchors.rightMargin: -(index + 1) * 3
            anchors.topMargin: -(index + 1) * 3 + 8
            anchors.bottomMargin: -(index + 1) * 3 - 8
            radius: root.radius + (index + 1) * 3
            color: Theme.color.shadow
            opacity: 0.22 - index * 0.05
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.color.overlay
        border.width: 1
        border.color: Theme.color.border
    }
}
