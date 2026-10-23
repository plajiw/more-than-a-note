import QtQuick
import QtQuick.Templates as T

// Icon-only button for toolbar and row actions (undo, add, settings...).
// `checkable` turns it into a toggle (bold, italic...). Clicking never takes
// focus away from the document; Tab still reaches it.
T.AbstractButton {
    id: control

    property string iconName
    property int size: Theme.size.controlMd
    property int iconSize: size >= Theme.size.controlMd ? Theme.size.iconToolbar : Theme.size.iconList
    property string toolTip
    property var keys: []
    // Forces a visual state in the gallery: "", "hover", "pressed" or "focus".
    property string previewState: ""

    readonly property bool showHover: previewState === "hover" || hovered
    readonly property bool showPressed: previewState === "pressed" || down

    implicitWidth: size
    implicitHeight: size
    focusPolicy: Qt.TabFocus
    hoverEnabled: true

    Accessible.role: checkable ? Accessible.CheckBox : Accessible.Button
    Accessible.name: toolTip

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            name: control.iconName
            size: control.iconSize
            color: !control.enabled ? Theme.color.textDisabled
                 : control.checked || control.showHover || control.showPressed ? Theme.color.textPrimary
                 : Theme.color.textSecondary
        }
    }

    background: Rectangle {
        radius: Theme.radius.sm
        color: !control.enabled ? "transparent"
             : control.showPressed ? Theme.color.pressed
             : control.checked ? Theme.color.hover
             : control.showHover ? Theme.color.raised
             : "transparent"
        border.width: control.checked ? 1 : 0
        border.color: Theme.color.border
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        FocusRing { visible: control.visualFocus || control.previewState === "focus"; controlRadius: Theme.radius.sm }
    }

    HintToolTip {
        id: tip
        text: control.toolTip
        keys: control.keys
        visible: control.hovered && control.toolTip !== "" && !control.down
    }
    onHoveredChanged: if (hovered) tip.delay = Theme.tipDelay()
}
