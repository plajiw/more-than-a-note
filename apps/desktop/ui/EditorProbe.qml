import QtQuick
import QtQuick.Controls

// E4 composition experiment. Text and ink are deliberately temporary here.
Item {
    id: root
    property string pageId: ""
    property bool penEnabled: false
    readonly property int strokeCount: ink.strokeCount
    readonly property int pointCount: ink.pointCount

    function reset() {
        ink.clear()
        firstText.text = "Texto editável 1 — clique aqui e escreva."
        secondText.text = "Texto editável 2 — tinta pode cruzar estas palavras."
    }

    onPageIdChanged: reset()
    onVisibleChanged: if (!visible) ink.cancelStroke()

    Rectangle {
        anchors.fill: parent
        color: Theme.paper.warm
    }

    Text {
        x: 48
        y: 38
        width: parent.width - 96
        text: "Prova do editor — texto e tinta temporários"
        color: Theme.paper.text
        font.family: Theme.paperFont
        font.pixelSize: 22
        font.weight: Font.Medium
    }
    Text {
        x: 48
        y: 76
        width: parent.width - 96
        text: "Selecione Texto para editar; selecione Caneta para desenhar. Nada é salvo nesta prova."
        wrapMode: Text.WordWrap
        color: Theme.color.textSecondary
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.caption.size
    }

    Rectangle {
        x: 48
        y: 148
        width: parent.width - 96
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
            text: "Texto editável 1 — clique aqui e escreva."
            textFormat: TextEdit.RichText
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            activeFocusOnTab: true
            color: Theme.paper.text
            font.family: Theme.paperFont
            font.pixelSize: 20
            Accessible.name: "Primeira caixa de texto"
        }
    }
    Rectangle {
        x: 48
        y: 332
        width: parent.width - 96
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
            text: "Texto editável 2 — tinta pode cruzar estas palavras."
            textFormat: TextEdit.RichText
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            activeFocusOnTab: true
            color: Theme.paper.text
            font.family: Theme.paperFont
            font.pixelSize: 20
            Accessible.name: "Segunda caixa de texto"
        }
    }

    InkProbeItem {
        id: ink
        objectName: "editorProbeInk"
        anchors.fill: parent
        z: 2
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
