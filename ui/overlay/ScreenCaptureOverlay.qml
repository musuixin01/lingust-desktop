import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Linguist

Window {
    id: overlay
    title: "Linguist 截图框选"

    signal accepted()
    signal cancelled()

    x: captureManager.screenX
    y: captureManager.screenY
    width: captureManager.screenWidth
    height: captureManager.screenHeight
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false

    property point dragStart: Qt.point(0, 0)
    property rect selection: Qt.rect(0, 0, 0, 0)
    property bool dragging: false

    function resetSelection() {
        selection = Qt.rect(0, 0, 0, 0)
        dragging = false
    }

    onVisibleChanged: {
        if (visible) {
            resetSelection()
            requestActivate()
        }
    }

    Image {
        anchors.fill: parent
        source: captureManager.previewUrl
        fillMode: Image.Stretch
        cache: false
    }

    Rectangle {
        x: 0; y: 0; width: parent.width
        height: Math.max(0, overlay.selection.y)
        color: "#73000000"
    }
    Rectangle {
        x: 0; y: overlay.selection.y
        width: Math.max(0, overlay.selection.x)
        height: Math.max(0, overlay.selection.height)
        color: "#73000000"
    }
    Rectangle {
        x: overlay.selection.x + overlay.selection.width
        y: overlay.selection.y
        width: Math.max(0, parent.width - x)
        height: Math.max(0, overlay.selection.height)
        color: "#73000000"
    }
    Rectangle {
        x: 0; y: overlay.selection.y + overlay.selection.height
        width: parent.width
        height: Math.max(0, parent.height - y)
        color: "#73000000"
    }

    Rectangle {
        x: overlay.selection.x
        y: overlay.selection.y
        width: overlay.selection.width
        height: overlay.selection.height
        visible: width > 0 && height > 0
        color: "transparent"
        border.width: 2
        border.color: "#6ea8ff"
        radius: 3
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        width: hintText.implicitWidth + 28
        height: 34
        radius: 10
        color: "#e6192234"
        border.color: "#4dffffff"
        Text {
            id: hintText
            anchors.centerIn: parent
            text: "拖动框选文字区域  ·  Esc 取消"
            color: "white"
            font.family: DesignTokens.fontUi
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: overlay.dragging ? Qt.CrossCursor : Qt.CrossCursor
        onPressed: function(mouse) {
            overlay.dragStart = Qt.point(mouse.x, mouse.y)
            overlay.selection = Qt.rect(mouse.x, mouse.y, 0, 0)
            overlay.dragging = true
        }
        onPositionChanged: function(mouse) {
            if (!overlay.dragging)
                return
            var left = Math.max(0, Math.min(overlay.dragStart.x, mouse.x))
            var top = Math.max(0, Math.min(overlay.dragStart.y, mouse.y))
            var right = Math.min(overlay.width, Math.max(overlay.dragStart.x, mouse.x))
            var bottom = Math.min(overlay.height, Math.max(overlay.dragStart.y, mouse.y))
            overlay.selection = Qt.rect(left, top, right - left, bottom - top)
        }
        onReleased: function(mouse) {
            if (!overlay.dragging)
                return
            overlay.dragging = false
            if (overlay.selection.width < 8 || overlay.selection.height < 8)
                return
            captureManager.confirmSelection(overlay.selection.x, overlay.selection.y,
                                            overlay.selection.width, overlay.selection.height)
            overlay.hide()
            overlay.accepted()
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            captureManager.cancelScreenshot()
            overlay.hide()
            overlay.cancelled()
        }
    }
}
