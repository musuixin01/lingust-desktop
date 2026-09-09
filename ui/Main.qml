import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls.Basic as Basic
import Linguist

Item {
    id: root
    anchors.fill: parent
    readonly property string currentMode: translatorWindow.currentMode
    property color shellColor: "#ee1c202a"
    property real shellOpacity: appState.cardOpacity
    readonly property var stateObject: appState

    function openPanel(panel) {
        panel.x = Math.max(16, Math.min(translatorWindow.x + 24, panel.screen.width - panel.width - 16))
        panel.y = Math.max(32, Math.min(translatorWindow.y + 24, panel.screen.height - panel.height - 32))
        panel.show()
        panel.raise()
        panel.requestActivate()
    }

    PillView {
        anchors.fill: parent
        visible: root.currentMode === "pill"
        onExpandRequested: translatorWindow.expandToCard()
        onMusicPanelRequested: root.openPanel(musicWindow)
        onMoreRequested: root.openPanel(actionsWindow)
    }
    CardView {
        anchors.fill: parent
        visible: root.currentMode === "card"
        isResizing: translatorWindow.isResizing
        onMoveRequested: translatorWindow.startSystemMove()
        onCollapseRequested: translatorWindow.collapseToPill()
        onTranslateRequested: appState.translate()
        onSettingsRequested: root.openPanel(settingsWindow)
        onMusicPanelRequested: root.openPanel(musicWindow)
        onHistoryRequested: { appState.refreshHistory(); root.openPanel(historyWindow) }
        onScreenshotRequested: root.openPanel(screenshotWindow)
        onMoreRequested: root.openPanel(actionsWindow)
        onQuitRequested: Qt.quit()
        onMinimizeToTaskbarRequested: translatorWindow.minimizeToTaskbar()
    }
    MouseArea {
        anchors.fill: parent
        visible: root.currentMode === "pill"
        z: -1
        onPressed: translatorWindow.startSystemMove()
    }

    component UtilityWindow: Window {
        id: utility
        // A tool window must not wait for the invisible offscreen scene.
        transientParent: null
        property Component page
        property bool pageLoaded: false
        onVisibleChanged: if (visible) pageLoaded = true
        width: 440
        height: 580
        minimumWidth: width
        maximumWidth: width
        minimumHeight: height
        maximumHeight: height
        visible: false
        color: "transparent"
        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        Loader { anchors.fill: parent; sourceComponent: utility.page; active: utility.pageLoaded }
        MouseArea {
            x: 24; y: 0; width: parent.width - 104; height: 22
            onPressed: utility.startSystemMove()
        }
        Shortcut { sequence: "Escape"; onActivated: utility.hide() }
    }
    UtilityWindow {
        id: settingsWindow
        title: "Linguist 设置"
        page: Component { SettingsView { onCloseRequested: settingsWindow.hide() } }
    }
    UtilityWindow {
        id: historyWindow
        title: "历史与生词本"
        width: 460
        height: 560
        page: Component { HistoryView { onCloseRequested: historyWindow.hide() } }
    }
    UtilityWindow {
        id: musicWindow
        title: "音乐控制"
        width: 360
        height: 360
        page: Component {
            MusicIslandCard {
                appState: root.stateObject
                onCloseRequested: musicWindow.hide()
                onSwitchTranslationRequested: { musicWindow.hide(); root.stateObject.setPillMusicMode(false) }
            }
        }
    }
    UtilityWindow {
        id: screenshotWindow
        title: "截图翻译"
        width: 460
        height: 540
        page: Component {
            Rectangle {
                color: "#f51c202a"
                radius: 24
                border.color: "#40ffffff"
                ScreenshotTranslationView {
                    anchors.fill: parent
                    anchors.margins: 16
                    onBackToTextRequested: screenshotWindow.hide()
                    onRetakeRequested: { screenshotWindow.hide(); root.stateObject.triggerSelectionTranslation() }
                }
            }
        }
    }
    component ActionButton: Basic.Button {
        implicitHeight: 36
        background: Rectangle {
            radius: 10
            color: parent.down ? "#33ffffff" : parent.hovered ? "#22ffffff" : "#10ffffff"
            border.color: parent.activeFocus ? "#60a5fa" : "transparent"
        }
        contentItem: Text {
            text: parent.text
            color: "#f1f5f9"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    UtilityWindow {
        id: actionsWindow
        title: "快捷操作"
        width: 320
        height: 520
        page: Component {
            Rectangle {
                radius: 24
                color: "#f51c202a"
                border.color: "#40ffffff"
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "快捷操作"; color: "white"; font { pixelSize: 17; weight: Font.DemiBold } Layout.fillWidth: true }
                        IconButton { iconSource: "qrc:/qt/qml/Linguist/resources/icons/close.svg"; tooltip: "关闭"; onClicked: actionsWindow.hide() }
                    }
                    Text { text: "翻译语言"; color: "#bac4d2"; font.pixelSize: 12 }
                    RowLayout {
                        Layout.fillWidth: true
                        Basic.ComboBox {
                            Layout.fillWidth: true
                            model: ["en", "zh", "ja", "ko", "fr", "de", "es", "ru"]
                            currentIndex: Math.max(0, model.indexOf(appState.sourceLang))
                            onActivated: appState.setSourceLang(currentText)
                        }
                        IconButton { iconSource: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"; tooltip: "交换语言"; onClicked: appState.swapLanguages() }
                        Basic.ComboBox {
                            Layout.fillWidth: true
                            model: ["zh", "en", "ja", "ko", "fr", "de", "es", "ru"]
                            currentIndex: Math.max(0, model.indexOf(appState.targetLang))
                            onActivated: appState.setTargetLang(currentText)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "翻译引擎"; color: "#bac4d2"; font.pixelSize: 12 }
                        Basic.ComboBox {
                            Layout.fillWidth: true
                            model: ["offline", "gemini", "deepl", "youdao"]
                            currentIndex: Math.max(0, model.indexOf(appState.engine))
                            onActivated: appState.setEngine(currentText)
                        }
                    }
                    Text { text: "文字大小  " + appState.fontSizePercent + "%"; color: "#bac4d2"; font.pixelSize: 12 }
                    Basic.Slider {
                        Layout.fillWidth: true
                        from: 70; to: 150; stepSize: 10
                        value: appState.fontSizePercent
                        onMoved: appState.setFontSizePercent(Math.round(value))
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        ActionButton { Layout.fillWidth: true; text: "历史与生词本"; onClicked: { actionsWindow.hide(); appState.refreshHistory(); root.openPanel(historyWindow) } }
                        ActionButton { Layout.fillWidth: true; text: appState.isFavorite ? "取消收藏" : "收藏"; onClicked: appState.setIsFavorite(!appState.isFavorite) }
                        ActionButton { Layout.fillWidth: true; text: "音乐控制"; onClicked: { actionsWindow.hide(); root.openPanel(musicWindow) } }
                        ActionButton { Layout.fillWidth: true; text: "截图翻译"; onClicked: { actionsWindow.hide(); appState.triggerSelectionTranslation(); root.openPanel(screenshotWindow) } }
                        ActionButton { Layout.fillWidth: true; text: appState.isPinned ? "取消置顶" : "置顶"; onClicked: appState.setIsPinned(!appState.isPinned) }
                        ActionButton { Layout.fillWidth: true; text: "设置"; onClicked: { actionsWindow.hide(); root.openPanel(settingsWindow) } }
                    }
                    ActionButton {
                        Layout.fillWidth: true
                        text: root.currentMode === "pill" ? "展开翻译卡片" : "收起为药丸"
                        onClicked: { actionsWindow.hide(); translatorWindow.toggleMode() }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
