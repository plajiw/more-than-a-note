import QtQuick
import QtQuick.Templates as T

// Overlay scroll bar: no track, a thin thumb that appears while scrolling or
// hovered, widens under the pointer and fades out when idle.
T.ScrollBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 2
    minimumSize: orientation === Qt.Horizontal ? height / width : width / height
    visible: policy === T.ScrollBar.AlwaysOn || (policy === T.ScrollBar.AsNeeded && size < 1.0)

    readonly property bool shown: active || hovered || pressed
    readonly property int thickness: hovered || pressed ? Theme.size.scrollThumbHover : Theme.size.scrollThumb

    contentItem: Item {
        implicitWidth: Theme.size.scrollHit - control.leftPadding - control.rightPadding
        implicitHeight: Theme.size.scrollHit - control.topPadding - control.bottomPadding

        Rectangle {
            anchors.right: control.vertical ? parent.right : undefined
            anchors.bottom: control.horizontal ? parent.bottom : undefined
            width: control.vertical ? control.thickness : parent.width
            height: control.horizontal ? control.thickness : parent.height
            radius: control.thickness / 2
            color: control.pressed ? Theme.color.textSecondary
                 : control.hovered ? Theme.color.textTertiary
                 : Qt.rgba(Theme.color.textTertiary.r, Theme.color.textTertiary.g, Theme.color.textTertiary.b, 0.6)
            opacity: control.shown ? 1 : 0

            Behavior on width { NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
            // Fades in quickly; lingers briefly before fading out.
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: control.shown ? 0 : 600 }
                    NumberAnimation { duration: Theme.motion.slow; easing.type: Easing.InOutCubic }
                }
            }
        }
    }
}
