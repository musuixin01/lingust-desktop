import QtQuick

Rectangle {
    id: lights
    property bool compact: false
    property bool micro: false
    property bool glassBackground: true
    property bool interactionEnabled: true
    // 药丸静止时连外框一起收紧；悬浮后恢复完整尺寸，释放的空间交给正文。
    width: micro ? (hovered ? 34 : 28) : (compact ? (hovered ? 44 : 34) : 48)
    height: micro ? (hovered ? 18 : 15) : (compact ? (hovered ? 22 : 18) : 24)
    radius: height / 2
    color: glassBackground ? (micro ? "#70141b29" : "#1affffff") : "transparent"
    border.color: glassBackground ? (micro ? "#30ffffff" : "#2bffffff") : "transparent"
    border.width: glassBackground ? 1 : 0

    readonly property bool hovered: interactionEnabled && lightsHover.hovered
    readonly property real indicatorSize: micro ? (hovered ? 7 : 5)
                                                : (compact ? (hovered ? 9 : 7) : 10)

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        visible: lights.glassBackground
        opacity: lights.micro ? 0.24 : 0.18
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#26ffffff" }
            GradientStop { position: 0.52; color: "#0db8d8ff" }
            GradientStop { position: 1.0; color: "#04040a18" }
        }
    }

    signal closeClicked()
    signal minimizeClicked()
    signal collapseClicked()

    Row {
        id: lightsRow
        anchors.centerIn: parent
        spacing: lights.micro ? (lights.hovered ? 3 : 2)
                              : (lights.compact && !lights.hovered ? 3 : 4)

        Behavior on spacing {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: [
                { color: "#ff5f57", action: "close", icon: "qrc:/qt/qml/Linguist/resources/icons/close.svg" },
                { color: "#febc2e", action: "minimize", icon: "qrc:/qt/qml/Linguist/resources/icons/minus.svg" },
                { color: "#28c840", action: "collapse", icon: "qrc:/qt/qml/Linguist/resources/icons/maximize.svg" }
            ]

            delegate: Rectangle {
                // 指示灯保持固定尺寸，悬停仅改变明暗。
                width: lights.indicatorSize
                height: width
                radius: width / 2
                color: modelData.color
                opacity: 0.9

                Image {
                    anchors.centerIn: parent
                    source: modelData.icon
                    sourceSize.width: parent.width * 0.6
                    sourceSize.height: parent.width * 0.6
                    opacity: buttonMouse.containsMouse ? 0.8 : 0.0
                    Behavior on opacity { NumberAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.Linear } }
                }

                MouseArea {
                    id: buttonMouse
                    anchors.fill: parent
                    anchors.topMargin: -7
                    anchors.bottomMargin: -7
                    anchors.leftMargin: -2
                    anchors.rightMargin: -2
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "close") lights.closeClicked()
                        else if (modelData.action === "minimize") lights.minimizeClicked()
                        else lights.collapseClicked()
                    }
                    onEntered: {
                        parent.opacity = 1.0
                    }
                    onExited: {
                        parent.opacity = 0.9
                    }
                }

                // 平滑动画

                Behavior on opacity { NumberAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
        }
    }

    Behavior on width {
        enabled: lights.compact
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        enabled: lights.compact
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // 只观察悬停，不覆盖三个操作按钮。
    HoverHandler { id: lightsHover }
}
