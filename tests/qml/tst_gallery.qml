import QtQuick
import QtTest
import MoreThanANote

// The gallery is the product owner's validation environment: every section
// must open in both themes without QML errors, and the text-card study must
// keep the approved geometry.
TestCase {
    name: "Gallery"
    when: windowShown

    Component { id: galleryComponent; Gallery {} }
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

    function init() {
        failOnWarning(/TypeError|ReferenceError|Binding loop|is not a function|Cannot read propert|Unable to assign|Cannot assign/)
        Theme.dark = true
    }

    function test_every_section_opens_in_both_themes() {
        const gallery = galleryComponent.createObject(null)
        verify(gallery !== null)
        gallery.visible = true
        tryVerify(() => gallery.visible)
        compare(gallery.sections.length, 10)
        for (const dark of [true, false]) {
            Theme.dark = dark
            for (const section of gallery.sections) {
                verify(gallery.goTo(section.sectionId), "Seção sem destino: " + section.sectionId)
                compare(gallery.currentSection, section.sectionId)
                wait(30)
                verify(inputDriver.capture(gallery, "gallery-" + section.sectionId + "-" + (dark ? "graphite" : "light") + ".png"))
            }
        }
        ignoreWarning(/seção desconhecida/)
        verify(!gallery.goTo("inexistente"))
        Theme.dark = true
        gallery.destroy()
        wait(50)
    }

    function test_text_card_geometry() {
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
        verify(inputDriver.capture(cardWindow, "text-card-short-controls.png"))
        verify(actions.y + actions.height <= editor.y)
        compare(resizeGrip.y + resizeGrip.height / 2, resizeGrip.parent.height / 2)
        // Object actions appear only with the pointer over the card.
        inputDriver.movePointer(cardWindow, 8, 8)
        tryCompare(actions, "visible", false)
        const bodyPoint = editor.mapToItem(cardWindow.contentItem, 20, 10)
        inputDriver.movePointer(cardWindow, bodyPoint.x, bodyPoint.y)
        tryCompare(actions, "visible", true)
        const duplicatePoint = duplicateButton.mapToItem(cardWindow.contentItem, 12, 12)
        inputDriver.movePointer(cardWindow, duplicatePoint.x, duplicatePoint.y)
        tryCompare(duplicateButton, "hovered", true)
        tryCompare(actions, "opacity", 1)
        wait(120)
        verify(inputDriver.capture(cardWindow, "text-card-duplicate-hover.png"))
        compare(deleteButton.hovered, false)
        const deletePoint = deleteButton.mapToItem(cardWindow.contentItem, 12, 12)
        inputDriver.movePointer(cardWindow, deletePoint.x, deletePoint.y)
        tryCompare(deleteButton, "hovered", true)
        compare(duplicateButton.hovered, false)
        inputDriver.movePointer(cardWindow, 8, 8)
        editor.text = "<p>" + "Texto longo com acentos é útil para verificar a altura. ".repeat(75) + "</p>"
        tryVerify(() => demo.cardHeight > shortHeight)
        compare(resizeGrip.y + resizeGrip.height / 2, resizeGrip.parent.height / 2)
        tryCompare(demo, "overflowsA4", true)
        compare(editor.height, editor.contentHeight)

        demo.reset()
        moveGrip.forceActiveFocus()
        inputDriver.keyClick(cardWindow, Qt.Key_Tab)
        tryCompare(editor, "activeFocus", true)
        inputDriver.keyClick(cardWindow, Qt.Key_Escape)
        tryCompare(moveGrip, "activeFocus", true)
        compare(demo.selected, true)
        const initialX = demo.cardX
        inputDriver.keyClick(cardWindow, Qt.Key_Right)
        tryCompare(demo, "cardX", initialX + 1)
        const initialWidth = demo.cardWidth
        inputDriver.keyClick(cardWindow, Qt.Key_Right, Qt.AltModifier)
        tryCompare(demo, "cardWidth", initialWidth + 1)
        compare(demo.fixedWidth, true)
        resizeGrip.forceActiveFocus()
        inputDriver.keyClick(cardWindow, Qt.Key_Right, Qt.ShiftModifier)
        tryCompare(demo, "cardWidth", initialWidth + 11)
        moveGrip.forceActiveFocus()
        inputDriver.keyClick(cardWindow, Qt.Key_Escape)
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
        inputDriver.keyClick(cardWindow, Qt.Key_Escape)
        tryCompare(demo, "cardX", beforeClick)
        mouseRelease(moveGrip, 60, 16)
        compare(demo.cardX, beforeClick)

        demo.setExample("long")
        demo.cardY = 330
        tryCompare(demo, "overflowsA4", true)
        inputDriver.movePointer(cardWindow, cardWindow.width - 12, 88)
        wait(100)
        verify(inputDriver.capture(cardWindow, "text-card-gallery-graphite.png"))
        Theme.dark = false
        wait(100)
        verify(inputDriver.capture(cardWindow, "text-card-gallery-light.png"))
        Theme.dark = true
        const widthHandle = resizeGrip.mapToItem(cardWindow.contentItem, 16, 20)
        inputDriver.movePointer(cardWindow, widthHandle.x, widthHandle.y)
        wait(700)
        verify(inputDriver.capture(cardWindow, "text-card-width-tooltip.png"))

        demo.width = 360
        tryVerify(() => demo.cardX + demo.cardWidth + demo.pageMargin <= paper.width + 0.1)
        cardWindow.destroy()
    }
}
