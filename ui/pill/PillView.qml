import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: pill

    property bool isDragging: false
    property bool leftHovered: false
    property bool rightHovered: false
    property bool searchFocused: false

    signal expandRequested()

    property bool leftVisible: width >= 280 || leftHovered
    property bool rightVisible: width >= 360 || rightHovered

    // === 毛玻璃背景 ===
    GlassSurface {
        anchors.fill: parent
        isPill: true
        isDragging: pill.isDragging
    }

    // === 内容行 ===
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        // --- 左侧：红绿灯（胶囊框，和卡片一致）---
        Item {
            id: leftArea
            Layout.preferredWidth: leftVisible ? 56 : 0
            Layout.fillHeight: true
            clip: true

            Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            TrafficLights {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 4
                opacity: leftVisible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                onCloseClicked: appState.clearText()
                onCollapseClicked: pill.expandRequested()
                onMinimizeClicked: pill.expandRequested()
            }

            MouseArea {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 20
                hoverEnabled: true
                onEntered: leftHovered = true
                onExited: leftHovered = false
                z: 10
            }
        }

        // --- 搜索框 ---
        Rectangle {
            id: searchBox
            Layout.preferredHeight: 28
            Layout.preferredWidth: searchFocused ? Math.min(180, Math.max(120, pill.width * 0.45)) : (pill.width < 280 ? 28 : 100)
            Layout.maximumWidth: searchFocused ? 180 : 140
            radius: 14
            color: searchFocused ? "#33ffffff" : "#1affffff"
            border.color: searchFocused ? "#8060a5fa" : DesignTokens.borderInput
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 4
                spacing: 4

                Image {
                    Layout.alignment: Qt.AlignVCenter
                    source: "qrc:/qt/qml/Linguist/resources/icons/search.svg"
                    sourceSize.width: 14; sourceSize.height: 14
                }

                TextField {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    id: pillInput
                    text: appState.sourceText
                    placeholderText: searchFocused ? "搜索/翻译..." : (pill.width >= 300 ? "搜索/翻译..." : "")
                    color: DesignTokens.textSecondary
                    font.pixelSize: 12
                    font.family: "Segoe UI"
                    background: Rectangle { color: "transparent" }
                    visible: searchFocused || pill.width >= 280
                    onTextChanged: appState.setSourceText(text)
                    onAccepted: appState.translate()
                    onFocusChanged: searchFocused = focus
                }

                Image {
                    Layout.alignment: Qt.AlignVCenter
                    source: "qrc:/qt/qml/Linguist/resources/icons/close.svg"
                    sourceSize.width: 12; sourceSize.height: 12
                    visible: appState.sourceText.length > 0 && searchFocused
                    MouseArea { anchors.fill: parent; onClicked: { appState.clearText(); pillInput.focus = true } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: pillInput.focus = true
                z: -1
            }
        }

        // --- 原文 | 译文 ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 4

                Text {
                    Layout.maximumWidth: parent.width * 0.35
                    text: appState.sourceText
                    color: "#d9ffffff"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: "Segoe UI"
                    elide: Text.ElideRight
                    visible: appState.sourceText.length > 0
                }

                Text {
                    text: pill.width < 300 ? "|" : "➔"
                    color: pill.width < 300 ? "#4cffffff" : DesignTokens.accentBlue
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                MarqueeText {
                    Layout.fillWidth: true
                    text: appState.completeTranslation()
                    textColor: "#f2ffffff"
                    fontSize: 12
                    visible: appState.translatedText.length > 0 && appState.sourceText.length > 0
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: appState.isLoading ? "翻译中..." : (appState.sourceText ? "按回车翻译..." : "输入或划词翻译")
                color: appState.sourceText ? "#80ffffff" : "#66ffffff"
                font.pixelSize: 11
                font.italic: true
                font.family: "Segoe UI"
                visible: appState.translatedText.length === 0 || appState.sourceText.length === 0
            }
        }

        // --- 右侧：操作按钮 ---
        Item {
            id: rightArea
            Layout.preferredWidth: rightVisible && !appState.isLoading ? 110 : 0
            Layout.fillHeight: true
            clip: true

            Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 28
                hoverEnabled: true
                onEntered: rightHovered = true
                onExited: rightHovered = false
                z: 10
            }

            // 加载指示器
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 6
                width: pill.width < 220 ? 20 : (pill.width < 280 ? 26 : 34)
                height: 2.5
                radius: 1.25
                color: "#1affffff"
                visible: appState.isLoading
                clip: true

                Rectangle {
                    height: parent.height
                    width: parent.width * 0.6
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: DesignTokens.accentBlue }
                        GradientStop { position: 0.5; color: "#67e8f9" }
                        GradientStop { position: 1.0; color: DesignTokens.accentEmerald }
                    }
                    NumberAnimation on x {
                        running: appState.isLoading
                        loops: Animation.Infinite
                        from: -width; to: parent.width
                        duration: 1250
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            // 按钮行
            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 4
                spacing: 2
                opacity: rightVisible && !appState.isLoading ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                    iconSize: 14
                    visible: appState.translatedText.length > 0
                    onClicked: appState.speak()
                }
                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/copy.svg"
                    iconSize: 14
                    visible: appState.translatedText.length > 0
                    onClicked: appState.copyTranslation()
                }
                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"
                    iconSize: 14
                    iconColor: "#cc93c5fd"
                }
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: "#26ffffff"
                    border.color: DesignTokens.borderSubtle
                    border.width: 1

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/Linguist/resources/icons/maximize.svg"
                        sourceSize.width: 14; sourceSize.height: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: pill.expandRequested()
                        onEntered: { parent.color = "#663b82f6"; parent.scale = 1.1 }
                        onExited: { parent.color = "#26ffffff"; parent.scale = 1.0 }
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }
            }
        }
    }

    // === 拉伸手柄 ===
    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 32
        anchors.right: parent.right; anchors.rightMargin: 32
        anchors.bottom: parent.bottom
        height: 12
        color: "transparent"
        z: 20
        MouseArea { anchors.fill: parent; cursorShape: Qt.SizeVerCursor }
    }
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top; anchors.topMargin: 8
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        width: 10
        color: "transparent"
        z: 20
        MouseArea { anchors.fill: parent; cursorShape: Qt.SizeHorCursor }
    }
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top; anchors.topMargin: 8
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        width: 10
        color: "transparent"
        z: 20
        MouseArea { anchors.fill: parent; cursorShape: Qt.SizeHorCursor }
    }
}
