import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T

// Real application toolbar. Settings keep the same footprint as tools change.
Island {
    id: root
    implicitHeight: Theme.size.toolbar

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

    readonly property bool textActive: activeTool === "text"
    readonly property bool penActive: activeTool === "pen"
    readonly property bool selectActive: activeTool === "select"

    function selectQuickColor(index) {
        if (index >= 0 && index < quickColors.length)
            selectedColorIndex = index
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
        palettePopup.close()
    }

    Flickable {
        id: strip
        anchors.fill: parent
        anchors.leftMargin: Theme.space.sm
        anchors.rightMargin: Theme.space.sm
        clip: true
        contentWidth: controls.implicitWidth
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: controls
            y: Math.round((strip.height - height) / 2)
            spacing: Theme.space.sm

            Row {
                spacing: Theme.space.xs
                IconButton { iconName: "undo"; toolTip: "Desfazer"; keys: ["Ctrl", "Z"]; enabled: false }
                IconButton { iconName: "redo"; toolTip: "Refazer"; keys: ["Ctrl", "Shift", "Z"]; enabled: false }
            }

            Rectangle {
                width: 1; height: 20; anchors.verticalCenter: parent.verticalCenter
                color: Theme.color.borderSubtle
            }

            Row {
                id: toolRow
                spacing: Theme.space.xs
                ToolModeButton { iconName: "text"; toolTip: "Texto"; keys: ["T"]; active: root.textActive; onClicked: root.activeTool = "text" }
                ToolModeButton { iconName: "pen"; toolTip: "Caneta"; keys: ["P"]; active: root.penActive; onClicked: { root.activeTool = "pen"; root.penMode = "pen" } }
                ToolModeButton { iconName: "select"; toolTip: "Seleção"; keys: ["V"]; active: root.selectActive; onClicked: root.activeTool = "select" }
            }

            Rectangle {
                width: 1; height: 20; anchors.verticalCenter: parent.verticalCenter
                color: Theme.color.borderSubtle
            }

            // One measured geometry for all modes: switching tools never shifts the strip.
            Item {
                width: Math.max(textControls.implicitWidth, penControls.implicitWidth, selectionControls.implicitWidth)
                height: Theme.size.controlMd

                Row {
                    id: textControls
                    visible: root.textActive
                    spacing: Theme.space.sm
                    Row {
                        spacing: Theme.space.xs
                        FieldButton {
                            width: 148; text: root.fontFamily; toolTip: "Fonte"
                            onClicked: fontMenu.open()
                            Menu {
                                id: fontMenu; y: parent.height
                                MenuItem { text: "IBM Plex Serif"; onTriggered: root.fontFamily = text }
                                MenuItem { text: "Inter"; onTriggered: root.fontFamily = text }
                                MenuItem { text: "JetBrains Mono"; onTriggered: root.fontFamily = text }
                            }
                        }
                        FieldButton {
                            width: 68; text: root.fontSize; toolTip: "Tamanho"
                            onClicked: sizeMenu.open()
                            Menu {
                                id: sizeMenu; y: parent.height
                                Repeater {
                                    model: ["12", "14", "16", "18", "24", "32"]
                                    MenuItem { required property string modelData; text: modelData; onTriggered: root.fontSize = text }
                                }
                            }
                        }
                    }
                    Row {
                        spacing: Theme.space.xs
                        IconButton { iconName: "bold"; toolTip: "Negrito"; keys: ["Ctrl", "B"]; checkable: true; checked: root.bold; onClicked: root.bold = !root.bold }
                        IconButton { iconName: "italic"; toolTip: "Itálico"; keys: ["Ctrl", "I"]; checkable: true; checked: root.italic; onClicked: root.italic = !root.italic }
                        IconButton { iconName: "underline"; toolTip: "Sublinhado"; keys: ["Ctrl", "U"]; checkable: true; checked: root.underline; onClicked: root.underline = !root.underline }
                        IconButton { iconName: "list"; toolTip: "Lista"; checkable: true; checked: root.bulletList; onClicked: root.bulletList = !root.bulletList }
                    }
                    Rectangle { width: 1; height: 20; anchors.verticalCenter: parent.verticalCenter; color: Theme.color.borderSubtle }
                    Row {
                        spacing: Theme.space.xs
                        Repeater {
                            model: root.quickColors
                            ToolColorSwatch {
                                required property int index
                                required property var modelData
                                slot: index + 1
                                inkColor: modelData.hex
                                colorName: modelData.name
                                selected: root.selectedColorIndex === index
                                onClicked: root.selectQuickColor(index)
                            }
                        }
                        IconButton { iconName: "palette"; toolTip: "Paleta de cores"; keys: ["0"]; onClicked: root.openPalette() }
                    }
                }

                Row {
                    id: penControls
                    visible: root.penActive
                    spacing: Theme.space.sm
                    Row {
                        spacing: Theme.space.xs
                        IconButton { iconName: "pen"; toolTip: "Caneta"; checkable: true; checked: root.penMode === "pen"; onClicked: root.penMode = "pen" }
                        IconButton { iconName: "highlighter"; toolTip: "Marca-texto"; checkable: true; checked: root.penMode === "highlighter"; onClicked: root.penMode = "highlighter" }
                        IconButton { iconName: "eraser"; toolTip: "Borracha"; keys: ["E"]; checkable: true; checked: root.penMode === "eraser"; onClicked: root.penMode = "eraser" }
                    }
                    Rectangle { width: 1; height: 20; anchors.verticalCenter: parent.verticalCenter; color: Theme.color.borderSubtle }
                    FieldButton {
                        width: 82; text: root.penWidth; toolTip: "Espessura da caneta"
                        onClicked: widthMenu.open()
                        Menu {
                            id: widthMenu; y: parent.height
                            Repeater {
                                model: ["1 px", "2 px", "4 px", "6 px", "8 px"]
                                MenuItem { required property string modelData; text: modelData; onTriggered: root.penWidth = text }
                            }
                        }
                    }
                    Row {
                        spacing: Theme.space.xs
                        Repeater {
                            model: root.quickColors
                            ToolColorSwatch {
                                required property int index
                                required property var modelData
                                slot: index + 1
                                inkColor: modelData.hex
                                colorName: modelData.name
                                enabled: root.penMode !== "eraser"
                                selected: root.selectedColorIndex === index
                                onClicked: root.selectQuickColor(index)
                            }
                        }
                        IconButton { iconName: "palette"; toolTip: "Paleta de cores"; keys: ["0"]; onClicked: root.openPalette() }
                    }
                }

                Row {
                    id: selectionControls
                    visible: root.selectActive
                    spacing: Theme.space.xs
                    IconButton { iconName: "select"; toolTip: "Selecionar objetos"; checkable: true; checked: root.selectionMode === "select"; onClicked: root.selectionMode = "select" }
                    IconButton { iconName: "lasso"; toolTip: "Seleção por laço"; checkable: true; checked: root.selectionMode === "lasso"; onClicked: root.selectionMode = "lasso" }
                    IconButton { iconName: "hand"; toolTip: "Mover vista"; checkable: true; checked: root.selectionMode === "hand"; onClicked: root.selectionMode = "hand" }
                }
            }
        }
    }

    Popup {
        id: palettePopup
        property int editingSlot: 0
        property var returnFocusItem: null
        parent: root
        popupType: Popup.Window
        x: Math.max(8, root.width - width - 16)
        y: root.height + 6
        width: 342
        padding: 16
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: { hexError.visible = false; hexField.forceActiveFocus() }
        onClosed: if (returnFocusItem) returnFocusItem.forceActiveFocus()
        background: Rectangle {
            radius: Theme.radius.lg
            color: Theme.color.overlay
            border.width: 1
            border.color: Theme.color.border
        }
        contentItem: Column {
            spacing: Theme.space.md
            Text {
                text: "Paleta de cores"
                font.family: Theme.uiFont
                font.pixelSize: Theme.type.titleSm.size
                font.weight: Font.DemiBold
                color: Theme.color.textPrimary
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
                    placeholderText: "Cor hexadecimal"
                    maximumLength: 7
                    onTextChanged: hexError.visible = false
                    onAccepted: root.applyPaletteColor()
                }
                ActionButton {
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
