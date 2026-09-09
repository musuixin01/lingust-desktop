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

    Behavior on color { enabled: !mouseArea.pressed; ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

    Image {
        anchors.centerIn: parent
        scale: mouseArea.pressed ? 0.90 : 1.0
        source: btn.iconSource
        sourceSize.width: btn.iconSize
        sourceSize.height: btn.iconSize
        opacity: active ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.75)

        Behavior on opacity { NumberAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }

}
