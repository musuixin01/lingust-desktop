import QtQuick

Rectangle {
    id: lights
    // 固定占位和命中区域，避免悬停让相邻工具来回移动。
    width: 48
    height: 24
    radius: height / 2
    color: "#1affffff"
    border.color: "#2bffffff"
    border.width: 1

    readonly property bool hovered: lightsHover.hovered

    signal closeClicked()
    signal minimizeClicked()
    signal collapseClicked()

    Row {
        id: lightsRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: [
                { color: "#ff5f57", action: "close", icon: "qrc:/qt/qml/Linguist/resources/icons/close.svg" },
                { color: "#febc2e", action: "minimize", icon: "qrc:/qt/qml/Linguist/resources/icons/minus.svg" },
                { color: "#28c840", action: "collapse", icon: "qrc:/qt/qml/Linguist/resources/icons/maximize.svg" }
            ]

            delegate: Rectangle {
                // 指示灯保持固定尺寸，悬停仅改变明暗。
                width: 10
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
            }
        }
    }

    // 只观察悬停，不覆盖三个操作按钮。
    HoverHandler { id: lightsHover }
}
