import QtQuick
import QtQuick.Templates as T

// Scrollable area with overlay scroll bars. Desktop behavior: stops at the
// edges (no rubber-band overshoot) and content is never covered by a gutter.
T.ScrollView {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    Component.onCompleted: {
        if (contentItem && contentItem.boundsBehavior !== undefined)
            contentItem.boundsBehavior = Flickable.StopAtBounds
    }

    T.ScrollBar.vertical: ThinScrollBar {
        parent: control
        x: control.mirrored ? 0 : control.width - width
        y: control.topPadding
        height: control.availableHeight
        active: control.T.ScrollBar.horizontal.active
    }

    T.ScrollBar.horizontal: ThinScrollBar {
        parent: control
        x: control.leftPadding
        y: control.height - height
        width: control.availableWidth
        active: control.T.ScrollBar.vertical.active
    }
}
