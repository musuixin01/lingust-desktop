import QtQuick
import Linguist

Item {
    id: root

    anchors.fill: parent

    property string currentMode: translatorWindow ? translatorWindow.currentMode : "pill"
    property bool isDragging: false

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
        visible: root.currentMode === "card"
        onCollapseRequested: translatorWindow.collapseToPill()
        onTranslateRequested: appState.translate()
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
}
