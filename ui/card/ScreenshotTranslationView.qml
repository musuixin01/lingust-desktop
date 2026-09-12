import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Linguist

Item {
    id: view
    signal retakeRequested()
    signal backToTextRequested()
    signal previewRequested(string source)

    property bool showImagePreview: true
    property var lines: appState.ocrLines || []
    property bool processing: appState.isOcrProcessing
    property string statusText: appState.ocrStatus
    readonly property bool hasImagePreview: appState.ocrImagePreview.length > 0
    readonly property real naturalContentHeight: 46
                                                 + (view.showImagePreview && view.hasImagePreview
                                                    ? Math.min(82, view.height * 0.24) + 6 : 0)
                                                 + (view.lines.length > 0 ? pairs.implicitHeight + 8 : 54)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 10
            color: "#12ffffff"
            border { width: 1; color: DesignTokens.borderSubtle }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 6

                Rectangle {
                    width: 22; height: 22; radius: 7
                    color: "#263b82f6"
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"
                        sourceSize.width: 12; sourceSize.height: 12
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "截图翻译"
                        color: DesignTokens.textPrimary
                        font { family: DesignTokens.fontUi; pixelSize: 11; weight: Font.DemiBold }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: view.processing ? view.statusText
                                              : "英文一行 · 中文一行 · " + view.lines.length + " 组"
                        color: DesignTokens.textTertiary
                        font { family: DesignTokens.fontUi; pixelSize: 9 }
                        elide: Text.ElideRight
                    }
                }
                IconButton {
                    objectName: "screenshotPreviewToggle"
                    width: 26; height: 26; iconSize: 12
                    iconSource: view.showImagePreview
                                ? "qrc:/qt/qml/Linguist/resources/icons/eye-off.svg"
                                : "qrc:/qt/qml/Linguist/resources/icons/eye.svg"
                    tooltip: view.showImagePreview ? "隐藏原截图" : "查看原截图"
                    enabled: appState.ocrImagePreview.length > 0
                    onClicked: view.showImagePreview = !view.showImagePreview
                }
                IconButton {
                    width: 26; height: 26; iconSize: 12
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/rotate-ccw.svg"
                    tooltip: "重新框选"
                    onClicked: view.retakeRequested()
                }
                IconButton {
                    width: 26; height: 26; iconSize: 11
                    iconSource: "qrc:/qt/qml/Linguist/resources/icons/close.svg"
                    tooltip: "返回文本翻译"
                    onClicked: view.backToTextRequested()
                }
            }
        }

        Rectangle {
            id: previewCard
            objectName: "screenshotThumbnail"
            Layout.fillWidth: true
            Layout.preferredHeight: view.showImagePreview && view.hasImagePreview
                                    ? Math.min(82, view.height * 0.24) : 0
            visible: view.showImagePreview && view.hasImagePreview
            radius: 9
            color: "#18000000"
            border { width: 1; color: DesignTokens.borderSubtle }
            clip: true
            scale: previewMouse.pressed ? 0.985 : 1
            opacity: previewMouse.pressed ? 0.86 : 1
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: DesignTokens.durationNormal; easing.type: Easing.OutCubic }
            }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Image {
                id: thumbnailImage
                anchors.fill: parent
                anchors.margins: 5
                source: appState.ocrImagePreview
                fillMode: Image.PreserveAspectFit
                cache: false
            }
            Rectangle {
                anchors { right: parent.right; bottom: parent.bottom; margins: 7 }
                width: 22; height: 22; radius: 7
                color: "#a0141d2e"
                border { width: 1; color: "#38ffffff" }
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/Linguist/resources/icons/maximize.svg"
                    sourceSize.width: 11; sourceSize.height: 11
                }
            }
            MouseArea {
                id: previewMouse
                objectName: "screenshotThumbnailOpen"
                anchors.fill: parent
                enabled: appState.ocrImagePreview.length > 0
                cursorShape: Qt.PointingHandCursor
                onClicked: view.previewRequested(appState.ocrImagePreview)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: view.lines.length === 0
                Basic.BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 32; height: 32
                    running: view.processing
                    visible: view.processing
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(280, view.width - 32)
                    text: view.statusText
                    color: view.processing ? DesignTokens.textSecondary : DesignTokens.accentRed
                    font { family: DesignTokens.fontUi; pixelSize: 12 }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !view.processing
                    text: "可以点击上方重新框选"
                    color: DesignTokens.textTertiary
                    font { family: DesignTokens.fontUi; pixelSize: 10 }
                }
            }

            Flickable {
                id: resultScroll
                anchors.fill: parent
                visible: view.lines.length > 0
                clip: true
                contentWidth: width
                contentHeight: pairs.implicitHeight + 8
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                maximumFlickVelocity: 1800
                WheelHandler {
                    orientation: Qt.Vertical
                    target: null
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        var maximumY = Math.max(0, resultScroll.contentHeight - resultScroll.height)
                        var delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y
                                                             : event.angleDelta.y / 120 * 52
                        resultScroll.contentY = Math.max(0, Math.min(maximumY,
                                                     resultScroll.contentY - delta))
                        event.accepted = true
                    }
                }
                ColumnLayout {
                    id: pairs
                    width: resultScroll.width
                    spacing: 2
                    Repeater {
                        model: view.lines
                        delegate: Item {
                            objectName: "screenshotPair" + index
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            implicitHeight: pairText.implicitHeight + 10
                            ColumnLayout {
                                id: pairText
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    topMargin: 4
                                    leftMargin: 4
                                    rightMargin: 10
                                }
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: pairText.width
                                    Layout.maximumWidth: pairText.width
                                    text: modelData.src
                                    color: DesignTokens.textPrimary
                                    font {
                                        family: DesignTokens.fontUi
                                        pixelSize: Math.round(13 * DesignTokens.fontScale)
                                        weight: Font.DemiBold
                                    }
                                    lineHeight: 1.18
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: pairText.width
                                    Layout.maximumWidth: pairText.width
                                    text: modelData.dst
                                    color: "#c7d1df"
                                    font {
                                        family: DesignTokens.fontUi
                                        pixelSize: Math.round(13 * DesignTokens.fontScale)
                                        weight: Font.Normal
                                    }
                                    lineHeight: 1.22
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }
                            }
                        }
                    }
                }
                Basic.ScrollBar.vertical: Basic.ScrollBar {
                    policy: resultScroll.contentHeight > resultScroll.height
                            ? Basic.ScrollBar.AsNeeded : Basic.ScrollBar.AlwaysOff
                    width: 5
                }
            }
        }
    }
}
