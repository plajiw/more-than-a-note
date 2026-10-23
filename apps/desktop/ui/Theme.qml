pragma Singleton
import QtQuick

// Design tokens from docs/13-estudo-visual.md §3. Values are proposals under
// evaluation; components read them from here instead of hard-coding colors.
QtObject {
    id: theme

    property bool dark: true

    // Under evaluation in the gallery (docs/13 §6, steps 2 and 3).
    property string uiFont: "Inter"
    property string paperFont: "IBM Plex Serif"
    property string iconSet: "phosphor"   // "phosphor" | "fluent"
    property bool nativeText: false

    readonly property QtObject graphite: QtObject {
        readonly property color base: "#17191C"
        readonly property color surface: "#202328"
        readonly property color raised: "#262A30"
        readonly property color hover: "#2D3239"
        readonly property color pressed: "#343A42"
        readonly property color overlay: "#2A2E35"
        readonly property color border: "#383D44"
        readonly property color borderSubtle: "#30353B"
        readonly property color borderStrong: "#4A5059"
        readonly property color textPrimary: "#F0F1F2"
        readonly property color textSecondary: "#AEB7C2"
        readonly property color textTertiary: "#7D8793"
        readonly property color textDisabled: "#5A626C"
        readonly property color accent: "#DDAA75"
        readonly property color accentHover: "#E6B988"
        readonly property color accentPressed: "#C9965F"
        readonly property color accentOn: "#191D21"
        readonly property color focus: "#7DAAF7"
        readonly property color danger: "#F07F72"
        readonly property color success: "#8FBD9C"
        readonly property color warning: "#E0B860"
        readonly property color shadow: Qt.rgba(0, 0, 0, 0.40)
    }

    readonly property QtObject light: QtObject {
        readonly property color base: "#F5F6F4"
        readonly property color surface: "#FFFFFF"
        readonly property color raised: "#F0F2F0"
        readonly property color hover: "#E7EAE7"
        readonly property color pressed: "#DCE0DD"
        readonly property color overlay: "#FFFFFF"
        readonly property color border: "#D4D9D7"
        readonly property color borderSubtle: "#E5E8E5"
        readonly property color borderStrong: "#B9C0BE"
        readonly property color textPrimary: "#1F252B"
        readonly property color textSecondary: "#52606C"
        readonly property color textTertiary: "#6E7983"
        readonly property color textDisabled: "#A7AFB5"
        readonly property color accent: "#9B6336"
        readonly property color accentHover: "#8A5629"
        readonly property color accentPressed: "#7A4A22"
        readonly property color accentOn: "#FFFFFF"
        readonly property color focus: "#2868BD"
        readonly property color danger: "#C2412F"
        readonly property color success: "#2F7D4F"
        readonly property color warning: "#9A6B00"
        readonly property color shadow: Qt.rgba(0.11, 0.14, 0.16, 0.12)
    }

    readonly property QtObject color: dark ? graphite : light

    // Paper never follows the interface theme.
    readonly property QtObject paper: QtObject {
        readonly property color warm: "#F4F0E9"
        readonly property color white: "#FFFEFA"
        readonly property color text: "#282B2E"
        readonly property color rule: "#D5CCC0"
    }

    readonly property QtObject space: QtObject {
        readonly property int xxs: 2
        readonly property int xs: 4
        readonly property int s6: 6
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int s20: 20
        readonly property int xl: 24
        readonly property int xxl: 32
        readonly property int xxxl: 40
    }

    readonly property QtObject radius: QtObject {
        readonly property int xs: 3
        readonly property int sm: 5
        readonly property int md: 7
        readonly property int lg: 10
        readonly property int xl: 12
    }

    readonly property QtObject size: QtObject {
        readonly property int controlXs: 24
        readonly property int controlSm: 28
        readonly property int controlMd: 32
        readonly property int controlLg: 36
        readonly property int menuBar: 28
        readonly property int notebookBar: 36
        readonly property int toolbar: 46
        readonly property int statusBar: 30
        readonly property int sectionRow: 30
        readonly property int pageRow: 34
        readonly property int libraryRow: 88
        readonly property int indexWidth: 248
        readonly property int iconToolbar: 20
        readonly property int iconList: 16
        readonly property int iconStatus: 14
    }

    // pixelSize, lineHeight (px), weight, letterSpacing (px)
    readonly property QtObject type: QtObject {
        readonly property var overline: ({ size: 10, line: 13, weight: Font.DemiBold, tracking: 0.6 })
        readonly property var caption: ({ size: 11, line: 14, weight: Font.Normal, tracking: 0 })
        readonly property var control: ({ size: 12, line: 16, weight: Font.Medium, tracking: 0 })
        readonly property var body: ({ size: 13, line: 18, weight: Font.Normal, tracking: -0.1 })
        readonly property var titleSm: ({ size: 15, line: 20, weight: Font.DemiBold, tracking: -0.15 })
        readonly property var title: ({ size: 20, line: 26, weight: Font.DemiBold, tracking: -0.3 })
        readonly property var display: ({ size: 28, line: 34, weight: Font.DemiBold, tracking: -0.5 })
    }

    readonly property QtObject motion: QtObject {
        readonly property int fast: 100
        readonly property int base: 160
        readonly property int slow: 240
    }
}
