import QtQuick

Rectangle {
    id: surface

    property bool isPill: false
    property bool isDragging: false
    property bool showShadow: true

    // 卡片：80% 不透明深灰（灰白系，无蓝调）；药丸：纯深黑
    color: isPill ? "#ff020617" : "#cc2a2a2e"
    radius: isPill ? 9999 : 32
    border.color: isDragging ? "#59ffffff" : "#26ffffff"
    border.width: 1

    // 卡片顶部灰白发光渐变
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: !isPill
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#26ffffff" }
            GradientStop { position: 0.35; color: "#0dffffff" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    // 药丸灰白高光渐变（黑亮釉面）
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: isPill
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#40ffffff" }
            GradientStop { position: 0.25; color: "#1affffff" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    // 顶部内发光刻痕
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "#59ffffff"
        border.width: 1
        opacity: isPill ? 0.9 : 0.7
        y: 1
        height: parent.height - 1
    }

    // 拖拽蓝色轮廓环
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "#4d60a5fa"
        border.width: 1.5
        opacity: isDragging ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
