import QtQuick

Item {
    id: surface
    visible: !(typeof translatorWindow !== "undefined" && translatorWindow
               && translatorWindow.usesNativeSurface === true)
    property bool isPill: false
    property bool isDragging: false
    property bool isResizing: false
    property bool showShadow: true
    readonly property real cornerRadius: Math.min(width / 2, height / 2,
        isPill ? height / 2 : DesignTokens.radiusCard)

    // All layers share the silhouette; Item.clip only clips a rectangle.
    Rectangle {
        anchors.fill: parent
        radius: surface.cornerRadius
        antialiasing: true
        color: surface.isPill ? DesignTokens.bgPill : DesignTokens.bgCardBase
        opacity: (typeof appState !== "undefined" && appState) ? appState.cardOpacity : 0.96
    }
    Rectangle {
        anchors.fill: parent
        radius: surface.cornerRadius
        antialiasing: true
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: "#23ffffff" }
            GradientStop { position: 0.18; color: "#16ffffff" }
            GradientStop { position: 0.75; color: "#0cffffff" }
            GradientStop { position: 1; color: "#10ffffff" }
        }
        border.width: 1
        border.color: surface.isDragging ? DesignTokens.borderActive : "#26ffffff"
    }
}
