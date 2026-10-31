import QtQuick
import QtQuick.Controls

// Page editor surface: text cards and mouse ink backed by PageEditorAdapter.
Item {
    id: root
    property string pageId: ""
    property bool penEnabled: false
    property bool textEnabled: false
    // Selection tool on objects (not the Hand): cards move by their body.
    property bool selectEnabled: false
    // The Text tool works per click: once a text is finished the editor asks
    // to hand back to Selection (C3, D1).
    signal textToolFinished()
    // View zoom of the page scene; card handles counter-scale by it.
    property real viewScale: 1
    // Size of the paper. The editor itself also covers cards placed off the
    // paper: Qt only delivers presses and hover to items inside the item
    // that holds them, so a card beyond the editor could not be grabbed back.
    property real paperWidth: 0
    property real paperHeight: 0
    width: Math.max(paperWidth, committedExtentRight + 160, contentExtentRight + 160)
    height: Math.max(paperHeight, contentExtentBottom + 160)
    readonly property color paperColor: Theme.paper.warm
    // The ink fringe is computed in device pixels, so redraw it on zoom.
    onViewScaleChanged: ink.update()
    property bool infiniteCanvas: editorModel && editorModel.infiniteCanvas
    property var editorModel: null
    property bool loading: false
    property bool inkLoadFailed: false
    property string selectedCardId: ""
    readonly property var activeTextCard: {
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && card.cardData.id === selectedCardId) return card
        }
        return null
    }
    readonly property bool editingText: activeTextCard !== null && activeTextCard.editorItem.activeFocus
    // The handles take Ctrl+D and Delete themselves; these shortcuts cover a
    // selected card while focus rests on the paper, never on a field or body.
    readonly property bool objectFocus: activeTextCard !== null && activeFocus
    readonly property bool dirty: {
        if (!editorModel) return false
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && card.dirty) return true
        }
        return false
    }
    // Only a failure is reported, in the status bar, never on the paper.
    readonly property string problem: inkLoadFailed ? "Alguns traços não puderam ser exibidos."
        : editorModel && editorModel.error !== "" ? editorModel.error : ""
    readonly property int strokeCount: ink.strokeCount
    readonly property int pointCount: ink.pointCount
    readonly property real maxCardBottom: {
        let bottom = paperHeight
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card) bottom = Math.max(bottom, card.y + card.height)
        }
        return bottom
    }
    readonly property real contentExtentBottom: {
        let bottom = 0
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card) bottom = Math.max(bottom, card.y + card.height)
        }
        return bottom
    }
    readonly property real contentExtentRight: {
        let right = 0
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card) right = Math.max(right, card.x + card.width)
        }
        return right
    }
    // Right edge of the stored geometry, without drag previews: the scene can
    // grow to hold a card off the paper without shifting under the pointer.
    readonly property real committedExtentRight: {
        let right = 0
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card) right = Math.max(right, (card.cardData.xPt + card.cardData.widthPt) * card.pxPerPt)
        }
        return right
    }
    // Card chrome (frame, handles, actions) is an overlay: it sits above the
    // ink and never changes the paint order of the content (docs/20 §2).
    readonly property alias chromeLayer: chromeLayer

    function loadFromModel() {
        if (!editorModel || editorModel.pageId !== pageId) return
        loading = true
        inkLoadFailed = !ink.loadStrokes(editorModel.inkStrokes)
        loading = false
    }

    // Commits pending typing of every card as history entries.
    function saveTexts() {
        if (!editorModel || !editorModel.demoEnabled) return true
        let saved = true
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && !card.save()) saved = false
        }
        return saved
    }

    function cardById(id) {
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && card.cardData.id === id) return card
        }
        return null
    }

    // Undo and redo select what they changed and give back its caret.
    function restoreSelection(id, selection) {
        const card = id === "" ? null : cardById(id)
        if (!card) {
            selectedCardId = ""
            root.forceActiveFocus()
            return
        }
        selectedCardId = id
        const caret = /^caret:(\d+):(\d+)$/.exec(selection)
        if (caret) card.restoreCaret(Number(caret[1]), Number(caret[2]))
        else card.moveHandle.forceActiveFocus()
    }

    function duplicateCard(card) {
        if (!card.save()) return
        const id = editorModel.duplicateText(card.cardData.id)
        if (id === "") return
        selectedCardId = id
        const copy = cardById(id)
        if (copy) copy.moveHandle.forceActiveFocus()
    }

    function deleteCard(card) {
        if (!card.save()) return
        if (editorModel.deleteText(card.cardData.id)) {
            selectedCardId = ""
            root.forceActiveFocus()
        }
    }

    onPageIdChanged: {
        selectedCardId = ""
        Qt.callLater(loadFromModel)
    }
    onVisibleChanged: if (!visible) ink.cancelStroke()
    Connections {
        target: root.editorModel
        function onPageLoaded() { Qt.callLater(root.loadFromModel) }
        function onFlushRequested() { root.saveTexts() }
        function onHistoryApplied(objectId, selection, undone) { root.restoreSelection(objectId, selection) }
    }
    Shortcut { sequence: "Ctrl+S"; enabled: root.visible; onActivated: root.saveTexts() }
    // While a text body has focus the card handles these keys itself.
    Shortcut {
        sequences: [StandardKey.Undo]
        enabled: root.visible && !root.editingText
        onActivated: root.editorModel.undo()
    }
    Shortcut {
        sequences: Qt.platform.os === "windows" ? [StandardKey.Redo] : [StandardKey.Redo, "Ctrl+Y"]
        enabled: root.visible && !root.editingText
        onActivated: root.editorModel.redo()
    }
    Shortcut {
        sequence: "Ctrl+D"
        enabled: root.visible && root.objectFocus
        onActivated: root.duplicateCard(root.activeTextCard)
    }
    Shortcut {
        sequences: [StandardKey.Delete, "Backspace"]
        enabled: root.visible && root.objectFocus
        onActivated: root.deleteCard(root.activeTextCard)
    }

    Rectangle {
        width: root.paperWidth
        height: root.paperHeight
        color: root.paperColor
    }

    // Tool surfaces exist only while their tool is active. A disabled MouseArea
    // keeps showing its cursor over everything below it, which left the pen's
    // crosshair over text cards after switching to the Text tool.
    MouseArea {
        objectName: "editorProbeTextSurface"
        width: root.paperWidth
        height: root.paperHeight
        visible: root.textEnabled && root.editorModel && root.editorModel.demoEnabled
        z: 0
        cursorShape: Qt.IBeamCursor
        onClicked: mouse => {
            if (!root.saveTexts()) return
            // A click outside the card being edited ends the editing and creates
            // nothing; the Text tool then hands back to Selection (C3, D1). A card
            // that is only selected does not hold the click: a new text starts.
            if (root.editingText) {
                root.selectedCardId = ""
                root.forceActiveFocus()
                root.textToolFinished()
                return
            }
            const id = root.editorModel.createTextAt(mouse.x * 3 / 4, mouse.y * 3 / 4)
            if (id !== "") Qt.callLater(() => {
                for (let i = 0; i < cards.count; ++i) {
                    const card = cards.itemAt(i)
                    if (card && card.cardData.id === id) {
                        card.editorItem.forceActiveFocus()
                        break
                    }
                }
            })
        }
    }

    Repeater {
        id: cards
        objectName: "editorTextCards"
        model: root.editorModel ? root.editorModel.textCardModel : []
        onItemRemoved: (index, item) => item.retired = true
        delegate: EditorTextCard {
            editorModel: root.editorModel
            selectionOwner: root
        }
    }

    // Selection tool on empty paper: a click clears the selection; a double
    // click starts a text there, as in Excalidraw.
    MouseArea {
        objectName: "editorProbeSelectSurface"
        width: root.paperWidth
        height: root.paperHeight
        visible: root.selectEnabled && root.editorModel && root.editorModel.demoEnabled
        z: 0
        // It sits above the cards in paint order; its default arrow would hide
        // their move cross (C3).
        cursorShape: undefined
        onClicked: {
            if (!root.saveTexts()) return
            root.selectedCardId = ""
            root.forceActiveFocus()
        }
        onDoubleClicked: mouse => {
            if (!root.saveTexts()) return
            const id = root.editorModel.createTextAt(mouse.x * 3 / 4, mouse.y * 3 / 4)
            if (id !== "") Qt.callLater(() => {
                const card = root.cardById(id)
                if (card) card.editAt()
            })
        }
    }

    InkProbeItem {
        id: ink
        objectName: "editorProbeInk"
        // Ink lives on the paper: a stroke dragged past the edge is cut there.
        width: root.paperWidth
        height: root.paperHeight
        clip: true
        z: 2
        onStrokeFinished: points => {
            if (root.editorModel && !root.editorModel.addInk(points))
                ink.loadStrokes(root.editorModel.inkStrokes)
        }
    }
    MouseArea {
        id: penSurface
        objectName: "editorProbePenSurface"
        x: 0
        y: 0
        width: root.paperWidth
        height: root.paperHeight
        z: 3
        visible: root.penEnabled
        cursorShape: Qt.CrossCursor
        preventStealing: true
        onPressed: mouse => ink.beginStroke(mouse.x, mouse.y + penSurface.y)
        onPositionChanged: mouse => {
            if (pressed) ink.appendPoint(mouse.x, mouse.y + penSurface.y)
        }
        onReleased: ink.endStroke()
        onCanceled: ink.cancelStroke()
    }
    Item {
        id: chromeLayer
        objectName: "editorChromeLayer"
        anchors.fill: parent
        z: 4
    }
}
