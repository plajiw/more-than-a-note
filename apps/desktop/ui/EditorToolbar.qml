import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T

// Notebook bar and toolbar in one 40 px island (docs/13 §6.1, "Topbar compacta").
// The notebook block stays fixed on the left; tools and settings scroll in
// narrow windows. Settings keep the same footprint as tools change.
Island {
    id: root
    implicitHeight: Theme.size.toolbar

    property string notebookName: ""
    signal libraryRequested()

    property string activeTool: "text"
    property string penMode: "pen"
    property string selectionMode: "select"
    property string fontFamily: "IBM Plex Serif"
    property string fontSize: "16"
    property string penWidth: "2 px"
    property var quickColors: [
        { name: "Grafite", hex: "#282B2E" },
        { name: "Âmbar", hex: "#9B6336" },
        { name: "Vermelho", hex: "#B94E50" },
        { name: "Laranja", hex: "#D07842" },
        { name: "Amarelo", hex: "#C39A35" },
        { name: "Verde", hex: "#46835A" },
        { name: "Turquesa", hex: "#397F85" },
        { name: "Azul", hex: "#2868BD" },
        { name: "Violeta", hex: "#805BA0" }
    ]
    property int selectedColorIndex: 0
    readonly property color selectedColor: quickColors[selectedColorIndex].hex
    readonly property bool paletteOpen: palettePopup.opened
    property bool bold: false
    property bool italic: false
    property bool underline: false
    property bool bulletList: false
    property var pageAdapter: null
    property var textTarget: null
    readonly property var currentStyle: textTarget ? textTarget.styleInfo : ({})
    readonly property int currentTextColorIndex: {
        if (!textTarget || !currentStyle.color) return selectedColorIndex
        const wanted = String(currentStyle.color).toUpperCase()
        for (let i = 0; i < quickColors.length; ++i)
            if (quickColors[i].hex.toUpperCase() === wanted) return i
        return -1
    }

    function formatText(kind, value) {
        if (textTarget) textTarget.applyFormat(kind, value)
    }

    // Priority overflow (docs/13 §6.1): below the full width the nine colors
    // become one well; below that, list, paragraph style and link move to "…".
    readonly property real colorsFullWidth: quickColors.length * (Theme.size.controlXs + Theme.space.xxs) + Theme.size.controlSm
    readonly property real textFullWidth: fontField.width + Theme.space.xxs + sizeField.width + Theme.space.s6
        + 4 * Theme.size.controlSm + 3 * Theme.space.xxs + Theme.space.s6 + paragraphField.width + Theme.space.s6
        + Theme.size.controlSm + Theme.space.s6 * 2 + 1 + colorsFullWidth
    readonly property bool compactColors: strip.width < textFullWidth
    readonly property bool compactText: strip.width < textFullWidth - colorsFullWidth + Theme.size.controlSm

    readonly property bool textActive: activeTool === "text"
    readonly property bool penActive: activeTool === "pen"
    readonly property bool selectActive: activeTool === "select"

    function selectQuickColor(index) {
        if (index >= 0 && index < quickColors.length) {
            selectedColorIndex = index
            formatText("color", quickColors[index].hex)
        }
    }

    function openPalette() {
        palettePopup.returnFocusItem = window && window.activeFocusItem ? window.activeFocusItem : null
        palettePopup.editingSlot = selectedColorIndex
        hexField.text = quickColors[selectedColorIndex].hex
        palettePopup.open()
    }

    function applyPaletteColor() {
        const value = hexField.text.trim().toUpperCase()
        if (!/^#[0-9A-F]{6}$/.test(value)) {
            hexError.visible = true
            hexField.forceActiveFocus()
            return
        }
        const updated = quickColors.slice()
        updated[palettePopup.editingSlot] = { name: "Personalizada", hex: value }
        quickColors = updated
        selectedColorIndex = palettePopup.editingSlot
        formatText("color", value)
        palettePopup.close()
    }

    Row {
        id: notebookBlock
        visible: root.notebookName !== ""
        width: visible ? implicitWidth : 0
        anchors.left: parent.left
        anchors.leftMargin: Theme.space.s6
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space.xxs
        IconButton {
            objectName: "backToLibrary"
            size: Theme.size.controlSm
            iconName: "back"
            toolTip: "Voltar à Biblioteca"
            onClicked: root.libraryRequested()
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 200)
            text: root.notebookName
            elide: Text.ElideRight
            color: Theme.color.textPrimary
            font.family: Theme.uiFont
            font.pixelSize: Theme.type.control.size
            font.weight: Font.DemiBold
            Accessible.role: Accessible.StaticText
            Accessible.name: "Caderno aberto: " + text
        }
        Item { width: Theme.space.xs; height: 1 }
        Rectangle { width: 1; height: 16; anchors.verticalCenter: parent.verticalCenter; color: Theme.color.borderSubtle }
    }

    // Undo/redo and the tools never scroll away; only tool settings collapse.
    Row {
        id: pinnedBlock
        anchors.left: notebookBlock.right
        anchors.leftMargin: Theme.space.s6
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space.s6

        Row {
            spacing: Theme.space.xxs
            IconButton {
                size: Theme.size.controlSm
                objectName: "pageDemoUndo"
                iconName: "undo"; keys: ["Ctrl", "Z"]
                // Names the step, as Pages, Photoshop and Affinity do.
                toolTip: root.pageAdapter && root.pageAdapter.undoLabel
                         ? "Desfazer " + root.pageAdapter.undoLabel.toLowerCase() : "Desfazer"
                enabled: root.pageAdapter && root.pageAdapter.demoEnabled && root.pageAdapter.canUndo
                onClicked: root.pageAdapter.undo()
            }
            IconButton {
                size: Theme.size.controlSm
                objectName: "pageDemoRedo"
                iconName: "redo"; keys: ["Ctrl", "Shift", "Z"]
                toolTip: root.pageAdapter && root.pageAdapter.redoLabel
                         ? "Refazer " + root.pageAdapter.redoLabel.toLowerCase() : "Refazer"
                enabled: root.pageAdapter && root.pageAdapter.demoEnabled && root.pageAdapter.canRedo
                onClicked: root.pageAdapter.redo()
            }
        }

        Rectangle {
            width: 1; height: 16; anchors.verticalCenter: parent.verticalCenter
            color: Theme.color.borderSubtle
        }

        // The active-tool pill slides between tools (160 ms) instead of blinking.
        Item {
            width: toolRow.implicitWidth
            height: toolRow.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                readonly property Item target: root.textActive ? textTool : root.penActive ? penTool : selectTool
                x: target.x
                width: target.width
                height: target.height
                radius: Theme.radius.sm
                color: Theme.color.hover
                Behavior on x { NumberAnimation { duration: Theme.motion.base; easing.type: Easing.OutCubic } }
            }
            Row {
                id: toolRow
                spacing: Theme.space.xxs
                ToolModeButton { id: textTool; showActiveFill: false; iconName: "text"; toolTip: "Texto"; keys: ["T"]; active: root.textActive; onClicked: root.activeTool = "text" }
                ToolModeButton { id: penTool; showActiveFill: false; iconName: "pen"; toolTip: "Caneta"; keys: ["P"]; active: root.penActive; onClicked: { root.activeTool = "pen"; root.penMode = "pen" } }
                ToolModeButton { id: selectTool; showActiveFill: false; iconName: "select"; toolTip: "Seleção"; keys: ["V"]; active: root.selectActive; onClicked: root.activeTool = "select" }
            }
        }

        Rectangle {
            width: 1; height: 16; anchors.verticalCenter: parent.verticalCenter
            color: Theme.color.borderSubtle
        }
    }

    Flickable {
        id: strip
        objectName: "toolbarStrip"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: pinnedBlock.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.space.s6
        anchors.rightMargin: Theme.space.s6
        clip: true
        contentWidth: controls.implicitWidth
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        onWidthChanged: Qt.callLater(revealFocusedItem)
        onContentWidthChanged: Qt.callLater(revealFocusedItem)

        function containsItem(item) {
            while (item) {
                if (item === strip) return true
                item = item.parent
            }
            return false
        }
        function revealFocusedItem() {
            const item = strip.Window.activeFocusItem
            if (!item || !containsItem(item)) return
            const left = item.mapToItem(strip, 0, 0).x
            const right = left + item.width
            if (left < Theme.space.xs)
                contentX = Math.max(0, contentX + left - Theme.space.xs)
            else if (right > width - Theme.space.xs)
                contentX = Math.min(contentWidth - width, contentX + right - width + Theme.space.xs)
        }
        // The containing window, so the toolbar also works inside the gallery.
        Connections {
            target: strip.Window.window
            function onActiveFocusItemChanged() { Qt.callLater(strip.revealFocusedItem) }
        }

        Row {
            id: controls
            y: Math.round((strip.height - height) / 2)
            spacing: Theme.space.s6

            // One measured geometry for all modes: switching tools never shifts the strip.
            Item {
                width: Math.max(textControls.implicitWidth, penControls.implicitWidth, selectionControls.implicitWidth)
                height: Theme.size.controlSm

                Row {
                    id: textControls
                    visible: root.textActive
                    spacing: Theme.space.s6
                    Row {
                        spacing: Theme.space.xxs
                        FieldButton {
                            id: fontField
                            quiet: true
                            width: Math.min(160, Math.max(72, implicitWidth)); text: root.textTarget ? (root.currentStyle.family || root.fontFamily) : root.fontFamily; toolTip: "Fonte"
                            onClicked: fontMenu.open()
                            AppMenu {
                                id: fontMenu; y: parent.height + Theme.space.xs; minimumWidth: 200
                                Repeater {
                                    model: ["IBM Plex Serif", "Inter", "JetBrains Mono"]
                                    AppMenuItem {
                                        required property string modelData
                                        text: modelData; font.family: modelData
                                        checkable: true; checked: fontField.text === modelData
                                        onTriggered: { root.fontFamily = text; root.formatText("family", text) }
                                    }
                                }
                            }
                        }
                        FieldButton {
                            id: sizeField
                            quiet: true
                            width: 52; text: root.textTarget ? String(root.currentStyle.size || root.fontSize) : root.fontSize; toolTip: "Tamanho"
                            onClicked: sizeMenu.open()
                            AppMenu {
                                id: sizeMenu; y: parent.height + Theme.space.xs; minimumWidth: 80
                                Repeater {
                                    model: ["12", "14", "16", "18", "24", "32"]
                                    AppMenuItem {
                                        required property string modelData
                                        text: modelData
                                        checkable: true; checked: sizeField.text === modelData
                                        onTriggered: { root.fontSize = text; root.formatText("size", text) }
                                    }
                                }
                            }
                        }
                    }
                    Row {
                        spacing: Theme.space.xxs
                        IconButton { size: Theme.size.controlSm; objectName: "textBoldButton"; iconName: "bold"; toolTip: "Negrito"; keys: ["Ctrl", "B"]; checkable: true; checked: root.textTarget ? !!root.currentStyle.bold : root.bold; onClicked: { const value = root.textTarget ? !root.currentStyle.bold : !root.bold; root.bold = value; root.formatText("bold", value) } }
                        IconButton { size: Theme.size.controlSm; iconName: "italic"; toolTip: "Itálico"; keys: ["Ctrl", "I"]; checkable: true; checked: root.textTarget ? !!root.currentStyle.italic : root.italic; onClicked: { const value = root.textTarget ? !root.currentStyle.italic : !root.italic; root.italic = value; root.formatText("italic", value) } }
                        IconButton { size: Theme.size.controlSm; iconName: "underline"; toolTip: "Sublinhado"; keys: ["Ctrl", "U"]; checkable: true; checked: root.textTarget ? !!root.currentStyle.underline : root.underline; onClicked: { const value = root.textTarget ? !root.currentStyle.underline : !root.underline; root.underline = value; root.formatText("underline", value) } }
                        IconButton { visible: !root.compactText; size: Theme.size.controlSm; iconName: "list"; toolTip: "Lista"; checkable: true; checked: root.textTarget ? root.currentStyle.list === "bullet" : root.bulletList; onClicked: { const value = root.textTarget ? root.currentStyle.list !== "bullet" : !root.bulletList; root.bulletList = value; root.formatText(value ? "bullet" : "no-list", "") } }
                    }
                    FieldButton {
                        id: paragraphField
                        visible: !root.compactText
                        quiet: true
                        width: 88; text: root.textTarget ? (root.currentStyle.heading > 0 ? "Título " + root.currentStyle.heading : "Corpo") : "Corpo"
                        toolTip: "Estilo de parágrafo"
                        onClicked: paragraphMenu.open()
                        AppMenu {
                            id: paragraphMenu; y: parent.height + Theme.space.xs
                            AppMenuItem { text: "Corpo"; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("body", "") }
                            AppMenuItem { text: "Título 1"; font.weight: Font.DemiBold; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("heading", "1") }
                            AppMenuItem { text: "Título 2"; font.weight: Font.DemiBold; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("heading", "2") }
                            AppMenuItem { text: "Título 3"; font.weight: Font.DemiBold; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("heading", "3") }
                            AppMenuSeparator {}
                            AppMenuItem { text: "Lista numerada"; checkable: true; checked: root.currentStyle.list === "numbered"; onTriggered: root.formatText("numbered", "") }
                            AppMenuItem { text: "Sem lista"; onTriggered: root.formatText("no-list", "") }
                        }
                    }
                    IconButton {
                        visible: !root.compactText
                        size: Theme.size.controlSm
                        iconName: "link"; toolTip: "Ligação"
                        checked: !!root.currentStyle.link
                        onClicked: linkPopup.open()
                    }
                    IconButton {
                        id: moreTextButton
                        objectName: "toolbarMoreText"
                        visible: root.compactText
                        size: Theme.size.controlSm
                        iconName: "more"; toolTip: "Mais formatação"
                        onClicked: moreTextMenu.popup(moreTextButton, 0, moreTextButton.height + Theme.space.xs)
                        AppMenu {
                            id: moreTextMenu
                            AppMenuItem { text: "Lista"; checkable: true; checked: root.currentStyle.list === "bullet"; onTriggered: root.formatText(root.currentStyle.list === "bullet" ? "no-list" : "bullet", "") }
                            AppMenuItem { text: "Lista numerada"; checkable: true; checked: root.currentStyle.list === "numbered"; onTriggered: root.formatText("numbered", "") }
                            AppMenuSeparator {}
                            AppMenuItem { text: "Corpo"; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("body", "") }
                            AppMenuItem { text: "Título 1"; font.weight: Font.DemiBold; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("heading", "1") }
                            AppMenuItem { text: "Título 2"; font.weight: Font.DemiBold; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("heading", "2") }
                            AppMenuItem { text: "Título 3"; font.weight: Font.DemiBold; checkable: true; checked: paragraphField.text === text; onTriggered: root.formatText("heading", "3") }
                            AppMenuSeparator {}
                            AppMenuItem { text: "Ligação…"; onTriggered: linkPopup.open() }
                        }
                    }
                    Rectangle { width: 1; height: 16; anchors.verticalCenter: parent.verticalCenter; color: Theme.color.borderSubtle }
                    Row {
                        spacing: Theme.space.xxs
                        Repeater {
                            model: root.quickColors
                            ToolColorSwatch {
                                size: Theme.size.controlXs
                                required property int index
                                required property var modelData
                                visible: !root.compactColors
                                slot: index + 1
                                inkColor: modelData.hex
                                colorName: modelData.name
                                selected: root.currentTextColorIndex === index
                                onClicked: root.selectQuickColor(index)
                            }
                        }
                        ToolColorSwatch {
                            objectName: "toolColorWell"
                            visible: root.compactColors
                            size: Theme.size.controlSm
                            inkColor: root.currentTextColorIndex >= 0 ? root.quickColors[root.currentTextColorIndex].hex : root.selectedColor
                            colorName: "atual; abre a paleta"
                            selected: true
                            onClicked: root.openPalette()
                        }
                        IconButton { visible: !root.compactColors; size: Theme.size.controlSm; iconName: "palette"; toolTip: "Paleta de cores"; keys: ["0"]; onClicked: root.openPalette() }
                    }
                }

                Row {
                    id: penControls
                    visible: root.penActive
                    spacing: Theme.space.s6
                    Row {
                        spacing: Theme.space.xxs
                        IconButton { size: Theme.size.controlSm; iconName: "pen"; toolTip: "Caneta"; checkable: true; checked: root.penMode === "pen"; onClicked: root.penMode = "pen" }
                        IconButton { size: Theme.size.controlSm; iconName: "highlighter"; toolTip: "Marca-texto"; checkable: true; checked: root.penMode === "highlighter"; onClicked: root.penMode = "highlighter" }
                        IconButton { size: Theme.size.controlSm; iconName: "eraser"; toolTip: "Borracha"; keys: ["E"]; checkable: true; checked: root.penMode === "eraser"; onClicked: root.penMode = "eraser" }
                    }
                    Rectangle { width: 1; height: 16; anchors.verticalCenter: parent.verticalCenter; color: Theme.color.borderSubtle }
                    FieldButton {
                        quiet: true
                        width: 64; text: root.penWidth; toolTip: "Espessura da caneta"
                        onClicked: widthMenu.open()
                        AppMenu {
                            id: widthMenu; y: parent.height + Theme.space.xs; minimumWidth: 96
                            Repeater {
                                model: ["1 px", "2 px", "4 px", "6 px", "8 px"]
                                AppMenuItem { required property string modelData; text: modelData; checkable: true; checked: root.penWidth === modelData; onTriggered: root.penWidth = text }
                            }
                        }
                    }
                    Row {
                        spacing: Theme.space.xxs
                        Repeater {
                            model: root.quickColors
                            ToolColorSwatch {
                                size: Theme.size.controlXs
                                required property int index
                                required property var modelData
                                slot: index + 1
                                inkColor: modelData.hex
                                colorName: modelData.name
                                visible: !root.compactColors
                                enabled: root.penMode !== "eraser"
                                selected: root.selectedColorIndex === index
                                onClicked: root.selectQuickColor(index)
                            }
                        }
                        ToolColorSwatch {
                            visible: root.compactColors
                            enabled: root.penMode !== "eraser"
                            size: Theme.size.controlSm
                            inkColor: root.selectedColor
                            colorName: "atual; abre a paleta"
                            selected: true
                            onClicked: root.openPalette()
                        }
                        IconButton { visible: !root.compactColors; size: Theme.size.controlSm; iconName: "palette"; toolTip: "Paleta de cores"; keys: ["0"]; onClicked: root.openPalette() }
                    }
                }

                Row {
                    id: selectionControls
                    visible: root.selectActive
                    spacing: Theme.space.xxs
                    IconButton { size: Theme.size.controlSm; iconName: "select"; toolTip: "Selecionar objetos"; checkable: true; checked: root.selectionMode === "select"; onClicked: root.selectionMode = "select" }
                    IconButton { size: Theme.size.controlSm; iconName: "lasso"; toolTip: "Seleção por laço"; checkable: true; checked: root.selectionMode === "lasso"; onClicked: root.selectionMode = "lasso" }
                    IconButton { size: Theme.size.controlSm; iconName: "hand"; toolTip: "Mover vista"; checkable: true; checked: root.selectionMode === "hand"; onClicked: root.selectionMode = "hand" }
                }
            }
        }
    }

    Popup {
        id: linkPopup
        width: 300
        padding: Theme.space.md
        y: root.height + Theme.space.xs
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: { linkField.text = root.currentStyle.link || ""; linkField.forceActiveFocus() }
        background: PopupSurface { radius: Theme.radius.lg }
        contentItem: Column {
            spacing: Theme.space.sm
            Text {
                text: "LIGAÇÃO DA SELEÇÃO"
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.overline.size
                font.weight: Theme.type.overline.weight
                font.letterSpacing: Theme.type.overline.tracking
                color: Theme.color.textTertiary
            }
            InputField {
                id: linkField
                width: parent.width
                fieldHeight: Theme.size.controlSm
                placeholderText: "https://..."
                selectByMouse: true
                onAccepted: if (root.textTarget && root.textTarget.applyFormat("link", text.trim())) linkPopup.close()
            }
            Row {
                anchors.right: parent.right
                spacing: Theme.space.s6
                ActionButton { implicitHeight: Theme.size.controlSm; variant: "subtle"; text: "Remover"; onClicked: { root.formatText("unlink", ""); linkPopup.close() } }
                ActionButton { implicitHeight: Theme.size.controlSm; variant: "primary"; text: "Aplicar"; onClicked: if (root.textTarget && root.textTarget.applyFormat("link", linkField.text.trim())) linkPopup.close() }
            }
        }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.motion.fast; easing.type: Easing.InCubic } }
    }

    Popup {
        id: palettePopup
        property int editingSlot: 0
        property var returnFocusItem: null
        parent: root
        popupType: Popup.Window
        x: Math.max(8, root.width - width - 16)
        y: root.height + Theme.space.xs
        width: 312
        padding: Theme.space.md
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: { hexError.visible = false; hexField.forceActiveFocus() }
        onClosed: if (returnFocusItem) returnFocusItem.forceActiveFocus()
        background: PopupSurface { radius: Theme.radius.lg }
        contentItem: Column {
            spacing: Theme.space.sm
            Text {
                text: "PALETA DE CORES"
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.overline.size
                font.weight: Theme.type.overline.weight
                font.letterSpacing: Theme.type.overline.tracking
                color: Theme.color.textTertiary
            }
            Text {
                text: "Escolha uma cor ou personalize uma posição de 1 a 9."
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.caption.size
                color: Theme.color.textSecondary
            }
            Row {
                spacing: Theme.space.xxs
                Repeater {
                    model: root.quickColors
                    ToolColorSwatch {
                        required property int index
                        required property var modelData
                        size: Theme.size.controlSm
                        slot: index + 1
                        inkColor: modelData.hex
                        colorName: modelData.name
                        selected: palettePopup.editingSlot === index
                        onClicked: {
                            palettePopup.editingSlot = index
                            root.selectQuickColor(index)
                            hexField.text = modelData.hex
                            hexError.visible = false
                        }
                    }
                }
            }
            Row {
                spacing: Theme.space.sm
                InputField {
                    id: hexField
                    width: 118
                    fieldHeight: Theme.size.controlSm
                    placeholderText: "Cor hexadecimal"
                    maximumLength: 7
                    onTextChanged: hexError.visible = false
                    onAccepted: root.applyPaletteColor()
                }
                ActionButton {
                    implicitHeight: Theme.size.controlSm
                    text: "Aplicar à cor " + (palettePopup.editingSlot + 1)
                    onClicked: root.applyPaletteColor()
                }
            }
            Text {
                id: hexError
                visible: false
                text: "Use o formato #RRGGBB."
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.caption.size
                color: Theme.color.danger
            }
        }
    }
}
