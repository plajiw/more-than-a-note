import QtQuick
import QtQuick.Templates as T

T.AbstractButton {
    id: root
    property string kind: "page"
    property string title: ""
    property color sectionColor: Theme.color.accent
    property bool selected: false
    signal settingsRequested()
    signal renameRequested()
    signal colorRequested(string value)
    signal deleteRequested()
    signal navigationRequested(int key)

    function openSettings() {
        menu.returnFocusItem = settingsButton
        menu.open()
        settingsRequested()
    }

    implicitHeight: kind === "section" ? Theme.size.sectionRow : Theme.size.pageRow
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    Accessible.role: Accessible.Button
    Accessible.name: (kind === "section" ? "Seção " : "Página ") + title + (selected ? ", selecionada" : "")
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down ||
            event.key === Qt.Key_Home || event.key === Qt.Key_End) {
            root.navigationRequested(event.key)
            event.accepted = true
        } else if (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)) {
            root.openSettings()
            event.accepted = true
        }
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.openSettings()
    }

    contentItem: Item {
        Icon {
            id: glyph
            anchors.left: parent.left
            anchors.leftMargin: Theme.space.sm
            anchors.verticalCenter: parent.verticalCenter
            name: root.kind === "section" ? "folder" : "page"
            size: Theme.size.iconList
            filled: root.kind === "section" && root.selected
            color: root.kind === "section" ? root.sectionColor
                : root.selected ? Theme.color.textPrimary : Theme.color.textSecondary
        }
        Text {
            anchors.left: glyph.right
            anchors.leftMargin: Theme.space.sm
            anchors.right: actions.left
            anchors.rightMargin: Theme.space.xs
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.type.body.size
            font.weight: root.selected ? Font.Medium : Font.Normal
            color: root.selected ? Theme.color.textPrimary : Theme.color.textSecondary
        }
        Row {
            id: actions
            anchors.right: parent.right
            anchors.rightMargin: Theme.space.xs
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space.xxs
            opacity: root.hovered || root.selected || settingsButton.activeFocus || deleteButton.activeFocus ? 1 : 0
            IconButton {
                id: settingsButton
                size: Theme.size.controlXs
                iconName: "settings"
                toolTip: root.kind === "section" ? "Configurações da seção" : "Configurações da página"
                onClicked: root.openSettings()
            }
            IconButton {
                id: deleteButton
                size: Theme.size.controlXs
                iconName: "delete"
                toolTip: root.kind === "section" ? "Excluir seção" : "Excluir página"
                onClicked: root.deleteRequested()
            }
        }
    }
    background: Rectangle {
        radius: Theme.radius.sm
        color: root.down ? Theme.color.pressed
             : root.selected ? Theme.color.hover
             : root.hovered ? Theme.color.raised : "transparent"
        border.width: root.selected ? 1 : 0
        border.color: Theme.color.borderStrong
        FocusRing { visible: root.visualFocus; controlRadius: Theme.radius.sm }
    }
    HintToolTip {
        text: root.title
        visible: root.hovered && !root.down && root.title.length > 26
    }
    IndexMenu {
        id: menu
        parent: root
        kind: root.kind
        itemTitle: root.title
        currentColor: root.sectionColor
        x: Math.max(0, root.width - width)
        y: root.height + Theme.space.xxs
        onRenameRequested: root.renameRequested()
        onColorRequested: value => root.colorRequested(value)
        onDeleteRequested: root.deleteRequested()
    }
}
