import QtQuick
import QtQuick.Controls.impl as Impl

// Single place that knows about icon files (Phosphor). `name` is a semantic id;
// `filled` selects the active-state variant.
Item {
    id: root

    property string name
    property int size: Theme.size.iconList
    property bool filled: false
    property color color: Theme.color.textSecondary

    readonly property var files: ({
        notebook: "notebook", book: "book-open-text", add: "plus", search: "magnifying-glass",
        back: "caret-left", undo: "arrow-u-up-left", redo: "arrow-u-up-right",
        text: "text-t", pen: "pen-nib", select: "cursor", eraser: "eraser", highlighter: "highlighter",
        bold: "text-b", italic: "text-italic", underline: "text-underline", list: "list-bullets",
        settings: "gear-six", delete: "trash", sidebar: "sidebar-simple", page: "file-text",
        folder: "folder", sort: "sort-ascending", grid: "squares-four", rows: "rows",
        minus: "minus", check: "check", ruler: "ruler", lasso: "lasso", palette: "palette", hand: "hand",
        chevronDown: "caret-down", close: "x"
    })

    implicitWidth: size
    implicitHeight: size
    Accessible.ignored: true

    Impl.IconImage {
        anchors.fill: parent
        source: root.name === "" ? ""
              : root.filled ? "qrc:/icons/phosphor/fill/" + root.files[root.name] + "-fill.svg"
                            : "qrc:/icons/phosphor/regular/" + root.files[root.name] + ".svg"
        sourceSize: Qt.size(root.size, root.size)
        color: root.color
    }
}
