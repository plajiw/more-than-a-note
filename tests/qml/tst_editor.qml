import QtQuick
import QtTest
import MoreThanANote

// Page editor: text cards, rich text, ink, viewport and the unified history.
AppTestCase {
    name: "Editor"

    function test_text_and_ink_roundtrip() {
        const pages = openFreshPages(2)
        const notebook = { id: notebookId("Caderno de teste") }
        const probe = control("editorProbe")
        tryCompare(probe, "visible", true)
        tryCompare(pageEditorAdapter, "pageId", pages[0].id)
        const toolbar = control("editorToolbar")
        toolbar.activeTool = "text"
        mouseClick(probe, 220, 210)
        tryVerify(() => pageEditorAdapter.textCards.length === 1)
        const id = pageEditorAdapter.textCards[0].id
        verify(id.length > 0)
        const card = control("editorTextCard")
        const first = control("editorTextCardBody")
        first.forceActiveFocus()
        inputDriver.typeText(app, "Aula")
        inputDriver.commitText(app, " é")
        tryVerify(() => first.text.includes("Aula é"))
        const save = control("editorModelSaveTexts")
        tryCompare(save, "enabled", true)
        save.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryVerify(() => pageEditorAdapter.textCards[0].text === "Aula é")
        tryCompare(save, "enabled", false)

        const canvas = control("canvasArea")
        const originalWindowWidth = app.width
        app.width = 720
        tryCompare(canvas, "width", 794)
        compare(control("editorTextCard").x, pageEditorAdapter.textCards[0].xPt * 4 / 3)
        app.width = originalWindowWidth

        let x = pageEditorAdapter.textCards[0].xPt
        let width = pageEditorAdapter.textCards[0].widthPt
        const moveGrip = control("editorTextMoveGrip")
        moveGrip.forceActiveFocus()
        keyClick(Qt.Key_Right)
        tryVerify(() => pageEditorAdapter.textCards[0].xPt === x + 1)
        const resizeGrip = control("editorTextResizeGrip")
        resizeGrip.forceActiveFocus()
        keyClick(Qt.Key_Right, Qt.ShiftModifier)
        tryVerify(() => pageEditorAdapter.textCards[0].widthPt === width + 10)
        compare(pageEditorAdapter.textCards[0].fixedWidth, true)

        toolbar.activeTool = "pen"
        toolbar.penMode = "pen"
        const surface = control("editorProbePenSurface")
        const ink = control("editorProbeInk")
        mousePress(surface, 100, 100)
        mouseMove(surface, 180, 110)
        mouseRelease(surface, 180, 110)
        tryCompare(pageEditorAdapter, "inkCount", 1)
        compare(ink.strokeCount, 1)
        wait(100)
        verify(inputDriver.capture(app, "editor-text-ink.png"))
        verify(pageEditorAdapter.canUndo)
        verify(pageEditorAdapter.undo())
        tryCompare(pageEditorAdapter, "inkCount", 0)
        tryCompare(ink, "strokeCount", 0)
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards[0].widthPt === width)
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards[0].xPt === x)
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards[0].text === "")
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards.length === 0)
        verify(pageEditorAdapter.redo())
        tryVerify(() => pageEditorAdapter.textCards.length === 1)
        verify(pageEditorAdapter.redo())
        tryVerify(() => pageEditorAdapter.textCards[0].text === "Aula é")
        verify(pageEditorAdapter.redo())
        tryVerify(() => pageEditorAdapter.textCards[0].xPt === x + 1)
        verify(pageEditorAdapter.redo())
        tryVerify(() => pageEditorAdapter.textCards[0].widthPt === width + 10)
        verify(pageEditorAdapter.redo())
        tryCompare(pageEditorAdapter, "inkCount", 1)
        tryCompare(ink, "strokeCount", 1)

        notebookStore.selectPage(pages[1].id)
        tryCompare(pageEditorAdapter, "inkCount", 0)
        tryVerify(() => pageEditorAdapter.textCards.length === 0)
        notebookStore.selectPage(pages[0].id)
        tryVerify(() => pageEditorAdapter.textCards[0].text === "Aula é")
        compare(pageEditorAdapter.textCards[0].id, id)
        compare(pageEditorAdapter.textCards[0].xPt, x + 1)
        compare(pageEditorAdapter.textCards[0].widthPt, width + 10)
        tryCompare(ink, "strokeCount", 1)
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook.id))
        tryVerify(() => pageEditorAdapter.textCards[0].text === "Aula é")
        compare(pageEditorAdapter.textCards[0].id, id)
        compare(pageEditorAdapter.textCards[0].xPt, x + 1)
        compare(pageEditorAdapter.textCards[0].widthPt, width + 10)
        tryCompare(pageEditorAdapter, "inkCount", 1)
        tryCompare(ink, "strokeCount", 1)

        verify(notebookStore.selectPage(pages[1].id))
        const secondId = pageEditorAdapter.createTextAt(100, 300)
        verify(secondId !== "" && secondId !== id)
        tryVerify(() => pageEditorAdapter.textCards.length === 1)
        verify(pageEditorAdapter.saveText(secondId, "Outra caixa"))
        const secondX = pageEditorAdapter.textCards[0].xPt
        const secondWidth = pageEditorAdapter.textCards[0].widthPt
        toolbar.activeTool = "text"
        probe.selectedCardId = secondId
        const secondMove = control("editorTextMoveGrip")
        mousePress(secondMove, 16, 16)
        mouseMove(secondMove, 48, 16)
        mouseRelease(secondMove, 48, 16)
        tryVerify(() => pageEditorAdapter.textCards[0].xPt > secondX + 10)
        const movedX = pageEditorAdapter.textCards[0].xPt
        probe.selectedCardId = secondId
        const secondResize = control("editorTextResizeGrip")
        mousePress(secondResize, 16, 20)
        mouseMove(secondResize, 48, 20)
        mouseRelease(secondResize, 48, 20)
        tryVerify(() => pageEditorAdapter.textCards[0].widthPt > secondWidth + 10)
        const resizedWidth = pageEditorAdapter.textCards[0].widthPt
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards[0].widthPt === secondWidth)
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards[0].xPt === secondX)
        verify(pageEditorAdapter.redo())
        verify(pageEditorAdapter.redo())
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectPage(pages[1].id))
        tryVerify(() => pageEditorAdapter.textCards[0].id === secondId)
        compare(pageEditorAdapter.textCards[0].text, "Outra caixa")
        compare(pageEditorAdapter.textCards[0].xPt, movedX)
        compare(pageEditorAdapter.textCards[0].widthPt, resizedWidth)
        const thirdId = pageEditorAdapter.createTextAt(290, 900)
        verify(thirdId !== "" && thirdId !== secondId)
        verify(pageEditorAdapter.saveText(thirdId, "Caixa independente"))
        tryVerify(() => probe.maxCardBottom > canvas.height)
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectPage(pages[1].id))
        tryVerify(() => pageEditorAdapter.textCards.length === 2)
        verify(pageEditorAdapter.textCards.some(card => card.id === secondId &&
                                                   card.text === "Outra caixa" && card.xPt === movedX))
        verify(pageEditorAdapter.textCards.some(card => card.id === thirdId &&
                                                   card.text === "Caixa independente"))
    }

    function test_rich_text_roundtrip() {
        const page = openFreshPages(1)[0]
        const notebook = { id: notebookId("Caderno de teste") }
        const id = pageEditorAdapter.createTextAt(160, 120)
        verify(id !== "")
        verify(pageEditorAdapter.saveText(id, "Outra caixa"))
        const probe = control("editorProbe")
        probe.selectedCardId = id
        tryVerify(() => probe.activeTextCard && probe.activeTextCard.cardData.id === id)
        const card = probe.activeTextCard
        const editor = card.editorItem
        editor.forceActiveFocus()
        editor.select(0, 5)
        verify(card.applyFormat("heading", "2"))
        editor.select(0, 5)
        const boldButton = findChild(control("editorToolbar"), "textBoldButton")
        verify(boldButton !== null)
        tryCompare(boldButton, "checked", true)
        boldButton.clicked()
        tryCompare(boldButton, "checked", false)
        boldButton.clicked()
        tryCompare(boldButton, "checked", true)
        editor.select(0, 5)
        verify(card.applyFormat("underline", true))
        editor.select(0, 5)
        verify(card.applyFormat("family", "Inter"))
        editor.select(0, 5)
        verify(card.applyFormat("size", 24))
        editor.select(0, 5)
        verify(card.applyFormat("color", "#2868BD"))
        editor.select(0, 5)
        verify(card.applyFormat("link", "https://example.org/aula"))
        // Formatting is its own history step, committed at once.
        verify(!card.dirty)
        compare(pageEditorAdapter.undoLabel, "Formatar texto")
        verify(inputDriver.capture(app, "rich-text-editor-graphite.png"))
        Theme.dark = false
        wait(350)
        verify(inputDriver.capture(app, "rich-text-editor-light.png"))
        Theme.dark = true
        verify(card.save())
        tryVerify(() => probe.activeTextCard && !probe.activeTextCard.dirty)
        verify(pageEditorAdapter.undo())
        verify(pageEditorAdapter.redo())
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectPage(page.id))
        probe.selectedCardId = id
        tryVerify(() => probe.activeTextCard && probe.activeTextCard.cardData.id === id)
        const reopened = probe.activeTextCard
        const style = pageEditorAdapter.richFormatAt(reopened.editorItem.textDocument, 2)
        compare(style.bold, true)
        compare(style.underline, true)
        compare(style.family, "Inter")
        compare(style.size, 24)
        compare(style.color.toUpperCase(), "#2868BD")
        compare(style.link, "https://example.org/aula")
        compare(style.heading, 2)
        const nextId = pageEditorAdapter.createTextAt(120, 420)
        verify(nextId !== "")
        probe.selectedCardId = nextId
        tryVerify(() => probe.activeTextCard && probe.activeTextCard.cardData.id === nextId)
        const nextCard = probe.activeTextCard
        nextCard.editorItem.forceActiveFocus()
        verify(nextCard.applyFormat("italic", true))
        inputDriver.commitText(app, "Item á")
        tryVerify(() => nextCard.editorItem.text.includes("Item á"))
        verify(nextCard.applyFormat("bullet", ""))
        verify(nextCard.save())
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectPage(page.id))
        probe.selectedCardId = nextId
        tryVerify(() => probe.activeTextCard && probe.activeTextCard.cardData.id === nextId)
        const nextStyle = pageEditorAdapter.richFormatAt(probe.activeTextCard.editorItem.textDocument, 2)
        compare(nextStyle.italic, true)
        compare(nextStyle.list, "bullet")
    }

    function test_viewport_and_infinite_page() {
        const page = openFreshPages(1)[0]
        const notebook = { id: notebookId("Caderno de teste") }
        const scroll = control("pageScroll")
        const canvas = control("canvasArea")
        const scene = control("pageScene")
        const id = pageEditorAdapter.createTextAt(100, 200)
        verify(id !== "")
        verify(pageEditorAdapter.saveText(id, "Zoom mantém pontos"))
        // Copy the values: newer Qt keeps list elements bound to the live list.
        const cardBefore = Object.assign({}, pageEditorAdapter.textCards.find(card => card.id === id))
        verify(cardBefore.id === id)
        const anchor = canvas.mapToItem(scroll, 180, 170)
        app.zoomAt(1.5, anchor.x, anchor.y)
        compare(app.pageZoom, 1.5)
        const after = canvas.mapToItem(scroll, 180, 170)
        verify(Math.abs(after.x - anchor.x) < 2)
        verify(Math.abs(after.y - anchor.y) < 2)
        compare(control("pageZoomLabel").text, "150%")
        const wheelAnchor = canvas.mapToItem(scroll, 180, 170)
        inputDriver.wheel(app, canvas, 180, 170, 120, Qt.ControlModifier)
        tryVerify(() => app.pageZoom > 1.5, 5000, "zoom após roda=" + app.pageZoom)
        const wheelAfter = canvas.mapToItem(scroll, 180, 170)
        verify(Math.abs(wheelAfter.x - wheelAnchor.x) < 2,
               "roda X: " + wheelAnchor.x + " → " + wheelAfter.x)
        verify(Math.abs(wheelAfter.y - wheelAnchor.y) < 2,
               "roda Y: " + wheelAnchor.y + " → " + wheelAfter.y)
        app.zoomAt(1.5)
        const cardAfter = pageEditorAdapter.textCards.find(card => card.id === id)
        compare(cardAfter.xPt, cardBefore.xPt)
        compare(cardAfter.yPt, cardBefore.yPt)
        compare(cardAfter.widthPt, cardBefore.widthPt)
        verify(scene.width > 794)
        const probe = control("editorProbe")
        probe.selectedCardId = id
        tryVerify(() => probe.activeTextCard && probe.activeTextCard.cardData.id === id)
        probe.activeTextCard.editorItem.forceActiveFocus()
        keyClick(Qt.Key_End)
        inputDriver.commitText(app, " é")
        verify(probe.activeTextCard.save())
        tryVerify(() => pageEditorAdapter.textCards.find(card => card.id === id).text.endsWith(" é"))
        probe.selectedCardId = id
        probe.activeTextCard.moveHandle.forceActiveFocus()
        keyClick(Qt.Key_Right)
        tryVerify(() => pageEditorAdapter.textCards.find(card => card.id === id).xPt === cardBefore.xPt + 1)
        probe.selectedCardId = id
        probe.activeTextCard.resizeHandle.forceActiveFocus()
        keyClick(Qt.Key_Right, Qt.ShiftModifier)
        tryVerify(() => pageEditorAdapter.textCards.find(card => card.id === id).widthPt === cardBefore.widthPt + 10)
        // Handles keep their screen size under zoom, and pointer travel on
        // screen converts back to page points: 30 px at 150% = 15 pt.
        probe.selectedCardId = id
        tryVerify(() => probe.activeTextCard && probe.activeTextCard.cardData.id === id)
        const grip = probe.activeTextCard.moveHandle
        const gripTopLeft = grip.mapToItem(scroll, 0, 0)
        const gripBottomRight = grip.mapToItem(scroll, grip.width, grip.height)
        verify(Math.abs(gripBottomRight.x - gripTopLeft.x - grip.width) < 0.5)
        verify(Math.abs(gripBottomRight.y - gripTopLeft.y - grip.height) < 0.5)
        const resize = probe.activeTextCard.resizeHandle
        verify(Math.abs(resize.mapToItem(scroll, resize.width, 0).x - resize.mapToItem(scroll, 0, 0).x
                        - resize.width) < 0.5)
        const dragFrom = pageEditorAdapter.textCards.find(card => card.id === id).xPt
        mousePress(grip, 16, 20)
        mouseMove(grip, 46, 20)
        mouseRelease(grip, 46, 20)
        tryVerify(() => Math.abs(pageEditorAdapter.textCards.find(card => card.id === id).xPt
                                 - dragFrom - 15) < 0.5)
        keyClick(Qt.Key_Equal, Qt.ControlModifier)
        tryCompare(app, "pageZoom", 1.75)
        keyClick(Qt.Key_Minus, Qt.ControlModifier)
        tryCompare(app, "pageZoom", 1.5)
        probe.selectedCardId = id
        verify(inputDriver.capture(app, "viewport-a4-150.png"))
        const keepX = scroll.contentX
        const keepY = scroll.contentY
        app.zoomAt(0.5)
        probe.selectedCardId = id
        wait(100)
        verify(inputDriver.capture(app, "viewport-a4-50.png"))
        app.zoomAt(1.5)
        scroll.contentX = keepX
        scroll.contentY = keepY
        const pan = control("pagePanSurface")
        const startX = scroll.contentX
        mousePress(pan, scroll.contentX + 260, scroll.contentY + 220, Qt.MiddleButton)
        mouseMove(pan, scroll.contentX + 220, scroll.contentY + 220)
        mouseRelease(pan, scroll.contentX + 220, scroll.contentY + 220, Qt.MiddleButton)
        verify(scroll.contentX > startX + 15)
        canvas.forceActiveFocus()
        inputDriver.keyPress(app, Qt.Key_Space)
        tryCompare(app, "spacePan", true)
        const handStart = scroll.contentX
        mousePress(pan, scroll.contentX + 260, scroll.contentY + 220, Qt.LeftButton)
        mouseMove(pan, scroll.contentX + 220, scroll.contentY + 220)
        mouseRelease(pan, scroll.contentX + 220, scroll.contentY + 220, Qt.LeftButton)
        verify(scroll.contentX > handStart + 15)
        inputDriver.keyRelease(app, Qt.Key_Space)
        tryCompare(app, "spacePan", false)
        verify(pageEditorAdapter.setInfiniteCanvas(true))
        tryCompare(pageEditorAdapter, "infiniteCanvas", true)
        verify(canvas.width > 794)
        scroll.contentX = 0
        scroll.contentY = 90
        verify(inputDriver.capture(app, "viewport-infinite-150.png"))
        verify(pageEditorAdapter.moveText(id, 900, 1000))
        verify(pageEditorAdapter.resizeText(id, 480))
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectSection(notebookStore.sections[0].id))
        verify(notebookStore.selectPage(page.id))
        tryCompare(pageEditorAdapter, "infiniteCanvas", true)
        const reopened = pageEditorAdapter.textCards.find(card => card.id === id)
        verify(reopened)
        compare(reopened.xPt, 900)
        compare(reopened.yPt, 1000)
        compare(reopened.widthPt, 480)
        app.zoomAt(1)
    }

    function test_unified_history() {
        const pages = openFreshPages(2)
        const probe = control("editorProbe")
        tryCompare(probe, "visible", true)
        const id = pageEditorAdapter.createTextAt(80, 600)
        verify(id !== "")
        probe.selectedCardId = id
        tryVerify(() => probe.cardById(id) !== null)
        const card = probe.cardById(id)
        const editor = card.editorItem

        // Typing becomes a history step after a pause, without Ctrl+S.
        editor.forceActiveFocus()
        inputDriver.typeText(app, "Ola")
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).text === "Ola", 3000)
        compare(pageEditorAdapter.undoLabel, "Digitar")
        inputDriver.typeText(app, " mundo")
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).text === "Ola mundo", 3000)
        // The delegate survives commands, so focus and caret stay in place.
        compare(probe.cardById(id), card)
        verify(editor.activeFocus)

        // Ctrl+Z in the body goes through the page history and restores the
        // caret from before the undone burst.
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).text === "Ola")
        tryVerify(() => editor.getText(0, editor.length) === "Ola")
        verify(editor.activeFocus)
        compare(editor.cursorPosition, 3)
        keyClick(Qt.Key_Z, Qt.ControlModifier | Qt.ShiftModifier)
        tryVerify(() => editor.getText(0, editor.length) === "Ola mundo")

        // Undo right after typing commits the pending burst first.
        inputDriver.typeText(app, "!")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        tryVerify(() => editor.getText(0, editor.length) === "Ola mundo")
        compare(pageEditorAdapter.redoLabel, "Digitar")

        // Held arrow keys fold into one step.
        const x = pageEditorAdapter.textCards.find(c => c.id === id).xPt
        card.moveHandle.forceActiveFocus()
        for (let step = 0; step < 5; ++step) keyClick(Qt.Key_Right)
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).xPt === x + 5)
        compare(pageEditorAdapter.undoLabel, "Mover caixa de texto")
        verify(pageEditorAdapter.undo())
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).xPt === x)
        compare(pageEditorAdapter.undoLabel, "Digitar")
        compare(probe.selectedCardId, id)

        // Duplicate and delete are commands with undo, from keys and buttons.
        const count = pageEditorAdapter.textCards.length
        card.moveHandle.forceActiveFocus()
        keyClick(Qt.Key_D, Qt.ControlModifier)
        tryCompare(pageEditorAdapter.textCards, "length", count + 1)
        verify(probe.selectedCardId !== id)
        const copy = pageEditorAdapter.textCards.find(c => c.id === probe.selectedCardId)
        compare(copy.text, "Ola mundo")
        compare(copy.xPt, x + 16)
        compare(pageEditorAdapter.undoLabel, "Duplicar caixa de texto")
        verify(pageEditorAdapter.undo())
        tryCompare(pageEditorAdapter.textCards, "length", count)
        probe.selectedCardId = id
        card.moveHandle.forceActiveFocus()
        keyClick(Qt.Key_Delete)
        tryCompare(pageEditorAdapter.textCards, "length", count - 1)
        compare(pageEditorAdapter.undoLabel, "Excluir caixa de texto")
        verify(pageEditorAdapter.undo())
        tryCompare(pageEditorAdapter.textCards, "length", count)
        compare(probe.selectedCardId, id)
        tryVerify(() => probe.cardById(id) && probe.cardById(id).moveHandle.activeFocus)

        // A box created and left empty leaves nothing to undo or redo.
        const labelBefore = pageEditorAdapter.undoLabel
        const empty = pageEditorAdapter.createTextAt(300, 700)
        tryVerify(() => probe.cardById(empty) !== null)
        probe.cardById(empty).editorItem.forceActiveFocus()
        probe.cardById(id).moveHandle.forceActiveFocus()
        tryVerify(() => !pageEditorAdapter.textCards.some(c => c.id === empty))
        compare(pageEditorAdapter.undoLabel, labelBefore)
        compare(pageEditorAdapter.canRedo, false)

        // A recent page keeps its history across navigation.
        verify(notebookStore.selectPage(pages[1].id))
        tryCompare(pageEditorAdapter, "pageId", pages[1].id)
        verify(notebookStore.selectPage(pages[0].id))
        tryCompare(pageEditorAdapter, "pageId", pages[0].id)
        compare(pageEditorAdapter.undoLabel, labelBefore)
        verify(pageEditorAdapter.undo())

    }

    // Carried over from the E4.1 probe: typing in a card never triggers the
    // one-key tool shortcuts, and IME composition reaches the card body.
    function test_typing_keeps_tools_and_ime() {
        openFreshPages(1)
        const probe = control("editorProbe")
        tryCompare(probe, "visible", true)
        const id = pageEditorAdapter.createTextAt(120, 200)
        verify(id !== "")
        probe.selectedCardId = id
        tryVerify(() => probe.cardById(id) !== null)
        const editor = probe.cardById(id).editorItem
        const toolbar = control("editorToolbar")
        toolbar.activeTool = "select"
        editor.forceActiveFocus()
        tryCompare(editor, "activeFocus", true)
        inputDriver.typeText(app, "Aula t p v")
        compare(toolbar.activeTool, "select", "Digitação no texto não pode acionar atalhos de ferramenta")
        tryVerify(() => editor.getText(0, editor.length).includes("t p v"))
        inputDriver.preeditText(app, "e")
        tryCompare(editor, "inputMethodComposing", true)
        inputDriver.commitText(app, "é")
        tryCompare(editor, "inputMethodComposing", false)
        tryVerify(() => editor.getText(0, editor.length).endsWith("é"))
    }

    // The gallery's Editor section opens a sample notebook in this profile.
    function test_gallery_opens_sample_editor() {
        app.openSampleEditor()
        tryCompare(notebookStore, "activeNotebookName", "Caderno de amostra")
        verify(notebookStore.activePageId !== "")
        tryCompare(control("editorProbe"), "visible", true)
        const sampleId = notebookStore.activeNotebookId
        notebookStore.closeNotebook()
        app.openSampleEditor()
        tryCompare(notebookStore, "activeNotebookId", sampleId)
        compare(notebookStore.notebooks.filter(item => item.title === "Caderno de amostra").length, 1)
    }
}
