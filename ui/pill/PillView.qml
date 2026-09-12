import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Item {
    id: pill

    property bool isDragging: false
    property bool isResizing: false
    property bool searchExpanded: false
    property bool rightActionsExpanded: false
    property bool pointerInsideWindow: true
    property bool nativeLeftRevealActive: false
    property bool nativeRightRevealActive: false
    readonly property var mediaState: typeof appState !== "undefined" ? appState : null
    readonly property real auroraOpacity: pillAuroraBorder.auraOpacity
    readonly property real auroraBloom: pillAuroraBorder.bloom
    readonly property real auroraPhase: pillAuroraBorder.phase

    signal expandRequested()
    signal minimizeToTaskbarRequested()
    signal musicPanelRequested()
    signal settingsRequested()
    signal screenshotRequested()

    readonly property bool isMusicMode: typeof appState !== "undefined" && appState && appState.pillMusicMode
    readonly property bool isMinimumState: width <= 220
    readonly property bool leftLightsRevealed: pointerInsideWindow && isMinimumState
                                               && !searchExpanded
                                               && (nativeLeftRevealActive || leftRevealHover.hovered)
    readonly property string conciseTranslationPrefix: importantTranslationPrefix()
    readonly property string conciseTranslationText: importantTranslationMeaning()
    readonly property real translationNaturalWidth: Math.ceil(translationTextMetrics.advanceWidth)
                                                     + (conciseTranslationPrefix.length > 0
                                                        ? Math.ceil(translationPrefixMetrics.advanceWidth) + 6 : 0)
    readonly property real preferredTranslationWidth: Math.max(width >= 220 ? 72 : 42,
        Math.min(width >= 300 ? 160 : width >= 220 ? 112 : 72, translationNaturalWidth + 4))
    readonly property real normalLeadingInset: isMinimumState ? 22 : 46
    readonly property real searchExpandedTargetWidth: Math.max(64, Math.min(108,
        width - normalLeadingInset - preferredTranslationWidth - 46))
    readonly property bool hasCompletedTranslation: appState && !appState.isTranslating
                                                    && appState.sourceText.length > 0
                                                    && appState.translatedText.length > 0
    readonly property bool hasSourceText: appState && appState.sourceText.trim().length > 0
    readonly property real searchNaturalWidth: Math.ceil(searchTextMetrics.advanceWidth) + 29
    readonly property real searchRestingWidth: hasSourceText
        ? Math.min(searchExpandedTargetWidth, Math.max(46, searchNaturalWidth)) : 26
    readonly property real searchEditingWidth: Math.min(searchExpandedTargetWidth,
        Math.max(64, searchNaturalWidth))
    readonly property real searchDesiredWidth: searchExpanded ? searchEditingWidth
                                                               : searchRestingWidth
    readonly property real rightFullWidth: 143
    readonly property real normalActionBudget: Math.max(23, Math.min(rightFullWidth,
        width - normalLeadingInset - searchDesiredWidth - preferredTranslationWidth - 18))
    readonly property int normalActionCount: width <= 180 ? 1
        : Math.max(1, Math.min(6, Math.floor((normalActionBudget + 1) / 24)))
    readonly property bool hasHiddenActions: normalActionCount < 6
    readonly property bool rightHoverExpanded: rightActionsExpanded && hasHiddenActions
                                                && !searchExpanded && !leftLightsRevealed
    readonly property bool showTrafficLights: !isMinimumState || leftLightsRevealed
    readonly property real rightBaseWidth: normalActionCount * 23 + (normalActionCount - 1)
    readonly property real rightWidthLimit: rightHoverExpanded
        ? Math.max(23, width - 13)
        : Math.max(24, width - leadingInset - searchBox.responsiveWidth - preferredTranslationWidth - 18)
    property real activeRightWidth: Math.min(rightHoverExpanded ? rightFullWidth : rightBaseWidth,
                                              rightWidthLimit)
    property real leadingInset: showTrafficLights ? pillTrafficLights.x + pillTrafficLights.width + 2 : 8

    TextMetrics {
        id: searchTextMetrics
        font.family: DesignTokens.fontUi
        font.pixelSize: 11
        text: appState ? appState.sourceText : ""
    }

    TextMetrics {
        id: translationPrefixMetrics
        font.family: DesignTokens.fontMono
        font.pixelSize: 11
        text: pill.conciseTranslationPrefix
    }

    TextMetrics {
        id: translationTextMetrics
        font.family: DesignTokens.fontUi
        font.pixelSize: 12
        text: pill.conciseTranslationText
    }

    onWidthChanged: {
        if (!nativeRightRevealActive && !rightEdgeHover.hovered)
            rightActionsExpanded = false
    }

    Timer {
        id: closeRightActionsTimer
        interval: 90
        onTriggered: {
            if (!pill.nativeRightRevealActive
                    && !rightEdgeHover.hovered && !rightActionsHover.hovered)
                pill.rightActionsExpanded = false
        }
    }

    Behavior on leadingInset {
        enabled: !pill.isResizing
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    Behavior on activeRightWidth {
        enabled: !pill.isResizing
        NumberAnimation { duration: 160; easing.type: Easing.OutQuart }
    }

    function openInlineSearch() {
        rightActionsExpanded = false
        searchExpanded = true
        Qt.callLater(function() {
            pillInput.forceActiveFocus(Qt.MouseFocusReason)
            pillInput.selectAll()
        })
    }

    function closeInlineSearch() {
        if (!searchExpanded)
            return
        searchExpanded = false
        pill.forceActiveFocus(Qt.MouseFocusReason)
    }

    function firstDefinition() {
        if (!appState || !appState.definitions || appState.definitions.length === 0)
            return null
        return appState.definitions[0]
    }

    function importantTranslationPrefix() {
        if (!appState || appState.isTranslating)
            return ""
        var definition = firstDefinition()
        if (definition && definition.partOfSpeech)
            return String(definition.partOfSpeech).trim()
        var raw = appState.translatedText ? String(appState.translatedText).trim() : ""
        var match = raw.match(/^([a-zA-Z]{1,6}\.)\s*/)
        return match ? match[1] : ""
    }

    function primaryMeaning(rawText) {
        var clean = String(rawText || "").replace(/\s+/g, " ").trim()
        if (clean.length === 0)
            return ""
        var groups = clean.split(/[；;\n]/)
        return groups[0].trim()
    }

    function importantTranslationMeaning() {
        if (!appState)
            return "输入、粘贴或划取"
        if (appState.isTranslating)
            return ""
        var definition = firstDefinition()
        if (definition && definition.meaning)
            return primaryMeaning(definition.meaning)
        var raw = appState.translatedText ? String(appState.translatedText).trim() : ""
        var match = raw.match(/^([a-zA-Z]{1,6}\.)\s*/)
        if (match)
            raw = raw.substring(match[0].length)
        return raw.length > 0 ? primaryMeaning(raw) : "输入、粘贴或划取"
    }

    function prepareKeyboardFocus(localX, localY) {
        if (isMusicMode || !searchBox.visible)
            return false
        var topLeft = searchBox.mapToItem(pill, 0, 0)
        var inside = localX >= topLeft.x && localX <= topLeft.x + searchBox.width
                  && localY >= topLeft.y && localY <= topLeft.y + searchBox.height
        if (inside) {
            openInlineSearch()
            pillInput.forceActiveFocus(Qt.MouseFocusReason)
        } else if (searchExpanded) {
            searchExpanded = false
            pill.forceActiveFocus(Qt.MouseFocusReason)
        }
        return inside
    }

    function settleSearchAfterTranslation() {
        if (searchExpanded && hasCompletedTranslation && !pointerInsideWindow) {
            searchExpanded = false
            pill.forceActiveFocus(Qt.OtherFocusReason)
        }
    }

    function settleEmptySearch() {
        if (!appState || appState.sourceText.trim().length > 0)
            return
        searchExpanded = false
        rightActionsExpanded = false
        pill.forceActiveFocus(Qt.OtherFocusReason)
    }

    Connections {
        target: appState
        function onSourceTextChanged() {
            if (appState.sourceText.trim().length === 0)
                Qt.callLater(pill.settleEmptySearch)
        }
    }

    function handlePointerLeave() {
        pointerInsideWindow = false
        nativeLeftRevealActive = false
        nativeRightRevealActive = false
        rightActionsExpanded = false
        closeRightActionsTimer.stop()
        settleSearchAfterTranslation()
    }

    function handlePointerMove(localX, localY) {
        pointerInsideWindow = true
        var overVerticalCenter = localY >= (height - 30) / 2
                              && localY <= (height + 30) / 2
        nativeLeftRevealActive = isMinimumState && !searchExpanded
                              && localX >= 0 && localX <= 16 && overVerticalCenter
        nativeRightRevealActive = hasHiddenActions && !searchExpanded && !isMusicMode
                               && localX >= width - 32 && localX <= width
                               && overVerticalCenter
        if (!hasHiddenActions || searchExpanded || isMusicMode) {
            rightActionsExpanded = false
            return
        }

        var actionsTopLeft = actionViewport.mapToItem(pill, 0, 0)
        var overActions = localX >= actionsTopLeft.x
                       && localX <= actionsTopLeft.x + actionViewport.width
                       && localY >= actionsTopLeft.y
                       && localY <= actionsTopLeft.y + actionViewport.height
        if (nativeRightRevealActive || (rightActionsExpanded && overActions)) {
            closeRightActionsTimer.stop()
            rightActionsExpanded = true
        } else if (rightActionsExpanded) {
            closeRightActionsTimer.restart()
        }
    }

    Connections {
        target: typeof appState !== "undefined" ? appState : null
        function onIsTranslatingChanged() {
            if (!appState.isTranslating)
                Qt.callLater(pill.settleSearchAfterTranslation)
        }
        function onTranslatedTextChanged() {
            if (pill.hasCompletedTranslation)
                Qt.callLater(pill.settleSearchAfterTranslation)
        }
    }

    // === 毛玻璃背景 ===
    GlassSurface {
        anchors.fill: parent
        isPill: true
        isDragging: pill.isDragging
        isResizing: pill.isResizing
    }
    AuroraBorder {
        id: pillAuroraBorder
        objectName: "pillAuroraBorder"
        active: pillInput.activeFocus
        processing: pillInput.activeFocus && appState.isTranslating
    }

    // 普通药丸常显；最小药丸保留一个左侧感应区，悬浮时平滑让出空间。
    TrafficLights {
        id: pillTrafficLights
        objectName: "pillTrafficLights"
        x: 10
        compact: true
        interactionEnabled: pill.pointerInsideWindow
        anchors.verticalCenter: parent.verticalCenter
        opacity: pill.showTrafficLights ? 1 : 0
        scale: pill.showTrafficLights ? 1 : 0.88
        enabled: pill.showTrafficLights
        z: 8
        onCloseClicked: appState.clearText()
        onCollapseClicked: pill.expandRequested()
        onMinimizeClicked: pill.minimizeToTaskbarRequested()
        Behavior on opacity {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Item {
        id: leftRevealZone
        objectName: "pillLeftRevealZone"
        x: 0
        width: pill.leftLightsRevealed ? 68 : 10
        height: parent.height
        visible: pill.isMinimumState
        z: 7
        HoverHandler { id: leftRevealHover }
    }

    // === 模式 1：灵动岛音乐模式 ===
    RowLayout {
        id: musicRow
        anchors.fill: parent
        anchors.leftMargin: pill.leadingInset
        anchors.rightMargin: 8
        spacing: 8
        visible: isMusicMode

        // 旋转唱片微缩图
        Item {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: 13
                color: "#0f172a"
                clip: true

                Image {
                    id: pillDisc
                    objectName: "pillAlbumDisc"
                    anchors.fill: parent
                    source: appState && appState.coverArtUrl ? appState.coverArtUrl
                                                            : "qrc:/qt/qml/Linguist/resources/icons/disc.svg"
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 64
                    sourceSize.height: 64

                    RotationAnimator {
                        target: pillDisc
                        from: 0
                        to: 360
                        duration: 6000
                        loops: Animation.Infinite
                        running: appState ? appState.musicPlaying : false
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: "#0a0f1e"
                    border.width: 1
                    border.color: "#ccffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.musicPanelRequested()
                }
            }

            Canvas {
                id: pillProgressRing
                objectName: "pillProgressRing"
                anchors.fill: parent
                readonly property real progress: appState && appState.trackDuration > 0
                                                 ? Math.max(0, Math.min(1, appState.trackPosition / appState.trackDuration))
                                                 : 0
                onProgressChanged: requestPaint()
                onPaint: {
                    var context = getContext("2d")
                    context.clearRect(0, 0, width, height)
                    context.lineWidth = 1.6
                    context.strokeStyle = Qt.rgba(1, 1, 1, 0.16)
                    context.beginPath()
                    context.arc(width / 2, height / 2, width / 2 - 1.2, 0, Math.PI * 2)
                    context.stroke()
                    if (progress > 0) {
                        context.strokeStyle = "#34d399"
                        context.lineCap = "round"
                        context.beginPath()
                        context.arc(width / 2, height / 2, width / 2 - 1.2,
                                    -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progress)
                        context.stroke()
                    }
                }
            }
        }

        // 跳动的音频均衡器柱 (3 bars)
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            visible: pill.width >= 240

            Repeater {
                model: 3
                Rectangle {
                    width: 2.5
                    height: (appState && appState.musicPlaying) ? (index === 1 ? 16 : (index === 0 ? 10 : 12)) : 4
                    radius: 1.2
                    color: "#34d399"
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                    SequentialAnimation on height {
                        running: appState ? appState.musicPlaying : false
                        loops: Animation.Infinite
                        NumberAnimation { to: index === 1 ? 6 : 14; duration: 250 + index * 80; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: index === 1 ? 16 : 5; duration: 250 + index * 80; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }

        // 歌曲标题与实时歌词
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: appState && appState.trackTitle
                      ? appState.trackTitle + (appState.trackArtist ? " · " + appState.trackArtist : "")
                      : "未播放音频"
                color: "white"
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: appState && appState.currentLyric ? appState.currentLyric
                                                        : (appState && appState.systemMediaConnected ? "正在获取歌词…" : "未检测到系统媒体")
                color: "#a7f3d0"
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            TapHandler { onTapped: pill.musicPanelRequested() }
        }

        // 播放控制按钮
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            IconButton {
                objectName: "pillMusicPrevious"
                enabled: appState && appState.systemMediaConnected
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/skip-back.svg"
                iconSize: 14
                tooltip: "上一首"
                visible: pill.width >= 300
                onClicked: if (appState) appState.prevTrack()
            }

            IconButton {
                objectName: "pillMusicToggle"
                enabled: appState && appState.systemMediaConnected
                iconSource: appState && appState.musicPlaying
                            ? "qrc:/qt/qml/Linguist/resources/icons/pause.svg"
                            : "qrc:/qt/qml/Linguist/resources/icons/play.svg"
                iconSize: 14
                iconColor: "#34d399"
                onClicked: if (appState) appState.toggleMusicPlay()
            }

            IconButton {
                objectName: "pillMusicNext"
                enabled: appState && appState.systemMediaConnected
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/skip-forward.svg"
                iconSize: 14
                visible: pill.width >= 300
                onClicked: if (appState) appState.nextTrack()
            }

            // 切回翻译药丸按钮
            IconButton {
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"
                iconSize: 14
                iconColor: Qt.rgba(1, 1, 1, 0.7)
                hoverColor: Qt.rgba(1, 1, 1, 0.15)
                onClicked: if (appState) appState.setPillMusicMode(false)
            }
        }
    }

    // === 标准翻译药丸：动作按实际隐式宽度分配，紧凑时收进独立菜单 ===
    RowLayout {
        id: translationRow
        anchors.fill: parent
        anchors.leftMargin: pill.leadingInset
        anchors.rightMargin: 10
        spacing: pill.rightHoverExpanded ? 0 : 5
        visible: !pill.isMusicMode

        Rectangle {
            id: searchBox
            objectName: "pillSearch"
            property real responsiveWidth: pill.rightHoverExpanded ? 0 : pill.searchDesiredWidth
            Layout.preferredWidth: responsiveWidth
            Layout.minimumWidth: Layout.preferredWidth
            Layout.maximumWidth: Layout.preferredWidth
            Layout.preferredHeight: 26
            radius: 13
            visible: !pill.leftLightsRevealed && !pill.rightHoverExpanded
            color: pillInput.activeFocus ? DesignTokens.bgInputFocus
                                         : (pill.hasSourceText ? "#18ffffff" : "#10182132")
            border.color: pillInput.activeFocus ? DesignTokens.borderInputFocus
                                                : (pill.hasSourceText ? DesignTokens.borderInput : "#45c7e3ff")
            border.width: 1
            Rectangle {
                objectName: "pillSearchGlass"
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, parent.radius - 1)
                opacity: pillInput.activeFocus ? 0.42 : (pill.hasSourceText ? 0.30 : 0.72)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#30ffffff" }
                    GradientStop { position: 0.48; color: "#10b9d9ff" }
                    GradientStop { position: 1.0; color: "#08040a18" }
                }
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
            Image {
                x: pill.hasSourceText || pill.searchExpanded ? 7
                                                            : Math.round((parent.width - width) / 2)
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/qt/qml/Linguist/resources/icons/search.svg"
                sourceSize.width: 14; sourceSize.height: 14
                opacity: pillInput.activeFocus ? 1 : 0.82
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
            HoverScrollText {
                id: compactSourceText
                objectName: "pillSearchSource"
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                height: 18
                visible: pill.hasSourceText && !pill.searchExpanded
                text: appState.sourceText
                textColor: DesignTokens.textSecondary
                fontSize: 11
                speed: 28
                interactionEnabled: pill.pointerInsideWindow
            }
            Basic.TextField {
                id: pillInput
                objectName: "pillSearchInput"
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.searchExpanded
                text: appState.sourceText
                placeholderText: "输入文字"
                color: DesignTokens.textSecondary
                font.pixelSize: 12
                padding: 0
                activeFocusOnPress: true
                selectByMouse: true
                persistentSelection: true
                background: Item {}
                cursorDelegate: Rectangle {
                    id: pillCaret
                    width: 1.5
                    radius: 0.75
                    color: DesignTokens.accentBlue
                    SequentialAnimation {
                        objectName: "pillCaretBlink"
                        running: pillInput.activeFocus && pillInput.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: 480 }
                        NumberAnimation { target: pillCaret; property: "opacity"; to: 0; duration: 70; easing.type: Easing.InOutSine }
                        PauseAnimation { duration: 430 }
                        NumberAnimation { target: pillCaret; property: "opacity"; to: 1; duration: 70; easing.type: Easing.InOutSine }
                    }
                }
                onTextEdited: appState.setSourceText(text)
                onAccepted: appState.translate()
                onActiveFocusChanged: {
                    if (!activeFocus && pill.searchExpanded) {
                        Qt.callLater(function() {
                            if (!pillInput.activeFocus)
                                pill.closeInlineSearch()
                        })
                    }
                }
                Keys.onEscapePressed: {
                    pill.closeInlineSearch()
                }
            }
            TapHandler {
                enabled: !pill.searchExpanded
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: pill.openInlineSearch()
            }
            Behavior on responsiveWidth {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }
        }
        Item {
            id: translationContent
            objectName: "pillTranslationContent"
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            clip: true
            visible: true
            HoverScrollText {
                objectName: "pillImportantTranslation"
                anchors.fill: parent
                visible: !appState.isTranslating
                prefix: pill.conciseTranslationPrefix
                prefixColor: DesignTokens.accentBlue
                allowStacking: false
                text: pill.conciseTranslationText
                textColor: appState.isTranslating ? DesignTokens.accentAmber : DesignTokens.textPrimary
                fontSize: 12
                interactionEnabled: pill.pointerInsideWindow
            }

            Item {
                id: translationMotion
                objectName: "pillTranslationMotion"
                anchors.fill: parent
                visible: appState.isTranslating

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: [DesignTokens.accentBlue, DesignTokens.accentPurple,
                                DesignTokens.accentEmerald]
                        delegate: Rectangle {
                            id: motionDot
                            objectName: "pillTranslationDot" + index
                            width: 5
                            height: 5
                            radius: 2.5
                            color: modelData
                            opacity: 0.38

                            SequentialAnimation {
                                objectName: index === 0 ? "pillTranslationMotionAnimation" : ""
                                running: translationMotion.visible
                                loops: Animation.Infinite
                                PauseAnimation { duration: index * 70 }
                                ParallelAnimation {
                                    NumberAnimation { target: motionDot; property: "y"; to: -3; duration: 170; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: motionDot; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: motionDot; property: "y"; to: 0; duration: 210; easing.type: Easing.InOutCubic }
                                    NumberAnimation { target: motionDot; property: "opacity"; to: 0.38; duration: 210; easing.type: Easing.InOutCubic }
                                }
                                PauseAnimation { duration: (2 - index) * 70 + 90 }
                            }
                        }
                    }
                }
            }
        }
        Item {
            id: actionViewport
            objectName: "pillActions"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: pill.activeRightWidth
            Layout.minimumWidth: Layout.preferredWidth
            Layout.maximumWidth: Layout.preferredWidth
            Layout.preferredHeight: 23
            clip: true
            HoverHandler {
                id: rightActionsHover
                onHoveredChanged: {
                    if (!hovered)
                        closeRightActionsTimer.restart()
                }
            }

            Row {
                id: pillActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Item {
                    width: 23; height: 23
                    readonly property real reveal: Math.max(0, Math.min(1, (x + pillActions.x + width) / width))
                    opacity: reveal
                    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    IconButton {
                        width: 23; height: 23
                        visible: parent.reveal > 0.98
                        enabled: parent.opacity > 0.9 && appState.translatedText.length > 0
                        active: appState.justCopied
                        iconSource: "qrc:/qt/qml/Linguist/resources/icons/copy.svg"
                        iconSize: 14
                        tooltip: "复制"
                        onClicked: appState.copyTranslation()
                    }
                }
                Item {
                    width: 23; height: 23
                    readonly property real reveal: Math.max(0, Math.min(1, (x + pillActions.x + width) / width))
                    opacity: reveal
                    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    IconButton {
                        width: 23; height: 23
                        visible: parent.reveal > 0.98
                        enabled: parent.opacity > 0.9
                        iconSource: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"
                        iconSize: 14
                        tooltip: "截图翻译"
                        onClicked: pill.screenshotRequested()
                    }
                }
                Item {
                    width: 23; height: 23
                    readonly property real reveal: Math.max(0, Math.min(1, (x + pillActions.x + width) / width))
                    opacity: reveal
                    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    IconButton {
                        width: 23; height: 23
                        visible: parent.reveal > 0.98
                        enabled: parent.opacity > 0.9
                        iconSource: "qrc:/qt/qml/Linguist/resources/icons/music.svg"
                        iconSize: 14
                        tooltip: "音乐控制"
                        onClicked: appState.togglePillMusicMode()
                    }
                }
                Item {
                    width: 23; height: 23
                    readonly property real reveal: Math.max(0, Math.min(1, (x + pillActions.x + width) / width))
                    opacity: reveal
                    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    IconButton {
                        width: 23; height: 23
                        objectName: "pillSettings"
                        visible: parent.reveal > 0.98
                        enabled: parent.opacity > 0.9
                        iconSource: "qrc:/qt/qml/Linguist/resources/icons/sliders.svg"
                        iconSize: 14
                        tooltip: "偏好设置"
                        onClicked: pill.settingsRequested()
                    }
                }
                Item {
                    width: 23; height: 23
                    readonly property real reveal: Math.max(0, Math.min(1, (x + pillActions.x + width) / width))
                    opacity: reveal
                    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    IconButton {
                        width: 23; height: 23
                        objectName: "pillSpeak"
                        visible: parent.reveal > 0.98
                        enabled: parent.opacity > 0.9
                                 && (appState.sourceText.length > 0 || appState.translatedText.length > 0)
                        iconSource: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                        iconSize: 14
                        tooltip: "朗读"
                        onClicked: appState.speak()
                    }
                }
                Item {
                    width: 23; height: 23
                    IconButton {
                        width: 23; height: 23
                        objectName: "pillExpand"
                        iconSource: "qrc:/qt/qml/Linguist/resources/icons/maximize.svg"
                        iconSize: 14
                        tooltip: "展开卡片"
                        onClicked: pill.expandRequested()
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 30
        visible: !pill.isMusicMode && pill.hasHiddenActions && !pill.searchExpanded
        z: 20
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            closeRightActionsTimer.stop()
            pill.rightActionsExpanded = true
        }
        onExited: closeRightActionsTimer.restart()
        onClicked: pill.expandRequested()
        property bool hovered: containsMouse
        id: rightEdgeHover
    }

    HoverHandler {
        id: pillHover
        onHoveredChanged: {
            if (hovered)
                pill.pointerInsideWindow = true
            else
                pill.handlePointerLeave()
        }
    }
}
