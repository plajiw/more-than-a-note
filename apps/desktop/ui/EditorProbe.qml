import QtQuick
import QtQuick.Controls

// E4 composition experiment and the opt-in persisted model slice.
Item {
    id: root
    property string pageId: ""
    property bool penEnabled: false
    property bool persistent: false
    property var editorModel: null
    property bool loading: false
    property bool inkLoadFailed: false
    readonly property bool dirty: persistent && editorModel &&
                                  (firstText.text !== editorModel.text1 || secondText.text !== editorModel.text2)
    readonly property int strokeCount: ink.strokeCount
    readonly property int pointCount: ink.pointCount

    function reset() {
        ink.clear()
        firstText.text = "Texto editável 1 — clique aqui e escreva."
        secondText.text = "Texto editável 2 — tinta pode cruzar estas palavras."
    }

    function loadFromModel() {
        if (!persistent || !editorModel || editorModel.pageId !== pageId) return
        loading = true
        firstText.text = editorModel.text1
        secondText.text = editorModel.text2
        inkLoadFailed = !ink.loadStrokes(editorModel.inkStrokes)
        loading = false
    }

    function saveTexts() {
        if (!persistent || !editorModel || !editorModel.demoEnabled) return
        if (editorModel.saveText(0, firstText.text))
            editorModel.saveText(1, secondText.text)
    }

    onPageIdChanged: persistent ? Qt.callLater(loadFromModel) : reset()
    onPersistentChanged: if (persistent) Qt.callLater(loadFromModel)
    onVisibleChanged: if (!visible) ink.cancelStroke()
    Connections {
        target: root.persistent ? root.editorModel : null
        function onPageLoaded() { Qt.callLater(root.loadFromModel) }
    }
    Shortcut { sequence: "Ctrl+S"; enabled: root.persistent && root.visible; onActivated: root.saveTexts() }

    Rectangle {
        anchors.fill: parent
        color: Theme.paper.warm
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
        text: root.persistent ? "Salve os textos com Ctrl+S; cada traço é salvo ao levantar a caneta." :
                                "Selecione Texto para editar; selecione Caneta para desenhar. Nada é salvo nesta prova."
        wrapMode: Text.WordWrap
        color: Theme.color.textSecondary
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
    }

    Rectangle {
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
        y: 498
        visible: root.persistent
        enabled: root.dirty && root.editorModel && root.editorModel.demoEnabled
        text: "Salvar textos"
        onClicked: root.saveTexts()
    }
    Text {
        x: 48
        y: 550
        width: parent.width - 96
        visible: root.persistent
        text: root.inkLoadFailed ? "Alguns traços não puderam ser exibidos nesta prova." :
              root.editorModel && root.editorModel.error !== "" ? root.editorModel.error :
              root.dirty ? "Texto alterado; salve antes de trocar de página." : "Alterações salvas."
        color: root.inkLoadFailed || root.editorModel && root.editorModel.error !== ""
               ? Theme.color.danger : Theme.color.textSecondary
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
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
