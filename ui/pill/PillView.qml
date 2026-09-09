import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Item {
    id: pill

    property bool isDragging: false
    readonly property var mediaState: typeof appState !== "undefined" ? appState : null

    signal expandRequested()
    signal musicPanelRequested()
    signal moreRequested()

    readonly property bool isMusicMode: typeof appState !== "undefined" && appState && appState.pillMusicMode

    // === 毛玻璃背景 ===
    GlassSurface {
        anchors.fill: parent
        isPill: true
        isDragging: pill.isDragging
    }

    // === 模式 1：灵动岛音乐模式 ===
    RowLayout {
        id: musicRow
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8
        visible: isMusicMode

        // 旋转唱片微缩图
        Item {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "#0f172a"
                border.width: 1
                border.color: Qt.rgba(0.06, 0.78, 0.55, 0.5)

                Image {
                    id: pillDisc
                    anchors.fill: parent
                    anchors.margins: 2
                    source: "qrc:/qt/qml/Linguist/resources/icons/disc.svg"

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
                    width: 8
                    height: 8
                    radius: 4
                    color: "#10b981"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.musicPanelRequested()
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
                text: appState && appState.trackTitle ? appState.trackTitle : "未播放音频"
                color: "white"
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: appState && appState.currentLyric ? appState.currentLyric : (appState && appState.trackArtist ? appState.trackArtist : "Windows GSMTC 媒体监听")
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
                iconSource: appState && appState.musicPlaying
                            ? "qrc:/qt/qml/Linguist/resources/icons/pause.svg"
                            : "qrc:/qt/qml/Linguist/resources/icons/play.svg"
                iconSize: 14
                iconColor: "#34d399"
                onClicked: if (appState) appState.toggleMusicPlay()
            }

            IconButton {
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
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6
        visible: !pill.isMusicMode

        TrafficLights {
            visible: pill.width >= 480
            Layout.alignment: Qt.AlignVCenter
            onCloseClicked: appState.clearText()
            onCollapseClicked: pill.expandRequested()
            onMinimizeClicked: pill.expandRequested()
        }
        Rectangle {
            id: searchBox
            objectName: "pillSearch"
            Layout.preferredWidth: pill.width >= 440 ? 100 : 28
            Layout.minimumWidth: Layout.preferredWidth
            Layout.maximumWidth: Layout.preferredWidth
            Layout.preferredHeight: 28
            radius: 14
            color: "#1affffff"
            border.color: DesignTokens.borderInput
            Image {
                anchors.left: parent.left
                anchors.leftMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/qt/qml/Linguist/resources/icons/search.svg"
                sourceSize.width: 14; sourceSize.height: 14
            }
            Basic.TextField {
                id: pillInput
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.width >= 440
                text: appState.sourceText
                placeholderText: "搜索..."
                color: DesignTokens.textSecondary
                font.pixelSize: 12
                padding: 0
                background: Item {}
                onTextChanged: appState.setSourceText(text)
                onAccepted: appState.translate()
            }
            MouseArea {
                anchors.fill: parent
                enabled: pill.width < 440
                cursorShape: Qt.PointingHandCursor
                onClicked: pill.expandRequested()
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            clip: true
            HoverScrollText {
                anchors.fill: parent
                text: appState.isTranslating ? "翻译中..." : (appState.translatedText.length > 0 ? appState.completeTranslation() : "输入或划词翻译")
                textColor: "#f2ffffff"
                fontSize: 12
            }
        }
        Row {
            id: pillActions
            objectName: "pillActions"
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: implicitWidth
            Layout.preferredWidth: implicitWidth
            spacing: 2
            IconButton {
                objectName: "pillSpeak"
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                iconSize: 14
                onClicked: appState.speak()
            }
            IconButton {
                visible: pill.width >= 340
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/copy.svg"
                iconSize: 14
                onClicked: appState.copyTranslation()
            }
            IconButton {
                visible: pill.width >= 340
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"
                iconSize: 14
                onClicked: appState.triggerSelectionTranslation()
            }
            IconButton {
                visible: pill.width >= 340
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/music.svg"
                iconSize: 14
                onClicked: appState.togglePillMusicMode()
            }
            Basic.ToolButton {
                id: moreButton
                objectName: "pillMore"
                width: 28; height: 28
                visible: pill.width < 340
                text: "⋯"
                contentItem: Text { text: "⋯"; color: "white"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 14; color: moreButton.down ? "#33ffffff" : (moreButton.hovered ? "#1affffff" : "transparent") }
                Accessible.name: "更多操作"
                onClicked: pill.moreRequested()
            }
            IconButton {
                objectName: "pillExpand"
                iconSource: "qrc:/qt/qml/Linguist/resources/icons/maximize.svg"
                iconSize: 14
                onClicked: pill.expandRequested()
            }
        }
    }
}
