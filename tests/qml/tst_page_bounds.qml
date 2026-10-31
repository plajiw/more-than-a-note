import QtQuick
import QtTest
import MoreThanANote

// C2: cards leave the paper and come back by their handle; ink stays on the
// paper. Gestures run in view coordinates, since the handle moves with the card.
AppTestCase {
    name: "PageBounds"

    // C3: the card moves by its body with the Selection tool.
    function dragGrip(card, scroll, dx, dy) {
        control("editorToolbar").activeTool = "select"
        const grip = findChild(card, "editorTextCardBodyArea")
        tryVerify(() => grip.visible)
        const start = grip.mapToItem(scroll, grip.width / 2, grip.height / 2)
        mousePress(grip, grip.width / 2, grip.height / 2)
        verify(grip.pressed, "a alça deve receber o clique em " + JSON.stringify(start))
        const steps = 8
        for (let i = 1; i <= steps; ++i)
            mouseMove(scroll, start.x + dx * i / steps, start.y + dy * i / steps)
        mouseRelease(scroll, start.x + dx, start.y + dy)
    }

    function test_card_leaves_and_returns_to_paper() {
        openFreshPages(1)
        const probe = control("editorProbe")
        const scroll = control("pageScroll")
        const toolbar = control("editorToolbar")
        app.zoomAt(1)
        toolbar.activeTool = "text"
        const id = pageEditorAdapter.createTextAt(100, 200)
        verify(pageEditorAdapter.saveText(id, "Vai e volta"))
        tryVerify(() => probe.cardById(id) !== null)
        const card = probe.cardById(id)
        const paperWidthPt = 595.2755905512

        // Out to the right, past the paper edge.
        probe.selectedCardId = id
        tryVerify(() => card.selectionBox.visible)
        dragGrip(card, scroll, 800, 0)
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).xPt > paperWidthPt,
                  3000, "x após sair=" + pageEditorAdapter.textCards.find(c => c.id === id).xPt)
        verify(inputDriver.capture(app, "card-out-of-paper.png"))

        // Back onto the paper: bring the card into view, then drag it left.
        probe.selectedCardId = id
        const cardInView = card.mapToItem(scroll, 0, 0)
        if (cardInView.x + card.width > scroll.width)
            scroll.contentX = Math.min(scroll.contentWidth - scroll.width,
                                       scroll.contentX + cardInView.x + card.width - scroll.width + 40)
        wait(50)
        tryVerify(() => card.selectionBox.visible)
        const back = card.mapToItem(scroll, 0, 0)
        verify(back.x >= 0 && back.x < scroll.width, "alça visível na vista: " + back.x)
        dragGrip(card, scroll, -800, 0)
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).xPt < paperWidthPt - 100,
                  3000, "x após voltar=" + pageEditorAdapter.textCards.find(c => c.id === id).xPt)
        // The view can get back to the paper's left edge.
        scroll.contentX = 0
        verify(control("canvasArea").mapToItem(scroll, 0, 0).x >= 0)
        verify(inputDriver.capture(app, "card-back-on-paper.png"))
    }

    function test_ink_stays_on_the_paper() {
        openFreshPages(1)
        const toolbar = control("editorToolbar")
        const scroll = control("pageScroll")
        const ink = control("editorProbeInk")
        const surface = control("editorProbePenSurface")
        const canvas = control("canvasArea")
        app.zoomAt(1)
        toolbar.activeTool = "pen"
        toolbar.penMode = "pen"
        // A stroke that starts on the paper and is dragged off its right edge.
        const start = surface.mapToItem(scroll, canvas.width - 60, 200)
        mousePress(surface, canvas.width - 60, 200)
        for (let i = 1; i <= 6; ++i)
            mouseMove(scroll, start.x + 30 * i, start.y + 10 * i)
        mouseRelease(scroll, start.x + 180, start.y + 60)
        tryCompare(pageEditorAdapter, "inkCount", 1)
        // Ink is drawn only inside the paper.
        verify(ink.clip, "a tinta deve ser recortada no papel")
        compare(ink.width, canvas.width)
        scroll.contentX = scroll.contentWidth - scroll.width
        wait(50)
        verify(inputDriver.capture(app, "ink-clipped-to-paper.png"))
        toolbar.activeTool = "text"
    }
}
