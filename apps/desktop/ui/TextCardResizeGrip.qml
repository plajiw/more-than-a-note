import QtQuick

// Width handle: slim capsule centered on a card's right border inside a wider
// invisible target. Same gesture contract as TextCardMoveGrip: deltas in
// `dragSpace`, drag-distance threshold, Esc cancels a gesture in progress.
MouseArea {
    id: grip
    property Item dragSpace: parent
    property bool pointerFocus: false
    property bool moved: false
    property bool gestureCanceled: false
    property real pressX: 0
    readonly property bool dragging: pressed && moved && !gestureCanceled

    signal resizeStarted()
    signal resizeUpdated(real dx)
    signal resizeFinished()
    signal resizeCanceled()
    signal nudged(real delta)
    signal dismissed()

    width: Theme.size.controlXs
    height: 44
    hoverEnabled: true
    activeFocusOnTab: true
    cursorShape: Qt.SizeHorCursor
    Accessible.role: Accessible.Button
    Accessible.name: "Ajustar largura da caixa de texto"

    onActiveFocusChanged: if (!activeFocus) pointerFocus = false
    onPressed: mouse => {
        pressX = mapToItem(dragSpace, mouse.x, mouse.y).x
        moved = false
        gestureCanceled = false
        pointerFocus = true
        forceActiveFocus()
    }
    onPositionChanged: mouse => {
        if (!pressed || gestureCanceled) return
        const dx = mapToItem(dragSpace, mouse.x, mouse.y).x - pressX
        if (!moved) {
            if (Math.abs(dx) < Qt.styleHints.startDragDistance) return
            moved = true
            resizeStarted()
        }
        resizeUpdated(dx)
    }
    onReleased: {
        if (moved && !gestureCanceled) resizeFinished()
        moved = false
    }
    onCanceled: {
        if (moved && !gestureCanceled) resizeCanceled()
        moved = false
    }

    Keys.onPressed: event => {
        pointerFocus = false
        event.accepted = true
        if (event.key === Qt.Key_Escape) {
            if (dragging) {
                gestureCanceled = true
                resizeCanceled()
            } else {
                dismissed()
            }
        } else if (!pressed && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
            const step = event.modifiers & Qt.ShiftModifier ? 10 : 1
            nudged(event.key === Qt.Key_Left ? -step : step)
        } else {
            event.accepted = false
        }
    }

    CardHandle {
        anchors.centerIn: parent
        width: 10
        height: 28
        radius: Theme.radius.xs
        hovered: grip.containsMouse
        pressed: grip.dragging
        keyFocus: grip.activeFocus && !grip.pointerFocus
        Row {
            anchors.centerIn: parent
            spacing: Theme.space.xxs
            Repeater {
                model: 2
                Rectangle {
                    width: 1
                    height: 10
                    color: grip.containsMouse || grip.dragging ? Theme.paper.text : Theme.paper.selection
                }
            }
        }
    }
    HintToolTip {
        text: "Ajustar largura"
        delay: 600
        z: 100
        visible: grip.containsMouse && !grip.pressed
    }
}
