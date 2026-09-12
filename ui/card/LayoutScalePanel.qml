import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Rectangle {
    id: panel
    signal closeRequested()

    radius: 15
    color: "#f0141d2e"
    border.width: 1
    border.color: DesignTokens.borderNormal
    clip: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 14
        opacity: 0.30
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#28ffffff" }
            GradientStop { position: 0.5; color: "#0db9d9ff" }
            GradientStop { position: 1.0; color: "#08040a18" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Text {
                Layout.fillWidth: true
                text: "页面比例"
                color: DesignTokens.textPrimary
                font { pixelSize: 12; weight: Font.DemiBold; family: DesignTokens.fontUi }
            }
            Rectangle {
                width: 42; height: 20; radius: 10
                color: "#182f80ed"
                border.width: 1
                border.color: "#3d60a5fa"
                Text {
                    anchors.centerIn: parent
                    text: appState.fontSizePercent + "%"
                    color: "#a9d2ff"
                    font { pixelSize: 10; family: DesignTokens.fontMono; weight: Font.DemiBold }
                }
            }
            IconButton {
                width: 20; height: 20
                iconSize: 9
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/close.svg"
                tooltip: "关闭"
                onClicked: panel.closeRequested()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            IconButton {
                width: 22; height: 22
                iconSize: 10
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/minus.svg"
                tooltip: "缩小页面"
                onClicked: appState.setFontSizePercent(appState.fontSizePercent - 10)
            }
            Basic.Slider {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                from: 70
                to: 150
                stepSize: 10
                value: appState.fontSizePercent
                onMoved: appState.setFontSizePercent(Math.round(value))
            }
            IconButton {
                width: 22; height: 22
                iconSize: 10
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/plus.svg"
                tooltip: "放大页面"
                onClicked: appState.setFontSizePercent(appState.fontSizePercent + 10)
            }
        }
    }
}
