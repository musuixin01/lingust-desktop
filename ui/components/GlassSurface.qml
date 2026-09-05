import QtQuick

Item {
    id: surface

    property bool isPill: false
    property bool isDragging: false
    property bool showShadow: true

    // 自动漫游高光的目标位置（限制在卡片中部，避免溢出）
    property real targetX: 190
    property real targetY: 245

    // === 背景 ===
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: surface.isPill ? 9999 : 32
        color: surface.isPill ? "#ff0a0a0a" : "#f2686870"
        border.color: surface.isDragging ? "#59ffffff" : "#26ffffff"
        border.width: 1
    }

    // === 卡片动态白色渐变高光（自动随机漫游，柔和弥散）===
    Rectangle {
        id: dynamicGlow
        width: 600
        height: 600
        radius: 300
        visible: !surface.isPill
        opacity: 0.5
        x: surface.targetX - 300
        y: surface.targetY - 300
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0dffffff" }
            GradientStop { position: 0.25; color: "#08ffffff" }
            GradientStop { position: 0.5; color: "#04ffffff" }
            GradientStop { position: 0.75; color: "#02ffffff" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
        Behavior on x { NumberAnimation { duration: 5000; easing.type: Easing.InOutSine } }
        Behavior on y { NumberAnimation { duration: 5000; easing.type: Easing.InOutSine } }
        z: 1
    }

    // 随机漫游定时器（限制在卡片中部 50% 区域，避免高光溢出角）
    Timer {
        interval: 4500
        running: !surface.isPill
        repeat: true
        onTriggered: {
            surface.targetX = surface.width * 0.25 + Math.random() * surface.width * 0.5
            surface.targetY = surface.height * 0.25 + Math.random() * surface.height * 0.5
        }
    }

    // === 内发光刻痕 ===
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: "transparent"
        border.color: "#40ffffff"
        border.width: 1
        opacity: surface.isPill ? 0.7 : 0.5
        y: 1
        height: parent.height - 1
        z: 2
    }

    // === 拖拽蓝色轮廓环 ===
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: "transparent"
        border.color: "#4d60a5fa"
        border.width: 1.5
        opacity: surface.isDragging ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        z: 3
    }
}
