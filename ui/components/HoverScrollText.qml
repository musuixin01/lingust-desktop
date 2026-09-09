import QtQuick

Item {
    id: root
    property string text: ""
    property color textColor: DesignTokens.textSecondary
    property int fontSize: DesignTokens.fontSizeSm
    property real speed: 35
    property bool hovered: hoverObserver.hovered
    property string prefix: ""
    property color prefixColor: DesignTokens.accentBlueDim
    readonly property bool stacked: prefix.length > 0 && width < 260 && height >= fontSize * 2 + 8
    readonly property bool isOverflow: scrollText.implicitWidth > textViewport.width
    readonly property real overflowDistance: Math.max(0, scrollText.implicitWidth - textViewport.width)
    readonly property real scrollDuration: overflowDistance / Math.max(1, speed)
    clip: true

    Text {
        id: prefixText
        objectName: "scrollPrefix"
        visible: root.prefix.length > 0
        x: 0
        y: root.stacked ? Math.max(0, (root.height - height - textViewport.height - 4) / 2) : (root.height - height) / 2
        width: root.stacked ? root.width : Math.min(implicitWidth, root.width * 0.42)
        text: root.prefix
        color: root.prefixColor
        font.pixelSize: root.fontSize - 1
        font.family: "Consolas"
        elide: Text.ElideRight
    }
    Item {
        id: textViewport
        objectName: "scrollViewport"
        x: root.stacked || !prefixText.visible ? 0 : prefixText.width + 6
        y: root.stacked ? prefixText.y + prefixText.height + 4 : (root.height - height) / 2
        width: Math.max(0, root.width - x)
        height: scrollText.implicitHeight
        clip: true
        Text {
            id: scrollText
            objectName: "scrollValue"
            x: 0
            text: root.text
            color: root.textColor
            font.pixelSize: root.fontSize
            font.family: "Segoe UI"
            font.weight: root.textColor === DesignTokens.textPrimary ? Font.DemiBold : Font.Normal
        }
    }
    SequentialAnimation {
        id: scrollSequence
        running: root.hovered && root.isOverflow
        loops: Animation.Infinite
        PauseAnimation { duration: 300 }
        NumberAnimation { target: scrollText; property: "x"; to: -root.overflowDistance; duration: root.scrollDuration * 1000; easing.type: Easing.Linear }
        PauseAnimation { duration: 600 }
        NumberAnimation { target: scrollText; property: "x"; to: 0; duration: root.scrollDuration * 1000; easing.type: Easing.Linear }
        PauseAnimation { duration: 600 }
        onStopped: scrollText.x = 0
    }
    function resetScroll() {
        scrollSequence.stop()
        scrollText.x = 0
        if (hovered && isOverflow) scrollSequence.start()
    }
    onWidthChanged: resetScroll()
    onTextChanged: resetScroll()
    onPrefixChanged: resetScroll()
    HoverHandler { id: hoverObserver }
}
