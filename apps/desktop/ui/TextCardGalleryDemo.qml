import QtQuick
import QtQuick.Controls

// Interactive geometry and rich-text composition study. This is gallery-only:
// persisted page coordinates, formatting commands and the final text renderer
// are handled by the E4 editor work, not by this sample.
Item {
    id: root
    objectName: "textCardGalleryDemo"
    implicitHeight: 620

    property real cardX: 52
    property real cardY: 76
    property real cardWidth: 320
    property bool fixedWidth: false
    property bool selected: true
    property bool gripCentered: false
    readonly property real cardHeight: card.height
    readonly property bool overflowsA4: cardY + cardHeight > paper.height
    readonly property real minCardWidth: 160
    readonly property real pageMargin: 24

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(value, maximum))
    }

    function keepInsideWidth() {
        const available = Math.max(minCardWidth, canvas.width - pageMargin * 2)
        cardWidth = Math.min(cardWidth, available)
        cardX = clamp(cardX, pageMargin, Math.max(pageMargin, canvas.width - cardWidth - pageMargin))
    }

    function moveBy(dx, dy) {
        cardX = clamp(cardX + dx, pageMargin,
                      Math.max(pageMargin, canvas.width - cardWidth - pageMargin))
        cardY = Math.max(pageMargin, cardY + dy)
        selected = true
    }

    function resizeBy(dx) {
        cardWidth = clamp(cardWidth + dx, minCardWidth,
                          Math.max(minCardWidth, canvas.width - cardX - pageMargin))
        fixedWidth = true
        selected = true
    }

    function setExample(kind) {
        if (kind === "short") {
            editor.text = "<p>Uma ideia começa aqui.</p>"
        } else if (kind === "long") {
            editor.text = "<p>Este texto cresce para baixo sem criar uma barra de rolagem dentro da caixa. " +
                          "A borda inferior do A4 continua visível para que você perceba quando o conteúdo passa dela.</p>" +
                          "<p>É possível mover a caixa pela alça superior e mudar a largura pela direita. " +
                          "Ao estreitar a caixa, as linhas se reorganizam e a altura aumenta.</p>" +
                          "<p>O texto é um objeto independente. Ele não é enviado automaticamente para outra página. " +
                          "Você pode ajustar a posição, a largura ou criar outra caixa para continuar.</p>" +
                          "<p>Mais conteúdo para testar a borda do papel e a área externa de trabalho. " +
                          "Nada deve desaparecer só porque a caixa ultrapassou o A4.</p>"
        } else {
            editor.text = "<p><span style='font-family:IBM Plex Serif; font-size:20px'>Uma caixa de texto livre</span></p>" +
                          "<p><span style='font-family:Inter; font-size:16px'>Fonte diferente, " +
                          "<b>negrito</b>, <i>itálico</i> e <u>sublinhado</u> no mesmo objeto.</span></p>" +
                          "<p><span style='font-family:JetBrains Mono; font-size:14px'>const ideia = \"editável\";</span></p>"
        }
        selected = true
    }

    function reset() {
        cardX = 52
        cardY = 76
        cardWidth = Math.min(320, Math.max(minCardWidth, canvas.width - pageMargin * 2))
        fixedWidth = false
        selected = true
        setExample("rich")
    }

    Row {
        id: choices
        spacing: 8
        ActionButton { objectName: "textCardShort"; text: "Curto"; onClicked: root.setExample("short") }
        ActionButton { objectName: "textCardLong"; text: "Longo"; onClicked: root.setExample("long") }
        ActionButton { objectName: "textCardRich"; text: "Formatado"; onClicked: root.setExample("rich") }
        ActionButton { objectName: "textCardReset"; text: "Restaurar"; onClicked: root.reset() }
        ActionButton {
            objectName: "textCardGripPlacement"
            text: root.gripCentered ? "Alça: centro" : "Alça: esquerda"
            onClicked: root.gripCentered = !root.gripCentered
        }
    }

    Text {
        x: 0
        y: choices.height + 8
        width: parent.width
        text: "Arraste pela alça superior · ajuste pela direita · clique no texto para editar · setas movem; Alt+setas ajustam a largura."
        wrapMode: Text.WordWrap
        color: Theme.color.textSecondary
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
    }

    Flickable {
        id: viewport
        objectName: "textCardViewport"
        y: 82
        width: parent.width
        height: parent.height - y - 36
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, root.cardY + root.cardHeight + 90)
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ThinScrollBar {}

        Item {
            id: canvas
            width: Math.min(viewport.width - 24, 740)
            height: viewport.contentHeight
            x: Math.max(0, (viewport.width - width) / 2)
            onWidthChanged: if (width > 0) root.keepInsideWidth()

            Rectangle {
                anchors.fill: parent
                color: Theme.paper.pasteboard
            }
            Rectangle {
                id: paper
                objectName: "textCardPaper"
                width: parent.width
                height: 470
                color: Theme.paper.white
                border.width: 1
                border.color: Theme.paper.rule
            }
            Rectangle {
                y: paper.height
                width: parent.width
                height: 1
                color: Theme.paper.selection
            }
            Text {
                x: paper.width - width - 12
                y: paper.height + 7
                text: "FIM DO A4"
                color: Theme.paper.selection
                font.family: Theme.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
                Accessible.ignored: true
            }
            Rectangle {
                id: card
                objectName: "textCardSample"
                x: root.cardX
                y: root.cardY
                width: root.cardWidth
                height: Math.max(48, editor.contentHeight + 24)
                radius: Theme.radius.island
                color: "transparent"
                border.width: root.selected || editor.activeFocus || cardHover.hovered ? 1 : 0
                border.color: Theme.paper.selection

                // Typing hides the object actions until the pointer moves again.
                property bool typing: false
                HoverHandler { id: cardHover; onPointChanged: card.typing = false }

                TextCardMoveGrip {
                    id: moveGrip
                    objectName: "textCardMoveGrip"
                    x: root.gripCentered ? (card.width - width) / 2 : editor.x
                    y: Theme.size.controlXs / 2 - height
                    z: 4
                    dragSpace: canvas
                    visible: root.selected || cardHover.hovered || activeFocus || containsMouse || pressed
                    property real originX: 0
                    property real originY: 0
                    onPressed: root.selected = true
                    onMoveStarted: {
                        originX = root.cardX
                        originY = root.cardY
                    }
                    onMoveUpdated: (dx, dy) => {
                        root.cardX = root.clamp(originX + dx, root.pageMargin,
                                                Math.max(root.pageMargin, canvas.width - root.cardWidth - root.pageMargin))
                        root.cardY = Math.max(root.pageMargin, originY + dy)
                    }
                    onMoveCanceled: {
                        root.cardX = originX
                        root.cardY = originY
                    }
                    onNudged: (dx, dy) => root.moveBy(dx, dy)
                    onWidthNudged: delta => root.resizeBy(delta)
                    onActivated: editor.forceActiveFocus()
                    onDismissed: {
                        root.selected = false
                        viewport.forceActiveFocus()
                    }
                }

                TextCardActionGroup {
                    id: cardActions
                    // Icons end on the body margin; the gap pads them on both sides.
                    x: editor.x + editor.width - width + Theme.space.xs
                    y: -height / 2
                    z: 4
                    shown: cardHover.hovered || moveGrip.containsMouse || resizeGrip.containsMouse
                    suppressed: moveGrip.dragging || resizeGrip.dragging || card.typing
                }

                TextEdit {
                    id: editor
                    objectName: "textCardEditor"
                    x: 12
                    y: 12
                    width: card.width - 24
                    height: Math.max(32, contentHeight)
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    activeFocusOnTab: true
                    color: Theme.paper.text
                    font.family: Theme.paperFont
                    font.pixelSize: 18
                    onActiveFocusChanged: if (activeFocus) root.selected = true
                    onTextChanged: if (activeFocus) card.typing = true
                    Keys.onEscapePressed: {
                        moveGrip.forceActiveFocus()
                        root.selected = true
                    }
                    Accessible.name: "Texto da caixa móvel"
                }

                TextCardResizeGrip {
                    id: resizeGrip
                    objectName: "textCardResizeGrip"
                    x: card.width - width / 2
                    y: (card.height - height) / 2
                    z: 3
                    dragSpace: canvas
                    visible: root.selected || cardHover.hovered || activeFocus || containsMouse || pressed
                    property real originalWidth: 0
                    onPressed: root.selected = true
                    onResizeStarted: originalWidth = root.cardWidth
                    onResizeUpdated: dx => {
                        root.cardWidth = root.clamp(originalWidth + dx, root.minCardWidth,
                                                    Math.max(root.minCardWidth, canvas.width - root.cardX - root.pageMargin))
                        root.fixedWidth = true
                    }
                    onResizeCanceled: root.cardWidth = originalWidth
                    onNudged: delta => root.resizeBy(delta)
                    onDismissed: moveGrip.forceActiveFocus()
                }
            }
        }
    }

    Text {
        objectName: "textCardGeometryStatus"
        x: 0
        y: parent.height - 26
        width: parent.width
        text: "Posição " + Math.round(root.cardX) + ", " + Math.round(root.cardY) +
              " · largura " + Math.round(root.cardWidth) + " (" + (root.fixedWidth ? "fixa" : "auto") + ")" +
              " · altura " + Math.round(root.cardHeight) +
              (root.overflowsA4 ? " · ultrapassa A4" : " · dentro do A4")
        color: Theme.color.textSecondary
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
        elide: Text.ElideRight
    }

    Component.onCompleted: reset()
}
