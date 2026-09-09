import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Item {
    id: card
    property bool isDragging: false
    property bool isResizing: false
    readonly property bool isMinimal: height < 160
    readonly property bool isCompact: width < 340
    readonly property real gutter: width < 240 ? 12 : 18
    signal collapseRequested()
    signal translateRequested()
    signal settingsRequested()
    signal musicPanelRequested()
    signal historyRequested()
    signal screenshotRequested()
    signal moreRequested()
    signal moveRequested()
    signal quitRequested()
    signal minimizeToTaskbarRequested()

    GlassSurface { anchors.fill: parent; isResizing: card.isResizing }

    Item {
        id: header
        objectName: "cardHeader"
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: card.isMinimal ? 32 : 48
        MouseArea { anchors.fill: parent; onPressed: card.moveRequested() }
        Row {
            anchors.left: parent.left
            anchors.leftMargin: card.gutter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            TrafficLights {
                anchors.verticalCenter: parent.verticalCenter
                onCloseClicked: card.quitRequested()
                onMinimizeClicked: card.minimizeToTaskbarRequested()
                onCollapseClicked: card.collapseRequested()
            }
            Text {
                visible: card.width >= 390
                anchors.verticalCenter: parent.verticalCenter
                text: "Linguist"
                font { pixelSize: 12; weight: Font.DemiBold; family: "Segoe UI" }
                color: DesignTokens.textSecondary
            }
        }
        Row {
            objectName: "headerActions"
            anchors.right: parent.right
            anchors.rightMargin: card.gutter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            LanguageSelector {
                visible: card.width >= 280 && !card.isMinimal
                anchors.verticalCenter: parent.verticalCenter
                sourceLang: appState.sourceLang.toUpperCase()
                targetLang: appState.targetLang.toUpperCase()
                onSwapClicked: appState.swapLanguages()
                onSourceClicked: card.moreRequested()
                onTargetClicked: card.moreRequested()
            }
            IconButton {
                visible: card.width >= 340 && !card.isMinimal
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/pin.svg"
                active: appState.isPinned
                tooltip: "置顶"
                onClicked: appState.setIsPinned(!appState.isPinned)
            }
            IconButton {
                objectName: "cardMore"
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/settings.svg"
                tooltip: "更多操作"
                onClicked: card.moreRequested()
            }
        }
    }

    Item {
        id: body
        objectName: "cardBody"
        anchors { top: header.bottom; bottom: footer.top; left: parent.left; right: parent.right }
        anchors.leftMargin: card.gutter
        anchors.rightMargin: card.gutter
        clip: true
        SearchInput {
            id: search
            objectName: "cardSearch"
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: card.isMinimal ? 28 : 36
            compact: card.isMinimal || card.width < 260
            text: appState.sourceText
            onUserTextChanged: function(value) { appState.setSourceText(value) }
            onSubmitted: card.translateRequested()
            onScreenshotClicked: card.screenshotRequested()
        }
        Flickable {
            id: scroll
            objectName: "cardScroll"
            anchors { top: search.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.topMargin: card.isMinimal ? 4 : 16
            clip: true
            contentWidth: width
            contentHeight: resultColumn.implicitHeight + 12
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            maximumFlickVelocity: 1800
            flickDeceleration: 2400
            ColumnLayout {
                id: resultColumn
                width: scroll.width
                spacing: 14
                Text {
                    Layout.fillWidth: true
                    visible: appState.isTranslating
                    text: "正在翻译…"
                    font.pixelSize: 13
                    color: DesignTokens.textSecondary
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: typeof appState.hasError !== "undefined" && appState.hasError
                    Text {
                        Layout.fillWidth: true
                        text: typeof appState.errorMessage !== "undefined" ? appState.errorMessage : ""
                        color: DesignTokens.accentRed
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                    Basic.Button { text: "重试"; onClicked: card.translateRequested() }
                }
                WordDetailView {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    visible: !card.isMinimal && !appState.isTranslating && appState.isWord && appState.translatedText.length > 0
                    word: appState.sourceText
                    phonetic: appState.phoneticUs.length > 0 ? appState.phoneticUs : appState.phoneticUk
                    translatedText: appState.translatedText
                    englishDefinition: appState.englishDefinition
                    definitions: appState.definitions
                    examples: appState.examples
                    synonyms: appState.synonyms
                    antonyms: appState.antonyms
                    wordForms: appState.wordForms
                    tags: appState.tags
                    compact: card.isCompact
                    veryCompact: card.width < 260
                    ultraCompact: card.width < 220
                }
                Text {
                    objectName: "compactTranslation"
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    visible: !appState.isTranslating && appState.translatedText.length > 0 && (card.isMinimal || !appState.isWord)
                    text: appState.completeTranslation()
                    color: DesignTokens.textPrimary
                    font { pixelSize: card.isMinimal ? 12 : Math.round(16 * DesignTokens.fontScale); family: "Segoe UI" }
                    wrapMode: Text.Wrap
                    lineHeight: 1.35
                }
                Text {
                    Layout.fillWidth: true
                    visible: !card.isMinimal && !appState.isWord && appState.translatedText.length > 0
                    text: appState.sourceText
                    color: DesignTokens.textTertiary
                    font.pixelSize: Math.round(13 * DesignTokens.fontScale)
                    wrapMode: Text.Wrap
                    lineHeight: 1.4
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: card.isMinimal ? 0 : 24
                    spacing: 8
                    visible: !appState.isTranslating && appState.translatedText.length === 0
                    Text {
                        Layout.fillWidth: true
                        text: card.isMinimal ? "输入文字，回车翻译" : "让理解更简单"
                        color: DesignTokens.textPrimary
                        font { pixelSize: card.isMinimal ? 12 : 20; weight: Font.DemiBold }
                        wrapMode: Text.Wrap
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !card.isMinimal
                        text: "输入单词或句子，按回车翻译。\n也可以选中文字，随时查看释义。"
                        color: DesignTokens.textTertiary
                        font.pixelSize: 13
                        lineHeight: 1.5
                        wrapMode: Text.Wrap
                    }
                }
            }
            Basic.ScrollBar.vertical: Basic.ScrollBar { policy: Basic.ScrollBar.AsNeeded; width: 4 }
        }
    }
    Item {
        id: footer
        objectName: "cardFooter"
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: card.isMinimal ? 10 : 44
        Rectangle {
            visible: !card.isMinimal
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: card.gutter
            anchors.rightMargin: card.gutter
            height: 1
            color: DesignTokens.borderSubtle
        }
        Row {
            objectName: "footerStatus"
            visible: !card.isMinimal
            anchors.left: parent.left
            anchors.leftMargin: card.gutter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            IconButton {
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/sparkles.svg"
                active: appState.selectionTranslation
                tooltip: "划词翻译"
                onClicked: appState.setSelectionTranslation(!appState.selectionTranslation)
            }
            Text {
                visible: card.width >= 390
                anchors.verticalCenter: parent.verticalCenter
                text: appState.engine === "offline" ? "离线词典" : appState.engine
                font.pixelSize: 11
                color: DesignTokens.textTertiary
            }
        }
        Row {
            objectName: "footerActions"
            visible: !card.isMinimal
            anchors.right: parent.right
            anchors.rightMargin: card.gutter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            IconButton {
                objectName: "cardCopy"
                iconSource: appState.justCopied ? "qrc:/qt/qml/Linguist/resources/icons/check.svg" : "qrc:/qt/qml/Linguist/resources/icons/copy.svg"
                tooltip: "复制译文"
                enabled: appState.translatedText.length > 0
                onClicked: appState.copyTranslation()
            }
            IconButton {
                objectName: "cardSpeak"
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                tooltip: "朗读"
                enabled: appState.sourceText.length > 0
                onClicked: appState.speak(appState.sourceText, appState.sourceLang)
            }
            IconButton {
                visible: card.width >= 250
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/heart.svg"
                tooltip: "收藏"
                active: appState.isFavorite
                enabled: appState.translatedText.length > 0
                onClicked: appState.setIsFavorite(!appState.isFavorite)
            }
            IconButton {
                visible: card.width >= 300
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/history.svg"
                tooltip: "历史与生词本"
                onClicked: card.historyRequested()
            }
        }
    }
}
