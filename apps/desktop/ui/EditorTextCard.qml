import QtQuick

// Editor version of the card studied in docs/13 and docs/17. Geometry in the
// adapter is in page points; only this view converts it to logical pixels.
Rectangle {
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
    readonly property alias moveHandle: moveGrip
    readonly property alias resizeHandle: resizeGrip
    // Limits in page points (docs/17): A4 width, paper margin, readable widths.
    readonly property real a4WidthPt: 595.2755905512
    readonly property real pageMarginPt: 24
    readonly property real minWidthPt: 120
    readonly property real maxWidthPt: 500
    // Handles and frame keep their screen size at any zoom, as in Pages,
    // Illustrator and Affinity; the body and its margins scale with the page.
    readonly property real chromeScale: 1 / Math.max(0.01, selectionOwner.viewScale || 1)
    // Frame and handles appear on hover, selection, editing or handle focus.
    readonly property bool chromeVisible: selected || editor.activeFocus || cardHover.hovered ||
                                          moveGrip.activeFocus || resizeGrip.activeFocus
    property real dragStartX: 0
    property real dragStartY: 0
    property real previewX: NaN
    property real previewY: NaN
    property real previewWidth: NaN

    objectName: "editorTextCard"
    x: isNaN(previewX) ? cardData.xPt * pxPerPt : previewX
    y: isNaN(previewY) ? cardData.yPt * pxPerPt : previewY
    width: isNaN(previewWidth) ? cardData.widthPt * pxPerPt : previewWidth
    height: Math.max(48, editor.contentHeight + 24)
    radius: Theme.radius.island
    color: "transparent"
    border.width: chromeVisible ? chromeScale : 0
    border.color: Theme.paper.selection
    // The selected card's handles stay above neighbouring cards.
    z: selected ? 2 : 1

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
    function clampXPt(xPt, widthPt) {
        const minimum = Math.max(pageMarginPt, xPt)
        return selectionOwner.infiniteCanvas ? minimum
             : Math.min(minimum, Math.max(pageMarginPt, a4WidthPt - pageMarginPt - widthPt))
    }
    function clampWidthPt(widthPt, xPt) {
        const maximum = selectionOwner.infiniteCanvas ? maxWidthPt
                      : Math.min(maxWidthPt, a4WidthPt - pageMarginPt - xPt)
        return Math.max(minWidthPt, Math.min(widthPt, maximum))
    }
    function clearPreview() {
        previewX = NaN
        previewY = NaN
        previewWidth = NaN
    }
    function persistGeometry(commit) {
        if (save()) commit()
    }
    // Keyboard nudges of the same card fold into one history entry.
    function moveBy(dx, dy) {
        const xPt = clampXPt(cardData.xPt + dx, cardData.widthPt)
        const yPt = Math.max(pageMarginPt, cardData.yPt + dy)
        persistGeometry(() => editorModel.moveText(cardData.id, xPt, yPt, true))
    }
    function resizeBy(delta) {
        const widthPt = clampWidthPt(cardData.widthPt + delta, cardData.xPt)
        persistGeometry(() => editorModel.resizeText(cardData.id, widthPt, true))
    }
    // The preview is cleared first so the committed geometry takes over in
    // the same frame.
    function commitMove() {
        const xPt = x / pxPerPt
        const yPt = y / pxPerPt
        clearPreview()
        persistGeometry(() => editorModel.moveText(cardData.id, xPt, yPt))
    }
    function commitResize() {
        const widthPt = width / pxPerPt
        clearPreview()
        persistGeometry(() => editorModel.resizeText(cardData.id, widthPt))
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

    // Typing hides the object actions until the pointer moves again.
    property bool typing: false
    HoverHandler { id: cardHover; onPointChanged: card.typing = false }
    MouseArea {
        anchors.fill: parent
        onClicked: card.selectionOwner.selectedCardId = card.cardData.id
    }

    TextCardMoveGrip {
        id: moveGrip
        objectName: "editorTextMoveGrip"
        x: editor.x
        y: Theme.size.controlXs / 2 - height
        z: 4
        dragSpace: card.parent
        visible: card.chromeVisible || containsMouse || pressed
        // Grown handles (zoomed out) scale from the body's top edge so they
        // rise instead of covering the first line; otherwise from the border.
        transform: Scale {
            origin.x: 0
            origin.y: card.chromeScale > 1 ? moveGrip.height : moveGrip.height - Theme.size.controlXs / 2
            xScale: card.chromeScale
            yScale: card.chromeScale
        }
        onPressed: card.selectionOwner.selectedCardId = card.cardData.id
        onMoveStarted: {
            card.dragStartX = card.x
            card.dragStartY = card.y
        }
        onMoveUpdated: (dx, dy) => {
            card.previewX = card.clampXPt((card.dragStartX + dx) / card.pxPerPt,
                                          card.cardData.widthPt) * card.pxPerPt
            card.previewY = Math.max(card.pageMarginPt,
                                     (card.dragStartY + dy) / card.pxPerPt) * card.pxPerPt
        }
        onMoveFinished: card.commitMove()
        onMoveCanceled: card.clearPreview()
        onNudged: (dx, dy) => card.moveBy(dx, dy)
        onWidthNudged: delta => card.resizeBy(delta)
        onActivated: editor.forceActiveFocus()
        onDuplicateRequested: card.selectionOwner.duplicateCard(card)
        onDeleteRequested: card.selectionOwner.deleteCard(card)
        onDismissed: {
            card.selectionOwner.selectedCardId = ""
            card.selectionOwner.forceActiveFocus()
        }
    }

    TextCardActionGroup {
        id: cardActions
        // Icons end on the body margin; the gap pads them on both sides.
        x: editor.x + editor.width - width + Theme.space.xs
        y: -height / 2
        z: 4
        paperColor: card.selectionOwner.paperColor
        onDuplicateRequested: card.selectionOwner.duplicateCard(card)
        onDeleteRequested: card.selectionOwner.deleteCard(card)
        shown: cardHover.hovered || moveGrip.containsMouse || resizeGrip.containsMouse
        // Also hidden when a narrow card at low zoom has no room beside the grip.
        suppressed: moveGrip.dragging || resizeGrip.dragging || card.typing ||
                    x + width - width * card.chromeScale <
                    moveGrip.x + (moveGrip.width + Theme.space.sm) * card.chromeScale
        transform: Scale {
            origin.x: cardActions.width
            origin.y: card.chromeScale > 1 ? cardActions.height : cardActions.height / 2
            xScale: card.chromeScale
            yScale: card.chromeScale
        }
    }

    TextEdit {
        id: editor
        objectName: "editorTextCardBody"
        x: 12
        y: 12
        width: card.width - 24
        height: Math.max(32, contentHeight)
        textFormat: TextEdit.RichText
        wrapMode: TextEdit.Wrap
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
                card.selectionOwner.selectedCardId = card.cardData.id
                return
            }
            card.save()
            // `text` is HTML in a rich editor; `length` counts characters.
            if (length === 0) Qt.callLater(() => {
                if (!editor.activeFocus && !moveGrip.activeFocus && !resizeGrip.activeFocus &&
                    card.editorModel && card.cardData.text.length === 0)
                    card.editorModel.discardEmptyText(card.cardData.id)
            })
        }
        Keys.onEscapePressed: {
            if (card.save()) moveGrip.forceActiveFocus()
        }
        Accessible.name: "Texto da caixa móvel"
    }

    TextCardResizeGrip {
        id: resizeGrip
        objectName: "editorTextResizeGrip"
        x: card.width - width / 2
        y: (card.height - height) / 2
        z: 3
        dragSpace: card.parent
        visible: card.chromeVisible || containsMouse || pressed
        transform: Scale {
            origin.x: resizeGrip.width / 2
            origin.y: resizeGrip.height / 2
            xScale: card.chromeScale
            yScale: card.chromeScale
        }
        property real originalWidth: 0
        onPressed: card.selectionOwner.selectedCardId = card.cardData.id
        onResizeStarted: originalWidth = card.width
        onResizeUpdated: dx => card.previewWidth =
            card.clampWidthPt((originalWidth + dx) / card.pxPerPt, card.cardData.xPt) * card.pxPerPt
        onResizeFinished: card.commitResize()
        onResizeCanceled: card.clearPreview()
        onNudged: delta => card.resizeBy(delta)
        onDuplicateRequested: card.selectionOwner.duplicateCard(card)
        onDeleteRequested: card.selectionOwner.deleteCard(card)
        onDismissed: moveGrip.forceActiveFocus()
    }
}
