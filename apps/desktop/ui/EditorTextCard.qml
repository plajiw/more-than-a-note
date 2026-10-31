import QtQuick

// Text card of the editor (C3, after Excalidraw): no capsule or buttons; a
// selection box with eight handles and a rotation handle (TextSelectionBox),
// moved by its body with the Selection tool, duplicated by Alt+drag or
// Ctrl+D, deleted with Delete. The width grows with the text until a handle
// fixes it; there is no maximum. Geometry in the adapter is in page points;
// only this view converts it to logical pixels.
Item {
    id: card
    required property var cardData
    required property var editorModel
    required property var selectionOwner
    readonly property bool selected: selectionOwner.selectedCardId === cardData.id
    readonly property real pxPerPt: 4 / 3
    readonly property bool dirty: editor.textDocument.modified
    property var styleInfo: ({})
    property var pendingStyles: ({})
    property string lastPlainText: ""
    // Typing is committed in bursts: after a pause, on focus loss and before
    // undo, redo or navigation. Each burst is one history entry that restores
    // the caret from before it.
    property bool burstActive: false
    property string burstSelection: ""
    property string lastCaret: "caret:0:0"
    property bool savingDocument: false
    property bool loadingDocument: false
    readonly property int revision: cardData.revision
    readonly property alias editorItem: editor
    // Keyboard focus of the card as an object (arrows, Enter, Delete, Ctrl+D).
    readonly property alias moveHandle: objectFocus
    readonly property alias objectItem: objectFocus
    readonly property alias selectionBox: box
    // 24 pt minimum on each side, no maximum (C3, D4).
    readonly property real minBoxPx: 24 * pxPerPt
    readonly property real padding: 8
    // Handles and frame keep their screen size at any zoom.
    readonly property real chromeScale: 1 / Math.max(0.01, selectionOwner.viewScale || 1)
    readonly property bool editing: editor.activeFocus
    readonly property bool empty: editor.length === 0
    // A fresh caret with no text shows no box: for the person the card exists
    // only once they type (C3, D1).
    readonly property bool boxSelected: selected && !(editing && empty)
    readonly property bool frameShown: boxSelected || (cardHover.hovered && !(editing && empty))
    readonly property real chromeZ: selected ? 2 : 1
    // Set when the Repeater removes this card: its chrome leaves the overlay at
    // once instead of lingering until the card is destroyed.
    property bool retired: false
    readonly property Item chromeParent: retired ? null : selectionOwner.chromeLayer

    // Gesture previews in the parent's pixels; NaN means "use the stored value".
    property real previewX: NaN
    property real previewY: NaN
    property real previewWidth: NaN
    property real previewHeight: NaN
    property real previewRotation: NaN
    // Alt+drag shows where the copy will land.
    property real ghostX: NaN
    property real ghostY: NaN
    property var gesture: null

    readonly property bool wrapping: cardData.fixedWidth || !isNaN(previewWidth)
    readonly property real contentHeightPx: editor.contentHeight + 2 * padding
    readonly property real autoWidthPx: Math.max(minBoxPx, editor.contentWidth + 2 * padding + 2)

    objectName: "editorTextCard"
    x: isNaN(previewX) ? cardData.xPt * pxPerPt : previewX
    y: isNaN(previewY) ? cardData.yPt * pxPerPt : previewY
    width: !isNaN(previewWidth) ? previewWidth
         : cardData.fixedWidth ? Math.max(minBoxPx, cardData.widthPt * pxPerPt) : autoWidthPx
    // Never shorter than the text; a fixed height may be taller.
    height: Math.max(minBoxPx, contentHeightPx,
                     !isNaN(previewHeight) ? previewHeight
                     : cardData.fixedHeight ? cardData.heightPt * pxPerPt : 0)
    rotation: isNaN(previewRotation) ? (cardData.rotation || 0) : previewRotation
    transformOrigin: Item.TopLeft
    // Selecting never changes the paint order of the content (docs/20 §2).
    z: 1

    function caretString() {
        return "caret:" + editor.selectionStart + ":" + editor.selectionEnd
    }
    function save(kind) {
        typingIdle.stop()
        applyPendingToInsertion()
        if (!dirty) {
            burstActive = false
            return true
        }
        savingDocument = true
        const saved = editorModel.saveRichText(cardData.id, editor.textDocument,
                                               burstActive ? burstSelection : caretString(),
                                               caretString(), kind || "typing")
        savingDocument = false
        if (saved) burstActive = false
        return saved
    }
    // The history changed this card's content: show it, keeping the caret
    // where it was unless the history restores its own selection afterwards.
    function reloadDocument() {
        typingIdle.stop()
        burstActive = false
        const start = editor.selectionStart
        const end = editor.selectionEnd
        loadingDocument = true
        editorModel.loadRichText(cardData.id, editor.textDocument)
        loadingDocument = false
        lastPlainText = editor.getText(0, editor.length)
        editor.select(Math.min(start, editor.length), Math.min(end, editor.length))
        // Selecting re-applies the editor font and flags the document; the
        // content is exactly what the history holds.
        editor.textDocument.modified = false
        lastCaret = caretString()
        refreshStyle()
    }
    function restoreCaret(start, end) {
        editor.forceActiveFocus()
        const clean = !dirty
        editor.select(Math.min(start, editor.length), Math.min(end, editor.length))
        if (clean) editor.textDocument.modified = false
        lastCaret = caretString()
    }
    onRevisionChanged: if (!savingDocument) reloadDocument()
    function caretMoved() {
        refreshStyle()
        if (!burstActive) lastCaret = caretString()
    }
    function refreshStyle() {
        const actual = editorModel.richFormatAt(editor.textDocument, editor.cursorPosition)
        styleInfo = editor.selectionStart === editor.selectionEnd
                  ? Object.assign({}, actual, pendingStyles) : actual
    }
    function applyPendingToInsertion() {
        const now = editor.getText(0, editor.length)
        const before = lastPlainText
        lastPlainText = now
        if (Object.keys(pendingStyles).length === 0 || now.length <= before.length) return
        let start = 0
        while (start < before.length && before[start] === now[start]) ++start
        let oldEnd = before.length
        let newEnd = now.length
        while (oldEnd > start && newEnd > start && before[oldEnd - 1] === now[newEnd - 1]) {
            --oldEnd
            --newEnd
        }
        if (newEnd <= start) return
        const caret = editor.cursorPosition
        editor.select(start, newEnd)
        for (const kind in pendingStyles) {
            const value = pendingStyles[kind]
            if (kind === "family") editor.cursorSelection.font.family = value
            else if (kind === "size") editor.cursorSelection.font.pointSize = Number(value)
            else if (kind === "bold") editor.cursorSelection.font.bold = value
            else if (kind === "italic") editor.cursorSelection.font.italic = value
            else if (kind === "underline") editor.cursorSelection.font.underline = value
            else if (kind === "color") editor.cursorSelection.color = value
        }
        editor.cursorPosition = caret
        refreshStyle()
    }
    function applyFormat(kind, value) {
        // Typing so far is its own step; the formatting is the next one.
        if (!save()) return false
        if (editor.selectionStart === editor.selectionEnd &&
            ["family", "size", "bold", "italic", "underline", "color"].includes(kind)) {
            const next = Object.assign({}, pendingStyles)
            next[kind] = value
            pendingStyles = next
        }
        if (kind === "family") editor.cursorSelection.font.family = value
        else if (kind === "size") editor.cursorSelection.font.pointSize = Number(value)
        else if (kind === "bold") editor.cursorSelection.font.bold = Boolean(value)
        else if (kind === "italic") editor.cursorSelection.font.italic = Boolean(value)
        else if (kind === "underline") editor.cursorSelection.font.underline = Boolean(value)
        else if (kind === "color") editor.cursorSelection.color = value
        else if (!editorModel.applyRichBlockFormat(editor.textDocument,
                                                   editor.selectionStart, editor.selectionEnd,
                                                   kind, String(value || ""))) return false
        if (dirty && !save("format")) return false
        refreshStyle()
        editor.forceActiveFocus()
        return true
    }

    function clearPreview() {
        previewX = NaN
        previewY = NaN
        previewWidth = NaN
        previewHeight = NaN
        previewRotation = NaN
        ghostX = NaN
        ghostY = NaN
    }
    function persistGeometry(commit) {
        if (save()) commit()
    }
    function select() {
        selectionOwner.selectedCardId = cardData.id
    }
    // Keyboard nudges of the same card fold into one history entry.
    function moveBy(dx, dy) {
        const xPt = Math.max(0, cardData.xPt + dx)
        const yPt = Math.max(0, cardData.yPt + dy)
        persistGeometry(() => editorModel.moveText(cardData.id, xPt, yPt, true))
    }
    function resizeBy(delta) {
        const widthPt = Math.max(24, width / pxPerPt + delta)
        persistGeometry(() => editorModel.setTextBox(cardData.id, cardData.xPt, cardData.yPt,
                                                      widthPt, height / pxPerPt, true))
    }
    // Starts a gesture: `point` is in the parent's pixels.
    function startGesture(kind, point) {
        gesture = {kind: kind, px: point.x, py: point.y, x: x, y: y, w: width, h: height,
                   r: rotation, moved: false, contentH: contentHeightPx}
    }
    function travelled(point) {
        if (!gesture) return false
        if (!gesture.moved) {
            const t = Qt.styleHints.startDragDistance
            if (Math.abs(point.x - gesture.px) < t && Math.abs(point.y - gesture.py) < t) return false
            gesture.moved = true
        }
        return true
    }
    function beginBoxGesture(point) {
        select()
        save()
        startGesture("box", point)
    }
    // fx/fy: handle position (0, 0.5 or 1 of the box). The pointer delta is
    // turned into the box's own axes, so a rotated box resizes along its sides;
    // the left and top edges move the origin by the same amount.
    function updateBoxGesture(point, fx, fy, keepRatio) {
        if (!travelled(point)) return
        const g = gesture
        const theta = g.r * Math.PI / 180
        const c = Math.cos(theta), s = Math.sin(theta)
        const dx = point.x - g.px, dy = point.y - g.py
        const lx = dx * c + dy * s
        const ly = -dx * s + dy * c
        let w = g.w + (fx === 1 ? lx : fx === 0 ? -lx : 0)
        let h = g.h + (fy === 1 ? ly : fy === 0 ? -ly : 0)
        if (keepRatio && fx !== 0.5 && fy !== 0.5) {
            const k = Math.max(w / g.w, h / g.h)
            w = g.w * k
            h = g.h * k
        }
        w = Math.max(minBoxPx, w)
        h = Math.max(minBoxPx, h)
        // Pulling the top edge down stops at the text: the box never gets
        // shorter than its content, so the bottom edge stays put.
        if (fy === 0 && fx === 0.5) h = Math.max(h, g.contentH)
        const sx = fx === 0 ? g.w - w : 0
        const sy = fy === 0 ? g.h - h : 0
        previewWidth = w
        previewHeight = h
        previewX = g.x + sx * c - sy * s
        previewY = g.y + sx * s + sy * c
    }
    function beginMove(point, duplicate) {
        select()
        save()
        startGesture(duplicate ? "duplicate" : "move", point)
    }
    function updateMove(point) {
        if (!travelled(point)) return
        const nx = gesture.x + point.x - gesture.px
        const ny = gesture.y + point.y - gesture.py
        if (gesture.kind === "duplicate") {
            ghostX = nx
            ghostY = ny
        } else {
            previewX = rotation === 0 ? Math.max(0, nx) : nx
            previewY = rotation === 0 ? Math.max(0, ny) : ny
        }
    }
    function beginRotation(point) {
        select()
        save()
        startGesture("rotate", point)
        const theta = rotation * Math.PI / 180
        gesture.cx = x + (width / 2) * Math.cos(theta) - (height / 2) * Math.sin(theta)
        gesture.cy = y + (width / 2) * Math.sin(theta) + (height / 2) * Math.cos(theta)
        gesture.a0 = Math.atan2(point.y - gesture.cy, point.x - gesture.cx)
    }
    // Rotates around the centre, which stays put: the origin follows.
    function updateRotation(point, snap) {
        if (!travelled(point)) return
        const g = gesture
        let degrees = g.r + (Math.atan2(point.y - g.cy, point.x - g.cx) - g.a0) * 180 / Math.PI
        if (snap) degrees = Math.round(degrees / 15) * 15
        degrees = ((degrees % 360) + 540) % 360 - 180
        const theta = degrees * Math.PI / 180
        previewRotation = degrees
        previewX = g.cx - (g.w / 2) * Math.cos(theta) + (g.h / 2) * Math.sin(theta)
        previewY = g.cy - (g.w / 2) * Math.sin(theta) - (g.h / 2) * Math.cos(theta)
    }
    // Ends any gesture as one command; a press that did not travel is a click.
    function finishGesture() {
        const g = gesture
        gesture = null
        if (!g || !g.moved) {
            clearPreview()
            return
        }
        const id = cardData.id
        if (g.kind === "duplicate") {
            const gx = ghostX / pxPerPt, gy = ghostY / pxPerPt
            clearPreview()
            const copy = editorModel.duplicateTextTo(id, gx, gy)
            if (copy !== "") {
                selectionOwner.selectedCardId = copy
                const made = selectionOwner.cardById(copy)
                if (made) made.objectItem.forceActiveFocus()
            }
            return
        }
        const xPt = x / pxPerPt, yPt = y / pxPerPt
        const wPt = width / pxPerPt, hPt = height / pxPerPt
        const degrees = rotation
        clearPreview()
        if (g.kind === "move") editorModel.moveText(id, xPt, yPt)
        else if (g.kind === "box") editorModel.setTextBox(id, xPt, yPt, wPt, hPt)
        else if (g.kind === "rotate") editorModel.rotateText(id, degrees, xPt, yPt)
        objectFocus.forceActiveFocus()
    }
    function cancelGesture() {
        gesture = null
        clearPreview()
    }
    function editAt(localX, localY) {
        select()
        editor.forceActiveFocus()
        if (localX === undefined) editor.cursorPosition = editor.length
        else editor.cursorPosition = editor.positionAt(localX - editor.x, localY - editor.y)
    }
    // Ends the editing: a card with text stays selected as an object; a caret
    // left without text leaves nothing. The Text tool then hands back to
    // Selection (C3, D1).
    function finishEditing() {
        if (!save()) return
        if (empty) {
            selectionOwner.selectedCardId = ""
            selectionOwner.forceActiveFocus()
        } else {
            select()
            objectFocus.forceActiveFocus()
        }
        selectionOwner.textToolFinished()
    }

    Component.onCompleted: {
        loadingDocument = true
        editorModel.loadRichText(cardData.id, editor.textDocument)
        loadingDocument = false
        lastPlainText = editor.getText(0, editor.length)
        refreshStyle()
    }

    Timer {
        id: typingIdle
        interval: 800
        onTriggered: card.save()
    }

    property bool typing: false
    HoverHandler { id: cardHover; onPointChanged: card.typing = false }

    // The margin around the text: with the Text tool a click there places the
    // caret, so the whole card reads as text (I-beam, blinking caret).
    MouseArea {
        objectName: "editorTextCardMargin"
        anchors.fill: parent
        cursorShape: card.selectionOwner.textEnabled ? Qt.IBeamCursor : Qt.ArrowCursor
        onClicked: mouse => {
            card.select()
            if (card.selectionOwner.textEnabled) card.editAt(mouse.x, mouse.y)
        }
    }

    TextEdit {
        id: editor
        objectName: "editorTextCardBody"
        x: card.padding
        y: card.padding
        // Automatic width: the line grows with the text, with no limit; a
        // fixed width wraps the text at it.
        width: card.wrapping ? card.width - 2 * card.padding : implicitWidth
        height: Math.max(24, contentHeight)
        textFormat: TextEdit.RichText
        wrapMode: card.wrapping ? TextEdit.Wrap : TextEdit.NoWrap
        selectByMouse: true
        activeFocusOnTab: true
        color: Theme.paper.text
        // Paper text measures the same on every system, at every zoom and in PDF.
        renderType: Text.QtRendering
        font.hintingPreference: Font.PreferNoHinting
        selectionColor: Qt.rgba(Theme.paper.focus.r, Theme.paper.focus.g, Theme.paper.focus.b, 0.24)
        selectedTextColor: Theme.paper.text
        font.family: Theme.paperFont
        font.pointSize: 16
        onTextChanged: {
            if (card.loadingDocument) return
            card.applyPendingToInsertion()
            if (!activeFocus) return
            card.typing = true
            // The caret is still where it was before this edit.
            if (!card.burstActive) {
                card.burstActive = true
                card.burstSelection = card.lastCaret
            }
            typingIdle.restart()
        }
        onCursorPositionChanged: card.caretMoved()
        onSelectionStartChanged: card.caretMoved()
        onSelectionEndChanged: card.caretMoved()
        Keys.onPressed: event => {
            // One history for the page: the document keeps no undo of its own.
            if (event.matches(StandardKey.Undo)) {
                card.editorModel.undo()
                event.accepted = true
                return
            }
            if (event.matches(StandardKey.Redo) ||
                (Qt.platform.os !== "windows" && event.key === Qt.Key_Y &&
                 event.modifiers === Qt.ControlModifier)) {
                card.editorModel.redo()
                event.accepted = true
                return
            }
            if (!(event.modifiers & Qt.ControlModifier)) return
            if (event.key === Qt.Key_B) card.applyFormat("bold", !card.styleInfo.bold)
            else if (event.key === Qt.Key_I) card.applyFormat("italic", !card.styleInfo.italic)
            else if (event.key === Qt.Key_U) card.applyFormat("underline", !card.styleInfo.underline)
            else return
            event.accepted = true
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                card.select()
                return
            }
            card.save()
            // `text` is HTML in a rich editor; `length` counts characters.
            if (length === 0) Qt.callLater(() => {
                if (!editor.activeFocus && card.editorModel && card.cardData.text.length === 0)
                    card.editorModel.discardEmptyText(card.cardData.id)
            })
        }
        Keys.onEscapePressed: card.finishEditing()
        Accessible.name: "Texto da caixa"
    }

    // With the Selection tool the body is a handle: click selects, drag moves,
    // Alt+drag duplicates, double click edits. While editing it steps aside so
    // the text takes the pointer.
    MouseArea {
        id: bodyArea
        objectName: "editorTextCardBodyArea"
        anchors.fill: parent
        z: 5
        visible: card.selectionOwner.selectEnabled && !card.editing
        cursorShape: Qt.SizeAllCursor
        preventStealing: true
        onPressed: mouse => {
            card.beginMove(mapToItem(card.parent, mouse.x, mouse.y),
                           (mouse.modifiers & Qt.AltModifier) !== 0)
            objectFocus.forceActiveFocus()
        }
        onPositionChanged: mouse => {
            if (pressed) card.updateMove(mapToItem(card.parent, mouse.x, mouse.y))
        }
        onReleased: card.finishGesture()
        onCanceled: card.cancelGesture()
        onDoubleClicked: mouse => card.editAt(mouse.x, mouse.y)
    }

    // The card as an object for the keyboard and screen readers.
    Item {
        id: objectFocus
        objectName: "editorTextObject"
        anchors.fill: parent
        activeFocusOnTab: true
        Accessible.role: Accessible.Graphic
        Accessible.name: "Caixa de texto: " + card.cardData.text
        Accessible.description: "Setas movem; Enter edita; Delete exclui; Ctrl+D duplica"
        Keys.onPressed: event => {
            const step = event.modifiers & Qt.ShiftModifier ? 10 : 1
            const alt = event.modifiers & Qt.AltModifier
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                const delta = event.key === Qt.Key_Left ? -step : step
                if (alt) card.resizeBy(delta)
                else card.moveBy(delta, 0)
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                card.moveBy(0, event.key === Qt.Key_Up ? -step : step)
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                card.editAt()
            } else if (event.key === Qt.Key_Escape) {
                if (card.gesture) {
                    card.cancelGesture()
                } else {
                    card.selectionOwner.selectedCardId = ""
                    card.selectionOwner.forceActiveFocus()
                }
            } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                card.selectionOwner.deleteCard(card)
            } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
                card.selectionOwner.duplicateCard(card)
            } else {
                return
            }
            event.accepted = true
        }
    }

    TextSelectionBox {
        id: box
        parent: card.chromeParent
        card: card
    }

    // Alt+drag: outline of where the copy will land.
    Rectangle {
        objectName: "editorTextCardGhost"
        parent: card.chromeParent
        visible: !isNaN(card.ghostX)
        x: isNaN(card.ghostX) ? 0 : card.ghostX
        y: isNaN(card.ghostY) ? 0 : card.ghostY
        z: card.chromeZ
        width: card.width / card.chromeScale
        height: card.height / card.chromeScale
        scale: card.chromeScale
        rotation: card.rotation
        transformOrigin: Item.TopLeft
        color: Qt.rgba(Theme.paper.focus.r, Theme.paper.focus.g, Theme.paper.focus.b, 0.06)
        border.width: 1
        border.color: Theme.paper.focus
    }
}
