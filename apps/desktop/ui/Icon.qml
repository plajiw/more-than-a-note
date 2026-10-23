import QtQuick
import QtQuick.Controls.impl as Impl

// Single place that knows about icon files. `name` is a semantic id; `filled`
// selects the active-state variant (Phosphor "fill", Fluent "filled").
Item {
    id: root

    property string name
    property int size: Theme.size.iconList
    property bool filled: false
    property color color: Theme.color.textSecondary
    property string iconSet: Theme.iconSet

    readonly property var phosphor: ({
        notebook: "notebook", book: "book-open-text", add: "plus", search: "magnifying-glass",
        back: "caret-left", undo: "arrow-u-up-left", redo: "arrow-u-up-right",
        text: "text-t", pen: "pen-nib", select: "cursor", eraser: "eraser", highlighter: "highlighter",
        bold: "text-b", italic: "text-italic", underline: "text-underline", list: "list-bullets",
        settings: "gear-six", delete: "trash", sidebar: "sidebar-simple", page: "file-text",
        folder: "folder", sort: "sort-ascending", grid: "squares-four", rows: "rows",
        minus: "minus", check: "check", ruler: "ruler", lasso: "lasso", palette: "palette", hand: "hand"
    })
    readonly property var fluent: ({
        notebook: "notebook", book: "book_open", add: "add", search: "search",
        back: "chevron_left", undo: "arrow_undo", redo: "arrow_redo",
        text: "text_t", pen: "pen", select: "cursor", eraser: "eraser", highlighter: "highlight",
        bold: "text_bold", italic: "text_italic", underline: "text_underline", list: "text_bullet_list_ltr",
        settings: "settings", delete: "delete", sidebar: "panel_left", page: "document_text",
        folder: "folder", sort: "arrow_sort", grid: "grid", rows: "list",
        minus: "subtract", check: "checkmark", ruler: "ruler", lasso: "lasso", palette: "color", hand: "hand_left"
    })

    function sourceFor(set, id, fill, px) {
        if (set === "fluent") {
            // Fluent has no 16 px drawing for a few icons.
            const no16 = id === "eraser" || id === "lasso"
            const grid = px <= 16 && !no16 ? 16 : (px <= 20 ? 20 : 24)
            return "qrc:/icons/fluent/" + fluent[id] + "_" + grid + "_" + (fill ? "filled" : "regular") + ".svg"
        }
        const file = phosphor[id]
        return fill ? "qrc:/icons/phosphor/fill/" + file + "-fill.svg"
                    : "qrc:/icons/phosphor/regular/" + file + ".svg"
    }

    implicitWidth: size
    implicitHeight: size
    Accessible.ignored: true

    Impl.IconImage {
        anchors.fill: parent
        source: root.name === "" ? "" : root.sourceFor(root.iconSet, root.name, root.filled, root.size)
        sourceSize: Qt.size(root.size, root.size)
        color: root.color
    }
}
