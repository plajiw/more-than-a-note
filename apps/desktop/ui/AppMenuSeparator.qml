import QtQuick
import QtQuick.Templates as T

T.MenuSeparator {
    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    leftPadding: Theme.space.sm
    rightPadding: Theme.space.sm
    topPadding: Theme.space.xs
    bottomPadding: Theme.space.xs
    contentItem: Rectangle { implicitHeight: 1; color: Theme.color.borderSubtle }
}
