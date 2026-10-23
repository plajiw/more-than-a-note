import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T

Popup {
    id: root
    property string kind: "page"
    property string itemTitle: ""
    property color currentColor: Theme.color.accent
    property var returnFocusItem: null
    signal renameRequested()
    signal colorRequested(string value)
    signal deleteRequested()

    popupType: Popup.Window
    width: 244
    padding: Theme.space.sm
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    focus: true
    onOpened: renameAction.forceActiveFocus()
    onClosed: if (returnFocusItem) returnFocusItem.forceActiveFocus()

    background: Rectangle {
        radius: Theme.radius.md
        color: Theme.color.overlay
        border.width: 1
        border.color: Theme.color.border
    }
    contentItem: Column {
        spacing: Theme.space.xs
        Text {
            width: parent.width - Theme.space.sm * 2
            x: Theme.space.sm
            height: 28
            verticalAlignment: Text.AlignVCenter
            text: root.itemTitle
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.type.caption.size
            font.weight: Font.DemiBold
            color: Theme.color.textSecondary
        }
        Rectangle { width: parent.width; height: 1; color: Theme.color.borderSubtle }
        IndexMenuAction {
            id: renameAction
            width: parent.width
            text: "Renomear"
            onClicked: { root.returnFocusItem = null; root.close(); root.renameRequested() }
        }
        Column {
            visible: root.kind === "section"
            spacing: Theme.space.xs
            Text {
                text: "COR DA SEÇÃO"
                leftPadding: Theme.space.sm
                topPadding: Theme.space.sm
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.overline.size
                font.weight: Theme.type.overline.weight
                color: Theme.color.textTertiary
            }
            Row {
                x: Theme.space.xs
                spacing: Theme.space.xxs
                Repeater {
                    model: [
                        { name: "Âmbar", hex: "#C58E61" },
                        { name: "Vermelho", hex: "#BF6B67" },
                        { name: "Dourado", hex: "#B99B56" },
                        { name: "Verde", hex: "#709A76" },
                        { name: "Azul", hex: "#6A91B8" },
                        { name: "Violeta", hex: "#967DB0" }
                    ]
                    ToolColorSwatch {
                        required property var modelData
                        slot: 0
                        inkColor: modelData.hex
                        colorName: modelData.name
                        selected: root.currentColor.toString().toUpperCase() === modelData.hex
                        onClicked: { root.close(); root.colorRequested(modelData.hex) }
                    }
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.color.borderSubtle }
        IndexMenuAction {
            width: parent.width
            text: root.kind === "section" ? "Excluir seção…" : "Excluir página…"
            danger: true
            onClicked: { root.returnFocusItem = null; root.close(); root.deleteRequested() }
        }
    }
}
