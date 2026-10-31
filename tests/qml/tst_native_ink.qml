import QtQuick
import QtTest
import MoreThanANote

// Pixel checks that only hold in a native graphics session: the offscreen
// software backend used by ctest does not draw the ink scene-graph nodes.
// Offscreen runs report these as SKIP, never as a silent pass.
AppTestCase {
    name: "NativeInk"

    function test_ink_over_text_and_isolated_dot() {
        if (inputDriver.isOffscreen())
            skip("Requer sessão gráfica nativa: o backend offscreen não desenha a tinta")
        openFreshPages(1)
        const probe = control("editorProbe")
        tryCompare(probe, "visible", true)
        const toolbar = control("editorToolbar")
        toolbar.activeTool = "text"
        mouseClick(probe, 220, 210)
        tryVerify(() => pageEditorAdapter.textCards.length === 1)
        control("editorTextCardBody").forceActiveFocus()
        inputDriver.typeText(app, "Aula")
        toolbar.activeTool = "pen"
        toolbar.penMode = "pen"
        const surface = control("editorProbePenSurface")
        const ink = control("editorProbeInk")
        mousePress(surface, 100, 100)
        mouseMove(surface, 180, 110)
        mouseRelease(surface, 180, 110)
        tryCompare(pageEditorAdapter, "inkCount", 1)
        wait(100)
        verify(inputDriver.hasInkInRect(app, ink, 98, 218, 85, 20), "O traço deve aparecer acima do texto")
        mouseClick(surface, 220, 180)
        tryCompare(pageEditorAdapter, "inkCount", 2)
        wait(100)
        verify(inputDriver.hasInkInRect(app, ink, 215, 295, 10, 10), "Um toque isolado deve produzir um ponto visível")
        verify(inputDriver.capture(app, "native-ink-over-text.png"))
    }

    // C2: a stroke dragged past the paper edge is drawn only on the paper.
    function test_ink_is_cut_at_the_paper_edge() {
        if (inputDriver.isOffscreen())
            skip("Requer sessão gráfica nativa: o backend offscreen não desenha a tinta")
        openFreshPages(1)
        app.zoomAt(1)
        const toolbar = control("editorToolbar")
        const scroll = control("pageScroll")
        const surface = control("editorProbePenSurface")
        const ink = control("editorProbeInk")
        const canvas = control("canvasArea")
        toolbar.activeTool = "pen"
        toolbar.penMode = "pen"
        // Bring the right edge of the paper into view.
        scroll.contentX = scroll.contentWidth - scroll.width
        wait(50)
        const y = 300
        const start = surface.mapToItem(scroll, canvas.width - 50, y)
        mousePress(surface, canvas.width - 50, y)
        for (let i = 1; i <= 5; ++i)
            mouseMove(scroll, start.x + 20 * i, start.y)
        mouseRelease(scroll, start.x + 100, start.y)
        tryCompare(pageEditorAdapter, "inkCount", 1)
        wait(100)
        const inkY = y + surface.y
        verify(inputDriver.hasInkInRect(app, ink, canvas.width - 45, inkY - 4, 35, 8),
               "O traço deve aparecer no papel")
        verify(!inputDriver.hasInkInRect(app, ink, canvas.width + 8, inkY - 4, 30, 8),
               "O traço não pode aparecer fora do papel")
        verify(inputDriver.capture(app, "native-ink-cut-at-paper-edge.png"))
        toolbar.activeTool = "text"
    }
}
