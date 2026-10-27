import QtQuick
import QtQuick.Controls

// E4 composition experiment and the opt-in persisted model slice.
Item {
    id: root
    property string pageId: ""
    property bool penEnabled: false
    property bool textEnabled: false
    property bool persistent: false
    // View zoom of the page scene; card handles counter-scale by it.
    property real viewScale: 1
    readonly property color paperColor: Theme.paper.warm
    // The ink fringe is computed in device pixels, so redraw it on zoom.
    onViewScaleChanged: ink.update()
    property bool infiniteCanvas: persistent && editorModel && editorModel.infiniteCanvas
    property var editorModel: null
    property bool loading: false
    property bool inkLoadFailed: false
    property string selectedCardId: ""
    readonly property var activeTextCard: {
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && card.cardData.id === selectedCardId) return card
        }
        return null
    }
    readonly property bool editingText: activeTextCard !== null && activeTextCard.editorItem.activeFocus
    // Object commands only act when focus is on the card's handles or the
    // paper, never while a toolbar field or the text body takes the keys.
    readonly property bool objectFocus: activeTextCard !== null &&
        (activeTextCard.moveHandle.activeFocus || activeTextCard.resizeHandle.activeFocus || activeFocus)
    readonly property bool dirty: {
        if (!persistent || !editorModel) return false
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && card.dirty) return true
        }
        return false
    }
    readonly property int strokeCount: ink.strokeCount
    readonly property int pointCount: ink.pointCount
    readonly property real maxCardBottom: {
        let bottom = height
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card) bottom = Math.max(bottom, card.y + card.height)
        }
        return bottom
    }
    readonly property real contentExtentBottom: {
        let bottom = 0
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card) bottom = Math.max(bottom, card.y + card.height)
        }
        return bottom
    }
    readonly property real contentExtentRight: {
        let right = 0
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card) right = Math.max(right, card.x + card.width)
        }
        return right
    }

    function reset() {
        ink.clear()
        firstText.text = "Texto editável 1 — clique aqui e escreva."
        secondText.text = "Texto editável 2 — tinta pode cruzar estas palavras."
    }

    function loadFromModel() {
        if (!persistent || !editorModel || editorModel.pageId !== pageId) return
        loading = true
        inkLoadFailed = !ink.loadStrokes(editorModel.inkStrokes)
        loading = false
    }

    // Commits pending typing of every card as history entries.
    function saveTexts() {
        if (!persistent || !editorModel || !editorModel.demoEnabled) return true
        let saved = true
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && !card.save()) saved = false
        }
        return saved
    }

    function cardById(id) {
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (card && card.cardData.id === id) return card
        }
        return null
    }

    // Undo and redo select what they changed and give back its caret.
    function restoreSelection(id, selection) {
        const card = id === "" ? null : cardById(id)
        if (!card) {
            selectedCardId = ""
            root.forceActiveFocus()
            return
        }
        selectedCardId = id
        const caret = /^caret:(\d+):(\d+)$/.exec(selection)
        if (caret) card.restoreCaret(Number(caret[1]), Number(caret[2]))
        else card.moveHandle.forceActiveFocus()
    }

    function duplicateCard(card) {
        if (!card.save()) return
        const id = editorModel.duplicateText(card.cardData.id)
        if (id === "") return
        selectedCardId = id
        const copy = cardById(id)
        if (copy) copy.moveHandle.forceActiveFocus()
    }

    function deleteCard(card) {
        if (!card.save()) return
        if (editorModel.deleteText(card.cardData.id)) {
            selectedCardId = ""
            root.forceActiveFocus()
        }
    }

    onPageIdChanged: {
        selectedCardId = ""
        if (persistent) Qt.callLater(loadFromModel)
        else reset()
    }
    onPersistentChanged: if (persistent) Qt.callLater(loadFromModel)
    onVisibleChanged: if (!visible) ink.cancelStroke()
    Connections {
        target: root.persistent ? root.editorModel : null
        function onPageLoaded() { Qt.callLater(root.loadFromModel) }
        function onFlushRequested() { root.saveTexts() }
        function onHistoryApplied(objectId, selection, undone) { root.restoreSelection(objectId, selection) }
    }
    Shortcut { sequence: "Ctrl+S"; enabled: root.persistent && root.visible; onActivated: root.saveTexts() }
    // While a text body has focus the card handles these keys itself.
    Shortcut {
        sequences: [StandardKey.Undo]
        enabled: root.persistent && root.visible && !root.editingText
        onActivated: root.editorModel.undo()
    }
    Shortcut {
        sequences: Qt.platform.os === "windows" ? [StandardKey.Redo] : [StandardKey.Redo, "Ctrl+Y"]
        enabled: root.persistent && root.visible && !root.editingText
        onActivated: root.editorModel.redo()
    }
    Shortcut {
        sequence: "Ctrl+D"
        enabled: root.persistent && root.visible && root.objectFocus
        onActivated: root.duplicateCard(root.activeTextCard)
    }
    Shortcut {
        sequences: [StandardKey.Delete, "Backspace"]
        enabled: root.persistent && root.visible && root.objectFocus
        onActivated: root.deleteCard(root.activeTextCard)
    }

    Rectangle {
        anchors.fill: parent
        color: root.paperColor
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.persistent && root.textEnabled && root.editorModel && root.editorModel.demoEnabled
        z: 0
        cursorShape: Qt.IBeamCursor
        onClicked: mouse => {
            if (!root.saveTexts()) return
            const id = root.editorModel.createTextAt(mouse.x * 3 / 4, mouse.y * 3 / 4)
            if (id !== "") Qt.callLater(() => {
                for (let i = 0; i < cards.count; ++i) {
                    const card = cards.itemAt(i)
                    if (card && card.cardData.id === id) {
                        card.editorItem.forceActiveFocus()
                        break
                    }
                }
            })
        }
    }

    Text {
        x: 48
        y: 38
        width: parent.width - 96
        text: root.persistent ? "Prova do editor — texto e tinta no caderno" :
                                "Prova do editor — texto e tinta temporários"
        color: Theme.paper.text
        font.family: Theme.paperFont
        font.pixelSize: 22
        font.weight: Font.Medium
    }
    Text {
        x: 48
        y: 76
        width: parent.width - 96
        text: root.persistent ? "Texto: clique no papel para criar; arraste a alça para mover; ajuste pela direita. Ctrl+S salva o texto." :
                                "Selecione Texto para editar; selecione Caneta para desenhar. Nada é salvo nesta prova."
        wrapMode: Text.WordWrap
        color: Theme.paper.textSecondary
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
    }

    Rectangle {
        visible: !root.persistent
        x: 48
        y: 148
        width: root.persistent ? Math.min(parent.width - 96, 320) : parent.width - 96
        height: 142
        radius: Theme.radius.sm
        color: "transparent"
        border.width: firstText.activeFocus ? 2 : 1
        border.color: firstText.activeFocus ? Theme.color.focus : Theme.paper.rule
        TextEdit {
            id: firstText
            objectName: "editorProbeText1"
            anchors.fill: parent
            anchors.margins: 12
            text: root.persistent ? "" : "Texto editável 1 — clique aqui e escreva."
            textFormat: root.persistent ? TextEdit.PlainText : TextEdit.RichText
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            activeFocusOnTab: true
            color: Theme.paper.text
            font.family: Theme.paperFont
            font.pixelSize: 20
            Accessible.name: "Primeira caixa de texto"
        }
        Text {
            anchors.left: firstText.left
            anchors.top: firstText.top
            visible: root.persistent && firstText.text.length === 0 && !firstText.activeFocus
            text: "Primeira caixa de texto"
            color: Theme.color.textTertiary
            font: firstText.font
        }
    }
    Rectangle {
        visible: !root.persistent
        x: 48
        y: 332
        width: root.persistent ? Math.min(parent.width - 96, 320) : parent.width - 96
        height: 142
        radius: Theme.radius.sm
        color: "transparent"
        border.width: secondText.activeFocus ? 2 : 1
        border.color: secondText.activeFocus ? Theme.color.focus : Theme.paper.rule
        TextEdit {
            id: secondText
            objectName: "editorProbeText2"
            anchors.fill: parent
            anchors.margins: 12
            text: root.persistent ? "" : "Texto editável 2 — tinta pode cruzar estas palavras."
            textFormat: root.persistent ? TextEdit.PlainText : TextEdit.RichText
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            activeFocusOnTab: true
            color: Theme.paper.text
            font.family: Theme.paperFont
            font.pixelSize: 20
            Accessible.name: "Segunda caixa de texto"
        }
        Text {
            anchors.left: secondText.left
            anchors.top: secondText.top
            visible: root.persistent && secondText.text.length === 0 && !secondText.activeFocus
            text: "Segunda caixa de texto"
            color: Theme.color.textTertiary
            font: secondText.font
        }
    }

    ActionButton {
        objectName: "editorModelSaveTexts"
        x: 48
        y: 112
        visible: root.persistent
        enabled: root.dirty && root.editorModel && root.editorModel.demoEnabled
        text: "Salvar textos"
        onClicked: root.saveTexts()
    }
    Text {
        x: 48
        y: 552
        width: parent.width - 96
        visible: root.persistent
        text: root.inkLoadFailed ? "Alguns traços não puderam ser exibidos nesta prova." :
              root.editorModel && root.editorModel.error !== "" ? root.editorModel.error :
              root.dirty ? "Editando…" : "Alterações salvas."
        color: root.inkLoadFailed || root.editorModel && root.editorModel.error !== ""
               ? Theme.color.danger : Theme.color.textSecondary
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
    }

    Repeater {
        id: cards
        objectName: "editorTextCards"
        model: root.persistent && root.editorModel ? root.editorModel.textCardModel : []
        delegate: EditorTextCard {
            editorModel: root.editorModel
            selectionOwner: root
        }
    }

    InkProbeItem {
        id: ink
        objectName: "editorProbeInk"
        anchors.fill: parent
        z: 2
        onStrokeFinished: points => {
            if (root.persistent && root.editorModel && !root.editorModel.addInk(points))
                ink.loadStrokes(root.editorModel.inkStrokes)
        }
    }
    MouseArea {
        id: penSurface
        objectName: "editorProbePenSurface"
        x: 0
        y: 120
        width: parent.width
        height: parent.height - y
        z: 3
        enabled: root.penEnabled
        cursorShape: Qt.CrossCursor
        preventStealing: true
        onPressed: mouse => ink.beginStroke(mouse.x, mouse.y + penSurface.y)
        onPositionChanged: mouse => {
            if (pressed) ink.appendPoint(mouse.x, mouse.y + penSurface.y)
        }
        onReleased: ink.endStroke()
        onCanceled: ink.cancelStroke()
    }
}
