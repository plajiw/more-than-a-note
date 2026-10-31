import QtQuick

// Selection box of a text card (C3), drawn in the editor's chrome layer above
// the ink: a 1 px frame, eight square handles that resize the box (never the
// letters) and a rotation handle above it. It follows the card's geometry and
// rotation; handles keep their screen size at any zoom. Gestures report to
// the card, which previews and commits them as single undo steps.
Item {
    id: box
    required property Item card
    readonly property real s: card.chromeScale
    readonly property bool selectedMode: card.boxSelected
    readonly property real handleTarget: 16
    readonly property real cornerSize: 9
    readonly property real pillLength: 14
    readonly property real pillThickness: 6
    readonly property real rotationSize: 10
    readonly property real rotationOffset: 24

    objectName: "textSelectionBox"
    x: card.x
    y: card.y
    width: card.width
    height: card.height
    rotation: card.rotation
    transformOrigin: Item.TopLeft
    z: card.chromeZ
    visible: card.frameShown

    // Screen-unit frame: a 1/zoom border would vanish under antialiasing.
    Rectangle {
        objectName: "textSelectionFrame"
        width: box.width / box.s
        height: box.height / box.s
        scale: box.s
        transformOrigin: Item.TopLeft
        color: "transparent"
        // The radius of the app's buttons (radius.sm), so the box reads as part
        // of the same family; it only rounds the frame, never clips the text.
        radius: Theme.radius.sm
        border.width: 1
        border.color: box.selectedMode ? Theme.paper.focus : Theme.paper.selection
        antialiasing: true
    }

    // Eight resize handles: fx/fy place them at 0, ½ or 1 of the box.
    Repeater {
        model: [
            {name: "topLeft", fx: 0, fy: 0}, {name: "top", fx: 0.5, fy: 0},
            {name: "topRight", fx: 1, fy: 0}, {name: "right", fx: 1, fy: 0.5},
            {name: "bottomRight", fx: 1, fy: 1}, {name: "bottom", fx: 0.5, fy: 1},
            {name: "bottomLeft", fx: 0, fy: 1}, {name: "left", fx: 0, fy: 0.5}
        ]
        delegate: Item {
            id: handle
            required property var modelData
            readonly property real fx: modelData.fx
            readonly property real fy: modelData.fy
            objectName: "textBoxHandle_" + modelData.name
            visible: box.selectedMode
            width: box.handleTarget
            height: box.handleTarget
            x: fx * box.width - width / 2
            y: fy * box.height - height / 2
            scale: box.s
            transformOrigin: Item.Center

            // Cursor of the handle's direction on screen, after rotation.
            readonly property int cursor: {
                const base = Math.atan2(fy - 0.5, fx - 0.5) * 180 / Math.PI + box.rotation
                const a = ((Math.round(base / 45) * 45) % 180 + 180) % 180
                return a === 0 ? Qt.SizeHorCursor : a === 45 ? Qt.SizeFDiagCursor
                     : a === 90 ? Qt.SizeVerCursor : Qt.SizeBDiagCursor
            }
            readonly property alias pressed: handleArea.pressed

            // Corners are dots; sides are short pills laid along their edge.
            readonly property bool side: fx === 0.5 || fy === 0.5
            Rectangle {
                objectName: "textBoxHandleMark"
                anchors.centerIn: parent
                width: !handle.side ? box.cornerSize : handle.fx === 0.5 ? box.pillLength : box.pillThickness
                height: !handle.side ? box.cornerSize : handle.fy === 0.5 ? box.pillLength : box.pillThickness
                radius: Math.min(width, height) / 2
                color: handleArea.containsMouse || handleArea.pressed ? Theme.paper.warm : Theme.paper.white
                border.width: 1
                border.color: Theme.paper.focus
                antialiasing: true
            }
            MouseArea {
                id: handleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: handle.cursor
                preventStealing: true
                onPressed: mouse => {
                    box.card.beginBoxGesture(mapToItem(box.card.parent, mouse.x, mouse.y))
                    forceActiveFocus()
                }
                onPositionChanged: mouse => {
                    if (pressed)
                        box.card.updateBoxGesture(mapToItem(box.card.parent, mouse.x, mouse.y),
                                                  handle.fx, handle.fy,
                                                  (mouse.modifiers & Qt.ShiftModifier) !== 0)
                }
                onReleased: box.card.finishGesture()
                onCanceled: box.card.cancelGesture()
                Keys.onEscapePressed: box.card.cancelGesture()
            }
        }
    }

    // A 1 px stem ties the rotation handle to the frame.
    Rectangle {
        objectName: "textBoxRotationStem"
        visible: box.selectedMode
        width: box.s
        height: (box.rotationOffset - box.rotationSize / 2) * box.s
        x: box.width / 2 - width / 2
        y: -height
        color: Theme.paper.focus
        antialiasing: true
    }

    // Rotation handle: a circle above the middle of the top edge.
    Item {
        id: rotationHandle
        objectName: "textBoxRotationHandle"
        visible: box.selectedMode
        width: box.handleTarget
        height: box.handleTarget
        x: box.width / 2 - width / 2
        y: -box.rotationOffset * box.s - height / 2
        scale: box.s
        transformOrigin: Item.Center
        readonly property alias pressed: rotationArea.pressed

        Rectangle {
            anchors.centerIn: parent
            width: box.rotationSize
            height: width
            radius: width / 2
            color: rotationArea.containsMouse || rotationArea.pressed ? Theme.paper.warm : Theme.paper.white
            border.width: 1
            border.color: Theme.paper.focus
            antialiasing: true
        }
        MouseArea {
            id: rotationArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            preventStealing: true
            onPressed: mouse => {
                box.card.beginRotation(mapToItem(box.card.parent, mouse.x, mouse.y))
                forceActiveFocus()
            }
            onPositionChanged: mouse => {
                if (pressed)
                    box.card.updateRotation(mapToItem(box.card.parent, mouse.x, mouse.y),
                                            (mouse.modifiers & Qt.ShiftModifier) !== 0)
            }
            onReleased: box.card.finishGesture()
            onCanceled: box.card.cancelGesture()
            Keys.onEscapePressed: box.card.cancelGesture()
        }
    }
}
