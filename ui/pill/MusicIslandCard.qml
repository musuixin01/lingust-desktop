import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Linguist

Item {
    id: root

    property var appState: null
    signal closeRequested()
    signal switchTranslationRequested()

    implicitWidth: 340
    implicitHeight: 280

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: DesignTokens.radiusWindow
        color: DesignTokens.windowSurface
        border.width: 1
        border.color: DesignTokens.borderNormal

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 48
            radius: surface.radius
            color: DesignTokens.windowHeader
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Top Header: Tag + Close / Back to Translation
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: Qt.rgba(0.06, 0.78, 0.55, 0.15)
                    border.color: Qt.rgba(0.06, 0.78, 0.55, 0.4)

                    Image {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: "qrc:/qt/qml/Linguist/resources/icons/music.svg"
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    Text {
                        text: "Linguist 灵动岛音乐"
                        color: "white"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: appState && appState.systemMediaConnected
                              ? (appState.musicPlaying ? "正在播放 · Windows 系统媒体" : "已暂停 · Windows 系统媒体")
                              : "未检测到系统媒体"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 10
                    }
                }

                // Switch to Translation Pill
                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"
                    width: 26; height: 26
                    iconSize: 13
                    hoverColor: Qt.rgba(1, 1, 1, 0.15)
                    onClicked: root.switchTranslationRequested()
                }

                // Close Expanded Popover
                IconButton {
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/close.svg"
                    width: 26; height: 26
                    iconSize: 13
                    hoverColor: Qt.rgba(1, 1, 1, 0.15)
                    onClicked: root.closeRequested()
                }
            }

            // Track Info Row: Vinyl Disk + Title & Artist
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Rotating Vinyl Disk
                Rectangle {
                    width: 54
                    height: 54
                    radius: 27
                    color: "#0f172a"
                    clip: true

                    Image {
                        id: vinylDisc
                        objectName: "musicCardAlbumDisc"
                        anchors.fill: parent
                        source: appState && appState.coverArtUrl ? appState.coverArtUrl
                                                                : "qrc:/qt/qml/Linguist/resources/icons/disc.svg"
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 128
                        sourceSize.height: 128

                        RotationAnimator {
                            objectName: "musicCardDiscRotation"
                            target: vinylDisc
                            from: 0
                            to: 360
                            duration: 8000
                            loops: Animation.Infinite
                            running: appState ? appState.musicPlaying : false
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: "#0a0f1e"
                        border.color: "white"
                        border.width: 1
                    }
                }

                Canvas {
                    objectName: "musicCardProgressRing"
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 58
                    Layout.leftMargin: -70
                    Layout.rightMargin: 12
                    readonly property real progress: appState && appState.trackDuration > 0
                                                     ? Math.max(0, Math.min(1, appState.trackPosition / appState.trackDuration))
                                                     : 0
                    onProgressChanged: requestPaint()
                    onPaint: {
                        var context = getContext("2d")
                        context.clearRect(0, 0, width, height)
                        context.lineWidth = 2
                        context.strokeStyle = Qt.rgba(1, 1, 1, 0.14)
                        context.beginPath()
                        context.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 2)
                        context.stroke()
                        if (progress > 0) {
                            context.strokeStyle = "#34d399"
                            context.lineCap = "round"
                            context.beginPath()
                            context.arc(width / 2, height / 2, width / 2 - 2,
                                        -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progress)
                            context.stroke()
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: appState && appState.trackTitle ? appState.trackTitle : "未播放音乐"
                        color: "white"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: appState && appState.trackArtist ? appState.trackArtist : "请先在音乐应用或浏览器中播放音频"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: appState && appState.trackAlbum ? appState.trackAlbum : ""
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }
            }

            // 多行歌词：同步歌词跟随当前时间，滚轮/触控板可自由浏览。
            Rectangle {
                id: lyricPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 76
                radius: 12
                color: Qt.rgba(0, 0, 0, 0.3)
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ListView {
                    id: lyricsList
                    objectName: "musicLyricsList"
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    spacing: 3
                    model: appState ? appState.musicLyrics : []
                    currentIndex: appState ? appState.currentLyricIndex : -1
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 220
                    highlightMoveVelocity: -1
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && !moving && !dragging)
                            positionViewAtIndex(currentIndex, ListView.Center)
                    }

                    delegate: Text {
                        required property var modelData
                        required property int index
                        width: lyricsList.width - 8
                        text: modelData.text
                        color: index === lyricsList.currentIndex ? "#a7f3d0" : Qt.rgba(1, 1, 1, 0.52)
                        font.pixelSize: index === lyricsList.currentIndex ? 12 : 11
                        font.weight: index === lyricsList.currentIndex ? Font.DemiBold : Font.Normal
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        lineHeight: 1.35
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: lyricsList.contentHeight > lyricsList.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 28
                    visible: !appState || appState.musicLyrics.length === 0
                    text: appState && appState.systemMediaConnected ? "正在查找歌词…" : "等待系统媒体会话"
                    color: Qt.rgba(1, 1, 1, 0.48)
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            // Progress Slider & Duration
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: appState && appState.trackDuration > 0 ? appState.trackDuration : 1
                    value: appState ? appState.trackPosition : 0
                    enabled: appState && appState.trackDuration > 0
                    onMoved: {
                        if (appState) {
                            appState.seekTrack(Math.floor(value));
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: {
                            var p = appState ? appState.trackPosition : 0;
                            var m = Math.floor(p / 60);
                            var s = p % 60;
                            return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
                        }
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: {
                            var d = appState ? appState.trackDuration : 0;
                            if (d <= 0) return "--:--";
                            var m = Math.floor(d / 60);
                            var s = d % 60;
                            return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
                        }
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 10
                    }
                }
            }

            // Playback Controls Row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                IconButton {
                    enabled: appState && appState.systemMediaConnected
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/skip-back.svg"
                    width: 32; height: 32
                    iconSize: 16
                    hoverColor: Qt.rgba(1, 1, 1, 0.15)
                    onClicked: if (appState) appState.prevTrack()
                }

                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: "#10b981"
                    opacity: appState && appState.systemMediaConnected ? 1 : 0.38

                    Image {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: appState && appState.musicPlaying
                                ? "qrc:/qt/qml/Linguist/resources/icons/pause.svg"
                                : "qrc:/qt/qml/Linguist/resources/icons/play.svg"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: appState && appState.systemMediaConnected
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (appState) appState.toggleMusicPlay()
                    }
                }

                IconButton {
                    enabled: appState && appState.systemMediaConnected
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/skip-forward.svg"
                    width: 32; height: 32
                    iconSize: 16
                    hoverColor: Qt.rgba(1, 1, 1, 0.15)
                    onClicked: if (appState) appState.nextTrack()
                }
            }
        }
    }
}
