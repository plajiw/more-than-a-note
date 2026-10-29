import QtQuick
import QtTest
import MoreThanANote

// Shared base for tests that drive the main window. Each tst_*.qml file gets
// its own profile (workspace_quick_tests.cpp); within a file, init() returns
// to the Library and every editor test works on pages of its own, so test
// functions never depend on the order they run in.
TestCase {
    when: windowShown

    property var app
    property int pageSerial: 0

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
        inputDriver.keyClick(app, key, modifiers || 0)
    }

    // QML errors fail the test instead of scrolling past in the log.
    function failOnQmlErrors() {
        failOnWarning(/TypeError|ReferenceError|Binding loop|is not a function|Cannot read propert|Unable to assign|Cannot assign/)
    }

    // Opens the test notebook on `count` new, empty pages and selects the first.
    function openFreshPages(count) {
        verify(notebookStore.openNotebook(notebookId("Caderno de teste")))
        verify(notebookStore.selectSection(notebookStore.sections[0].id))
        const created = []
        for (let i = 0; i < count; ++i) {
            const title = "Teste " + (++pageSerial)
            verify(notebookStore.addPage(title))
            const page = notebookStore.pages.find(item => item.title === title)
            verify(page !== undefined, "Página de teste ausente: " + title)
            created.push(page)
        }
        verify(notebookStore.selectPage(created[0].id))
        tryCompare(pageEditorAdapter, "pageId", created[0].id)
        tryVerify(() => findChild(app.contentItem, "editorProbe").visible)
        waitForRendering(app.contentItem)
        return created
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
    }

    function init() {
        failOnQmlErrors()
        notebookStore.closeNotebook()
        Theme.dark = true
        app.pageZoom = 1
        app.width = 1100
        tryCompare(app, "narrowWorkspace", false)
        app.requestActivate()
        tryCompare(app, "active", true)
    }
}
