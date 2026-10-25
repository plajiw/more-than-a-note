import QtQuick
import QtTest
import MoreThanANote

TestCase {
    name: "WorkspaceKeyboard"
    when: windowShown

    property var app

    Component { id: appComponent; Main {} }

    function control(name) {
        const found = findChild(app.contentItem, name)
        verify(found !== null, "Controle ausente: " + name)
        return found
    }

    function notebookId(title) {
        const entry = notebookStore.notebooks.find(notebook => notebook.title === title)
        verify(entry !== undefined, "Caderno de teste ausente: " + title)
        return entry.id
    }

    function keyClick(key, modifiers) {
        keyboardDriver.keyClick(app, key, modifiers || 0)
    }

    function initTestCase() {
        app = appComponent.createObject(null)
        verify(app !== null)
        tryVerify(() => app.visible)
        app.requestActivate()
        tryCompare(app, "active", true)
    }

    function cleanupTestCase() {
        app.destroy()
        wait(50)
        testSetup.finish()
    }

    function test_a_empty_and_search_states() {
        const search = control("notebookSearch")
        search.forceActiveFocus()
        keyboardDriver.typeText(app, "inexistente")
        tryCompare(control("libraryList"), "count", 0)
        keyClick(Qt.Key_A, Qt.ControlModifier)
        keyClick(Qt.Key_Backspace)
        tryCompare(control("libraryList"), "count", 2)

        const emptyRow = control("libraryNotebook_" + notebookId("Caderno vazio"))
        emptyRow.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeSectionId", "")
        compare(control("canvasArea").Accessible.name, "Página vazia")
        const back = control("backToLibrary")
        back.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeNotebookId", "")
    }

    function test_b_create_notebook_by_keyboard() {
        const create = control("newNotebookButton")
        create.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryVerify(() => app.activeFocusItem && app.activeFocusItem.objectName === "newNotebookName")
        keyboardDriver.typeText(app, "Criado pelo teclado")
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeNotebookName", "Criado pelo teclado")
        const back = control("backToLibrary")
        back.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeNotebookId", "")
    }

    function test_keyboard_navigation_and_focus_return() {
        app.requestActivate()
        tryCompare(app, "active", true)
        const fixtureId = notebookId("Caderno E2")
        const libraryRow = control("libraryNotebook_" + fixtureId)
        libraryRow.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeNotebookId", fixtureId)

        const firstSection = notebookStore.sections[0]
        const secondSection = notebookStore.sections[1]
        const sectionRow = control("sectionRow_" + firstSection.id)
        sectionRow.forceActiveFocus()
        keyClick(Qt.Key_Down)
        tryCompare(app, "activeFocusItem", control("sectionRow_" + secondSection.id))
        keyClick(Qt.Key_Up)
        tryCompare(app, "activeFocusItem", sectionRow)
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeSectionId", firstSection.id)

        const page = notebookStore.pages[0]
        const pageRow = control("pageRow_" + page.id)
        pageRow.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activePageId", page.id)
        compare(app.activeFocusItem, pageRow)
        verify(keyboardDriver.capture(app, "page-wide-graphite.png"))
        Theme.dark = false
        wait(350)
        verify(keyboardDriver.capture(app, "page-wide-light.png"))
        Theme.dark = true

        let reachedCanvas = false
        for (let n = 0; n < 40; ++n) {
            keyClick(Qt.Key_Tab)
            if (app.activeFocusItem === control("canvasArea")) {
                reachedCanvas = true
                break
            }
        }
        verify(reachedCanvas, "Tab deve alcançar a prévia da página")
        keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
        verify(app.activeFocusItem !== control("canvasArea"), "Shift+Tab deve sair da página")

        const back = control("backToLibrary")
        back.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeNotebookId", "")
        tryCompare(app, "activeFocusItem", control("newNotebookButton"))
    }

    function test_splitter_and_narrow_index() {
        app.requestActivate()
        tryCompare(app, "active", true)
        const fixtureId = notebookId("Caderno E2")
        const libraryRow = control("libraryNotebook_" + fixtureId)
        libraryRow.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(notebookStore, "activeNotebookId", fixtureId)

        const splitter = control("indexResize")
        splitter.forceActiveFocus()
        keyClick(Qt.Key_Home)
        const minimumX = splitter.x
        keyClick(Qt.Key_End)
        verify(splitter.x > minimumX, "End deve ampliar o índice")
        keyClick(Qt.Key_Left)
        verify(splitter.x < minimumX + 120, "Seta esquerda deve reduzir a largura")

        app.width = 800
        tryCompare(app, "narrowWorkspace", true)
        const show = control("showIndexButton")
        show.forceActiveFocus()
        keyClick(Qt.Key_Space)
        tryCompare(app, "indexShown", true)
        keyClick(Qt.Key_Escape)
        tryCompare(app, "indexShown", false)
        tryCompare(app, "activeFocusItem", show)
        verify(keyboardDriver.capture(app, "page-narrow.png"))

        app.width = 720
        tryCompare(app, "width", 720)
        const toolbar = control("editorToolbar")
        const strip = findChild(toolbar, "toolbarStrip")
        const lastColor = findChild(toolbar, "quickColor_9")
        lastColor.forceActiveFocus()
        tryVerify(() => {
            const position = lastColor.mapToItem(strip, 0, 0)
            return position.x >= 0 && position.x + lastColor.width <= strip.width
        })
        verify(keyboardDriver.capture(app, "page-minimum.png"))
    }

    function test_z_context_menu_inline_edit_and_shortcut_scope() {
        app.width = 1100
        tryCompare(app, "narrowWorkspace", false)
        const firstSection = notebookStore.sections[0]
        const sectionRow = control("sectionRow_" + firstSection.id)
        sectionRow.forceActiveFocus()
        keyClick(Qt.Key_F10, Qt.ShiftModifier)
        const menu = findChild(sectionRow, "indexMenu")
        verify(menu !== null)
        tryCompare(menu, "opened", true)
        const renameAction = findChild(menu, "renameIndexAction")
        tryCompare(renameAction, "activeFocus", true)
        renameAction.clicked()
        tryCompare(app, "indexEditKind", "section/rename")
        tryCompare(menu, "opened", false)
        app.requestActivate()
        const rename = findChild(sectionRow.parent, "sectionRename")
        const renameField = findChild(rename, "indexNameField")
        tryCompare(renameField, "activeFocus", true)
        keyClick(Qt.Key_Escape)
        tryCompare(app, "indexEditKind", "")
        tryCompare(app, "activeFocusItem", sectionRow)

        const addSection = control("addSeções")
        addSection.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(app, "indexEditKind", "section/create")
        const createField = findChild(control("sectionCreate"), "indexNameField")
        tryCompare(app, "activeFocusItem", createField)
        const toolbar = control("editorToolbar")
        toolbar.activeTool = "select"
        keyboardDriver.typeText(app, "Turma T")
        compare(toolbar.activeTool, "select", "Atalho T não pode trocar ferramenta em um campo")
        keyClick(Qt.Key_Return)
        tryCompare(app, "indexEditKind", "")
        tryVerify(() => notebookStore.sections.some(section => section.title === "Turma T"))

        keyClick(Qt.Key_Home)
        tryVerify(() => findChild(app.contentItem, "sectionRow_" + firstSection.id) !== null)
        const originalSection = control("sectionRow_" + firstSection.id)
        originalSection.forceActiveFocus()
        keyClick(Qt.Key_Return)
        const firstPage = control("pageRow_" + notebookStore.pages[0].id)
        firstPage.forceActiveFocus()
        keyClick(Qt.Key_Return)
        const canvas = control("canvasArea")
        canvas.forceActiveFocus()
        keyClick(Qt.Key_T)
        tryCompare(toolbar, "activeTool", "text")
    }

    function test_zz_page_model_demo() {
        const pages = notebookStore.pages
        verify(pages.length >= 2)
        notebookStore.selectPage(pages[0].id)
        pageTestAdapter.demoEnabled = true
        tryCompare(pageTestAdapter, "pageId", pages[0].id)
        compare(pageTestAdapter.objects.length, 0)

        const add = control("pageDemoAdd")
        add.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(pageTestAdapter, "canUndo", true)
        compare(pageTestAdapter.objects.length, 1)
        compare(pageTestAdapter.objects[0].kind, "text")
        compare(pageTestAdapter.objects[0].preview, "Texto de teste")
        const id = pageTestAdapter.objects[0].id
        const x = pageTestAdapter.objects[0].xPt

        const move = control("pageDemoMove")
        move.forceActiveFocus()
        keyClick(Qt.Key_Return)
        compare(pageTestAdapter.objects[0].id, id)
        compare(pageTestAdapter.objects[0].xPt, x + 30)
        verify(keyboardDriver.capture(app, "page-model-demo.png"))

        const undo = control("pageDemoUndo")
        undo.forceActiveFocus()
        keyClick(Qt.Key_Return)
        compare(pageTestAdapter.objects[0].xPt, x)
        const redo = control("pageDemoRedo")
        redo.forceActiveFocus()
        keyClick(Qt.Key_Return)
        compare(pageTestAdapter.objects[0].xPt, x + 30)

        notebookStore.selectPage(pages[1].id)
        tryCompare(pageTestAdapter, "pageId", pages[1].id)
        compare(pageTestAdapter.objects.length, 0)
        notebookStore.selectPage(pages[0].id)
        compare(pageTestAdapter.objects.length, 0)
        pageTestAdapter.demoEnabled = false
        compare(pageTestAdapter.pageId, "")
    }

    function test_zzz_editor_probe() {
        const pages = notebookStore.pages
        verify(pages.length >= 2)
        notebookStore.selectPage(pages[0].id)
        app.editorProbeEnabled = true
        const probe = control("editorProbe")
        tryCompare(probe, "visible", true)
        const first = control("editorProbeText1")
        first.forceActiveFocus()
        tryCompare(app, "activeFocusItem", first)
        keyClick(Qt.Key_End)
        keyboardDriver.typeText(app, " Teste")
        verify(first.text.includes("Teste"))

        const toolbar = control("editorToolbar")
        toolbar.activeTool = "select"
        keyboardDriver.typeText(app, " t p v")
        compare(toolbar.activeTool, "select", "Digitação no texto não pode acionar atalhos de ferramenta")
        verify(first.text.includes("t p v"))
        keyboardDriver.preeditText(app, "e")
        tryCompare(first, "inputMethodComposing", true)
        keyboardDriver.commitText(app, "é")
        tryCompare(first, "inputMethodComposing", false)
        verify(first.text.includes("é"))

        toolbar.activeTool = "pen"
        toolbar.penMode = "pen"
        const surface = control("editorProbePenSurface")
        const ink = control("editorProbeInk")
        mousePress(surface, 100, 100)
        mouseMove(surface, 180, 110)
        mouseRelease(surface, 180, 110)
        tryCompare(ink, "strokeCount", 1)
        verify(ink.pointCount >= 2)
        wait(100)
        if (!keyboardDriver.isOffscreen())
            verify(keyboardDriver.hasInkInRect(app, ink, 95, 210, 90, 30),
                   "O traço deve aparecer acima do texto na sessão gráfica")
        mouseClick(surface, 220, 180)
        tryCompare(ink, "strokeCount", 2)
        if (!keyboardDriver.isOffscreen())
            verify(keyboardDriver.hasInkInRect(app, ink, 215, 295, 10, 10),
                   "Um toque isolado deve produzir um ponto visível")
        verify(keyboardDriver.capture(app, "editor-probe-text-ink.png"))

        toolbar.activeTool = "text"
        mouseClick(first, 40, 20)
        tryCompare(app, "activeFocusItem", first)
        compare(ink.strokeCount, 2)
        notebookStore.selectPage(pages[1].id)
        tryCompare(ink, "strokeCount", 0)
        verify(!first.text.includes("Teste"))
        app.editorProbeEnabled = false
    }

    function test_zzzz_editor_model_roundtrip() {
        const notebook = notebookStore.notebooks.find(item => item.title === "Caderno E2")
        verify(notebook)
        verify(notebookStore.openNotebook(notebook.id))
        const pages = notebookStore.pages
        verify(pages.length >= 2)
        verify(notebookStore.selectPage(pages[0].id))
        pageEditorAdapter.setEnabled(true)
        app.editorModelEnabled = true
        const probe = control("editorProbe")
        tryCompare(probe, "visible", true)
        tryCompare(pageEditorAdapter, "pageId", pages[0].id)
        const first = control("editorProbeText1")
        const second = control("editorProbeText2")
        tryCompare(first, "text", "")
        first.forceActiveFocus()
        keyboardDriver.typeText(app, "Aula")
        keyboardDriver.commitText(app, " é")
        tryVerify(() => first.text.includes("Aula é"))
        second.text = "Diagrama\ne objetos"
        const save = control("editorModelSaveTexts")
        tryCompare(save, "enabled", true)
        save.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(pageEditorAdapter, "text1", "Aula é")
        tryCompare(pageEditorAdapter, "text2", "Diagrama\ne objetos")
        tryCompare(save, "enabled", false)

        const toolbar = control("editorToolbar")
        toolbar.activeTool = "pen"
        toolbar.penMode = "pen"
        const surface = control("editorProbePenSurface")
        const ink = control("editorProbeInk")
        mousePress(surface, 100, 100)
        mouseMove(surface, 180, 110)
        mouseRelease(surface, 180, 110)
        tryCompare(pageEditorAdapter, "inkCount", 1)
        compare(ink.strokeCount, 1)
        if (!keyboardDriver.isOffscreen()) {
            wait(100)
            verify(keyboardDriver.capture(app, "editor-model-text-ink.png"))
            verify(keyboardDriver.hasInkInRect(app, ink, 98, 218, 85, 20))
        }
        verify(pageEditorAdapter.canUndo)
        verify(pageEditorAdapter.undo())
        tryCompare(pageEditorAdapter, "inkCount", 0)
        tryCompare(ink, "strokeCount", 0)
        verify(pageEditorAdapter.undo())
        tryCompare(pageEditorAdapter, "text2", "")
        tryCompare(second, "text", "")
        verify(pageEditorAdapter.undo())
        tryCompare(pageEditorAdapter, "text1", "")
        tryCompare(first, "text", "")
        verify(pageEditorAdapter.redo())
        tryCompare(pageEditorAdapter, "text1", "Aula é")
        verify(pageEditorAdapter.redo())
        tryCompare(pageEditorAdapter, "text2", "Diagrama\ne objetos")
        verify(pageEditorAdapter.redo())
        tryCompare(pageEditorAdapter, "inkCount", 1)
        tryCompare(ink, "strokeCount", 1)

        notebookStore.selectPage(pages[1].id)
        tryCompare(pageEditorAdapter, "inkCount", 0)
        tryCompare(first, "text", "")
        notebookStore.selectPage(pages[0].id)
        tryCompare(pageEditorAdapter, "text1", "Aula é")
        tryCompare(first, "text", "Aula é")
        tryCompare(ink, "strokeCount", 1)
        notebookStore.closeNotebook()
        verify(notebookStore.openNotebook(notebook.id))
        tryCompare(pageEditorAdapter, "text1", "Aula é")
        tryCompare(pageEditorAdapter, "text2", "Diagrama\ne objetos")
        tryCompare(pageEditorAdapter, "inkCount", 1)
        tryCompare(ink, "strokeCount", 1)
        pageEditorAdapter.setEnabled(false)
        app.editorModelEnabled = false
    }
}
