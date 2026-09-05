import QtQuick

Row {
    id: selector

    property string sourceLang: "EN"
    property string targetLang: "ZH"
    property bool compact: false
    property bool minimal: false

    signal sourceClicked()
    signal targetClicked()
    signal swapClicked()

    spacing: 4

    // 源语言胶囊
    Rectangle {
        width: selector.minimal ? 36 : (selector.compact ? 48 : 56)
        height: 24
        radius: 12
        color: "transparent"
        border.color: DesignTokens.borderInput
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: selector.sourceLang
            color: DesignTokens.textSecondary
            font.pixelSize: selector.minimal ? 9 : 10
            font.weight: Font.Medium
            font.family: "Segoe UI"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: selector.sourceClicked()
            onEntered: parent.color = "#1affffff"
            onExited: parent.color = "transparent"
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // 交换按钮
    Rectangle {
        width: 20
        height: 20
        radius: 10
        color: "transparent"

        Image {
            anchors.centerIn: parent
            source: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"
            sourceSize.width: 12
            sourceSize.height: 12
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: selector.swapClicked()
            onEntered: parent.color = "#1affffff"
            onExited: parent.color = "transparent"
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // 目标语言胶囊
    Rectangle {
        width: selector.minimal ? 36 : (selector.compact ? 48 : 56)
        height: 24
        radius: 12
        color: "transparent"
        border.color: DesignTokens.borderInput
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: selector.targetLang
            color: DesignTokens.textSecondary
            font.pixelSize: selector.minimal ? 9 : 10
            font.weight: Font.Medium
            font.family: "Segoe UI"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: selector.targetClicked()
            onEntered: parent.color = "#1affffff"
            onExited: parent.color = "transparent"
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
