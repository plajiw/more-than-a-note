import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Visual evaluation board for docs/13-estudo-visual.md §6, steps 2 and 3.
// The switches change Theme globally, so the main window follows them too.
ApplicationWindow {
    id: gallery
    width: 1180
    height: 820
    title: "Galeria visual — avaliação"
    color: Theme.color.base
    font.family: Theme.uiFont
    font.pixelSize: Theme.type.body.size

    readonly property var iconNames: ["notebook", "book", "add", "search", "back", "undo", "redo", "text",
        "pen", "select", "eraser", "highlighter", "bold", "italic", "underline", "list", "settings",
        "delete", "sidebar", "page", "folder", "sort", "grid", "rows", "ruler", "lasso", "palette", "hand"]

    // One row of a component in each forced state, for side-by-side review.
    component StateRow: RowLayout {
        id: stateRow
        property string label
        property Component sample
        property var states: ["", "hover", "pressed", "focus", "disabled"]
        spacing: Theme.space.xl
        Styled { text: stateRow.label; token: Theme.type.caption; color: Theme.color.textSecondary; Layout.preferredWidth: 120 }
        Repeater {
            model: stateRow.states
            delegate: Item {
                required property string modelData
                implicitWidth: Math.max(120, loader.implicitWidth)
                implicitHeight: Math.max(Theme.size.controlLg, loader.implicitHeight)
                Loader {
                    id: loader
                    active: parent.modelData !== "none"
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: stateRow.sample
                    onLoaded: {
                        item.previewState = parent.modelData === "disabled" ? "" : parent.modelData
                        item.enabled = parent.modelData !== "disabled"
                    }
                }
            }
        }
    }

    component Styled: Text {
        property var token: Theme.type.body
        property string family: Theme.uiFont
        font.family: family
        font.pixelSize: token.size
        font.weight: token.weight
        font.letterSpacing: token.tracking
        lineHeight: token.line
        lineHeightMode: Text.FixedHeight
        color: Theme.color.textPrimary
        renderType: Theme.nativeText ? Text.NativeRendering : Text.QtRendering
        elide: Text.ElideRight
    }

    component Heading: Styled {
        token: Theme.type.overline
        color: Theme.color.textTertiary
        font.capitalization: Font.AllUppercase
        Layout.topMargin: Theme.space.xl
    }

    component Choice: RowLayout {
        id: choice
        property string label
        property var options: []
        property int current: 0
        signal picked(int index)
        spacing: Theme.space.sm
        Styled { text: choice.label; token: Theme.type.caption; color: Theme.color.textSecondary }
        Repeater {
            model: choice.options
            delegate: Rectangle {
                required property string modelData
                required property int index
                readonly property bool active: index === choice.current
                implicitWidth: optionText.implicitWidth + Theme.space.lg
                implicitHeight: Theme.size.controlSm
                radius: Theme.radius.sm
                color: active ? Theme.color.hover : (area.containsMouse ? Theme.color.raised : "transparent")
                border.width: 1
                border.color: active ? Theme.color.borderStrong : Theme.color.border
                Styled {
                    id: optionText
                    anchors.centerIn: parent
                    text: parent.modelData
                    token: Theme.type.control
                    color: parent.active ? Theme.color.textPrimary : Theme.color.textSecondary
                }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: choice.picked(parent.index) }
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData
                Accessible.checked: active
            }
        }
    }

    component FontColumn: ColumnLayout {
        id: fontColumn
        property string family
        spacing: Theme.space.md
        Styled { family: fontColumn.family; token: Theme.type.overline; text: fontColumn.family; color: Theme.color.accent; font.capitalization: Font.AllUppercase }
        Styled { family: fontColumn.family; token: Theme.type.display; text: "Nenhum caderno ainda" }
        Styled { family: fontColumn.family; token: Theme.type.title; text: "Biblioteca" }
        Styled { family: fontColumn.family; token: Theme.type.titleSm; text: "Arquitetura de Computadores" }
        Styled { family: fontColumn.family; token: Theme.type.body; text: "Pipeline e hazards — revisão da aula 4" }
        Styled { family: fontColumn.family; token: Theme.type.body; text: "Superescalares"; font.weight: Font.DemiBold }
        Styled { family: fontColumn.family; token: Theme.type.control; text: "IBM Plex Serif   ·   16   ·   B   I   U"; color: Theme.color.textSecondary }
        Styled { family: fontColumn.family; token: Theme.type.overline; text: "Seções   ·   Páginas da seção"; color: Theme.color.textTertiary; font.capitalization: Font.AllUppercase }
        Styled { family: fontColumn.family; token: Theme.type.caption; text: "Salvo localmente   ·   Página 1 de 4   ·   100%"; color: Theme.color.textSecondary; font.features: { "tnum": 1 } }
        Styled { family: fontColumn.family; token: Theme.type.body; text: "Ação é ótima: ç ã õ é ê í ú à — 0123456789"; color: Theme.color.textSecondary }
    }

    header: Rectangle {
        implicitHeight: headerRow.implicitHeight + Theme.space.lg * 2
        color: Theme.color.surface
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.color.borderSubtle }
        Flow {
            id: headerRow
            anchors.fill: parent
            anchors.margins: Theme.space.lg
            spacing: Theme.space.xl
            Choice {
                label: "Tema"; options: ["Grafite", "Claro"]; current: Theme.dark ? 0 : 1
                onPicked: index => Theme.dark = index === 0
            }
            Choice {
                label: "Renderização do texto"; options: ["Qt", "Nativa"]
                current: Theme.nativeText ? 1 : 0
                onPicked: index => Theme.nativeText = index === 1
            }
        }
    }

    ScrollArea {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        Timer {
            interval: 200
            running: startWithIndexGallery
            onTriggered: if (scroll.contentItem) scroll.contentItem.contentY = Math.max(0, indexHeading.y - Theme.space.xl)
        }

        ColumnLayout {
            width: scroll.availableWidth - Theme.space.xxl * 2
            x: Theme.space.xxl
            spacing: Theme.space.sm

            Styled {
                Layout.topMargin: Theme.space.xl
                Layout.fillWidth: true
                token: Theme.type.caption
                color: Theme.color.textTertiary
                text: "Escala da tela: " + Math.round(Screen.devicePixelRatio * 100) + "%. Para comparar 100/125/150%, mude a escala do Windows ou rode com --scale=1.25 / --scale=1.5."
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }

            Heading { text: "Componentes · estados lado a lado" }
            RowLayout {
                spacing: Theme.space.xl
                Item { Layout.preferredWidth: 120 }
                Repeater {
                    model: ["Normal", "Hover", "Pressionado", "Foco (teclado)", "Desabilitado"]
                    delegate: Styled {
                        required property string modelData
                        Layout.preferredWidth: 120
                        text: modelData
                        token: Theme.type.overline
                        color: Theme.color.textTertiary
                        font.capitalization: Font.AllUppercase
                    }
                }
            }
            StateRow { label: "Botão primário"; sample: Component { ActionButton { variant: "primary"; text: "Novo caderno" } } }
            StateRow { label: "Botão secundário"; sample: Component { ActionButton { text: "Importar" } } }
            StateRow { label: "Botão sutil"; sample: Component { ActionButton { variant: "subtle"; text: "Cancelar" } } }
            StateRow { label: "Botão de ícone"; sample: Component { IconButton { iconName: "undo"; toolTip: "Desfazer" } } }
            StateRow { label: "Ícone ligado (B)"; sample: Component { IconButton { iconName: "bold"; checkable: true; checked: true; toolTip: "Negrito" } } }
            StateRow { label: "Campo com menu"; sample: Component { FieldButton { text: "IBM Plex Serif"; toolTip: "Fonte" } } }
            StateRow {
                label: "Campo de texto"
                states: ["", "hover", "none", "focus", "disabled"]   // no pressed state
                sample: Component { InputField { implicitWidth: 160; placeholderText: "Nome do caderno" } }
            }
            StateRow { label: "Checkbox"; sample: Component { AppCheckBox { text: "Mostrar réguas"; checked: true } } }
            StateRow { label: "Lista de seleção"; sample: Component { SelectList { implicitWidth: 120; model: ["A4", "Carta", "Infinita"] } } }

            Heading { text: "Componentes · interativo (passe o mouse, clique, use Tab)" }
            Flow {
                Layout.fillWidth: true
                spacing: Theme.space.lg
                AppCheckBox { text: "Mostrar réguas"; checked: true }
                AppCheckBox { text: "Ajustar à grade" }
                SelectList { Accessible.name: "Formato da página"; model: ["A4", "Carta", "Infinita"] }
            }
            Flow {
                Layout.fillWidth: true
                spacing: Theme.space.sm
                IconButton { iconName: "undo"; toolTip: "Desfazer"; keys: ["Ctrl", "Z"] }
                IconButton { iconName: "redo"; toolTip: "Refazer"; keys: ["Ctrl", "Shift", "Z"] }
                Item { width: Theme.space.md; height: 1 }
                FieldButton { text: "IBM Plex Serif"; toolTip: "Fonte"; implicitWidth: 150 }
                FieldButton { text: "16"; toolTip: "Tamanho"; implicitWidth: 64 }
                IconButton { iconName: "bold"; checkable: true; toolTip: "Negrito"; keys: ["Ctrl", "B"] }
                IconButton { iconName: "italic"; checkable: true; toolTip: "Itálico"; keys: ["Ctrl", "I"] }
                IconButton { iconName: "underline"; checkable: true; toolTip: "Sublinhado"; keys: ["Ctrl", "U"] }
                IconButton { iconName: "list"; checkable: true; toolTip: "Lista" }
                Item { width: Theme.space.md; height: 1 }
                IconButton { iconName: "add"; size: Theme.size.controlSm; toolTip: "Nova página" }
                IconButton { iconName: "settings"; size: Theme.size.controlXs; toolTip: "Configurações da página" }
                IconButton { iconName: "delete"; size: Theme.size.controlXs; toolTip: "Excluir" }
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.md
                spacing: Theme.space.sm
                SearchBox {
                    id: demoSearch
                    implicitWidth: 320
                    fieldHeight: Theme.size.controlLg
                    placeholderText: "Buscar cadernos"
                    keys: ["Ctrl", "K"]
                }
                ActionButton { variant: "primary"; text: "Novo caderno"; toolTip: "Criar caderno"; keys: ["Ctrl", "N"] }
                ActionButton { text: "Importar" }
                ActionButton { variant: "subtle"; text: "Cancelar" }
            }
            Shortcut { sequence: "Ctrl+K"; onActivated: demoSearch.forceActiveFocus() }

            Heading { text: "Toolbar real · Texto, Caneta e Seleção" }
            Styled {
                Layout.fillWidth: true
                token: Theme.type.caption
                color: Theme.color.textTertiary
                text: "Troque a ferramenta e compare os ajustes no mesmo espaço. Os controles mudam a seleção visual; o editor de conteúdo ainda não está conectado."
            }
            EditorToolbar {
                Layout.fillWidth: true
                Layout.maximumWidth: 1000
            }

            Heading { id: indexHeading; text: "Índice · seções, páginas e menus" }
            Styled {
                Layout.fillWidth: true
                token: Theme.type.caption
                color: Theme.color.textTertiary
                text: "Passe o mouse nas linhas para revelar ações; clique na engrenagem para avaliar o menu e na adição para avaliar a criação inline."
            }
            Row {
                Layout.fillWidth: true
                Layout.maximumWidth: 1000
                Layout.preferredHeight: 320
                spacing: Theme.space.island
                Island {
                    width: Theme.size.indexWidth
                    height: parent.height
                    property string createKind: ""
                    Column {
                    anchors.fill: parent
                    anchors.margins: Theme.space.sm
                    spacing: Theme.space.xs
                    IndexHeader {
                        width: parent.width
                        title: "Seções"
                        addTooltip: "Nova seção"
                        onAddRequested: parent.parent.createKind = "section"
                    }
                    IndexCreate {
                        width: parent.width
                        visible: parent.parent.createKind === "section"
                        kind: "section"
                        onVisibleChanged: if (visible) Qt.callLater(begin)
                        onSubmitted: parent.parent.createKind = ""
                        onCanceled: parent.parent.createKind = ""
                    }
                    IndexRow { width: parent.width; kind: "section"; title: "Arquitetura de Computadores"; sectionColor: "#C58E61"; selected: true }
                    IndexRow { width: parent.width; kind: "section"; title: "Redes e protocolos"; sectionColor: "#6A91B8" }
                    IndexRow { width: parent.width; kind: "section"; title: "Cálculo II"; sectionColor: "#709A76" }
                    Rectangle { width: parent.width; height: 1; color: Theme.color.borderSubtle }
                    IndexHeader {
                        width: parent.width
                        title: "Páginas"
                        addTooltip: "Nova página"
                        onAddRequested: parent.parent.createKind = "page"
                    }
                    IndexCreate {
                        width: parent.width
                        visible: parent.parent.createKind === "page"
                        kind: "page"
                        onVisibleChanged: if (visible) Qt.callLater(begin)
                        onSubmitted: parent.parent.createKind = ""
                        onCanceled: parent.parent.createKind = ""
                    }
                    IndexRow { width: parent.width; title: "Barramentos"; selected: true }
                    IndexRow { width: parent.width; title: "Memória cache" }
                    IndexRow { width: parent.width; title: "Pipeline e hazards" }
                    }
                }
                Island {
                    width: Math.max(0, parent.width - Theme.size.indexWidth - Theme.space.island)
                    height: parent.height
                    color: Theme.color.base
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Theme.space.lg
                        width: Math.min(parent.width - Theme.space.xl * 2, 500)
                        height: 520
                        color: Theme.paper.warm
                        border.width: 1
                        border.color: Theme.paper.rule
                        Styled {
                            x: 36; y: 36
                            family: Theme.paperFont
                            token: ({ size: 28, line: 34, weight: Font.Medium, tracking: -0.3 })
                            color: Theme.paper.text
                            text: "Barramentos"
                        }
                    }
                }
            }

            Heading { text: "Ilhas e rolagem" }
            Styled {
                Layout.fillWidth: true
                token: Theme.type.caption
                color: Theme.color.textTertiary
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                text: "Painéis são ilhas sobre o fundo da janela, separados por " + Theme.space.island + " px e com raio de " + Theme.radius.island + " px. Role o índice e a página: a barra de rolagem só aparece ao rolar ou passar o mouse, e engrossa sob o ponteiro."
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: 1000
                implicitHeight: 420
                color: Theme.color.base
                border.width: 1
                border.color: Theme.color.borderSubtle

                Island {
                    id: barIsland
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space.island }
                    height: Theme.size.toolbar
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.space.sm
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space.xs
                        IconButton { iconName: "undo"; toolTip: "Desfazer"; keys: ["Ctrl", "Z"] }
                        IconButton { iconName: "redo"; toolTip: "Refazer"; keys: ["Ctrl", "Shift", "Z"] }
                        Item { width: Theme.space.md; height: 1 }
                        FieldButton { text: "IBM Plex Serif"; toolTip: "Fonte"; implicitWidth: 150 }
                        FieldButton { text: "16"; toolTip: "Tamanho"; implicitWidth: 64 }
                        IconButton { iconName: "bold"; checkable: true; toolTip: "Negrito"; keys: ["Ctrl", "B"] }
                        IconButton { iconName: "italic"; checkable: true; toolTip: "Itálico"; keys: ["Ctrl", "I"] }
                    }
                }
                Island {
                    id: statusIsland
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space.island }
                    height: Theme.size.statusBar
                    Styled {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.space.md
                        anchors.verticalCenter: parent.verticalCenter
                        token: Theme.type.caption
                        color: Theme.color.textSecondary
                        text: "Salvo localmente   ·   Página 3 de 40   ·   100%"
                        font.features: { "tnum": 1 }
                    }
                }
                Island {
                    id: indexIsland
                    anchors { left: parent.left; top: barIsland.bottom; bottom: statusIsland.top; margins: Theme.space.island }
                    width: 220
                    ListView {
                        id: demoPages
                        anchors.fill: parent
                        anchors.margins: Theme.space.xs
                        boundsBehavior: Flickable.StopAtBounds
                        model: 40
                        currentIndex: 2
                        Component.onCompleted: positionViewAtBeginning()
                        ScrollBar.vertical: ThinScrollBar {}
                        delegate: Rectangle {
                            required property int index
                            width: ListView.view.width - Theme.space.xs
                            height: Theme.size.pageRow
                            radius: Theme.radius.sm
                            color: ListView.isCurrentItem ? Theme.color.hover : rowArea.containsMouse ? Theme.color.raised : "transparent"
                            border.width: ListView.isCurrentItem ? 1 : 0
                            border.color: Theme.color.border
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.space.sm
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.space.sm
                                Icon { name: "page"; anchors.verticalCenter: parent.verticalCenter }
                                Styled { text: "Página " + (parent.parent.index + 1); anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true; onClicked: demoPages.currentIndex = parent.index }
                        }
                    }
                }
                Island {
                    anchors { left: indexIsland.right; right: parent.right; top: barIsland.bottom; bottom: statusIsland.top; margins: Theme.space.island }
                    color: Theme.color.base
                    ScrollArea {
                        id: demoCanvas
                        anchors.fill: parent
                        anchors.margins: 1
                        contentWidth: availableWidth
                        Item {
                            width: demoCanvas.availableWidth
                            implicitHeight: 1100
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: Theme.space.xl
                                width: Math.min(parent.width - Theme.space.xxl * 2, 520)
                                height: 1040
                                color: Theme.paper.warm
                                border.width: 1
                                border.color: Theme.paper.rule
                                Styled {
                                    x: 36; y: 36
                                    family: Theme.paperFont
                                    token: ({ size: 28, line: 34, weight: Font.Medium, tracking: -0.3 })
                                    color: Theme.paper.text
                                    text: "Página 3"
                                }
                            }
                        }
                    }
                }
            }

            Heading { text: "1 · Tipografia da interface (Inter)" }
            FontColumn { family: Theme.uiFont; Layout.fillWidth: true }

            Heading { text: "2 · Código e atalhos (JetBrains Mono)" }
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: 805
                implicitHeight: codeText.implicitHeight + Theme.space.lg * 2
                radius: Theme.radius.md
                color: Theme.color.surface
                border.width: 1
                border.color: Theme.color.borderSubtle
                Styled {
                    id: codeText
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space.lg }
                    family: Theme.monoFont
                    font.features: Theme.codeFeatures
                    token: Theme.type.code
                    elide: Text.ElideNone
                    color: Theme.color.textPrimary
                    text: "// encaminhamento evita a bolha no pipeline
if (ex.rd != 0 && ex.rd == id.rs1) {
    forward_a = FROM_EX;   // 0x1F → 31
}"
                }
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.sm
                spacing: Theme.space.xl
                Repeater {
                    model: [{ label: "Buscar", keys: ["Ctrl", "K"] }, { label: "Desfazer", keys: ["Ctrl", "Z"] },
                            { label: "Refazer", keys: ["Ctrl", "Shift", "Z"] }, { label: "Texto", keys: ["T"] },
                            { label: "Caneta", keys: ["P"] }, { label: "Seleção", keys: ["V"] }]
                    delegate: Row {
                        required property var modelData
                        spacing: Theme.space.sm
                        Styled { text: parent.modelData.label; token: Theme.type.caption; color: Theme.color.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Kbd { keys: parent.modelData.keys; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
            // Tooltip as it will appear on a tool button.
            Rectangle {
                Layout.topMargin: Theme.space.md
                implicitWidth: tipRow.implicitWidth + Theme.space.md * 2
                implicitHeight: 28
                radius: Theme.radius.sm
                color: Theme.color.overlay
                border.width: 1
                border.color: Theme.color.border
                Row {
                    id: tipRow
                    anchors.centerIn: parent
                    spacing: Theme.space.sm
                    Styled { text: "Buscar no caderno"; token: Theme.type.caption; anchors.verticalCenter: parent.verticalCenter }
                    Kbd { keys: ["Ctrl", "K"]; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Heading { text: "3 · Papel (não muda com o tema)" }
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: 805
                implicitHeight: paperColumn.implicitHeight + 88
                color: Theme.paper.warm
                border.width: 1
                border.color: Theme.paper.rule
                ColumnLayout {
                    id: paperColumn
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 44 }
                    spacing: Theme.space.md
                    Styled { family: Theme.uiFont; token: Theme.type.overline; text: "QUINTA-FEIRA, 23 DE OUTUBRO"; color: "#8A7F72" }
                    Styled { family: Theme.paperFont; token: ({ size: 38, line: 46, weight: Font.Medium, tracking: -0.4 }); text: "Pipeline e hazards"; color: Theme.paper.text }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.paper.rule }
                    Styled {
                        Layout.fillWidth: true
                        family: Theme.paperFont
                        token: ({ size: 16, line: 26, weight: Font.Normal, tracking: 0 })
                        color: Theme.paper.text
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                        text: "Um hazard de dados acontece quando uma instrução depende do resultado de outra que ainda não terminou. O encaminhamento (forwarding) resolve a maioria dos casos sem parar o pipeline."
                    }
                }
            }

            Heading { text: "4 · Ícones Phosphor — regular, ativo (fill) e tamanhos 14 / 16 / 20" }
            Repeater {
                model: [{ label: "" }]
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.space.sm
                    Repeater {
                        model: [{ size: 20, filled: false }, { size: 20, filled: true }, { size: 16, filled: false }, { size: 14, filled: false }]
                        delegate: RowLayout {
                            id: iconRow
                            required property var modelData
                            spacing: Theme.space.sm
                            Styled {
                                Layout.preferredWidth: 96
                                token: Theme.type.caption
                                color: Theme.color.textTertiary
                                text: iconRow.modelData.size + " px" + (iconRow.modelData.filled ? " · ativo" : "")
                            }
                            Repeater {
                                model: gallery.iconNames
                                delegate: Rectangle {
                                    required property string modelData
                                    implicitWidth: Theme.size.controlMd
                                    implicitHeight: Theme.size.controlMd
                                    radius: Theme.radius.sm
                                    color: iconRow.modelData.filled ? Theme.color.hover : "transparent"
                                    Icon {
                                        anchors.centerIn: parent
                                        name: parent.modelData
                                        size: iconRow.modelData.size
                                        filled: iconRow.modelData.filled
                                        color: iconRow.modelData.filled ? Theme.color.accent : Theme.color.textSecondary
                                    }
                                    ToolTip.visible: tipArea.containsMouse
                                    ToolTip.text: modelData
                                    MouseArea { id: tipArea; anchors.fill: parent; hoverEnabled: true }
                                }
                            }
                        }
                    }
                }
            }

            Heading { text: "5 · Cores do tema" }
            Flow {
                Layout.fillWidth: true
                Layout.bottomMargin: Theme.space.xxl
                spacing: Theme.space.md
                Repeater {
                    model: ["base", "surface", "raised", "hover", "pressed", "overlay", "border", "borderSubtle",
                        "borderStrong", "textPrimary", "textSecondary", "textTertiary", "textDisabled", "accent",
                        "accentHover", "accentPressed", "focus", "danger", "success", "warning"]
                    delegate: ColumnLayout {
                        required property string modelData
                        spacing: Theme.space.xs
                        Rectangle {
                            implicitWidth: 112
                            implicitHeight: 48
                            radius: Theme.radius.md
                            color: Theme.color[parent.modelData]
                            border.width: 1
                            border.color: Theme.color.border
                        }
                        Styled { text: parent.modelData; token: Theme.type.caption; color: Theme.color.textSecondary }
                        Styled { text: String(Theme.color[parent.modelData]).toUpperCase(); token: Theme.type.caption; color: Theme.color.textTertiary }
                    }
                }
            }
        }
    }
}
