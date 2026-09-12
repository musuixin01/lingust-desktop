import QtQuick

Rectangle {
    id: btn

    property string iconSource: ""
    property color iconColor: "#99ffffff"
    property color hoverColor: "#ffffff"
    property color hoverBg: "#1affffff"
    property bool active: false
    property color activeColor: "#60a5fa"
    property int iconSize: 14
    property string tooltip: ""
    property bool feedbackActive: false
    activeFocusOnTab: enabled && visible
    Accessible.role: Accessible.Button
    Accessible.name: tooltip.length > 0 ? tooltip : iconSource.split("/").pop().replace(".svg", "")
    Accessible.onPressAction: if (enabled) clicked()
    Keys.onSpacePressed: function(event) { if (enabled) clicked(); event.accepted = true }
    Keys.onReturnPressed: function(event) { if (enabled) clicked(); event.accepted = true }
    opacity: enabled ? 1 : 0.4

    width: 28
    height: 28
    radius: width / 2
    color: mouseArea.pressed ? "#33ffffff" : (active ? "#263b82f6" : (mouseArea.containsMouse ? hoverBg : "transparent"))
    border.color: activeFocus ? "#93c5fd" : (active ? "#4d60a5fa" : "transparent")
    border.width: active || activeFocus ? 1 : 0

    signal clicked()

    onClicked: {
        feedbackActive = true
        feedbackTimer.restart()
        executionBounce.restart()
    }

    Timer {
        id: feedbackTimer
        interval: 280
        onTriggered: btn.feedbackActive = false
    }

    Behavior on color { enabled: !mouseArea.pressed; ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

    Image {
        id: iconImage
        anchors.centerIn: parent
        scale: 1.0
        source: btn.iconSource
        sourceSize.width: btn.iconSize
        sourceSize.height: btn.iconSize
        opacity: active ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.75)

        Behavior on opacity { NumberAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
    }

    SequentialAnimation {
        id: executionBounce
        NumberAnimation { target: iconImage; property: "scale"; to: 1.1; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: iconImage; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.OutBack }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: DesignTokens.accentBlue
        opacity: btn.feedbackActive ? 0.9 : 0
        scale: btn.feedbackActive ? 1 : 0.82
        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            executionBounce.stop()
            iconImage.scale = 0.94
        }
        onCanceled: iconImage.scale = 1.0
        onClicked: btn.clicked()
    }

}
