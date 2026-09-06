import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: card

    property bool isDragging: false
    property string resizeEdge: "none"
    property bool isMinimal: height <= 130 || (width <= 220 && height <= 160)
    property bool isUltraCompact: !isMinimal && (width < 280 || height < 260)
    property bool isVeryCompact: !isMinimal && (width < 340 || height < 330)
    property bool isCompact: !isMinimal && (width < 420 || height < 400)
    property bool dynamicCompact: !isMinimal && (appState.compactMode || isCompact)
    property bool dynamicTight: !isMinimal && isVeryCompact

    // === 顶部栏动态空间分配 ===
    property real leftMargin: isUltraCompact ? 8 : (isVeryCompact ? 10 : 14)
    property real rightMargin: isUltraCompact ? 8 : (isVeryCompact ? 10 : 14)
    property real rightFullWidth: 104
    property real rightMinWidth: 52
    property real middleNaturalWidth: 178
    property real middleCompactWidth: 152
    property real middleMinimalWidth: 76
    property real middleMinWidth: 54
    property real availableWidth: width - leftMargin - rightMargin - 38
    property real middleAvailable: availableWidth - rightFullWidth
    property real topSpacing: middleAvailable > middleNaturalWidth ? Math.min(6, (middleAvailable - middleNaturalWidth) / 2) : 0
    property real middleWidth: Math.min(middleNaturalWidth, Math.max(middleMinWidth, middleAvailable))
    property bool middleIsCompact: middleWidth <= middleCompactWidth
    property bool middleIsMinimal: middleWidth <= middleMinimalWidth
    property bool middleIsMin: middleWidth <= middleMinWidth
    property real rightWidth: middleIsMin ? Math.max(rightMinWidth, availableWidth - middleMinWidth) : rightFullWidth
    property real settingsBtnW: Math.max(0, Math.min(26, rightWidth - 78))
    property real fontBtnW: Math.max(0, Math.min(26, rightWidth - 52))

    signal collapseRequested()
    signal translateRequested()
    signal settingsRequested()
    signal quitRequested()
    signal minimizeToTaskbarRequested()

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
            Layout.preferredHeight: isUltraCompact ? 40 : (isVeryCompact ? 44 : 50)
            color: "transparent"
            visible: !card.isMinimal

            // Row结构自动排列不重叠，弹簧动画线性(100ms)无弹簧感
            Row {
                id: topRow
                anchors.fill: parent
                anchors.leftMargin: card.leftMargin
                anchors.rightMargin: card.rightMargin
                spacing: 0

                // 1. 红绿灯
                TrafficLights {
                    id: trafficLights
                    anchors.verticalCenter: parent.verticalCenter
                    onCloseClicked: card.quitRequested()
                    onMinimizeClicked: card.minimizeToTaskbarRequested()
                    onCollapseClicked: card.collapseRequested()
                }

                // 2. 左弹簧（线性动画，无弹簧感）
                Item {
                    id: leftSpring
                    height: 1
                    width: Math.max(0, (topRow.width - trafficLights.width - middleGroup.width - iconGroup.width) / 2)
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                }

                // 3. 中间组
                Row {
                    id: middleGroup
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: card.topSpacing
                    Behavior on spacing { NumberAnimation { duration: 100; easing.type: Easing.Linear } }

                    LanguageSelector {
                        id: langSelector
                        anchors.verticalCenter: parent.verticalCenter
                        sourceLang: appState.sourceLang
                        targetLang: appState.targetLang
                        compact: card.middleIsCompact && !card.middleIsMinimal
                        minimal: card.middleIsMinimal && !card.middleIsMin
                        textOnly: card.middleIsMin && !langSelector.hovered
                        iconOnly: false
                        onSwapClicked: appState.swapLanguages()
                    }

                    // 引擎状态
                    Rectangle {
                        id: engineIndicator
                        anchors.verticalCenter: parent.verticalCenter
                        height: 18
                        radius: 9
                        color: "#1affffff"
                        border.color: engineIndicator.expanded ? DesignTokens.borderInput : "transparent"
                        border.width: engineIndicator.expanded ? 1 : 0
                        property bool expanded: (!card.middleIsMinimal || engineMouse.containsMouse)
                        width: expanded ? (engineRow.width + 16) : 18
                        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                        Behavior on border.color { ColorAnimation { duration: 100; easing.type: Easing.Linear } }

                        Row {
                            id: engineRow
                            anchors.centerIn: parent
                            spacing: 6
                            opacity: engineIndicator.expanded ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.Linear } }

                            Item {
                                width: 6; height: 6
                                anchors.verticalCenter: parent.verticalCenter
                                Rectangle { anchors.fill: parent; radius: 3; color: appState.engine === "offline" ? DesignTokens.accentAmber : DesignTokens.accentEmerald }
                                Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: appState.engine === "offline" ? DesignTokens.accentAmber : DesignTokens.accentEmerald; opacity: 0.3 }
                            }
                            Text {
                                text: appState.engine === "gemini" ? "Gemini" : appState.engine === "deepl" ? "DeepL" : appState.engine === "youdao" ? "有道" : "离线"
                                color: "#93c5fd"; font.pixelSize: 9; font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item {
                            anchors.centerIn: parent
                            width: 6; height: 6
                            visible: !engineIndicator.expanded
                            Rectangle { anchors.fill: parent; radius: 3; color: appState.engine === "offline" ? DesignTokens.accentAmber : DesignTokens.accentEmerald }
                            Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: appState.engine === "offline" ? DesignTokens.accentAmber : DesignTokens.accentEmerald; opacity: 0.3 }
                        }

                        MouseArea {
                            id: engineMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.color = "#26ffffff"
                            onExited: parent.color = "#1affffff"
                        }
                        Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.Linear } }
                    }
                }

                // 4. 右弹簧（线性动画，无弹簧感）
                Item {
                    id: rightSpring
                    height: 1
                    width: leftSpring.width
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                }

                // 5. 右边图标组（Row自动排列不重叠，clip确保不超出边框）
                Row {
                    id: iconGroup
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    clip: true

                    // 截图（始终显示）
                    Item { width: 26; height: 26; IconButton { anchors.centerIn: parent; iconSource: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"; iconColor: "#cc60a5fa"; iconSize: 13 } }

                    // 固定（始终显示）
                    Item { width: 26; height: 26; IconButton { anchors.centerIn: parent; iconSource: "qrc:/qt/qml/Linguist/resources/icons/pin.svg"; active: appState.isPinned; iconSize: 13; onClicked: appState.setIsPinned(!appState.isPinned) } }

                    // 字体（先被吸进去）
                    Item {
                        id: fontBtnContainer
                        width: card.fontBtnW
                        height: 26
                        clip: true
                        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                        IconButton {
                            anchors.centerIn: parent
                            iconSource: "qrc:/qt/qml/Linguist/resources/icons/type.svg"
                            iconSize: 13
                            scale: fontBtnContainer.width > 10 ? 1.0 : 0.0
                            opacity: fontBtnContainer.width > 10 ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                        }
                    }

                    // 设置（后被吸进去）
                    Item {
                        id: settingsBtnContainer
                        width: card.settingsBtnW
                        height: 26
                        clip: true
                        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                        IconButton {
                            anchors.centerIn: parent
                            iconSource: "qrc:/qt/qml/Linguist/resources/icons/settings.svg"
                            iconSize: 13
                            scale: settingsBtnContainer.width > 10 ? 1.0 : 0.0
                            opacity: settingsBtnContainer.width > 10 ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                            onClicked: card.settingsRequested()
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: card.leftMargin; anchors.rightMargin: card.rightMargin
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
                                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.Linear } }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.preferredHeight: dynamicTight ? 8 : (dynamicCompact ? 10 : 14) }
                }
            }
        }

        // ========== 操作工具栏 ==========
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "transparent"
            visible: !card.isMinimal && !appState.isLoading && appState.translatedText.length > 0

            // Row结构，左边Smart-Select开关，右边操作图标
            Row {
                anchors.fill: parent
                anchors.leftMargin: card.leftMargin
                anchors.rightMargin: card.rightMargin
                spacing: 0

                // 左边：Smart-Select 切换按钮
                Row {
                    id: smartSelectGroup
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 28; height: 14; radius: 7
                        color: appState.selectionTranslation ? "#cc3b82f6" : "#26ffffff"

                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: appState.selectionTranslation ? (parent.width - width - 2) : 2
                            Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
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

                // 弹簧
                Item {
                    width: parent.width - smartSelectGroup.width - actionButtons.width
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                }

                // 右边：操作图标
                Row {
                    id: actionButtons
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

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

            // Row结构，左边EN➔ZH，右边窗口尺寸，弹簧隔开
            Row {
                anchors.fill: parent
                anchors.leftMargin: card.leftMargin
                anchors.rightMargin: card.rightMargin
                spacing: 0

                // 左边：EN➔ZH
                Text {
                    id: bottomLangText
                    anchors.verticalCenter: parent.verticalCenter
                    text: appState.sourceLang + "➔" + appState.targetLang
                    color: "#cc60a5fa"
                    font.pixelSize: 10
                    font.family: "Consolas"
                }

                // 弹簧（隔开左右）
                Item {
                    width: parent.width - bottomLangText.width - sizeText.width
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                }

                // 右边：窗口尺寸
                Text {
                    id: sizeText
                    anchors.verticalCenter: parent.verticalCenter
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
