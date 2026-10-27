import QtQuick

// Move handle seated on a card's top border: 24 px capsule, 32 px target that
// grows upward. Gestures are reported as deltas in `dragSpace` coordinates;
// the owner applies limits and decides when to persist. A press that does not
// travel past the platform drag distance is not a move, and Esc cancels.
MouseArea {
    id: grip
    property Item dragSpace: parent
    property bool pointerFocus: false
    property bool moved: false
    property bool gestureCanceled: false
    property point pressPoint
    readonly property bool dragging: pressed && moved && !gestureCanceled

    signal moveStarted()
    signal moveUpdated(real dx, real dy)
    signal moveFinished()
    signal moveCanceled()
    signal nudged(real dx, real dy)
    signal widthNudged(real delta)
    signal activated()
    signal dismissed()

    width: 40
    height: Theme.size.controlMd
    hoverEnabled: true
    activeFocusOnTab: true
    cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: "Mover caixa de texto; Alt e setas ajustam a largura"

    onActiveFocusChanged: if (!activeFocus) pointerFocus = false
    onPressed: mouse => {
        pressPoint = mapToItem(dragSpace, mouse.x, mouse.y)
        moved = false
        gestureCanceled = false
        pointerFocus = true
        forceActiveFocus()
    }
    onPositionChanged: mouse => {
        if (!pressed || gestureCanceled) return
        const point = mapToItem(dragSpace, mouse.x, mouse.y)
        const dx = point.x - pressPoint.x
        const dy = point.y - pressPoint.y
        if (!moved) {
            const threshold = Qt.styleHints.startDragDistance
            if (Math.abs(dx) < threshold && Math.abs(dy) < threshold) return
            moved = true
            moveStarted()
        }
        moveUpdated(dx, dy)
    }
    onReleased: {
        if (moved && !gestureCanceled) moveFinished()
        moved = false
    }
    onCanceled: {
        if (moved && !gestureCanceled) moveCanceled()
        moved = false
    }

    Keys.onPressed: event => {
        pointerFocus = false
        event.accepted = true
        if (event.key === Qt.Key_Escape) {
            if (dragging) {
                gestureCanceled = true
                moveCanceled()
            } else {
                dismissed()
            }
            return
        }
        if (pressed) return
        const step = event.modifiers & Qt.ShiftModifier ? 10 : 1
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            const delta = event.key === Qt.Key_Left ? -step : step
            if (event.modifiers & Qt.AltModifier) widthNudged(delta)
            else nudged(delta, 0)
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            nudged(0, event.key === Qt.Key_Up ? -step : step)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activated()
        } else {
            event.accepted = false
        }
    }

    CardHandle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.size.controlXs
        hovered: grip.containsMouse
        pressed: grip.dragging
        keyFocus: grip.activeFocus && !grip.pointerFocus
        Grid {
            anchors.centerIn: parent
            columns: 3
            spacing: 3
            Repeater {
                model: 6
                Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: grip.containsMouse || grip.dragging ? Theme.paper.text : Theme.paper.selection
                }
            }
        }
    }
    HintToolTip {
        text: "Mover caixa de texto"
        delay: 600
        z: 100
        visible: grip.containsMouse && !grip.pressed
    }
}
