import QtQuick
import QtQuick.Templates as T

// Icon-only button for toolbar and row actions (undo, add, settings...).
// `checkable` turns it into a toggle (bold, italic...). Clicking never takes
// focus away from the document; Tab still reaches it. `onPaper` keeps the
// same state rules with paper colors, which never follow the interface theme.
T.AbstractButton {
    id: control

    property string iconName
    property int size: Theme.size.controlMd
    property int iconSize: size >= Theme.size.controlMd ? Theme.size.iconToolbar : Theme.size.iconList
    property string toolTip
    property var keys: []
    property bool onPaper: false
    // Forces a visual state in the gallery: "", "hover", "pressed" or "focus".
    property string previewState: ""

    readonly property bool showHover: previewState === "hover" || hovered
    readonly property bool showPressed: previewState === "pressed" || down

    implicitWidth: size
    implicitHeight: size
    focusPolicy: Qt.TabFocus
    hoverEnabled: true
    Keys.onReturnPressed: activateFromKeyboard()
    Keys.onEnterPressed: activateFromKeyboard()

    function activateFromKeyboard() {
        if (checkable) toggle()
        clicked()
    }

    Accessible.role: checkable ? Accessible.CheckBox : Accessible.Button
    Accessible.name: toolTip

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            name: control.iconName
            size: control.iconSize
            color: !control.enabled ? (control.onPaper ? Theme.paper.rule : Theme.color.textDisabled)
                 : control.checked || control.showHover || control.showPressed
                   ? (control.onPaper ? Theme.paper.text : Theme.color.textPrimary)
                 : (control.onPaper ? Theme.paper.selection : Theme.color.textSecondary)
        }
    }

    background: Rectangle {
        radius: Theme.radius.sm
        color: !control.enabled ? "transparent"
             : control.showPressed ? (control.onPaper ? Theme.paper.pasteboard : Theme.color.pressed)
             : control.checked || control.showHover ? (control.onPaper ? Theme.paper.warm
                                                       : control.checked ? Theme.color.hover : Theme.color.raised)
             : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        FocusRing {
            visible: control.visualFocus || control.previewState === "focus"
            controlRadius: Theme.radius.sm
            border.color: control.onPaper ? Theme.paper.focus : Theme.color.focus
        }
    }

    HintToolTip {
        id: tip
        text: control.toolTip
        keys: control.keys
        visible: control.hovered && control.toolTip !== "" && !control.down
    }
    onHoveredChanged: if (hovered) tip.delay = Theme.tipDelay()
}
