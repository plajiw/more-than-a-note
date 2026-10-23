import QtQuick
import QtQuick.Templates as T

// Single-choice list for page and application settings.
T.ComboBox {
    id: control

    property string previewState: ""
    readonly property bool showHover: previewState === "hover" || hovered
    readonly property bool showPressed: previewState === "pressed" || down
    readonly property bool showFocus: previewState === "focus" || visualFocus

    implicitWidth: 160
    implicitHeight: Theme.size.controlMd
    leftPadding: Theme.space.md - 2
    rightPadding: Theme.space.sm
    focusPolicy: Qt.TabFocus
    hoverEnabled: true
    font.family: Theme.uiFont
    font.pixelSize: Theme.type.control.size
    font.weight: Theme.type.control.weight

    contentItem: Item {
        Text {
            anchors.left: parent.left
            anchors.right: caret.left
            anchors.rightMargin: Theme.space.sm
            anchors.verticalCenter: parent.verticalCenter
            text: control.displayText
            font: control.font
            color: control.enabled ? Theme.color.textPrimary : Theme.color.textDisabled
            elide: Text.ElideRight
        }
        Icon {
            id: caret
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            name: "chevronDown"
            size: Theme.size.iconStatus
            color: control.enabled ? Theme.color.textSecondary : Theme.color.textDisabled
        }
    }

    background: Rectangle {
        radius: Theme.radius.md
        color: !control.enabled ? Theme.color.base
             : control.showPressed ? Theme.color.pressed
             : control.showHover ? Theme.color.hover : Theme.color.raised
        border.width: 1
        border.color: control.showFocus ? Theme.color.focus
                    : control.showHover && control.enabled ? Theme.color.borderStrong : Theme.color.border
    }

    delegate: T.ItemDelegate {
        id: option
        required property int index
        required property string modelData
        width: control.popup.availableWidth
        height: Theme.size.controlMd
        highlighted: control.highlightedIndex === index
        text: modelData
        font: control.font
        hoverEnabled: true
        contentItem: Text {
            text: option.text
            font: option.font
            color: option.enabled ? Theme.color.textPrimary : Theme.color.textDisabled
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: Theme.radius.sm
            color: option.highlighted || option.hovered ? Theme.color.hover : "transparent"
        }
    }

    popup: T.Popup {
        y: control.height + Theme.space.xs
        width: control.width
        padding: Theme.space.xs
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 208)
        contentItem: ListView {
            implicitHeight: contentHeight
            clip: true
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
        }
        background: Rectangle {
            color: Theme.color.overlay
            radius: Theme.radius.md
            border.width: 1
            border.color: Theme.color.borderStrong
        }
    }
}
