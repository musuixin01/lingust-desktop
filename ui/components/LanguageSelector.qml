import QtQuick

Rectangle {
    id: selector
    width: selector.textOnly ? 36 : (selector.iconOnly ? 24 : (selector.minimal ? 56 : (selector.compact ? 70 : 82)))
    height: 24
    radius: 12
    color: "transparent"
    // textOnly模式下无边框
    border.color: selector.textOnly ? "transparent" : DesignTokens.borderInput
    border.width: selector.textOnly ? 0 : 1

    property string sourceLang: "EN"
    property string targetLang: "ZH"
    property bool compact: false
    property bool minimal: false
    property bool iconOnly: false
    property bool textOnly: false
    readonly property bool hovered: selectorHover.hovered

    signal sourceClicked()
    signal targetClicked()
    signal swapClicked()

    // 完整模式：EN ⇄ ZH
    Item {
        anchors.fill: parent
        visible: !selector.iconOnly && !selector.textOnly

        // 源语言
        Text {
            id: sourceText
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: selector.sourceLang
            color: srcMouse.containsMouse ? "#ffffff" : DesignTokens.textSecondary
            font.pixelSize: selector.minimal ? 9 : 10
            font.weight: Font.Medium
            font.family: "Segoe UI"

            Behavior on color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

            MouseArea {
                id: srcMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: selector.sourceClicked()
            }
        }

        // 交换按钮
        Rectangle {
            id: swapBtn
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: 9
            color: swapMouse.containsMouse ? "#26ffffff" : "transparent"
            scale: swapMouse.pressed ? 0.88 : (swapMouse.containsMouse ? 1.10 : 1.0)

            Behavior on color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
            Behavior on scale { enabled: !swapMouse.pressed; NumberAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

            Image {
                id: swapIcon
                anchors.centerIn: parent
                source: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"
                sourceSize.width: 11
                sourceSize.height: 11
                property real rot: 0
                rotation: rot
                Behavior on rot { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: swapMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    swapIcon.rot += 180;
                    selector.swapClicked();
                }
            }
        }

        // 目标语言
        Text {
            id: targetText
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: selector.targetLang
            color: tgtMouse.containsMouse ? "#ffffff" : DesignTokens.textSecondary
            font.pixelSize: selector.minimal ? 9 : 10
            font.weight: Font.Medium
            font.family: "Segoe UI"

            Behavior on color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

            MouseArea {
                id: tgtMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: selector.targetClicked()
            }
        }
    }

    // iconOnly模式：只显示交换图标
    Item {
        anchors.fill: parent
        visible: selector.iconOnly && !selector.textOnly

        Rectangle {
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: 9
            color: "transparent"

            Image {
                anchors.centerIn: parent
                source: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"
                sourceSize.width: 11
                sourceSize.height: 11
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: selector.swapClicked()
                onEntered: parent.color = "#1affffff"
                onExited: parent.color = "transparent"
            }
        }
    }

    // textOnly模式：EN➔ZH 蓝色无边框
    Text {
        anchors.centerIn: parent
        visible: selector.textOnly
        text: selector.sourceLang + "➔" + selector.targetLang
        color: "#60a5fa"
        font.pixelSize: 10
        font.weight: Font.Medium
        font.family: "Segoe UI"

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            onClicked: selector.swapClicked()
        }
    }

    // 悬停观察不抢占子按钮点击；宽度直接跟随布局。
    HoverHandler { id: selectorHover }
}
