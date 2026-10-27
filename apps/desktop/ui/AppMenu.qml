import QtQuick
import QtQuick.Templates as T

// Menu and toolbar picker (docs/13 §6.3) on the shared PopupSurface.
T.Menu {
    id: control

    property int minimumWidth: 180

    implicitWidth: Math.max(implicitBackgroundWidth, contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight, contentHeight + topPadding + bottomPadding)
    margins: Theme.space.sm
    overlap: 0
    padding: Theme.space.xs

    delegate: AppMenuItem {}

    contentItem: ListView {
        // The widest row sets the width, so labels and shortcuts never elide.
        implicitWidth: {
            let widest = 0
            for (let i = 0; i < control.count; ++i) {
                const item = control.itemAt(i)
                if (item) widest = Math.max(widest, item.implicitWidth)
            }
            return widest
        }
        implicitHeight: contentHeight
        model: control.contentModel
        interactive: Window.window ? contentHeight + control.topPadding + control.bottomPadding > control.height : false
        clip: true
        currentIndex: control.currentIndex
        boundsBehavior: Flickable.StopAtBounds
    }

    background: PopupSurface {
        implicitWidth: control.minimumWidth
        implicitHeight: Theme.size.menuItem + Theme.space.sm
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion.fast; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.motion.fast; easing.type: Easing.InCubic }
    }
}
