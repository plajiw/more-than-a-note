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
}
