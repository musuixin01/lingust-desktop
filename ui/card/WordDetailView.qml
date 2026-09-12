import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: wordDetail

    property string word: "Efficient"
    property string phonetic: ""
    property string translatedText: "高效的；有能力的"
    property string englishDefinition: ""
    property var definitions: []
    property var examples: []
    property var synonyms: []
    property var antonyms: []
    property var wordForms: []
    property real fontScale: DesignTokens.fontScale
    property bool compact: false
    property bool veryCompact: false
    property bool ultraCompact: false
    readonly property real headerNaturalWidth: wordTitle.implicitWidth + wordPhonetic.implicitWidth + speechButtons.implicitWidth + 16
    readonly property bool singleLineHeader: width >= headerNaturalWidth
    readonly property int lexicalSectionCount: (wordForms.length > 0 ? 1 : 0)
                                               + (synonyms.length > 0 ? 1 : 0)
                                               + (antonyms.length > 0 ? 1 : 0)
    readonly property real lexicalColumnMinWidth: compact ? 128 : 144

    spacing: wordDetail.ultraCompact ? 6 : (wordDetail.veryCompact ? 8 : (wordDetail.compact ? 10 : 12))

    // 空间充足时单词、音标和发音共用一行；只有实际放不下时才分行。
    GridLayout {
        id: wordHeader
        objectName: "wordHeader"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        columns: wordDetail.singleLineHeader ? 3 : 1
        columnSpacing: 8
        rowSpacing: 6

        Text {
            id: wordTitle
            objectName: "wordTitle"
            Layout.fillWidth: !wordDetail.singleLineHeader
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            text: wordDetail.word
            color: DesignTokens.textPrimary
            font.bold: true
            font.pixelSize: Math.round((wordDetail.ultraCompact ? 15 : (wordDetail.compact ? 17 : 20)) * wordDetail.fontScale)
            font.family: DesignTokens.fontUi
            wrapMode: wordDetail.singleLineHeader ? Text.NoWrap : Text.WrapAnywhere
            visible: text.length > 0
        }
        Text {
            id: wordPhonetic
            objectName: "wordPhonetic"
            Layout.fillWidth: !wordDetail.singleLineHeader
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            text: wordDetail.phonetic.length > 0 ? (wordDetail.phonetic.startsWith("/") ? wordDetail.phonetic : "/" + wordDetail.phonetic + "/") : ""
            color: "#93c5fd"
            font.pixelSize: Math.round((wordDetail.ultraCompact ? 10 : (wordDetail.compact ? 11 : 12)) * wordDetail.fontScale)
            font.family: DesignTokens.fontMono
            wrapMode: wordDetail.singleLineHeader ? Text.NoWrap : Text.WrapAnywhere
            visible: text.length > 0
        }
        Row {
            id: speechButtons
            objectName: "wordSpeechButtons"
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            spacing: 4
            Repeater {
                model: [
                    { label: "美", accent: "#60a5fa", langAccent: "us" },
                    { label: "英", accent: "#34d399", langAccent: "uk" }
                ]
                delegate: Rectangle {
                    width: 38; height: 24; radius: 6
                    color: speechMouse.pressed ? "#33ffffff" : (speechMouse.containsMouse ? "#26ffffff" : "#14ffffff")
                    border.color: DesignTokens.borderSubtle
                    border.width: 1
                    Row {
                        anchors.centerIn: parent
                        spacing: 3
                        Image {
                            source: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                            sourceSize.width: 10; sourceSize.height: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            color: modelData.accent
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: speechMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appState.speak(wordDetail.word, "en", modelData.langAccent)
                    }
                }
            }
        }
    }

    // 英文释义
    Text {
        Layout.fillWidth: true
        text: wordDetail.englishDefinition
        color: "#80ffffff"
        font.pixelSize: wordDetail.compact ? 11 : 12
        font.family: DesignTokens.fontReading
        font.italic: true
        wrapMode: Text.Wrap
        visible: wordDetail.englishDefinition.length > 0
    }

    // 分隔线
    Rectangle { Layout.fillWidth: true; height: 1; color: DesignTokens.borderSubtle }

    // === 主释义卡片 ===
    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: "#0dffffff"
        border.color: DesignTokens.borderSubtle
        border.width: 1
        implicitHeight: defColumn.implicitHeight + (wordDetail.compact ? 14 : 18)

        ColumnLayout {
            id: defColumn
            anchors.fill: parent
            anchors.margins: wordDetail.compact ? 8 : 10
            spacing: 6

            // 第一释义（只显示一个）
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    radius: 6
                    color: "#263b82f6"
                    border.color: "#403b82f6"
                    border.width: 1
                    implicitWidth: posText.implicitWidth + 14
                    height: 20

                    Text {
                        id: posText
                        anchors.centerIn: parent
                        text: wordDetail.definitions.length > 0 && wordDetail.definitions[0].partOfSpeech.length > 0
                              ? wordDetail.definitions[0].partOfSpeech : "adj."
                        color: "#93c5fd"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: wordDetail.definitions.length > 0 ? wordDetail.definitions[0].meaning : wordDetail.translatedText
                    color: "#f2ffffff"
                    font.pixelSize: Math.round((wordDetail.ultraCompact ? 12 : (wordDetail.compact ? 14 : 15)) * wordDetail.fontScale)
                    font.weight: Font.DemiBold
                    font.family: DesignTokens.fontUi
                    wrapMode: Text.Wrap
                }
            }

            // 补充释义（对齐 Web 端 definitions.slice(1)）
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: wordDetail.definitions && wordDetail.definitions.length > 1

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#14ffffff"
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                }

                Repeater {
                    model: wordDetail.definitions && wordDetail.definitions.length > 1 ? wordDetail.definitions.slice(1) : []
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: modelData.partOfSpeech ? modelData.partOfSpeech : ""
                            color: "#60a5fa"
                            font.pixelSize: 10
                            font.family: DesignTokens.fontMono
                            font.bold: true
                            visible: text.length > 0
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.meaning ? modelData.meaning : ""
                            color: "#ccffffff"
                            font.pixelSize: Math.round((wordDetail.ultraCompact ? 11 : 12) * wordDetail.fontScale)
                            font.family: DesignTokens.fontUi
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    // === 双语例句 ===
    ColumnLayout {
        objectName: "bilingualExamples"
        Layout.fillWidth: true
        spacing: 4
        visible: wordDetail.examples.length > 0

        Text {
            text: "双语例句"
            color: DesignTokens.textPlaceholder
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            font.capitalization: Font.AllUppercase
        }

        Repeater {
            model: wordDetail.examples.slice(0, 2)
            delegate: Rectangle {
                id: egCard
                Layout.fillWidth: true
                radius: 8
                color: egMouse.containsMouse ? "#14ffffff" : "#08ffffff"
                border.color: egMouse.containsMouse ? "#33ffffff" : DesignTokens.borderSubtle
                border.width: 1
                implicitHeight: exampleRow.implicitHeight + 14

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: exampleRow
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    ColumnLayout {
                        id: exampleColumn
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: modelData.src
                            color: "#e6ffffff"
                            font.pixelSize: 11
                            font.family: DesignTokens.fontReading
                            wrapMode: Text.Wrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.dst
                            color: "#80ffffff"
                            font.pixelSize: 10
                            font.family: DesignTokens.fontUi
                            wrapMode: Text.Wrap
                        }
                    }

                    Image {
                        source: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                        sourceSize.width: 12; sourceSize.height: 12
                        opacity: egMouse.containsMouse ? 0.9 : 0.3
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: egMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof appState !== "undefined" && appState && modelData.src) {
                            appState.speak(modelData.src, "en");
                        }
                    }
                }
            }
        }
    }

    // 宽卡片横向利用空间，窄卡片仍按词形、同义词、反义词顺序排列。
    GridLayout {
        id: lexicalGrid
        objectName: "lexicalGrid"
        Layout.fillWidth: true
        columns: Math.max(1, Math.min(wordDetail.lexicalSectionCount,
                    Math.floor((width + columnSpacing) / (wordDetail.lexicalColumnMinWidth + columnSpacing))))
        uniformCellWidths: columns > 1
        columnSpacing: 12
        rowSpacing: 10
        visible: wordDetail.lexicalSectionCount > 0

    // === 词形变化：紧跟例句，先看用法再看派生形式 ===
    ColumnLayout {
        id: wordFormsSection
        objectName: "wordFormsSection"
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 4
        visible: wordDetail.wordForms.length > 0

        Text {
            text: "词形变化"
            color: DesignTokens.textPlaceholder
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: wordDetail.wordForms
                delegate: Rectangle {
                    radius: 7
                    color: "#0dffffff"
                    border.color: DesignTokens.borderSubtle
                    border.width: 1
                    implicitWidth: formRow.implicitWidth + 14
                    height: 24

                    Row {
                        id: formRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: modelData.name + ":"
                            color: DesignTokens.textTertiary
                            font.pixelSize: 10
                            font.family: DesignTokens.fontUi
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.value
                            color: DesignTokens.textSecondary
                            font.pixelSize: 10
                            font.family: DesignTokens.fontUi
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // === 同义词 ===
    ColumnLayout {
        objectName: "synonymSection"
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 4
        visible: wordDetail.synonyms.length > 0

        Text {
            text: "同义词"
            color: DesignTokens.textPlaceholder
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            font.capitalization: Font.AllUppercase
        }

        Flow {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: wordDetail.synonyms
                delegate: Rectangle {
                    radius: 6
                    color: "#0dffffff"
                    border.color: DesignTokens.borderSubtle
                    border.width: 1
                    implicitWidth: synText.implicitWidth + 12
                    height: 20

                    Text {
                        id: synText
                        anchors.centerIn: parent
                        text: modelData
                        color: "#ccffffff"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.color = "#26ffffff"
                        onExited: parent.color = "#0dffffff"
                        onClicked: {
                            if (typeof appState !== "undefined" && appState) {
                                appState.setSourceText(modelData);
                                appState.translate();
                            }
                        }
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }

    // === 反义词 ===
    ColumnLayout {
        objectName: "antonymSection"
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 4
        visible: wordDetail.antonyms.length > 0

        Text {
            text: "反义词"
            color: DesignTokens.textPlaceholder
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            font.capitalization: Font.AllUppercase
        }

        Flow {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: wordDetail.antonyms
                delegate: Rectangle {
                    radius: 6
                    color: "#0dffffff"
                    border.color: DesignTokens.borderSubtle
                    border.width: 1
                    implicitWidth: antText.implicitWidth + 12
                    height: 20

                    Text {
                        id: antText
                        anchors.centerIn: parent
                        text: modelData
                        color: "#f87171"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.color = "#26ffffff"
                        onExited: parent.color = "#0dffffff"
                        onClicked: {
                            if (typeof appState !== "undefined" && appState) {
                                appState.setSourceText(modelData);
                                appState.translate();
                            }
                        }
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
    }
}
