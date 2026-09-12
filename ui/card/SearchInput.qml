import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: searchBox

    property string text: ""
    property string placeholder: "输入文字"
    property bool multiLine: false
    property bool compact: false
    property bool muted: false
    property bool focused: false
    signal userTextChanged(string newText)
    signal cleared()
    signal submitted()
    signal screenshotClicked()
    function focusEditor() { input.forceActiveFocus(Qt.MouseFocusReason) }
    function blurEditor() {
        input.focus = false
        searchBox.focused = false
    }

    radius: 13
    color: searchBox.focused ? DesignTokens.bgInputFocus
                             : (searchBox.muted ? "#38141b29" : "#18ffffff")
    border.color: searchBox.focused ? DesignTokens.borderInputFocus
                                    : (searchBox.muted ? "#20ffffff" : DesignTokens.borderInput)
    border.width: 1

    implicitHeight: 26

    Rectangle {
        objectName: "cardSearchGlass"
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        opacity: searchBox.focused ? 0.42 : (searchBox.muted ? 0.18 : 0.30)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#30ffffff" }
            GradientStop { position: 0.48; color: "#10b9d9ff" }
            GradientStop { position: 1.0; color: "#08040a18" }
        }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 7
        anchors.rightMargin: 5
        spacing: 6
        opacity: searchBox.muted ? 0.38 : 1
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Image {
            Layout.alignment: Qt.AlignVCenter
            source: "qrc:/qt/qml/Linguist/resources/icons/search.svg"
            sourceSize.width: searchBox.compact ? 13 : 14
            sourceSize.height: searchBox.compact ? 13 : 14
            opacity: searchBox.focused ? 1 : 0.82
        }

        TextField {
            id: input
            objectName: "searchTextField"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            text: searchBox.text
            placeholderText: searchBox.placeholder
            color: DesignTokens.textSecondary
            selectionColor: "#400070eb"
            selectedTextColor: DesignTokens.textPrimary
            activeFocusOnPress: true
            selectByMouse: true
            persistentSelection: true
            font.pixelSize: Math.round((searchBox.compact ? 11 : 12) * DesignTokens.fontScale)
            padding: 0
            font.family: DesignTokens.fontUi
            background: Rectangle { color: "transparent" }
            cursorDelegate: Rectangle {
                id: cardCaret
                width: 1.5
                radius: 0.75
                color: DesignTokens.accentBlue
                SequentialAnimation {
                    objectName: "cardCaretBlink"
                    running: input.activeFocus
                    loops: Animation.Infinite
                    PauseAnimation { duration: 480 }
                    NumberAnimation { target: cardCaret; property: "opacity"; to: 0; duration: 70; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: 430 }
                    NumberAnimation { target: cardCaret; property: "opacity"; to: 1; duration: 70; easing.type: Easing.InOutSine }
                }
            }
            verticalAlignment: TextInput.AlignVCenter

            onTextEdited: searchBox.userTextChanged(text)
            onAccepted: searchBox.submitted()
            onActiveFocusChanged: searchBox.focused = activeFocus
        }

        // 清空按钮
        Rectangle {
            objectName: "searchClear"
            Layout.alignment: Qt.AlignVCenter
            width: 18; height: 18; radius: 9
            color: "transparent"
            visible: searchBox.text.length > 0

            Image {
                anchors.centerIn: parent
                source: "qrc:/qt/qml/Linguist/resources/icons/close.svg"
                sourceSize.width: 10; sourceSize.height: 10
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    searchBox.cleared()
                    searchBox.forceActiveFocus(Qt.MouseFocusReason)
                }
                onEntered: parent.color = "#1affffff"
                onExited: parent.color = "transparent"
            }
        }

        // 截图按钮
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 20; height: 20; radius: 10
            color: "transparent"

            Image {
                anchors.centerIn: parent
                source: "qrc:/qt/qml/Linguist/resources/icons/crop.svg"
                sourceSize.width: 13; sourceSize.height: 13
                opacity: 0.8
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    searchBox.screenshotClicked()
                }
                onEntered: parent.color = "#1affffff"
                onExited: parent.color = "transparent"
            }
        }
    }

    Behavior on color { ColorAnimation { duration: DesignTokens.durationFast; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: DesignTokens.durationFast; easing.type: Easing.OutCubic } }
}
