pragma Singleton
import QtQuick

QtObject {
    id: tokens

    // === Surfaces (厚实清透·液态玻璃) ===
    readonly property color bgCard: "#bf5c5c64"
    readonly property color bgCardDeep: "#d93a3a40"
    readonly property color bgSubtle: "#00000000"
    readonly property color bgPill: "#e60e0e12"
    readonly property color bgDark: "#e0101014"
    readonly property color bgInput: "#00000000"
    readonly property color bgInputFocus: "#1affffff"

    // === Borders (细腻高级) ===
    readonly property color borderNormal: "#2bffffff"
    readonly property color borderActive: "#4dffffff"
    readonly property color borderSubtle: "#1affffff"
    readonly property color borderInput: "#2effffff"
    readonly property color borderInputFocus: "#4d60a5fa"

    // === Text ===
    readonly property color textPrimary: "white"
    readonly property color textSecondary: "#e0ffffff"
    readonly property color textTertiary: "#99ffffff"
    readonly property color textPlaceholder: "#59ffffff"

    // === Accent Colors ===
    readonly property color accentBlue: "#60a5fa"
    readonly property color accentBlueDim: "#8060a5fa"
    readonly property color accentEmerald: "#34d399"
    readonly property color accentAmber: "#fbbf24"
    readonly property color accentRed: "#f87171"
    readonly property color accentPurple: "#c084fc"

    // === Traffic Lights ===
    readonly property color lightRed: "#ccf87171"
    readonly property color lightAmber: "#ccfbbf24"
    readonly property color lightEmerald: "#cc34d399"

    // === Radii ===
    readonly property int radiusCard: 32
    readonly property int radiusInner: 20
    readonly property int radiusMinimal: 16
    readonly property int radiusPill: 9999

    // === Spacing (8pt grid) ===
    readonly property int spaceXs: 4
    readonly property int spaceSm: 6
    readonly property int spaceMd: 8
    readonly property int spaceLg: 12
    readonly property int spaceXl: 16
    readonly property int space2xl: 24

    // === Font Sizes ===
    readonly property real fontScale: appState ? appState.fontSizePercent / 100.0 : 0.92
    readonly property int fontSizeMicro: 9
    readonly property int fontSizeXs: 11
    readonly property int fontSizeSm: 13
    readonly property int fontSizeBase: 15
    readonly property int fontSizeLg: 18
    readonly property int fontSizeXl: 20

    // === Animation ===
    readonly property int durationFast: 150
    readonly property int durationNormal: 250
    readonly property int durationSlow: 300
    readonly property string easingOut: "OutCubic"
    readonly property string easingSpring: "OutBack"

    // === Shadows (厚实深度) ===
    readonly property color shadowColor: "#a0000000"
    readonly property real shadowBlur: 70
    readonly property real shadowY: 30
}
