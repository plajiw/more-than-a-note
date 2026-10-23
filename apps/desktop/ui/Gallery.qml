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
                label: "Fonte da interface"; options: ["Inter", "IBM Plex Sans"]
                current: Theme.uiFont === "Inter" ? 0 : 1
                onPicked: index => Theme.uiFont = options[index]
            }
            Choice {
                label: "Ícones"; options: ["Phosphor", "Fluent"]
                current: Theme.iconSet === "phosphor" ? 0 : 1
                onPicked: index => Theme.iconSet = index === 0 ? "phosphor" : "fluent"
            }
            Choice {
                label: "Renderização do texto"; options: ["Qt", "Nativa"]
                current: Theme.nativeText ? 1 : 0
                onPicked: index => Theme.nativeText = index === 1
            }
        }
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

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

            Heading { text: "1 · Tipografia da interface" }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.xxl
                FontColumn { family: "Inter"; Layout.fillWidth: true; Layout.preferredWidth: 1 }
                Rectangle { Layout.fillHeight: true; width: 1; color: Theme.color.borderSubtle }
                FontColumn { family: "IBM Plex Sans"; Layout.fillWidth: true; Layout.preferredWidth: 1 }
            }

            Heading { text: "2 · Papel (não muda com o tema)" }
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

            Heading { text: "3 · Ícones — regular, ativo (fill) e tamanhos 14 / 16 / 20" }
            Repeater {
                model: [{ set: "phosphor", label: "Phosphor" }, { set: "fluent", label: "Fluent System Icons" }]
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.space.sm
                    Styled { text: modelData.label; token: Theme.type.titleSm; Layout.topMargin: Theme.space.md }
                    Repeater {
                        model: [{ size: 20, filled: false }, { size: 20, filled: true }, { size: 16, filled: false }, { size: 14, filled: false }]
                        delegate: RowLayout {
                            id: iconRow
                            required property var modelData
                            property string set: parent.modelData.set
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
                                        iconSet: iconRow.set
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

            Heading { text: "4 · Cores do tema" }
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
