import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: settingsView
    width: 420
    height: 560
    radius: 24
    color: "#f22a2a2e"
    border.color: "#33ffffff"
    border.width: 1

    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // 标题栏
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "设置"
                color: "#ffffff"
                font.pixelSize: 18
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 28; height: 28; radius: 14
                color: "#1affffff"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#ccffffff"
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: settingsView.closeRequested()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#1affffff" }

        // 滚动内容区
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width
                spacing: 20

                // === 翻译引擎 ===
                Text {
                    text: "翻译引擎"
                    color: "#99ffffff"
                    font.pixelSize: 12
                    font.weight: Font.SemiBold
                    font.letterSpacing: 1
                    font.capitalization: Font.AllUppercase
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: ["gemini", "deepl", "youdao", "offline"]
                        delegate: Rectangle {
                            width: 80; height: 32; radius: 16
                            color: appState.engine === modelData ? "#cc3b82f6" : "#1affffff"
                            border.color: appState.engine === modelData ? "#60a5fa" : "#26ffffff"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData === "gemini" ? "Gemini" : modelData === "deepl" ? "DeepL" : modelData === "youdao" ? "有道" : "离线"
                                color: appState.engine === modelData ? "#ffffff" : "#b2ffffff"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: appState.setEngine(modelData)
                            }
                        }
                    }
                }

                // API 密钥输入
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: appState.engine !== "offline"

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: appState.engine === "gemini" ? "Gemini API Key" : appState.engine === "deepl" ? "DeepL API Key" : "有道 AppKey"
                        color: "#ffffff"
                        selectionColor: "#60a5fa"
                        font.pixelSize: 12
                        background: Rectangle {
                            radius: 8
                            color: "#0dffffff"
                            border.color: "#26ffffff"
                            border.width: 1
                        }
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: appState.engine === "youdao" ? "有道 AppSecret" : ""
                        color: "#ffffff"
                        font.pixelSize: 12
                        visible: appState.engine === "youdao"
                        background: Rectangle {
                            radius: 8
                            color: "#0dffffff"
                            border.color: "#26ffffff"
                            border.width: 1
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1affffff" }

                // === 翻译设置 ===
                Text {
                    text: "翻译设置"
                    color: "#99ffffff"
                    font.pixelSize: 12
                    font.weight: Font.SemiBold
                    font.letterSpacing: 1
                    font.capitalization: Font.AllUppercase
                }

                // 划词翻译
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text { text: "全局划词翻译"; color: "#f2ffffff"; font.pixelSize: 13 }
                        Text { text: "选中文字自动翻译"; color: "#66ffffff"; font.pixelSize: 10 }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 44; height: 24; radius: 12
                        color: appState.selectionTranslation ? "#cc3b82f6" : "#33ffffff"

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: appState.selectionTranslation ? (parent.width - width - 3) : 3
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: appState.setSelectionTranslation(!appState.selectionTranslation)
                        }
                    }
                }

                // 自动发音
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text { text: "自动发音"; color: "#f2ffffff"; font.pixelSize: 13 }
                        Text { text: "翻译完成后自动朗读"; color: "#66ffffff"; font.pixelSize: 10 }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 44; height: 24; radius: 12
                        color: appState.autoSpeak ? "#cc3b82f6" : "#33ffffff"

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: appState.autoSpeak ? (parent.width - width - 3) : 3
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: appState.setAutoSpeak(!appState.autoSpeak)
                        }
                    }
                }

                // 紧凑模式
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text { text: "紧凑模式"; color: "#f2ffffff"; font.pixelSize: 13 }
                        Text { text: "减小间距和字体大小"; color: "#66ffffff"; font.pixelSize: 10 }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 44; height: 24; radius: 12
                        color: appState.compactMode ? "#cc3b82f6" : "#33ffffff"

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: appState.compactMode ? (parent.width - width - 3) : 3
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: appState.setCompactMode(!appState.compactMode)
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1affffff" }

                // === 外观设置 ===
                Text {
                    text: "外观设置"
                    color: "#99ffffff"
                    font.pixelSize: 12
                    font.weight: Font.SemiBold
                    font.letterSpacing: 1
                    font.capitalization: Font.AllUppercase
                }

                // 卡片透明度
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "卡片透明度"; color: "#f2ffffff"; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { text: Math.round(appState.cardOpacity * 100) + "%"; color: "#93c5fd"; font.pixelSize: 12; font.family: "Consolas" }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 0.6; to: 1.0; stepSize: 0.05
                        value: appState.cardOpacity
                        onMoved: appState.setCardOpacity(value)
                    }
                }

                // 字体大小
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "字体大小"; color: "#f2ffffff"; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { text: Math.round(appState.fontSizePercent) + "%"; color: "#93c5fd"; font.pixelSize: 12; font.family: "Consolas" }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 60; to: 150; stepSize: 5
                        value: appState.fontSizePercent
                        onMoved: appState.setFontSizePercent(value)
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 20 }
            }
        }
    }
}
