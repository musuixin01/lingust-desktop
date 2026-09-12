import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Item {
    id: card
    property real resultReveal: 1
    property real resultRevealOffset: 0
    readonly property real auroraOpacity: cardAuroraBorder.auraOpacity
    readonly property real auroraBloom: cardAuroraBorder.bloom
    readonly property real auroraPhase: cardAuroraBorder.phase
    function queueResultReveal() {
        resultRevealDelay.restart()
    }
    Timer {
        id: resultRevealDelay
        interval: 0
        onTriggered: {
            if (!appState.isTranslating && appState.translatedText.length > 0) {
                resultRevealAnimation.stop()
                card.resultReveal = 0
                card.resultRevealOffset = 7
                resultRevealAnimation.start()
            }
        }
    }
    ParallelAnimation {
        id: resultRevealAnimation
        objectName: "cardResultRevealAnimation"
        NumberAnimation {
            target: card
            property: "resultReveal"
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: card
            property: "resultRevealOffset"
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Connections {
        target: appState
        function onTranslatedTextChanged() { card.queueResultReveal() }
        function onIsTranslatingChanged() {
            if (!appState.isTranslating)
                card.queueResultReveal()
        }
    }
    function prepareKeyboardFocus(localX, localY) {
        if (appState.screenshotMode)
            return false
        var point = search.mapFromItem(card, localX, localY)
        if (point.x >= 0 && point.y >= 0 && point.x <= search.width && point.y <= search.height) {
            search.focusEditor()
            return true
        }
        search.blurEditor()
        card.forceActiveFocus(Qt.MouseFocusReason)
        return false
    }
    function handlePointerLeave() {
        revealIntentTimer.stop()
        pendingReveal = ""
        nativeLeftRevealActive = false
        nativeRightRevealActive = false
    }
    function scheduleReveal(side) {
        if (pendingReveal === side && revealIntentTimer.running)
            return
        pendingReveal = side
        revealIntentTimer.restart()
    }
    function handlePointerMove(localX, localY) {
        var revealAlreadyOpen = nativeLeftRevealActive || nativeRightRevealActive
        var topBandHeight = isMinimal && !revealAlreadyOpen ? 18 : header.height
        var inTopBand = localY >= 0 && localY <= topBandHeight
        if (!inTopBand) {
            handlePointerLeave()
            return
        }
        if (isMinimal) {
            if (search.focused) {
                handlePointerLeave()
                return
            }
            var keepLeft = nativeLeftRevealActive && localX <= 72
            var keepRight = nativeRightRevealActive && localX >= width - 118
            if (!keepRight && (keepLeft || localX <= 26)) {
                nativeRightRevealActive = false
                if (!nativeLeftRevealActive) scheduleReveal("left")
            } else if (!keepLeft && (keepRight || localX >= width - 30)) {
                nativeLeftRevealActive = false
                if (!nativeRightRevealActive) scheduleReveal("right")
            } else {
                handlePointerLeave()
            }
        } else {
            nativeLeftRevealActive = false
            var keepNormalRight = nativeRightRevealActive
                    && localX >= width - gutter - rightFullWidth
            if (localX >= width - 32 || keepNormalRight) {
                if (!nativeRightRevealActive) scheduleReveal("right")
            } else {
                revealIntentTimer.stop()
                pendingReveal = ""
                nativeRightRevealActive = false
            }
        }
    }
    property bool isDragging: false
    property bool isResizing: false
    property bool nativeLeftRevealActive: false
    property bool nativeRightRevealActive: false
    property string pendingReveal: ""
    Timer {
        id: revealIntentTimer
        objectName: "cardRevealIntentTimer"
        interval: 110
        repeat: false
        onTriggered: {
            if (card.pendingReveal === "left" && card.isMinimal)
                card.nativeLeftRevealActive = true
            else if (card.pendingReveal === "right")
                card.nativeRightRevealActive = true
            card.pendingReveal = ""
        }
    }
    readonly property bool isMinimal: height <= 130 || (width <= 220 && height <= 160)
    readonly property bool isUltraCompact: !isMinimal && (width < 280 || height < 260)
    readonly property bool isVeryCompact: !isMinimal && (width < 340 || height < 330)
    readonly property bool isCompact: !isMinimal && (width < 420 || height < 400)
    readonly property int defaultWindowHeight: 200
    readonly property int richWindowWidth: 350
    readonly property int richWindowHeight: 420
    readonly property bool hasVisibleResult: appState.screenshotMode
                                               ? appState.ocrLines.length > 0
                                               : appState.translatedText.length > 0
    readonly property real resultImplicitHeight: appState.screenshotMode
                                                   ? screenshotResult.naturalContentHeight
                                                   : resultColumn.implicitHeight + 12
    readonly property real naturalWindowHeight: 148 + resultImplicitHeight
    readonly property bool hasRichResult: appState.screenshotMode
                                             ? appState.ocrLines.length >= 4 || naturalWindowHeight > 340
                                             : (appState.isWord
                                                ? appState.examples.length > 0
                                                  || appState.synonyms.length > 0
                                                  || appState.antonyms.length > 0
                                                  || appState.wordForms.length > 0
                                                : appState.translatedText.length > 160
                                                  || naturalWindowHeight > 340)
    // Keep empty and concise results at the reference compact size. Rich content
    // grows from its actual rendered height and stops at the large-card size.
    readonly property int desiredWindowWidth: !hasVisibleResult || appState.isTranslating
                                                  ? 220
                                                  : (hasRichResult ? richWindowWidth : 220)
    readonly property int desiredWindowHeight: !hasVisibleResult || appState.isTranslating
                                                       ? defaultWindowHeight
                                                       : (hasRichResult ? richWindowHeight
                                                                        : defaultWindowHeight)
    readonly property real gutter: Math.round((isUltraCompact ? 8 : (isVeryCompact ? 10 : 14))
                                               * Math.max(0.9, Math.min(1.16, DesignTokens.fontScale)))
    readonly property real middleNaturalWidth: 138
    readonly property real middleMinWidth: 54
    readonly property real rightFullWidth: 104
    readonly property real rightMinWidth: 26
    readonly property real trafficSlotWidth: isUltraCompact ? 40 : 44
    readonly property real topContentWidth: Math.max(0, width - gutter * 2)
    readonly property real spaceAfterTrafficLights: Math.max(0, topContentWidth - trafficSlotWidth)
    // First compress the middle pair; after it reaches its minimum, clip the
    // right actions from the left. Its position is centered in the live gap.
    readonly property real baseMiddleWidth: Math.min(middleNaturalWidth,
                                                      Math.max(middleMinWidth,
                                                               spaceAfterTrafficLights - rightFullWidth))
    readonly property real baseRightWidth: Math.min(rightFullWidth,
                                                     Math.max(rightMinWidth,
                                                              spaceAfterTrafficLights - baseMiddleWidth))
    readonly property real baseEngineWidth: baseMiddleWidth >= middleNaturalWidth ? 52 : 14
    readonly property real languageRoom: Math.max(36, baseMiddleWidth - baseEngineWidth - 4)
    readonly property real baseLanguageWidth: languageRoom >= 82 ? 82 : (languageRoom >= 70 ? 70 : (languageRoom >= 56 ? 56 : 36))
    readonly property bool languageHoverExpanded: languageSelector.hovered && baseLanguageWidth < 82 && !rightHover.hovered
    readonly property bool engineHoverExpanded: engineHover.hovered && baseEngineWidth < 52 && !rightHover.hovered
    readonly property bool rightHoverExpanded: nativeRightRevealActive
                                                && baseRightWidth < rightFullWidth
                                                && !isMinimal
    readonly property bool showMinimalTraffic: isMinimal && nativeLeftRevealActive
    readonly property bool showMinimalActions: isMinimal && nativeRightRevealActive
    readonly property real requestedMiddleWidth: languageHoverExpanded ? 82 + 4 + baseEngineWidth : (engineHoverExpanded ? baseLanguageWidth + 4 + 52 : baseMiddleWidth)
    readonly property real activeMiddleWidth: isMinimal ? 0 : (rightHoverExpanded ? 0 : Math.min(spaceAfterTrafficLights, requestedMiddleWidth))
    readonly property real activeRightWidth: isMinimal
                                                ? (showMinimalActions ? Math.min(rightFullWidth, topContentWidth) : 0)
                                                : (rightHoverExpanded ? Math.min(rightFullWidth, spaceAfterTrafficLights) : ((languageHoverExpanded || engineHoverExpanded) ? Math.max(0, Math.min(baseRightWidth, spaceAfterTrafficLights - activeMiddleWidth)) : baseRightWidth))
    readonly property bool middleIsCompact: baseLanguageWidth < 82
    readonly property bool middleIsMinimal: baseLanguageWidth <= 56
    readonly property bool middleIsMin: baseLanguageWidth <= 36
    property bool layoutPanelVisible: false
    signal collapseRequested()
    signal translateRequested()
    signal settingsRequested()
    signal musicPanelRequested()
    signal historyRequested()
    signal screenshotRequested()
    signal screenshotPreviewRequested(string source)
    signal moveRequested()
    signal quitRequested()
    signal minimizeToTaskbarRequested()
    signal layoutPanelRequested()
    GlassSurface { anchors.fill: parent; isResizing: card.isResizing }
    AuroraBorder {
        id: cardAuroraBorder
        objectName: "cardAuroraBorder"
        active: search.focused || appState.isTranslating
        processing: appState.isTranslating
    }

    MouseArea {
        id: outerBlankMoveArea
        objectName: "cardBlankAreaMoveHandler"
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        pressAndHoldInterval: 280
        onPressAndHold: card.moveRequested()
    }

    Item {
        id: header
        objectName: "cardHeader"
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: card.isMinimal ? 34 : 44
        visible: true
        // The collapsed header yields its hit plane to the search field. Once a
        // corner group is revealed it rises above the field, as the visual
        // interaction promises.
        z: card.isMinimal && !card.showMinimalTraffic && !card.showMinimalActions ? 1 : 10
        Rectangle {
            id: headerDivider
            objectName: "cardHeaderDivider"
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 5
                rightMargin: 5
                bottomMargin: 5
            }
            height: 1
            color: DesignTokens.borderSubtle
            opacity: 0.66
            visible: !card.isMinimal
        }
        MouseArea {
            anchors.fill: parent
            enabled: !card.isMinimal
            onPressed: card.moveRequested()
        }
        Item {
            id: topRow
            objectName: "headerActions"
            z: 1
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: card.gutter
            anchors.rightMargin: card.gutter
            y: card.isMinimal ? Math.round((header.height - height) / 2)
                              : headerDivider.y - height - 2
            height: 28
            Item {
                id: trafficSlot
                objectName: "headerTraffic"
                width: card.isMinimal ? (card.showMinimalTraffic ? card.trafficSlotWidth : 0)
                                      : card.trafficSlotWidth
                height: 24
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                Behavior on width {
                    enabled: !card.isResizing
                    NumberAnimation { duration: 190; easing.type: Easing.OutQuart }
                }
                TrafficLights {
                    id: trafficLights
                    objectName: "cardTrafficLights"
                    compact: true
                    micro: true
                    glassBackground: true
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: !card.isMinimal || card.showMinimalTraffic ? 1 : 0
                    scale: !card.isMinimal || card.showMinimalTraffic ? 1 : 0.88
                    enabled: !card.isMinimal || card.showMinimalTraffic
                    onCloseClicked: card.quitRequested()
                    onMinimizeClicked: card.minimizeToTaskbarRequested()
                    onCollapseClicked: card.collapseRequested()
                    Behavior on opacity {
                        enabled: !card.isResizing
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        enabled: !card.isResizing
                        NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                    }
                }
            }
            Item {
                id: middleGroup
                objectName: "headerMiddle"
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round(trafficSlot.x + trafficSlot.width
                              + (iconGroup.x - trafficSlot.x - trafficSlot.width - width) / 2)
                width: card.activeMiddleWidth
                height: 22
                visible: !card.isMinimal
                clip: true
                Behavior on width {
                    enabled: !card.isResizing
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    LanguageSelector {
                        id: languageSelector
                        objectName: "headerLanguage"
                        anchors.verticalCenter: parent.verticalCenter
                        sourceLang: appState.sourceLang.toUpperCase()
                        targetLang: appState.targetLang.toUpperCase()
                        controlHeight: 22
                        labelFontSize: 9
                        compact: !languageSelector.hovered && card.middleIsCompact && !card.middleIsMinimal
                        minimal: !languageSelector.hovered && card.middleIsMinimal && !card.middleIsMin
                        textOnly: !languageSelector.hovered && card.middleIsMin
                        onSwapClicked: appState.swapLanguages()
                        onSourceSelected: function(code) {
                            appState.setSourceLang(code)
                        }
                        onTargetSelected: function(code) {
                            appState.setTargetLang(code)
                        }
                    }
                    Rectangle {
                        id: engineIndicator
                        anchors.verticalCenter: parent.verticalCenter
                        objectName: "headerEngine"
                        property bool expanded: card.baseEngineWidth >= 52 || engineHover.hovered
                        width: expanded ? 52 : 14
                        height: expanded ? 22 : 14
                        radius: height / 2
                        color: engineHover.hovered ? DesignTokens.surfaceHover : "#1affffff"
                        border.width: expanded ? 1 : 0
                        border.color: DesignTokens.borderInput
                        Row {
                            id: engineRow
                            anchors.centerIn: parent
                            spacing: 6
                            opacity: engineIndicator.expanded ? 1 : 0
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6; height: 6; radius: 3
                                color: appState.engine === "offline" ? DesignTokens.accentAmber : DesignTokens.accentEmerald
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: appState.engine === "gemini" ? "Gemini" : appState.engine === "deepl" ? "DeepL" : appState.engine === "youdao" ? "有道" : "离线"
                                color: "#93c5fd"
                                font { pixelSize: 9; weight: Font.Medium }
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            visible: !engineIndicator.expanded
                            width: 5; height: 5; radius: 2.5
                            color: appState.engine === "offline" ? DesignTokens.accentAmber : DesignTokens.accentEmerald
                        }
                        HoverHandler { id: engineHover }
                        Behavior on color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
                    }
                }
            }
            Item {
                id: iconGroup
                objectName: "headerIcons"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: card.activeRightWidth
                height: 28
                clip: true
                Rectangle {
                    objectName: "cardActionsGlass"
                    anchors {
                        fill: parent
                        topMargin: 2
                        bottomMargin: 2
                    }
                    radius: 12
                    visible: card.isMinimal && card.showMinimalActions
                    color: "#68141b29"
                    border.width: 1
                    border.color: "#2effffff"
                    opacity: iconGroup.width > 12 ? 1 : 0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#22ffffff" }
                        GradientStop { position: 0.48; color: "#0cbed8f4" }
                        GradientStop { position: 1.0; color: "#03040a18" }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
                Behavior on width {
                    enabled: !card.isResizing
                    NumberAnimation { duration: 210; easing.type: Easing.OutQuart }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: card.rightFullWidth
                    height: 28
                    spacing: 0
                    Item {
                        objectName: "cardScreenshotReveal"
                        readonly property real reveal: Math.max(0, Math.min(1, (iconGroup.width - 78) / 26))
                        width: 26; height: 26
                        opacity: reveal
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        IconButton {
                            objectName: "cardScreenshot"
                            visible: parent.reveal >= 0.999
                            width: 24; height: 24
                            anchors.centerIn: parent
                            iconSource: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"
                            iconColor: "#cc60a5fa"
                            iconSize: 13
                            tooltip: "截图翻译"
                            onClicked: card.screenshotRequested()
                        }
                    }
                    Item {
                        objectName: "cardPinReveal"
                        readonly property real reveal: Math.max(0, Math.min(1, (iconGroup.width - 52) / 26))
                        width: 26; height: 26
                        opacity: reveal
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        IconButton {
                            objectName: "cardPin"
                            visible: parent.reveal >= 0.999
                            width: 24; height: 24
                            anchors.centerIn: parent
                            iconSource: "qrc:/qt/qml/Linguist/resources/icons/pin.svg"
                            active: appState.isPinned
                            iconSize: 13
                            tooltip: "置顶"
                            onClicked: appState.setIsPinned(!appState.isPinned)
                        }
                    }
                    Item {
                        objectName: "cardMusicReveal"
                        readonly property real reveal: Math.max(0, Math.min(1, (iconGroup.width - 26) / 26))
                        width: 26; height: 26
                        opacity: reveal
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        IconButton {
                            objectName: "cardMusic"
                            visible: parent.reveal >= 0.999
                            width: 24; height: 24
                            anchors.centerIn: parent
                            iconSource: "qrc:/qt/qml/Linguist/resources/icons/music.svg"
                            iconColor: DesignTokens.accentEmerald
                            iconSize: 13
                            tooltip: "音乐控制"
                            onClicked: card.musicPanelRequested()
                        }
                    }
                    Item {
                        objectName: "cardSettingsReveal"
                        readonly property real reveal: Math.max(0, Math.min(1, iconGroup.width / 26))
                        width: 26; height: 26
                        opacity: reveal
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        IconButton {
                            objectName: "cardSettings"
                            visible: parent.reveal >= 0.999
                            width: 24; height: 24
                            anchors.centerIn: parent
                            iconSource: "qrc:/qt/qml/Linguist/resources/icons/settings.svg"
                            iconSize: 13
                            tooltip: "偏好设置"
                            onClicked: card.settingsRequested()
                        }
                    }
                }
                HoverHandler {
                    id: rightHover
                    onHoveredChanged: {
                        if (card.isMinimal)
                            return
                        if (hovered)
                            card.scheduleReveal("right")
                        else
                            card.handlePointerLeave()
                    }
                }
            }
        }
        Item {
            objectName: "cardTopLeftRevealZone"
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: card.showMinimalTraffic ? 72 : 26
            visible: card.isMinimal
            z: 0
        }
        Item {
            objectName: "cardTopRightRevealZone"
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: card.showMinimalActions ? 118 : 30
            visible: card.isMinimal || card.baseRightWidth < card.rightFullWidth
            z: 0
        }
    }

    Item {
        id: body
        objectName: "cardBody"
        anchors {
            top: card.isMinimal ? parent.top : header.bottom
            bottom: footer.top
            left: parent.left
            right: parent.right
            topMargin: card.isMinimal ? 5 : 0
        }
        z: 2
        anchors.leftMargin: card.gutter
        anchors.rightMargin: card.gutter
        anchors.bottomMargin: !card.isMinimal && footer.height === 0 ? 20 : 0
        clip: true
        SearchInput {
            id: search
            objectName: "cardSearch"
            anchors { top: parent.top; left: parent.left; right: parent.right }
            visible: !appState.screenshotMode
            compact: card.isMinimal || card.width < 260
            height: card.isMinimal ? 24 : 26
            radius: height / 2
            muted: card.isMinimal && !focused
                   && (card.showMinimalTraffic || card.showMinimalActions)
            enabled: !muted
            text: appState.sourceText
            onUserTextChanged: function(value) { appState.setSourceText(value) }
            onCleared: appState.clearText()
            onSubmitted: card.translateRequested()
            onScreenshotClicked: card.screenshotRequested()
        }
        Flickable {
            id: scroll
            objectName: "cardScroll"
            property bool wheelScrolling: false
            property real wheelTargetY: contentY
            anchors { top: search.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.topMargin: card.isMinimal ? 4 : 16
            clip: true
            contentWidth: width
            contentHeight: resultColumn.implicitHeight + 12
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            maximumFlickVelocity: 1800
            visible: !appState.screenshotMode
            flickDeceleration: 2400
            MouseArea {
                id: bodyBlankMoveArea
                anchors.fill: parent
                enabled: !card.hasVisibleResult || scroll.contentHeight <= scroll.height + 1
                acceptedButtons: Qt.LeftButton
                pressAndHoldInterval: 280
                onPressAndHold: card.moveRequested()
            }
            function applyWheel(event) {
                var maximumY = Math.max(0, contentHeight - height)
                if (maximumY <= 0)
                    return
                var pixelStep = event.pixelDelta.y
                if (pixelStep !== 0) {
                    wheelScrollAnimation.stop()
                    contentY = Math.max(0, Math.min(maximumY, contentY - pixelStep))
                    wheelTargetY = contentY
                } else {
                    var notchStep = event.angleDelta.y / 120 * 56
                    wheelTargetY = Math.max(0, Math.min(maximumY,
                                        (wheelScrollAnimation.running ? wheelTargetY : contentY) - notchStep))
                    wheelScrollAnimation.from = contentY
                    wheelScrollAnimation.to = wheelTargetY
                    wheelScrollAnimation.restart()
                }
                wheelScrolling = true
                wheelIdleTimer.restart()
                event.accepted = true
            }
            NumberAnimation {
                id: wheelScrollAnimation
                target: scroll
                property: "contentY"
                duration: DesignTokens.durationFast
                easing.type: Easing.OutCubic
            }
            Timer {
                id: wheelIdleTimer
                interval: 420
                onTriggered: scroll.wheelScrolling = false
            }
            WheelHandler {
                id: contentWheelHandler
                orientation: Qt.Vertical
                target: null
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => scroll.applyWheel(event)
            }
            ColumnLayout {
                id: resultColumn
                width: scroll.width
                spacing: 14
                Item {
                    id: cardTranslationMotion
                    objectName: "cardTranslationMotion"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    visible: appState.isTranslating
                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        Repeater {
                            model: [DesignTokens.accentBlue, DesignTokens.accentPurple,
                                    DesignTokens.accentEmerald]
                            delegate: Rectangle {
                                id: cardMotionDot
                                objectName: index === 0 ? "cardTranslationDot0" : ""
                                width: 5
                                height: 5
                                radius: 2.5
                                color: modelData
                                opacity: 0.35
                                SequentialAnimation {
                                    objectName: index === 0 ? "cardTranslationMotionAnimation" : ""
                                    running: cardTranslationMotion.visible
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 70 }
                                    ParallelAnimation {
                                        NumberAnimation { target: cardMotionDot; property: "y"; to: -3; duration: 160; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: cardMotionDot; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
                                    }
                                    ParallelAnimation {
                                        NumberAnimation { target: cardMotionDot; property: "y"; to: 0; duration: 210; easing.type: Easing.InOutCubic }
                                        NumberAnimation { target: cardMotionDot; property: "opacity"; to: 0.35; duration: 210; easing.type: Easing.InOutCubic }
                                    }
                                    PauseAnimation { duration: (2 - index) * 70 + 80 }
                                }
                            }
                        }
                    }
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
                ColumnLayout {
                    id: translatedResult
                    objectName: "cardTranslatedResult"
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 14
                    visible: !appState.isTranslating && appState.translatedText.length > 0
                    opacity: card.isMinimal ? 1 : card.resultReveal
                    transform: Translate { y: card.isMinimal ? 0 : card.resultRevealOffset }
                    WordDetailView {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: !card.isMinimal && appState.isWord
                        word: appState.sourceText
                        phonetic: appState.phoneticUs.length > 0 ? appState.phoneticUs : appState.phoneticUk
                        translatedText: appState.translatedText
                        englishDefinition: appState.englishDefinition
                        definitions: appState.definitions
                        examples: appState.examples
                        synonyms: appState.synonyms
                        antonyms: appState.antonyms
                        wordForms: appState.wordForms
                        compact: card.isCompact
                        veryCompact: card.width < 260
                        ultraCompact: card.width < 220
                    }
                    Text {
                        objectName: "compactTranslation"
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: card.isMinimal || !appState.isWord
                        text: {
                            // Q_INVOKABLE calls are opaque to QML dependency tracking.
                            // Read both result sources explicitly so native AppState
                            // updates always re-evaluate the compact card text.
                            var translatedRevision = appState.translatedText
                            var definitionsRevision = appState.definitions
                            return appState.completeTranslation()
                        }
                        color: DesignTokens.textPrimary
                        font { pixelSize: card.isMinimal ? 12 : Math.round(16 * DesignTokens.fontScale); family: DesignTokens.fontUi }
                        wrapMode: Text.Wrap
                        lineHeight: 1.35
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !card.isMinimal && !appState.isWord
                        text: appState.sourceText
                        color: DesignTokens.textTertiary
                        font.pixelSize: Math.round(13 * DesignTokens.fontScale)
                        wrapMode: Text.Wrap
                        lineHeight: 1.4
                    }
                }
                Item {
                    id: emptyPrompt
                    objectName: "cardEmptyPrompt"
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Layout.bottomMargin: 6
                    Layout.preferredHeight: Math.max(card.isMinimal ? 28 : 64,
                                                     scroll.height - 12)
                    visible: !appState.isTranslating && appState.translatedText.length === 0
                    property real reveal: 0
                    opacity: reveal
                    transform: Translate {
                        y: (1 - emptyPrompt.reveal) * 6
                    }
                    onVisibleChanged: {
                        if (visible) {
                            reveal = 0
                            emptyPromptReveal.restart()
                        }
                    }
                    Component.onCompleted: {
                        if (visible)
                            emptyPromptReveal.start()
                    }
                    Column {
                        id: emptyPromptContent
                        objectName: "cardEmptyPromptContent"
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 7
                        Text {
                            objectName: "cardEmptyPromptTitle"
                            width: parent.width
                            text: "开始翻译"
                            color: DesignTokens.textPrimary
                            font { pixelSize: card.isMinimal ? 11 : 15; weight: Font.Medium; family: DesignTokens.fontUi }
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }
                        Text {
                            objectName: "cardEmptyPromptHint"
                            width: parent.width
                            visible: !card.isMinimal
                            text: "输入文字，或直接划词"
                            color: DesignTokens.textTertiary
                            font.pixelSize: 11
                            font.family: DesignTokens.fontUi
                            horizontalAlignment: Text.AlignHCenter
                            lineHeight: 1.3
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
            NumberAnimation {
                id: emptyPromptReveal
                target: emptyPrompt
                property: "reveal"
                to: 1
                duration: 700
                easing.type: Easing.OutCubic
            }
            Basic.ScrollBar.vertical: Basic.ScrollBar {
                id: verticalScrollBar
                objectName: "cardScrollBar"
                policy: card.isMinimal ? Basic.ScrollBar.AlwaysOff
                                       : (scroll.contentHeight > scroll.height ? Basic.ScrollBar.AlwaysOn
                                                                              : Basic.ScrollBar.AsNeeded)
                width: 6
                active: hovered || pressed || scroll.movingVertically || scroll.wheelScrolling
                padding: 1
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: "#8fa9bad0"
                    opacity: verticalScrollBar.active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: DesignTokens.durationFast; easing.type: Easing.OutCubic } }
                }
                background: Item { implicitWidth: 6 }
            }
        }

        ScreenshotTranslationView {
            id: screenshotResult
            objectName: "cardScreenshotResult"
            anchors.fill: parent
            visible: appState.screenshotMode
            onRetakeRequested: card.screenshotRequested()
            onBackToTextRequested: appState.exitScreenshotMode()
            onPreviewRequested: source => card.screenshotPreviewRequested(source)
        }
    }
    Item {
        id: footer
        objectName: "cardFooter"
        z: 4
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        readonly property bool showActions: !card.isMinimal && card.height >= 160
        readonly property real innerWidth: Math.max(0, card.width - card.gutter * 2)
        readonly property bool canCopy: appState.translatedText.length > 0
        readonly property bool canSpeak: appState.sourceText.length > 0
        readonly property bool canFavorite: appState.translatedText.length > 0
        readonly property int optionalActionCount: (canCopy ? 1 : 0) + (canSpeak ? 1 : 0) + (canFavorite ? 1 : 0) + 1
        readonly property int optionalSlots: Math.max(0, Math.floor((innerWidth - 68) / 32))
        readonly property int speakRank: (canCopy ? 1 : 0) + 1
        readonly property int favoriteRank: (canCopy ? 1 : 0) + (canSpeak ? 1 : 0) + 1
        readonly property int historyRank: (canCopy ? 1 : 0) + (canSpeak ? 1 : 0) + (canFavorite ? 1 : 0) + 1
        readonly property real baseHeight: showActions
                                                   ? Math.round(32 * Math.max(0.9, Math.min(1.15, DesignTokens.fontScale)))
                                                   : 0
        height: baseHeight
        Rectangle {
            id: actionToolbar
            objectName: "cardActionToolbar"
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: footer.baseHeight
            visible: footer.showActions
            color: "transparent"
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: DesignTokens.borderSubtle
            }
            Row {
                id: smartSelectGroup
                objectName: "footerStatus"
                anchors.left: parent.left
                anchors.leftMargin: Math.max(12, card.gutter)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Rectangle {
                    width: 28; height: 14; radius: 7
                    color: appState.selectionTranslation ? "#cc3b82f6" : "#26ffffff"
                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: appState.selectionTranslation ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appState.setSelectionTranslation(!appState.selectionTranslation)
                    }
                }
                Text {
                    id: smartSelectLabel
                    anchors.verticalCenter: parent.verticalCenter
                    visible: footer.optionalSlots >= footer.optionalActionCount
                             && footer.innerWidth >= 76 + footer.optionalActionCount * 32 + implicitWidth
                    text: appState.selectionTranslation ? "Smart-Select" : "Paused"
                    color: DesignTokens.textSecondary
                    font { pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1; capitalization: Font.AllUppercase }
                }
            }
            Row {
                objectName: "footerActions"
                anchors.right: parent.right
                anchors.rightMargin: Math.max(12, card.gutter)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                IconButton {
                    objectName: "cardCopy"
                    visible: footer.canCopy && footer.optionalSlots >= 1
                    iconSource: appState.justCopied ? "qrc:/qt/qml/Linguist/resources/icons/check.svg" : "qrc:/qt/qml/Linguist/resources/icons/copy.svg"
                    iconSize: 14
                    iconColor: appState.justCopied ? DesignTokens.accentEmerald : "#ccffffff"
                    tooltip: "复制译文"
                    onClicked: appState.copyTranslation()
                }
                IconButton {
                    objectName: "cardSpeak"
                    visible: footer.canSpeak && footer.optionalSlots >= footer.speakRank
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                    iconSize: 14
                    tooltip: "朗读原文"
                    onClicked: appState.speak(appState.sourceText, appState.sourceLang)
                }
                IconButton {
                    objectName: "cardFavorite"
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/heart.svg"
                    iconSize: 14
                    visible: footer.canFavorite && footer.optionalSlots >= footer.favoriteRank
                    active: appState.isFavorite
                    activeColor: DesignTokens.accentAmber
                    tooltip: "收藏"
                    onClicked: appState.setIsFavorite(!appState.isFavorite)
                }
                IconButton {
                    objectName: "cardHistory"
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/history.svg"
                    iconSize: 14
                    visible: footer.optionalSlots >= footer.historyRank
                    tooltip: "历史与生词本"
                    onClicked: card.historyRequested()
                }
                IconButton {
                    objectName: "footerFont"
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/type.svg"
                    iconSize: 14
                    active: card.layoutPanelVisible
                    tooltip: "页面排版"
                    onClicked: card.layoutPanelRequested()
                }
            }
        }
    }
}
