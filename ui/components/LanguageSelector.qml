import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Window

Rectangle {
    id: selector
    width: selector.textOnly ? 36 : (selector.iconOnly ? 24 : (selector.minimal ? 56 : (selector.compact ? 70 : 82)))
    property int controlHeight: 24
    property int labelFontSize: 10
    height: controlHeight
    radius: height / 2
    color: "transparent"
    // textOnly模式下无边框
    border.color: selector.textOnly ? "transparent" : DesignTokens.borderInput
    border.width: selector.textOnly ? 0 : 1

    property string sourceLang: "EN"
    property string targetLang: "ZH"
    property bool compact: false
    property bool minimal: false
    property bool iconOnly: false
    property bool textOnly: false
    readonly property bool hovered: selectorHover.hovered || languagePopup.opened
    property string pickerMode: "source"
    readonly property var languages: [
        { code: "auto", name: "自动检测", shortName: "AUTO" },
        { code: "zh", name: "简体中文", shortName: "ZH" },
        { code: "en", name: "英语", shortName: "EN" },
        { code: "ja", name: "日语", shortName: "JA" },
        { code: "ko", name: "韩语", shortName: "KO" },
        { code: "fr", name: "法语", shortName: "FR" },
        { code: "de", name: "德语", shortName: "DE" },
        { code: "es", name: "西班牙语", shortName: "ES" },
        { code: "pt", name: "葡萄牙语", shortName: "PT" },
        { code: "it", name: "意大利语", shortName: "IT" },
        { code: "ru", name: "俄语", shortName: "RU" },
        { code: "ar", name: "阿拉伯语", shortName: "AR" },
        { code: "vi", name: "越南语", shortName: "VI" },
        { code: "th", name: "泰语", shortName: "TH" }
    ]
    readonly property var pickerLanguages: pickerMode === "source"
                                                 ? languages : languages.slice(1)

    signal sourceClicked()
    signal targetClicked()
    signal swapClicked()
    signal sourceSelected(string code)
    signal targetSelected(string code)

    function shortLabel(code) {
        var normalized = String(code).toLowerCase()
        for (var i = 0; i < languages.length; ++i) {
            if (languages[i].code === normalized)
                return languages[i].shortName
        }
        return normalized.toUpperCase()
    }
    function openPicker(mode) {
        pickerMode = mode
        languagePopup.open()
    }
    function chooseLanguage(code) {
        if (pickerMode === "source")
            sourceSelected(code)
        else
            targetSelected(code)
        languagePopup.close()
    }

    // 完整模式：EN ⇄ ZH
    Item {
        anchors.fill: parent
        visible: !selector.iconOnly && !selector.textOnly

        // 源语言
        Text {
            id: sourceText
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: selector.shortLabel(selector.sourceLang)
            color: srcMouse.containsMouse ? "#ffffff" : DesignTokens.textSecondary
            font.pixelSize: selector.minimal ? Math.max(8, selector.labelFontSize - 1)
                                             : selector.labelFontSize
            font.weight: Font.Medium
            font.family: DesignTokens.fontUi

            Behavior on color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

            MouseArea {
                id: srcMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    selector.sourceClicked()
                    selector.openPicker("source")
                }
            }
        }

        // 交换按钮
        Rectangle {
            id: swapBtn
            anchors.centerIn: parent
            width: selector.controlHeight <= 22 ? 16 : 18
            height: width
            radius: width / 2
            color: swapMouse.containsMouse ? "#26ffffff" : "transparent"
            scale: swapMouse.pressed ? 0.88 : (swapMouse.containsMouse ? 1.10 : 1.0)

            Behavior on color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }
            Behavior on scale { enabled: !swapMouse.pressed; NumberAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

            Image {
                id: swapIcon
                anchors.centerIn: parent
                source: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"
                sourceSize.width: selector.controlHeight <= 22 ? 10 : 11
                sourceSize.height: selector.controlHeight <= 22 ? 10 : 11
                property real rot: 0
                rotation: rot
                Behavior on rot { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: swapMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    swapIcon.rot += 180;
                    selector.swapClicked();
                }
            }
        }

        // 目标语言
        Text {
            id: targetText
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: selector.shortLabel(selector.targetLang)
            color: tgtMouse.containsMouse ? "#ffffff" : DesignTokens.textSecondary
            font.pixelSize: selector.minimal ? Math.max(8, selector.labelFontSize - 1)
                                             : selector.labelFontSize
            font.weight: Font.Medium
            font.family: DesignTokens.fontUi

            Behavior on color { ColorAnimation { duration: DesignTokens.toolbarFeedbackMs; easing.type: Easing.OutCubic } }

            MouseArea {
                id: tgtMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    selector.targetClicked()
                    selector.openPicker("target")
                }
            }
        }
    }

    // iconOnly模式：只显示交换图标
    Item {
        anchors.fill: parent
        visible: selector.iconOnly && !selector.textOnly

        Rectangle {
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: 9
            color: "transparent"

            Image {
                anchors.centerIn: parent
                source: "qrc:/qt/qml/Linguist/resources/icons/swap.svg"
                sourceSize.width: 11
                sourceSize.height: 11
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: selector.swapClicked()
                onEntered: parent.color = "#1affffff"
                onExited: parent.color = "transparent"
            }
        }
    }

    // textOnly模式：EN➔ZH 蓝色无边框
    Text {
        anchors.centerIn: parent
        visible: selector.textOnly
        text: selector.shortLabel(selector.sourceLang) + "➔" + selector.shortLabel(selector.targetLang)
        color: "#60a5fa"
        font.pixelSize: selector.labelFontSize
        font.weight: Font.Medium
        font.family: DesignTokens.fontUi

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            onClicked: selector.swapClicked()
        }
    }

    // 悬停观察不抢占子按钮点击；宽度直接跟随布局。
    HoverHandler { id: selectorHover }

    Basic.Popup {
        id: languagePopup
        objectName: "languagePicker"
        readonly property point selectorPosition: selector.mapToItem(null, 0, 0)
        readonly property real hostWidth: selector.Window.window
                                          ? selector.Window.window.width : 220
        readonly property real hostHeight: selector.Window.window
                                           ? selector.Window.window.height : 200
        x: Math.round(Math.max(8 - selectorPosition.x,
                              Math.min((selector.width - width) / 2,
                                       hostWidth - selectorPosition.x - width - 8)))
        y: Math.round(Math.max(8 - selectorPosition.y,
                              Math.min(selector.height + 4,
                                       hostHeight - selectorPosition.y - height - 8)))
        width: 148
        height: Math.min(148, selector.pickerLanguages.length * 28 + 8)
        padding: 4
        modal: false
        focus: true
        closePolicy: Basic.Popup.CloseOnEscape | Basic.Popup.CloseOnPressOutside
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: 170; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: 0.98; duration: 110; easing.type: Easing.InCubic }
            }
        }
        background: Rectangle {
            radius: 12
            color: "#f3182233"
            border { width: 1; color: "#45ffffff" }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 11
                color: "#0cffffff"
            }
        }
        contentItem: ListView {
            id: languageList
            clip: true
            model: selector.pickerLanguages
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: -1
            interactive: true
            flickDeceleration: 2600
            WheelHandler {
                orientation: Qt.Vertical
                target: null
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    var maximumY = Math.max(0, languageList.contentHeight - languageList.height)
                    var delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y
                                                         : event.angleDelta.y / 120 * 42
                    languageList.contentY = Math.max(0, Math.min(maximumY,
                                                   languageList.contentY - delta))
                    event.accepted = true
                }
            }
            delegate: Rectangle {
                required property var modelData
                width: languageList.width
                height: 28
                radius: 8
                readonly property bool selected: modelData.code ===
                    (selector.pickerMode === "source" ? selector.sourceLang.toLowerCase()
                                                       : selector.targetLang.toLowerCase())
                color: languageMouse.containsMouse ? "#20ffffff"
                                                    : (selected ? "#243b82f6" : "transparent")
                Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }
                Text {
                    anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
                    text: modelData.name
                    color: parent.selected ? "#b9dcff" : DesignTokens.textPrimary
                    font { family: DesignTokens.fontUi; pixelSize: 10; weight: parent.selected ? Font.DemiBold : Font.Normal }
                }
                Text {
                    anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
                    text: modelData.code === "auto" ? "AUTO" : modelData.code.toUpperCase()
                    color: DesignTokens.textTertiary
                    font { family: DesignTokens.fontMono; pixelSize: 8 }
                }
                MouseArea {
                    id: languageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: selector.chooseLanguage(modelData.code)
                }
            }
            Basic.ScrollBar.vertical: Basic.ScrollBar { policy: Basic.ScrollBar.AsNeeded; width: 4 }
        }
    }
}
