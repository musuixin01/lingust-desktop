import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: card

    property bool isDragging: false
    property bool isMinimal: height <= 130 || (width <= 220 && height <= 160)
    property bool isUltraCompact: !isMinimal && (width < 280 || height < 260)
    property bool isVeryCompact: !isMinimal && (width < 340 || height < 330)
    property bool isCompact: !isMinimal && (width < 420 || height < 400)
    property bool dynamicCompact: !isMinimal && (appState.compactMode || isCompact)
    property bool dynamicTight: !isMinimal && isVeryCompact

    signal collapseRequested()
    signal translateRequested()
    signal settingsRequested()

    // === 毛玻璃背景 ===
    GlassSurface {
        anchors.fill: parent
        isPill: false
        isDragging: card.isDragging
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ========== 顶部栏 ==========
        Rectangle {
            id: topBar
            Layout.fillWidth: true
            Layout.preferredHeight: isUltraCompact ? 28 : (isVeryCompact ? 32 : 38)
            color: "transparent"
            visible: !card.isMinimal

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: isUltraCompact ? 8 : (isVeryCompact ? 10 : 14)
                anchors.rightMargin: isUltraCompact ? 8 : (isVeryCompact ? 10 : 14)
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 8

                TrafficLights {
                    Layout.alignment: Qt.AlignVCenter
                    compact: card.isUltraCompact
                    onCloseClicked: appState.clearText()
                    onMinimizeClicked: card.collapseRequested()
                    onRefreshClicked: card.translateRequested()
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    LanguageSelector {
                        sourceLang: appState.sourceLang
                        targetLang: appState.targetLang
                        compact: card.width < 360
                        minimal: card.width < 270
                        onSwapClicked: appState.swapLanguages()
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: card.width >= 390 ? 80 : 22
                        radius: 11
                        color: "#1affffff"
                        border.color: DesignTokens.borderInput
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Rectangle { width: 6; height: 6; radius: 3; color: appState.engine === "offline" ? DesignTokens.accentAmber : DesignTokens.accentEmerald }
                            Text {
                                text: appState.engine === "gemini" ? "Gemini" : appState.engine === "deepl" ? "DeepL" : appState.engine === "youdao" ? "有道" : "离线"
                                color: "#93c5fd"; font.pixelSize: 10; font.weight: Font.Medium
                                visible: card.width >= 390
                            }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true
                            onEntered: parent.color = "#26ffffff"
                            onExited: parent.color = "#1affffff" }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Item { Layout.fillWidth: true }

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    IconButton { iconSource: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"; iconColor: "#cc60a5fa"; iconSize: card.isUltraCompact ? 10 : (card.isVeryCompact ? 12 : 14) }
                    IconButton { iconSource: "qrc:/qt/qml/Linguist/resources/icons/pin.svg"; active: appState.isPinned; iconSize: card.isUltraCompact ? 10 : (card.isVeryCompact ? 12 : 14); onClicked: appState.setIsPinned(!appState.isPinned) }
                    IconButton { iconSource: "qrc:/qt/qml/Linguist/resources/icons/type.svg"; iconSize: card.isUltraCompact ? 10 : (card.isVeryCompact ? 12 : 14) }
                    IconButton { iconSource: "qrc:/qt/qml/Linguist/resources/icons/settings.svg"; iconSize: card.isUltraCompact ? 10 : (card.isVeryCompact ? 12 : 14); onClicked: card.settingsRequested() }
                }
            }

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1; color: DesignTokens.borderSubtle
            }
        }

        // ========== 内容区 ==========
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // --- 极简模式 ---
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                visible: card.isMinimal

                SearchInput {
                    Layout.fillWidth: true
                    compact: true
                    text: appState.sourceText
                    placeholder: "搜索或输入..."
                    onTextChanged: appState.setSourceText(text)
                    onSubmitted: appState.translate()
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: appState.isLoading
                        Image {
                            source: "qrc:/qt/qml/Linguist/resources/icons/sparkles.svg"
                            sourceSize.width: 12; sourceSize.height: 12
                            RotationAnimation on rotation { running: appState.isLoading; loops: Animation.Infinite; from: 0; to: 360; duration: 1000 }
                        }
                        Text { text: "正在翻译..."; color: "#80ffffff"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    }

                    HoverScrollText {
                        anchors.fill: parent
                        text: appState.completeTranslation()
                        textColor: "#f2ffffff"
                        fontSize: 12
                        prefix: appState.isWord && appState.phonetic ? appState.phonetic : ""
                        visible: !appState.isLoading && appState.translatedText.length > 0
                    }
                }
            }

            // --- 标准/紧凑模式 ---
            Flickable {
                id: flickable
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: contentColumn.implicitHeight + (dynamicTight ? 16 : (dynamicCompact ? 20 : 28))
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: contentColumn
                    x: dynamicTight ? 8 : (dynamicCompact ? 10 : 14)
                    y: dynamicTight ? 8 : (dynamicCompact ? 10 : 14)
                    width: flickable.width - (dynamicTight ? 16 : (dynamicCompact ? 20 : 28))
                    spacing: dynamicTight ? 4 : (dynamicCompact ? 8 : 12)

                    SearchInput {
                        Layout.fillWidth: true
                        compact: dynamicCompact
                        text: appState.sourceText
                        onTextChanged: appState.setSourceText(text)
                        onSubmitted: appState.translate()
                    }

                    // 加载中
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 16
                        Layout.bottomMargin: 16
                        spacing: 8
                        visible: appState.isLoading

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            source: "qrc:/qt/qml/Linguist/resources/icons/sparkles.svg"
                            sourceSize.width: 20; sourceSize.height: 20
                            RotationAnimation on rotation { running: appState.isLoading; loops: Animation.Infinite; from: 0; to: 360; duration: 1000 }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "正在翻译中..."
                            color: "#80ffffff"
                            font.pixelSize: 12; font.letterSpacing: 1
                        }
                    }

                    // 单词详情
                    WordDetailView {
                        Layout.fillWidth: true
                        word: appState.sourceText
                        phonetic: appState.phonetic
                        translatedText: appState.translatedText
                        definitions: appState.definitions
                        examples: appState.examples
                        synonyms: appState.synonyms
                        compact: dynamicCompact
                        veryCompact: dynamicTight
                        ultraCompact: isUltraCompact
                        visible: !appState.isLoading && appState.isWord && appState.translatedText.length > 0
                    }

                    // 句子翻译
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: !appState.isLoading && !appState.isWord && appState.translatedText.length > 0

                        HoverScrollText { Layout.fillWidth: true; text: appState.translatedText; textColor: "#f2ffffff"; fontSize: isUltraCompact ? 12 : (isVeryCompact ? 14 : 16) }
                        Rectangle { Layout.fillWidth: true; height: 1; color: DesignTokens.borderSubtle }
                        HoverScrollText { Layout.fillWidth: true; text: appState.sourceText; textColor: "#80ffffff"; fontSize: isUltraCompact ? 10 : (isVeryCompact ? 12 : 13) }
                    }

                    // 空状态
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        spacing: 8
                        visible: !appState.isLoading && appState.translatedText.length === 0

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "输入文本或在桌面文档中划词即刻精准翻译"
                            color: "#66ffffff"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flow {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6
                            visible: !isUltraCompact

                            Repeater {
                                model: ["Efficient", "Serendipity", "Resilient", "AI 神经翻译"]
                                delegate: Rectangle {
                                    radius: 10
                                    color: "#0dffffff"
                                    border.color: DesignTokens.borderSubtle
                                    border.width: 1
                                    implicitWidth: demoText.implicitWidth + 16
                                    height: 22

                                    Text {
                                        id: demoText
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#93c5fd"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: { appState.setSourceText(modelData); appState.translate() }
                                        onEntered: parent.color = "#26ffffff"
                                        onExited: parent.color = "#0dffffff"
                                    }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.preferredHeight: dynamicTight ? 8 : (dynamicCompact ? 10 : 14) }
                }
            }
        }

        // ========== 操作工具栏（固定在底部栏上方）==========
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "transparent"
            visible: !card.isMinimal && !appState.isLoading && appState.translatedText.length > 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: appState.sourceLang + "➔" + appState.targetLang
                    color: "#cc60a5fa"
                    font.pixelSize: 10
                    font.family: "Consolas"
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/copy.svg"
                    iconSize: 14
                    iconColor: appState.justCopied ? "#4ade80" : "#ccffffff"
                    onClicked: appState.copyTranslation()
                }
                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                    iconSize: 14
                    onClicked: appState.speak(appState.sourceText, appState.sourceLang)
                }
                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/heart.svg"
                    iconSize: 14
                    active: appState.isFavorite
                    activeColor: DesignTokens.accentAmber
                    onClicked: appState.setIsFavorite(!appState.isFavorite)
                }
                IconButton { iconSource: "qrc:/qt/qml/Linguist/resources/icons/history.svg"; iconSize: 14 }
            }

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top
                height: 1; color: DesignTokens.borderSubtle
            }
        }

        // ========== 底部栏 ==========
        Rectangle {
            id: bottomBar
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "#0dffffff"
            visible: !card.isMinimal && height >= 220 && card.width >= 240

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    Rectangle {
                        width: 28; height: 14; radius: 7
                        color: appState.selectionTranslation ? "#cc3b82f6" : "#26ffffff"

                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: appState.selectionTranslation ? (parent.width - width - 2) : 2
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea { anchors.fill: parent; onClicked: appState.setSelectionTranslation(!appState.selectionTranslation) }
                    }

                    Text {
                        text: appState.selectionTranslation ? "Smart-Select" : "Paused"
                        color: "#b2ffffff"
                        font.pixelSize: 10; font.weight: Font.SemiBold; font.letterSpacing: 1
                        font.capitalization: Font.AllUppercase
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Math.round(card.width) + "×" + Math.round(card.height)
                    color: "#4cffffff"
                    font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 2
                    font.family: "Consolas"
                }
            }

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top
                height: 1; color: DesignTokens.borderSubtle
            }
        }
    }
}
