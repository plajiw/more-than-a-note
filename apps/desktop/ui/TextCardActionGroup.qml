import QtQuick

// Duplicate and Delete as paper IconButtons in a gap cut into the card's top
// border: commands, not a second handle, so they carry no capsule of their own.
// The owner sets `shown` (pointer over the card); leaving keeps them for a
// short grace period so the pointer can travel to them, and `suppressed`
// hides them at once during gestures and typing.
Item {
    id: root
    objectName: "textCardActions"
    property bool shown: false
    property bool suppressed: false
    // Color of the paper behind the card, so the gap reads as a break in the line.
    property color paperColor: Theme.paper.white
    signal duplicateRequested()
    signal deleteRequested()
    readonly property bool hoveredGroup: groupHover.hovered
    readonly property bool present: !suppressed && (shown || hoveredGroup || leaveGrace.running)

    implicitWidth: actions.implicitWidth + Theme.space.xs * 2
    implicitHeight: Theme.size.controlXs
    width: implicitWidth
    height: implicitHeight
    opacity: present ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }

    onShownChanged: if (!shown) leaveGrace.restart()
    Timer { id: leaveGrace; interval: 150 }
    HoverHandler { id: groupHover }

    // Interrupts the frame line so the icons never sit on top of it.
    Rectangle {
        anchors.fill: parent
        color: root.paperColor
    }

    Row {
        id: actions
        anchors.centerIn: parent
        spacing: Theme.space.xxs

        IconButton {
            objectName: "textCardDuplicateButton"
            onPaper: true
            size: Theme.size.controlXs
            iconSize: Theme.size.iconList
            iconName: "duplicate"
            toolTip: "Duplicar caixa de texto"
            keys: ["Ctrl", "D"]
            focusPolicy: Qt.NoFocus
            onClicked: root.duplicateRequested()
        }
        IconButton {
            objectName: "textCardDeleteButton"
            onPaper: true
            size: Theme.size.controlXs
            iconSize: Theme.size.iconList
            iconName: "delete"
            toolTip: "Excluir caixa de texto"
            keys: ["Delete"]
            focusPolicy: Qt.NoFocus
            onClicked: root.deleteRequested()
        }
    }
}
