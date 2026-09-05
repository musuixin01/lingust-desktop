import QtQuick
import Linguist

Item {
    id: root

    anchors.fill: parent

    property string currentMode: translatorWindow ? translatorWindow.currentMode : "pill"
    property bool isDragging: false
    property bool showSettings: false

    // === 状态机：pill ↔ card ===
    states: [
        State {
            name: "pill"
            when: root.currentMode === "pill"
            PropertyChanges { target: pillView; opacity: 1.0; visible: true }
            PropertyChanges { target: cardView; opacity: 0.0; visible: false }
        },
        State {
            name: "card"
            when: root.currentMode === "card"
            PropertyChanges { target: pillView; opacity: 0.0; visible: false }
            PropertyChanges { target: cardView; opacity: 1.0; visible: true }
        }
    ]

    transitions: [
        Transition {
            from: "pill"; to: "card"
            SequentialAnimation {
                NumberAnimation { target: pillView; property: "opacity"; to: 0; duration: 100 }
                NumberAnimation { target: cardView; property: "opacity"; to: 1; duration: 200 }
            }
        },
        Transition {
            from: "card"; to: "pill"
            SequentialAnimation {
                NumberAnimation { target: cardView; property: "opacity"; to: 0; duration: 100 }
                NumberAnimation { target: pillView; property: "opacity"; to: 1; duration: 200 }
            }
        }
    ]

    // === 药丸视图 ===
    PillView {
        id: pillView
        anchors.fill: parent
        isDragging: root.isDragging
        visible: root.currentMode === "pill"
        onExpandRequested: translatorWindow.expandToCard()
    }

    // === 卡片视图 ===
    CardView {
        id: cardView
        anchors.fill: parent
        isDragging: root.isDragging
        visible: root.currentMode === "card" && !root.showSettings
        onCollapseRequested: translatorWindow.collapseToPill()
        onTranslateRequested: appState.translate()
        onSettingsRequested: root.showSettings = true
    }

    // 设置页面
    SettingsView {
        id: settingsView
        anchors.centerIn: parent
        width: Math.min(parent.width - 20, 420)
        height: Math.min(parent.height - 20, 560)
        visible: root.showSettings
        z: 100
        onCloseRequested: root.showSettings = false
    }

    // === 拖拽区域（仅顶部栏，不遮挡按钮）===
    MouseArea {
        id: dragArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.currentMode === "pill" ? parent.height : 38
        z: 1

        propagateComposedEvents: true
        hoverEnabled: false

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.isDragging = true
                if (translatorWindow) translatorWindow.startSystemMove()
            }
        }
        onReleased: function() {
            root.isDragging = false
        }
    }

    // === 8向缩放手柄（顶层，确保在拖拽区域之上）===
    // 右下角
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 18; height: 18
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
            }
        }
    }
    // 左下角
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 18; height: 18
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
            }
        }
    }
    // 右上角
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        width: 18; height: 18
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.RightEdge | Qt.TopEdge)
            }
        }
    }
    // 左上角
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        width: 18; height: 18
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
            }
        }
    }
    // 右边缘
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: 10
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.RightEdge)
            }
        }
    }
    // 左边缘
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: 10
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.LeftEdge)
            }
        }
    }
    // 下边缘
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        height: 10
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.BottomEdge)
            }
        }
    }
    // 上边缘（避开顶部拖拽区域的中间部分，只在两侧）
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 120
        anchors.right: parent.right
        anchors.rightMargin: 120
        height: 8
        color: "transparent"
        z: 100
        visible: root.currentMode === "card"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            onPressed: function(m) {
                if (m.button === Qt.LeftButton && translatorWindow)
                    translatorWindow.startSystemResize(Qt.TopEdge)
            }
        }
    }
}
