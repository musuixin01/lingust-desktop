import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Linguist

Item {
    id: root
    anchors.fill: parent
    readonly property string currentMode: translatorWindow.currentMode
    property color shellColor: currentMode === "pill" ? "#e6090f1c" : "#e60f172a"
    property real shellOpacity: appState.cardOpacity
    property real auroraOpacity: currentMode === "card" ? cardView.auroraOpacity : pillView.auroraOpacity
    property real auroraBloom: currentMode === "card" ? cardView.auroraBloom : pillView.auroraBloom
    property real auroraPhase: currentMode === "card" ? cardView.auroraPhase : pillView.auroraPhase
    readonly property var stateObject: appState
    property var settingsPanel: null
    property var historyPanel: null
    property var musicPanel: null
    property var layoutPanel: null
    property var imagePreviewPanel: null
    property bool captureStarting: false
    Behavior on shellColor {
        ColorAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
    function prepareKeyboardFocus(localX, localY) {
        return root.currentMode === "card"
            ? cardView.prepareKeyboardFocus(localX, localY)
            : pillView.prepareKeyboardFocus(localX, localY)
    }
    function handlePointerLeave() {
        if (root.currentMode === "pill") pillView.handlePointerLeave()
        else cardView.handlePointerLeave()
    }
    function handlePointerMove(localX, localY) {
        if (root.currentMode === "pill") pillView.handlePointerMove(localX, localY)
        else cardView.handlePointerMove(localX, localY)
    }

    function openPanel(panel) {
        panel.x = Math.max(16, Math.min(translatorWindow.x + 24, panel.screen.width - panel.width - 16))
        panel.y = Math.max(32, Math.min(translatorWindow.y + 24, panel.screen.height - panel.height - 32))
        panel.show()
        panel.raise()
        panel.requestActivate()
    }
    function openSettings() {
        if (!settingsPanel) settingsPanel = settingsWindowComponent.createObject(null)
        openPanel(settingsPanel)
    }
    function openHistory() {
        if (!historyPanel) historyPanel = historyWindowComponent.createObject(null)
        appState.refreshHistory()
        openPanel(historyPanel)
    }
    function openMusic() {
        if (!musicPanel) musicPanel = musicWindowComponent.createObject(null)
        openPanel(musicPanel)
    }
    function openScreenshotPreview(source) {
        if (!source || source.length === 0)
            return
        if (!imagePreviewPanel)
            imagePreviewPanel = screenshotPreviewWindowComponent.createObject(null)
        imagePreviewPanel.imageSource = source
        openPanel(imagePreviewPanel)
    }
    function toggleLayoutPanel() {
        if (!layoutPanel)
            layoutPanel = layoutPanelWindowComponent.createObject(null)
        if (layoutPanel.visible) {
            layoutPanel.dismiss()
            return
        }
        positionLayoutPanelBelowCard(true)
        layoutPanel.show()
        layoutPanel.raise()
        layoutPanel.requestActivate()
        Qt.callLater(function() { positionLayoutPanelBelowCard(false) })
    }
    function positionLayoutPanelBelowCard(ensureRoom) {
        if (!layoutPanel)
            return
        var activeScreen = layoutPanel.screen || translatorWindow.screen || Qt.application.screens[0]
        var available = activeScreen.availableGeometry
        var anchorY = translatorWindow.nativeFrameY + translatorWindow.nativeFrameHeight + 2
        var neededBottom = anchorY + layoutPanel.height + 10
        if (ensureRoom && neededBottom > available.y + available.height) {
            translatorWindow.y = Math.max(available.y + 10,
                                          translatorWindow.nativeFrameY
                                          - (neededBottom - available.y - available.height))
            anchorY = translatorWindow.nativeFrameY + translatorWindow.nativeFrameHeight + 2
        }
        var anchorX = translatorWindow.nativeFrameX
                      + (translatorWindow.nativeFrameWidth - layoutPanel.width) / 2
        layoutPanel.x = Math.max(available.x + 10,
                                 Math.min(Math.round(anchorX),
                                          available.x + available.width - layoutPanel.width - 10))
        layoutPanel.y = Math.round(anchorY)
    }
    function enterPillMusic() {
        appState.setPillMusicMode(true)
        translatorWindow.collapseToPill()
    }
    function showScreenshotInCard() {
        translatorWindow.show()
        translatorWindow.expandToCard()
        translatorWindow.raise()
        adaptiveCardHeightTimer.restart()
    }
    function beginScreenshotCapture() {
        if (captureStarting)
            return
        captureStarting = true
        translatorWindow.hide()
        captureDelay.restart()
    }

    PillView {
        id: pillView
        anchors.fill: parent
        isResizing: translatorWindow.isResizing
        visible: true
        enabled: root.currentMode === "pill"
        opacity: root.currentMode === "pill" ? 1 : 0
        z: root.currentMode === "pill" ? 2 : 1
        Behavior on opacity {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }
        onExpandRequested: translatorWindow.expandToCard()
        onMinimizeToTaskbarRequested: translatorWindow.minimizeToTaskbar()
        onMusicPanelRequested: root.openMusic()
        onSettingsRequested: root.openSettings()
        onScreenshotRequested: root.beginScreenshotCapture()
    }
    CardView {
        id: cardView
        anchors.fill: parent
        visible: true
        enabled: root.currentMode === "card"
        opacity: root.currentMode === "card" ? 1 : 0
        z: root.currentMode === "card" ? 2 : 1
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        isResizing: translatorWindow.isResizing
        layoutPanelVisible: root.layoutPanel !== null && root.layoutPanel.visible
        onMoveRequested: translatorWindow.startSystemMove()
        onCollapseRequested: translatorWindow.collapseToPill()
        onTranslateRequested: appState.translate()
        onSettingsRequested: root.openSettings()
        onMusicPanelRequested: root.enterPillMusic()
        onHistoryRequested: root.openHistory()
        onScreenshotRequested: root.beginScreenshotCapture()
        onScreenshotPreviewRequested: source => root.openScreenshotPreview(source)
        onQuitRequested: Qt.quit()
        onMinimizeToTaskbarRequested: translatorWindow.minimizeToTaskbar()
        onLayoutPanelRequested: root.toggleLayoutPanel()
        onDesiredWindowHeightChanged: adaptiveCardHeightTimer.restart()
        onDesiredWindowWidthChanged: adaptiveCardHeightTimer.restart()
    }

    Timer {
        id: adaptiveCardHeightTimer
        interval: 20
        repeat: false
        onTriggered: {
            if (root.currentMode === "card" && !translatorWindow.isResizing
                    && !cardView.isMinimal)
                translatorWindow.adjustSizeToContent(cardView.desiredWindowWidth,
                                                       cardView.desiredWindowHeight)
        }
    }
    MouseArea {
        anchors.fill: parent
        visible: root.currentMode === "pill"
        z: -1
        onPressed: translatorWindow.startSystemMove()
    }

    Timer {
        id: captureDelay
        interval: 140
        repeat: false
        onTriggered: {
            root.captureStarting = false
            if (captureManager.startScreenshotMode()) {
                captureOverlay.show()
                captureOverlay.raise()
                captureOverlay.requestActivate()
            } else {
                translatorWindow.show()
            }
        }
    }

    ScreenCaptureOverlay {
        id: captureOverlay
        onAccepted: root.showScreenshotInCard()
        onCancelled: translatorWindow.show()
    }

    Connections {
        target: appState
        function onScreenshotRequested() { root.beginScreenshotCapture() }
    }

    Connections {
        target: translatorWindow
        function onNativeFrameGeometryChanged() { root.positionLayoutPanelBelowCard(false) }
        function onCurrentModeChanged() {
            if (translatorWindow.currentMode !== "card" && root.layoutPanel && root.layoutPanel.visible)
                root.layoutPanel.dismiss()
        }
    }

    Connections {
        target: captureManager
        function onCaptureFailed(message) {
            root.captureStarting = false
            captureOverlay.hide()
            root.showScreenshotInCard()
        }
    }

    component UtilityWindow: Window {
        id: utility
        // A tool window must not wait for the invisible offscreen scene.
        transientParent: null
        property Component page
        property bool pageLoaded: false
        property bool movable: true
        function dismiss() {
            if (!visible || closeMotion.running) return
            closeMotion.restart()
        }
        onVisibleChanged: {
            if (visible) {
                pageLoaded = true
                pageLoader.opacity = 0
                pageLoader.scale = 0.965
                Qt.callLater(function() { openMotion.restart() })
            }
        }
        width: 440
        height: 580
        minimumWidth: width
        maximumWidth: width
        minimumHeight: height
        maximumHeight: height
        visible: false
        color: "transparent"
        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        Loader {
            id: pageLoader
            anchors.fill: parent
            sourceComponent: utility.page
            active: utility.pageLoaded
            transformOrigin: Item.Center
        }
        ParallelAnimation {
            id: openMotion
            NumberAnimation { target: pageLoader; property: "opacity"; to: 1; duration: DesignTokens.durationPanelOpen; easing.type: Easing.OutCubic }
            NumberAnimation { target: pageLoader; property: "scale"; to: 1; duration: DesignTokens.durationPanelOpen; easing.type: Easing.OutBack; easing.overshoot: 0.35 }
        }
        SequentialAnimation {
            id: closeMotion
            ParallelAnimation {
                NumberAnimation { target: pageLoader; property: "opacity"; to: 0; duration: DesignTokens.durationPanelClose; easing.type: Easing.InCubic }
                NumberAnimation { target: pageLoader; property: "scale"; to: 0.98; duration: DesignTokens.durationPanelClose; easing.type: Easing.InCubic }
            }
            ScriptAction { script: utility.hide() }
        }
        MouseArea {
            x: 24; y: 0; width: parent.width - 104; height: 22
            enabled: utility.movable
            onPressed: utility.startSystemMove()
        }
        Shortcut { sequence: "Escape"; onActivated: utility.dismiss() }
    }
    Component {
        id: settingsWindowComponent
        UtilityWindow {
            title: "Linguist 设置"
            page: Component { SettingsView { onCloseRequested: root.settingsPanel.dismiss() } }
        }
    }
    Component {
        id: historyWindowComponent
        UtilityWindow {
            title: "历史与生词本"
            width: 460
            height: 560
            page: Component { HistoryView { onCloseRequested: root.historyPanel.dismiss() } }
        }
    }
    Component {
        id: musicWindowComponent
        UtilityWindow {
            title: "音乐控制"
            width: 360
            height: 360
            page: Component {
                MusicIslandCard {
                    appState: root.stateObject
                    onCloseRequested: root.musicPanel.dismiss()
                    onSwitchTranslationRequested: { root.musicPanel.dismiss(); root.stateObject.setPillMusicMode(false) }
                }
            }
        }
    }
    Component {
        id: layoutPanelWindowComponent
        UtilityWindow {
            id: layoutWindow
            title: "页面排版"
            width: 212
            height: 76
            movable: false
            Timer {
                interval: 16
                repeat: true
                running: layoutWindow.visible
                onTriggered: root.positionLayoutPanelBelowCard(false)
            }
            page: Component {
                LayoutScalePanel {
                    onCloseRequested: root.layoutPanel.dismiss()
                }
            }
        }
    }
    Component {
        id: screenshotPreviewWindowComponent
        UtilityWindow {
            id: screenshotPreviewWindow
            title: "截图原图"
            width: 680
            height: 480
            property string imageSource: ""
            page: Component {
                ScreenshotPreview {
                    sourceUrl: screenshotPreviewWindow.imageSource
                    onCloseRequested: screenshotPreviewWindow.dismiss()
                }
            }
        }
    }
}
