import QtQuick
import QtQuick.Templates as T

// Notebook row in the Library (docs/13 §6.3): 56 px, book-spine cover with the
// title's initial, title and quiet metadata. Hover `raised`, current `hover`,
// keyboard focus ring only. Actions live in the context menu and on keys.
T.AbstractButton {
    id: control

    property string title
    property int sectionCount: 0
    property int pageCount: 0
    property var modified
    property color coverColor: "#C58E61"
    property bool current: false

    signal navigationRequested(int key)
    signal menuRequested(real x, real y)
    signal renameRequested()
    signal deleteRequested()

    readonly property bool showActions: hovered || current || visualFocus
    readonly property string metadata: {
        const parts = [plural(sectionCount, "seção", "seções"), plural(pageCount, "página", "páginas")]
        const when = describeDate(modified)
        if (when !== "") parts.push(when)
        return parts.join(" · ")
    }

    function plural(n, one, many) { return n + " " + (n === 1 ? one : many) }
    // Activity, not only edits: the date comes from the notebook file.
    function describeDate(value) {
        if (!value || isNaN(value.getTime())) return ""
        const now = new Date()
        const day = new Date(value.getFullYear(), value.getMonth(), value.getDate())
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const days = Math.round((today - day) / 86400000)
        if (days === 0) return "atividade hoje, " + Qt.formatTime(value, "HH:mm")
        if (days === 1) return "atividade ontem"
        return "atividade em " + Qt.locale("pt_BR").toString(value, "d MMM")
    }
    function contrastOn(c) {
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        const l = 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
        return (1.05 / (l + 0.05)) >= ((l + 0.05) / 0.074) ? "#FFFFFF" : Theme.paper.text
    }

    implicitHeight: Theme.size.libraryRow
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    Accessible.role: Accessible.ListItem
    Accessible.name: title
    Accessible.description: "Caderno, " + metadata
    Accessible.selectable: true
    Accessible.selected: current

    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onSpacePressed: clicked()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_Home || event.key === Qt.Key_End
                || event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
            navigationRequested(event.key); event.accepted = true
        } else if (event.key === Qt.Key_F2) {
            renameRequested(); event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
            deleteRequested(); event.accepted = true
        } else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
            menuRequested(Theme.space.lg, height); event.accepted = true
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: point => control.menuRequested(point.position.x, point.position.y)
    }

    contentItem: Item {
        Rectangle {
            id: cover
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.space.md
            width: 32; height: 40
            radius: Theme.radius.xs
            color: control.coverColor
            border.width: 1
            border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.15)
            Accessible.ignored: true
            Rectangle {
                x: 1; y: 1
                width: 4; height: parent.height - 2
                radius: 1
                color: Qt.darker(control.coverColor, 1.25)
            }
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 2
                text: control.title.trim().charAt(0).toUpperCase()
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.titleSm.size
                font.weight: Font.DemiBold
                color: control.contrastOn(control.coverColor)
            }
        }
        Column {
            anchors.left: cover.right
            anchors.leftMargin: Theme.space.md
            anchors.right: menuButton.left
            anchors.rightMargin: Theme.space.sm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space.xxs
            Text {
                id: titleLabel
                width: parent.width
                text: control.title
                elide: Text.ElideRight
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.titleSm.size - 1
                font.weight: Font.DemiBold
                color: Theme.color.textPrimary
            }
            Text {
                width: parent.width
                text: control.metadata
                elide: Text.ElideRight
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.caption.size
                font.features: { "tnum": 1 }
                color: Theme.color.textTertiary
            }
        }
        IconButton {
            id: menuButton
            anchors.right: parent.right
            anchors.rightMargin: Theme.space.sm
            anchors.verticalCenter: parent.verticalCenter
            size: Theme.size.controlXs
            iconName: "settings"
            toolTip: "Opções do caderno"
            focusPolicy: Qt.NoFocus
            opacity: control.showActions ? 1 : 0
            enabled: control.showActions
            Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
            onClicked: control.menuRequested(x, y + height)
        }
    }

    background: Rectangle {
        radius: Theme.radius.sm
        color: control.down ? Theme.color.pressed
             : control.current ? Theme.color.hover
             : control.hovered ? Theme.color.raised : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
        FocusRing { visible: control.visualFocus; controlRadius: Theme.radius.sm }
    }

    HintToolTip {
        text: control.title
        visible: control.hovered && titleLabel.truncated
        delay: 600
    }
}
