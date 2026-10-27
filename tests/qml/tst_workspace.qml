import QtQuick
import QtTest
import MoreThanANote

TestCase {
    name: "WorkspaceKeyboard"
    when: windowShown

    property var app

    Component { id: appComponent; Main {} }
    Component {
        id: textCardDemoComponent
        Window {
            width: 840
            height: 740
            visible: true
            color: Theme.color.base
            property alias demo: cardDemo
            TextCardGalleryDemo {
                id: cardDemo
                anchors.fill: parent
                anchors.margins: 20
            }
        }
    }

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
        // Narrow toolbars collapse the nine colors into one well (priority overflow).
        const lastColor = toolbar.compactColors ? findChild(toolbar, "toolColorWell") : findChild(toolbar, "quickColor_9")
        verify(lastColor.visible)
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
        const toolbar = control("editorToolbar")
        toolbar.activeTool = "text"
        mouseClick(probe, 220, 210)
        tryVerify(() => pageEditorAdapter.textCards.length === 1)
        const id = pageEditorAdapter.textCards[0].id
        verify(id.length > 0)
        const card = control("editorTextCard")
        const first = control("editorTextCardBody")
        first.forceActiveFocus()
        keyboardDriver.typeText(app, "Aula")
        keyboardDriver.commitText(app, " é")
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
        pageEditorAdapter.setEnabled(false)
        app.editorModelEnabled = false
    }

    function test_zzzzr_rich_text_roundtrip() {
        const notebook = notebookStore.notebooks.find(item => item.title === "Caderno E2")
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectSection(notebookStore.sections[0].id))
        const page = notebookStore.pages[0]
        verify(notebookStore.selectPage(page.id))
        pageEditorAdapter.setEnabled(true)
        app.editorModelEnabled = true
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
        if (!keyboardDriver.isOffscreen()) {
            verify(keyboardDriver.capture(app, "rich-text-editor-dark.png"))
            Theme.dark = false
            wait(350)
            verify(keyboardDriver.capture(app, "rich-text-editor-light.png"))
            Theme.dark = true
        }
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
        keyboardDriver.commitText(app, "Item á")
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
        pageEditorAdapter.setEnabled(false)
        app.editorModelEnabled = false
    }

    function test_zzzzs_viewport_and_infinite_page() {
        const notebook = notebookStore.notebooks.find(item => item.title === "Caderno E2")
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectSection(notebookStore.sections[0].id))
        const page = notebookStore.pages[0]
        verify(notebookStore.selectPage(page.id))
        pageEditorAdapter.setEnabled(true)
        app.editorModelEnabled = true
        const scroll = control("pageScroll")
        const canvas = control("canvasArea")
        const scene = control("pageScene")
        const id = pageEditorAdapter.createTextAt(100, 200)
        verify(id !== "")
        verify(pageEditorAdapter.saveText(id, "Zoom mantém pontos"))
        const cardBefore = pageEditorAdapter.textCards.find(card => card.id === id)
        verify(cardBefore)
        const anchor = canvas.mapToItem(scroll, 180, 170)
        app.zoomAt(1.5, anchor.x, anchor.y)
        compare(app.pageZoom, 1.5)
        const after = canvas.mapToItem(scroll, 180, 170)
        verify(Math.abs(after.x - anchor.x) < 2)
        verify(Math.abs(after.y - anchor.y) < 2)
        compare(control("pageZoomLabel").text, "150%")
        const wheelAnchor = canvas.mapToItem(scroll, 180, 170)
        keyboardDriver.wheel(app, canvas, 180, 170, 120, Qt.ControlModifier)
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
        keyboardDriver.commitText(app, " é")
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
        if (!keyboardDriver.isOffscreen()) {
            probe.selectedCardId = id
            verify(keyboardDriver.capture(app, "viewport-a4-150.png"))
            const keepX = scroll.contentX
            const keepY = scroll.contentY
            app.zoomAt(0.5)
            probe.selectedCardId = id
            wait(100)
            verify(keyboardDriver.capture(app, "viewport-a4-50.png"))
            app.zoomAt(1.5)
            scroll.contentX = keepX
            scroll.contentY = keepY
        }
        const pan = control("pagePanSurface")
        const startX = scroll.contentX
        mousePress(pan, scroll.contentX + 260, scroll.contentY + 220, Qt.MiddleButton)
        mouseMove(pan, scroll.contentX + 220, scroll.contentY + 220)
        mouseRelease(pan, scroll.contentX + 220, scroll.contentY + 220, Qt.MiddleButton)
        verify(scroll.contentX > startX + 15)
        canvas.forceActiveFocus()
        keyboardDriver.keyPress(app, Qt.Key_Space)
        tryCompare(app, "spacePan", true)
        const handStart = scroll.contentX
        mousePress(pan, scroll.contentX + 260, scroll.contentY + 220, Qt.LeftButton)
        mouseMove(pan, scroll.contentX + 220, scroll.contentY + 220)
        mouseRelease(pan, scroll.contentX + 220, scroll.contentY + 220, Qt.LeftButton)
        verify(scroll.contentX > handStart + 15)
        keyboardDriver.keyRelease(app, Qt.Key_Space)
        tryCompare(app, "spacePan", false)
        verify(pageEditorAdapter.setInfiniteCanvas(true))
        tryCompare(pageEditorAdapter, "infiniteCanvas", true)
        verify(canvas.width > 794)
        scroll.contentX = 0
        scroll.contentY = 90
        if (!keyboardDriver.isOffscreen())
            verify(keyboardDriver.capture(app, "viewport-infinite-150.png"))
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
        pageEditorAdapter.setEnabled(false)
        app.editorModelEnabled = false
    }

    function test_zzzzt_unified_history() {
        const notebook = notebookStore.notebooks.find(item => item.title === "Caderno E2")
        verify(notebookStore.openNotebook(notebook.id))
        verify(notebookStore.selectSection(notebookStore.sections[0].id))
        const pages = notebookStore.pages
        verify(pages.length >= 2)
        verify(notebookStore.selectPage(pages[0].id))
        pageEditorAdapter.setEnabled(true)
        app.editorModelEnabled = true
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
        keyboardDriver.typeText(app, "Ola")
        tryVerify(() => pageEditorAdapter.textCards.find(c => c.id === id).text === "Ola", 3000)
        compare(pageEditorAdapter.undoLabel, "Digitar")
        keyboardDriver.typeText(app, " mundo")
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
        keyboardDriver.typeText(app, "!")
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

        pageEditorAdapter.setEnabled(false)
        app.editorModelEnabled = false
    }

    function test_zzzzz_text_card_gallery_geometry() {
        const cardWindow = textCardDemoComponent.createObject(null)
        verify(cardWindow !== null)
        tryVerify(() => cardWindow.visible)
        cardWindow.requestActivate()
        tryCompare(cardWindow, "active", true)
        const demo = cardWindow.demo
        const editor = findChild(demo, "textCardEditor")
        const moveGrip = findChild(demo, "textCardMoveGrip")
        const resizeGrip = findChild(demo, "textCardResizeGrip")
        const actions = findChild(demo, "textCardActions")
        const duplicateButton = findChild(actions, "textCardDuplicateButton")
        const deleteButton = findChild(actions, "textCardDeleteButton")
        const paper = findChild(demo, "textCardPaper")
        verify(editor && moveGrip && resizeGrip && paper && actions && duplicateButton && deleteButton)
        compare(duplicateButton.width, deleteButton.width)
        compare(duplicateButton.height, deleteButton.height)
        compare(duplicateButton.width, 24)
        compare(duplicateButton.iconSize, deleteButton.iconSize)
        compare(duplicateButton.iconSize, 16)
        // Top chrome capsules are seated on the border (24 px drawn, 32 px
        // target growing upward) and aligned to the body margins.
        compare(moveGrip.height, 32)
        compare(moveGrip.y + moveGrip.height, editor.y)
        compare(actions.y + actions.height / 2, 0)
        compare(moveGrip.x, editor.x)
        compare(actions.x + actions.width - 4, editor.x + editor.width)
        compare(resizeGrip.x + resizeGrip.width / 2, resizeGrip.parent.width)
        demo.setExample("short")
        const shortHeight = demo.cardHeight
        if (!keyboardDriver.isOffscreen())
            verify(keyboardDriver.capture(cardWindow, "text-card-short-controls.png"))
        verify(actions.y + actions.height <= editor.y)
        compare(resizeGrip.y + resizeGrip.height / 2, resizeGrip.parent.height / 2)
        // Object actions appear only with the pointer over the card.
        keyboardDriver.movePointer(cardWindow, 8, 8)
        tryCompare(actions, "visible", false)
        const bodyPoint = editor.mapToItem(cardWindow.contentItem, 20, 10)
        keyboardDriver.movePointer(cardWindow, bodyPoint.x, bodyPoint.y)
        tryCompare(actions, "visible", true)
        const duplicatePoint = duplicateButton.mapToItem(cardWindow.contentItem, 12, 12)
        keyboardDriver.movePointer(cardWindow, duplicatePoint.x, duplicatePoint.y)
        tryCompare(duplicateButton, "hovered", true)
        tryCompare(actions, "opacity", 1)
        wait(120)
        if (!keyboardDriver.isOffscreen())
            verify(keyboardDriver.capture(cardWindow, "text-card-duplicate-hover.png"))
        compare(deleteButton.hovered, false)
        const deletePoint = deleteButton.mapToItem(cardWindow.contentItem, 12, 12)
        keyboardDriver.movePointer(cardWindow, deletePoint.x, deletePoint.y)
        tryCompare(deleteButton, "hovered", true)
        compare(duplicateButton.hovered, false)
        keyboardDriver.movePointer(cardWindow, 8, 8)
        editor.text = "<p>" + "Texto longo com acentos é útil para verificar a altura. ".repeat(75) + "</p>"
        tryVerify(() => demo.cardHeight > shortHeight)
        compare(resizeGrip.y + resizeGrip.height / 2, resizeGrip.parent.height / 2)
        tryCompare(demo, "overflowsA4", true)
        compare(editor.height, editor.contentHeight)

        demo.reset()
        moveGrip.forceActiveFocus()
        keyboardDriver.keyClick(cardWindow, Qt.Key_Tab)
        tryCompare(editor, "activeFocus", true)
        keyboardDriver.keyClick(cardWindow, Qt.Key_Escape)
        tryCompare(moveGrip, "activeFocus", true)
        compare(demo.selected, true)
        const initialX = demo.cardX
        keyboardDriver.keyClick(cardWindow, Qt.Key_Right)
        tryCompare(demo, "cardX", initialX + 1)
        const initialWidth = demo.cardWidth
        keyboardDriver.keyClick(cardWindow, Qt.Key_Right, Qt.AltModifier)
        tryCompare(demo, "cardWidth", initialWidth + 1)
        compare(demo.fixedWidth, true)
        resizeGrip.forceActiveFocus()
        keyboardDriver.keyClick(cardWindow, Qt.Key_Right, Qt.ShiftModifier)
        tryCompare(demo, "cardWidth", initialWidth + 11)
        moveGrip.forceActiveFocus()
        keyboardDriver.keyClick(cardWindow, Qt.Key_Escape)
        tryCompare(demo, "selected", false)
        compare(moveGrip.visible, false)
        editor.forceActiveFocus()
        tryCompare(demo, "selected", true)

        const beforeDrag = demo.cardX
        mousePress(moveGrip, 16, 16)
        mouseMove(moveGrip, 48, 16)
        mouseRelease(moveGrip, 48, 16)
        tryVerify(() => demo.cardX > beforeDrag + 15)
        const beforeResize = demo.cardWidth
        mousePress(resizeGrip, 16, 20)
        mouseMove(resizeGrip, 48, 20)
        mouseRelease(resizeGrip, 48, 20)
        tryVerify(() => demo.cardWidth > beforeResize + 15)
        // A plain click is not a move; Esc during a drag restores the origin.
        const beforeClick = demo.cardX
        mousePress(moveGrip, 16, 16)
        mouseRelease(moveGrip, 16, 16)
        compare(demo.cardX, beforeClick)
        mousePress(moveGrip, 16, 16)
        mouseMove(moveGrip, 60, 16)
        tryVerify(() => demo.cardX > beforeClick + 15)
        compare(actions.present, false)
        keyboardDriver.keyClick(cardWindow, Qt.Key_Escape)
        tryCompare(demo, "cardX", beforeClick)
        mouseRelease(moveGrip, 60, 16)
        compare(demo.cardX, beforeClick)

        demo.setExample("long")
        demo.cardY = 330
        tryCompare(demo, "overflowsA4", true)
        if (!keyboardDriver.isOffscreen()) {
            keyboardDriver.movePointer(cardWindow, cardWindow.width - 12, 88)
            wait(100)
            verify(keyboardDriver.capture(cardWindow, "text-card-gallery-dark.png"))
            Theme.dark = false
            wait(100)
            verify(keyboardDriver.capture(cardWindow, "text-card-gallery-light.png"))
            Theme.dark = true
            const widthHandle = resizeGrip.mapToItem(cardWindow.contentItem, 16, 20)
            keyboardDriver.movePointer(cardWindow, widthHandle.x, widthHandle.y)
            wait(700)
            verify(keyboardDriver.capture(cardWindow, "text-card-width-tooltip.png"))
        }

        demo.width = 360
        tryVerify(() => demo.cardX + demo.cardWidth + demo.pageMargin <= paper.width + 0.1)
        cardWindow.destroy()
    }
}
