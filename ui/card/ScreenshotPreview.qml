import QtQuick
import QtQuick.Controls.Basic as Basic
import Linguist

Rectangle {
    id: preview
    required property string sourceUrl
    signal closeRequested()

    radius: 26
    color: "#f20b1220"
    border { width: 1; color: "#40ffffff" }
    clip: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        radius: 20
        color: "#a8060a12"
        border { width: 1; color: "#20ffffff" }

        Image {
            id: fullImage
            anchors.fill: parent
            anchors.margins: 12
            source: preview.sourceUrl
            fillMode: Image.PreserveAspectFit
            cache: false
            asynchronous: true
        }

        Text {
            anchors.centerIn: parent
            visible: fullImage.status === Image.Loading
            text: "正在打开原图…"
            color: DesignTokens.textSecondary
            font { family: DesignTokens.fontUi; pixelSize: 12 }
        }
    }

    Rectangle {
        x: 18; y: 14
        width: titleText.implicitWidth + 20; height: 28; radius: 10
        color: "#b3182233"
        border { width: 1; color: "#2cffffff" }
        Text {
            id: titleText
            anchors.centerIn: parent
            text: "截图原图"
            color: DesignTokens.textPrimary
            font { family: DesignTokens.fontUi; pixelSize: 11; weight: Font.DemiBold }
        }
    }

    IconButton {
        anchors { top: parent.top; right: parent.right; margins: 14 }
        width: 28; height: 28; iconSize: 12
        iconSource: "qrc:/qt/qml/Linguist/resources/icons/close.svg"
        tooltip: "关闭"
        onClicked: preview.closeRequested()
    }
}
