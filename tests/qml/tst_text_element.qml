import QtQuick
import QtTest
import MoreThanANote

// C3: text card after Excalidraw. Each test follows a row of the interaction
// table in specs/006-c3-excalidraw-text-element/spec.md. Pointer travel runs
// in view coordinates, because handles and bodies move with the card.
AppTestCase {
    name: "TextElement"

    function setup() {
        openFreshPages(1)
        app.zoomAt(1)
        const ctx = {
            probe: control("editorProbe"),
            toolbar: control("editorToolbar"),
            scroll: control("pageScroll")
        }
        ctx.scroll.contentX = 0
        ctx.scroll.contentY = 0
        return ctx
    }
    function makeCard(ctx, text) {
        const id = pageEditorAdapter.createTextAt(150, 150)
        verify(pageEditorAdapter.saveText(id, text))
        tryVerify(() => ctx.probe.cardById(id) !== null)
        return id
    }
    function stored(id) {
        return pageEditorAdapter.textCards.find(c => c.id === id)
    }
    function handle(card, name) {
        const h = findChild(card.selectionBox, "textBoxHandle_" + name)
        verify(h !== null, "alça " + name)
        return h
    }
    // Press on `item` at its centre and travel (dx, dy) in view pixels.
    function drag(item, scroll, dx, dy, modifiers) {
        const start = item.mapToItem(scroll, item.width / 2, item.height / 2)
        mousePress(item, item.width / 2, item.height / 2, Qt.LeftButton, modifiers || Qt.NoModifier)
        for (let i = 1; i <= 6; ++i)
            mouseMove(scroll, start.x + dx * i / 6, start.y + dy * i / 6, -1, Qt.LeftButton, modifiers || Qt.NoModifier)
        mouseRelease(scroll, start.x + dx, start.y + dy, Qt.LeftButton, modifiers || Qt.NoModifier)
    }

    function test_text_tool_works_per_click() {
        const ctx = setup()
        ctx.toolbar.activeTool = "text"
        const before = pageEditorAdapter.textCards.length
        mouseClick(ctx.probe, 300, 300)
        tryVerify(() => ctx.probe.editingText)
        const card = ctx.probe.activeTextCard
        // A caret alone: no box until something is typed.
        verify(card.editorItem.cursorVisible)
        verify(!card.selectionBox.visible)
        verify(inputDriver.capture(app, "text-tool-caret.png"))
        inputDriver.typeText(app, "Uma linha que cresce sem quebrar ate onde a pessoa quiser escrever, mesmo alem do papel e da tela")
        tryVerify(() => card.selectionBox.visible)
        // Automatic width: one line, wider than the old 500 pt limit.
        tryVerify(() => card.width > 500 * 4 / 3, 3000, "largura automática=" + card.width)
        verify(card.editorItem.lineCount === 1)
        verify(!stored(card.cardData.id).fixedWidth)
        // Finishing hands back to Selection and leaves the card selected.
        keyClick(Qt.Key_Escape)
        tryCompare(ctx.toolbar, "activeTool", "select")
        compare(ctx.probe.selectedCardId, card.cardData.id)
        verify(card.objectItem.activeFocus)
        compare(pageEditorAdapter.textCards.length, before + 1)
        verify(inputDriver.capture(app, "text-box-selected.png"))

        // A caret left empty leaves nothing.
        ctx.toolbar.activeTool = "text"
        mouseClick(ctx.probe, 500, 420)
        tryVerify(() => ctx.probe.editingText)
        keyClick(Qt.Key_Escape)
        tryVerify(() => pageEditorAdapter.textCards.length === before + 1)
        tryCompare(ctx.toolbar, "activeTool", "select")
    }

    // C3 closing round: the Text tool hands back to Selection; with
    // Selection a double click on empty paper starts a text; Space pans with a
    // card selected.
    function test_text_tool_returns_to_selection_on_any_finish() {
        const ctx = setup()
        const before = pageEditorAdapter.textCards.length
        // Click elsewhere on the paper.
        ctx.toolbar.activeTool = "text"
        mouseClick(ctx.probe, 200, 200)
        tryVerify(() => ctx.probe.editingText)
        inputDriver.typeText(app, "Primeiro")
        mouseClick(ctx.probe, 450, 300)
        tryCompare(ctx.toolbar, "activeTool", "select")
        compare(pageEditorAdapter.textCards.length, before + 1)
        // Selection: a double click on empty paper starts a text there.
        wait(Qt.styleHints.mouseDoubleClickInterval + 50)
        mouseDoubleClickSequence(ctx.probe, 250, 420)
        tryVerify(() => ctx.probe.editingText)
        inputDriver.typeText(app, "Segundo")
        keyClick(Qt.Key_Escape)
        tryCompare(pageEditorAdapter.textCards, "length", before + 2)
        compare(ctx.toolbar.activeTool, "select")
        // Space pans while a card is selected and holds the keyboard.
        const card = ctx.probe.activeTextCard
        verify(card.objectItem.activeFocus)
        inputDriver.keyPress(app, Qt.Key_Space)
        tryCompare(app, "spacePan", true)
        compare(inputDriver.cursorAt(app, card, card.width / 2, card.height / 2), Qt.OpenHandCursor)
        inputDriver.keyRelease(app, Qt.Key_Space)
        tryCompare(app, "spacePan", false)
        // The cursor follows on the next pointer move.
        compare(inputDriver.cursorAt(app, card, card.width / 2 + 1, card.height / 2), Qt.SizeAllCursor)
    }

    function test_eight_handles_resize_the_box() {
        const ctx = setup()
        const id = makeCard(ctx, "Caixa")
        ctx.toolbar.activeTool = "select"
        ctx.probe.selectedCardId = id
        const card = ctx.probe.cardById(id)
        tryVerify(() => card.selectionBox.visible)
        const px = 4 / 3
        const cases = [
            {name: "right", dx: 60, dy: 0, w: 60, h: 0, x: 0, y: 0},
            {name: "left", dx: -60, dy: 0, w: 60, h: 0, x: -60, y: 0},
            {name: "bottom", dx: 0, dy: 60, w: 0, h: 60, x: 0, y: 0},
            {name: "top", dx: 0, dy: -60, w: 0, h: 60, x: 0, y: -60},
            {name: "bottomRight", dx: 30, dy: 30, w: 30, h: 30, x: 0, y: 0},
            {name: "topLeft", dx: -30, dy: -30, w: 30, h: 30, x: -30, y: -30},
            {name: "topRight", dx: 30, dy: -30, w: 30, h: 30, x: 0, y: -30},
            {name: "bottomLeft", dx: -30, dy: 30, w: 30, h: 30, x: -30, y: 0}
        ]
        for (const c of cases) {
            const b = {x: card.x, y: card.y, w: card.width, h: card.height}
            drag(handle(card, c.name), ctx.scroll, c.dx, c.dy)
            tryVerify(() => Math.abs(card.width - b.w - c.w) < 1 && Math.abs(card.height - b.h - c.h) < 1,
                      2000, c.name + ": " + card.width + "x" + card.height)
            verify(Math.abs(card.x - b.x - c.x) < 1 && Math.abs(card.y - b.y - c.y) < 1,
                   c.name + " origem: " + card.x + "," + card.y)
            const s = stored(id)
            verify(s.fixedWidth && s.fixedHeight)
            compare(s.widthPt, card.width / px)
        }
        // The letters never change size.
        compare(card.editorItem.font.pointSize, 16)
        // One gesture, one undo step.
        const beforeUndo = {w: card.width, h: card.height}
        verify(pageEditorAdapter.undo())
        tryVerify(() => Math.abs(card.width - beforeUndo.w) > 1 || Math.abs(card.height - beforeUndo.h) > 1)
        verify(pageEditorAdapter.redo())
        tryVerify(() => Math.abs(card.width - beforeUndo.w) < 1)
        // Esc cancels a gesture in progress.
        const right = handle(card, "right")
        const w0 = card.width
        const start = right.mapToItem(ctx.scroll, right.width / 2, right.height / 2)
        mousePress(right, right.width / 2, right.height / 2)
        mouseMove(ctx.scroll, start.x + 40, start.y)
        mouseMove(ctx.scroll, start.x + 80, start.y)
        verify(card.width > w0 + 50)
        keyClick(Qt.Key_Escape)
        tryCompare(card, "width", w0)
        mouseRelease(ctx.scroll, start.x + 80, start.y)
        compare(card.width, w0)
    }

    function test_handle_cursors_follow_rotation() {
        const ctx = setup()
        const id = makeCard(ctx, "Cursor")
        ctx.toolbar.activeTool = "select"
        ctx.probe.selectedCardId = id
        const card = ctx.probe.cardById(id)
        tryVerify(() => card.selectionBox.visible)
        compare(handle(card, "right").cursor, Qt.SizeHorCursor)
        compare(handle(card, "bottom").cursor, Qt.SizeVerCursor)
        compare(handle(card, "bottomRight").cursor, Qt.SizeFDiagCursor)
        compare(handle(card, "topRight").cursor, Qt.SizeBDiagCursor)
        verify(pageEditorAdapter.rotateText(id, 45, stored(id).xPt, stored(id).yPt))
        tryCompare(card, "rotation", 45)
        compare(handle(card, "right").cursor, Qt.SizeFDiagCursor)
        compare(handle(card, "bottomRight").cursor, Qt.SizeVerCursor)
        compare(handle(card, "bottom").cursor, Qt.SizeBDiagCursor)
    }

    // What the window shows, not just what the handle asks for (C3, roteiro 5).
    function test_pointer_shows_move_and_resize_cursors() {
        const ctx = setup()
        const id = makeCard(ctx, "Cursor na tela")
        ctx.toolbar.activeTool = "select"
        const card = ctx.probe.cardById(id)
        // Selection tool over the body: the move cross, selected or not.
        compare(inputDriver.cursorAt(app, card, card.width / 2, card.height / 2), Qt.SizeAllCursor)
        ctx.probe.selectedCardId = id
        tryVerify(() => card.selectionBox.visible)
        compare(inputDriver.cursorAt(app, card, card.width / 2, card.height / 2), Qt.SizeAllCursor)
        const expected = {right: Qt.SizeHorCursor, left: Qt.SizeHorCursor,
                          top: Qt.SizeVerCursor, bottom: Qt.SizeVerCursor,
                          topLeft: Qt.SizeFDiagCursor, bottomRight: Qt.SizeFDiagCursor,
                          topRight: Qt.SizeBDiagCursor, bottomLeft: Qt.SizeBDiagCursor}
        for (const name in expected) {
            const h = handle(card, name)
            compare(inputDriver.cursorAt(app, h, h.width / 2, h.height / 2), expected[name], name)
        }
        const rotate = findChild(card.selectionBox, "textBoxRotationHandle")
        compare(inputDriver.cursorAt(app, rotate, rotate.width / 2, rotate.height / 2), Qt.OpenHandCursor)
        // Text tool over the card: the I-beam.
        ctx.toolbar.activeTool = "text"
        compare(inputDriver.cursorAt(app, card, card.width / 2, card.height / 2), Qt.IBeamCursor)
    }

    function test_rotation_around_centre() {
        const ctx = setup()
        const id = makeCard(ctx, "Gira em torno do centro")
        const notebook = notebookStore.activeNotebookId
        const page = notebookStore.activePageId
        ctx.toolbar.activeTool = "select"
        ctx.probe.selectedCardId = id
        const card = ctx.probe.cardById(id)
        tryVerify(() => card.selectionBox.visible)
        const centre = card.mapToItem(ctx.scroll, card.width / 2, card.height / 2)
        const rotate = findChild(card.selectionBox, "textBoxRotationHandle")
        verify(rotate.visible)
        // Drag the handle from above the centre to its right: about +90°;
        // Shift snaps to 15°.
        const start = rotate.mapToItem(ctx.scroll, rotate.width / 2, rotate.height / 2)
        const radius = centre.y - start.y
        mousePress(rotate, rotate.width / 2, rotate.height / 2, Qt.LeftButton, Qt.ShiftModifier)
        mouseMove(ctx.scroll, centre.x + radius * 0.7, centre.y - radius * 0.7, -1, Qt.LeftButton, Qt.ShiftModifier)
        mouseMove(ctx.scroll, centre.x + radius, centre.y + 3, -1, Qt.LeftButton, Qt.ShiftModifier)
        mouseRelease(ctx.scroll, centre.x + radius, centre.y + 3, Qt.LeftButton, Qt.ShiftModifier)
        tryCompare(card, "rotation", 90)
        compare(stored(id).rotation, 90)
        // The centre did not move.
        const after = card.mapToItem(ctx.scroll, card.width / 2, card.height / 2)
        verify(Math.abs(after.x - centre.x) < 1.5 && Math.abs(after.y - centre.y) < 1.5,
               "centro: " + JSON.stringify(centre) + " → " + JSON.stringify(after))
        verify(inputDriver.capture(app, "text-box-rotated-90.png"))
        // Rotated text stays editable.
        card.editAt()
        tryVerify(() => card.editorItem.activeFocus && card.editorItem.cursorVisible)
        inputDriver.typeText(app, "!")
        keyClick(Qt.Key_Escape)
        tryVerify(() => stored(id).text.endsWith("!"))
        // Reopening keeps the angle.
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook))
        verify(notebookStore.selectPage(page))
        tryVerify(() => stored(id) !== undefined && stored(id).rotation === 90)
    }

    function test_selection_tool_moves_duplicates_and_deletes() {
        const ctx = setup()
        const id = makeCard(ctx, "Objeto")
        ctx.toolbar.activeTool = "select"
        const card = ctx.probe.cardById(id)
        const body = findChild(card, "editorTextCardBodyArea")
        tryVerify(() => body.visible)
        // Click selects; drag moves.
        mouseClick(body, 10, 10)
        tryCompare(ctx.probe, "selectedCardId", id)
        const x0 = stored(id).xPt
        drag(body, ctx.scroll, 60, 0)
        tryVerify(() => Math.abs(stored(id).xPt - x0 - 45) < 0.5)
        // Alt+drag leaves the original and drops a copy, in one undo step.
        const count = pageEditorAdapter.textCards.length
        const xBefore = stored(id).xPt
        drag(body, ctx.scroll, 0, 120, Qt.AltModifier)
        tryVerify(() => pageEditorAdapter.textCards.length === count + 1)
        compare(stored(id).xPt, xBefore)
        const copy = pageEditorAdapter.textCards.find(c => c.id !== id && c.text === "Objeto")
        verify(copy !== undefined)
        verify(Math.abs(copy.yPt - stored(id).yPt - 90) < 0.5)
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards.length === count)
        // Ctrl+D duplicates and Delete deletes the selected card.
        ctx.probe.selectedCardId = id
        card.objectItem.forceActiveFocus()
        keyClick(Qt.Key_D, Qt.ControlModifier)
        tryVerify(() => pageEditorAdapter.textCards.length === count + 1)
        const dup = ctx.probe.selectedCardId
        verify(dup !== id)
        ctx.probe.cardById(dup).objectItem.forceActiveFocus()
        keyClick(Qt.Key_Delete)
        tryVerify(() => pageEditorAdapter.textCards.length === count)
        // Double click edits at the point.
        mouseDoubleClickSequence(body, 10, 10)
        tryVerify(() => card.editorItem.activeFocus)
        keyClick(Qt.Key_Escape)
        // Click on empty paper clears the selection.
        mouseClick(ctx.probe, 700, 450)
        tryCompare(ctx.probe, "selectedCardId", "")
    }

    function test_box_has_a_minimum_and_no_maximum() {
        const ctx = setup()
        const id = makeCard(ctx, "Limites")
        const s = stored(id)
        verify(!pageEditorAdapter.setTextBox(id, s.xPt, s.yPt, 10, 40))
        verify(!pageEditorAdapter.setTextBox(id, s.xPt, s.yPt, 40, 10))
        verify(pageEditorAdapter.setTextBox(id, s.xPt, s.yPt, 24, 24))
        verify(pageEditorAdapter.setTextBox(id, s.xPt, s.yPt, 5000, 3000))
        const notebook = notebookStore.activeNotebookId
        const page = notebookStore.activePageId
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook))
        verify(notebookStore.selectPage(page))
        tryVerify(() => stored(id) !== undefined && stored(id).widthPt === 5000 &&
                        stored(id).heightPt === 3000)
    }
}
