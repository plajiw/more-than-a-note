import QtQuick

// Keyboard shortcut shown as key caps in the mono font, e.g. keys: ["Ctrl", "K"].
Row {
    id: root

    property var keys: []

    spacing: Theme.space.xxs
    Accessible.role: Accessible.StaticText
    Accessible.name: keys.join(" + ")

    Repeater {
        model: root.keys
        delegate: Rectangle {
            required property string modelData
            implicitWidth: Math.max(implicitHeight, label.implicitWidth + Theme.space.s6 * 2)
            implicitHeight: 18
            radius: Theme.radius.xs
            color: Theme.color.raised
            border.width: 1
            border.color: Theme.color.border
            Text {
                id: label
                anchors.centerIn: parent
                text: parent.modelData
                font.family: Theme.monoFont
                font.pixelSize: Theme.type.kbd.size
                font.weight: Theme.type.kbd.weight
                font.features: Theme.codeFeatures
                color: Theme.color.textSecondary
                renderType: Theme.nativeText ? Text.NativeRendering : Text.QtRendering
            }
        }
    }
}
