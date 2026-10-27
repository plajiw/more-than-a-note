import QtQuick

// Library message for "no notebooks yet" (query empty) and "no search results".
Column {
    id: root

    property string query: ""
    signal clearRequested()

    readonly property bool searching: query.trim() !== ""

    spacing: Theme.space.sm
    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        name: root.searching ? "search" : "notebook"
        size: root.searching ? 32 : 48
        color: Theme.color.textTertiary
    }
    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.searching ? "Nenhum caderno corresponde a “" + root.query.trim() + "”" : "Nenhum caderno ainda"
        font.family: Theme.uiFont
        font.pixelSize: root.searching ? Theme.type.body.size : Theme.type.title.size
        font.weight: Font.DemiBold
        color: Theme.color.textPrimary
    }
    Text {
        width: parent.width
        visible: !root.searching
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "Os cadernos ficam neste computador. Crie o primeiro para organizar seções e páginas."
        font.family: Theme.uiFont
        font.pixelSize: Theme.type.body.size
        color: Theme.color.textSecondary
    }
    ActionButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.searching
        variant: "subtle"
        text: "Limpar busca"
        onClicked: root.clearRequested()
    }
}
