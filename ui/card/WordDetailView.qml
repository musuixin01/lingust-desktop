import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: wordDetail

    property string word: "Efficient"
    property string phonetic: "/ɪˈfɪʃnt/"
    property string translatedText: "高效的；有能力的"
    property var definitions: []
    property var examples: []
    property var synonyms: []
    property bool compact: false
    property bool veryCompact: false
    property bool ultraCompact: false

    spacing: wordDetail.ultraCompact ? 6 : (wordDetail.veryCompact ? 8 : (wordDetail.compact ? 10 : 12))

    // === 单词标题行 ===
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Row {
                spacing: 6

                Text {
                    text: wordDetail.word
                    color: DesignTokens.textPrimary
                    font.pixelSize: wordDetail.ultraCompact ? 14 : (wordDetail.veryCompact ? 16 : (wordDetail.compact ? 18 : 20))
                    font.weight: Font.Bold
                    font.family: "Segoe UI"
                    font.letterSpacing: -0.3
                }

                Text {
                    text: wordDetail.phonetic
                    color: "#cc93c5fd"
                    font.pixelSize: wordDetail.ultraCompact ? 9 : (wordDetail.compact ? 10 : 11)
                    font.family: "Consolas"
                    anchors.verticalCenter: parent.verticalCenter
                    visible: wordDetail.phonetic.length > 0
                }
            }
        }

        // 发音按钮
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Repeater {
                model: [
                    { label: "美", color: DesignTokens.accentBlue },
                    { label: "英", color: DesignTokens.accentEmerald }
                ]

                delegate: Rectangle {
                    width: 32; height: 20; radius: 6
                    color: "#0dffffff"
                    border.color: DesignTokens.borderSubtle
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        Image {
                            source: "qrc:/qt/qml/Linguist/resources/icons/volume.svg"
                            sourceSize.width: 10; sourceSize.height: 10
                        }
                        Text {
                            text: modelData.label
                            color: "#b2ffffff"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#26ffffff"
                        onExited: parent.color = "#0dffffff"
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
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
        implicitHeight: defColumn.implicitHeight + (wordDetail.compact ? 16 : 20)

        ColumnLayout {
            id: defColumn
            anchors.fill: parent
            anchors.margins: wordDetail.compact ? 8 : 10
            spacing: 6

            // 第一释义
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    radius: 6
                    color: "#333b82f6"
                    border.color: "#4c3b82f6"
                    border.width: 1
                    implicitWidth: posText.implicitWidth + 12
                    height: 18

                    Text {
                        id: posText
                        anchors.centerIn: parent
                        text: wordDetail.definitions.length > 0 ? wordDetail.definitions[0].partOfSpeech : "adj."
                        color: "#93c5fd"
                        font.pixelSize: 10
                        font.weight: Font.SemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: wordDetail.definitions.length > 0 ? wordDetail.definitions[0].meaning : wordDetail.translatedText
                    color: "#f2ffffff"
                    font.pixelSize: wordDetail.ultraCompact ? 12 : (wordDetail.compact ? 14 : 15)
                    font.weight: Font.SemiBold
                    font.family: "Segoe UI"
                    wrapMode: Text.Wrap
                }
            }

            // 更多释义
            Repeater {
                model: wordDetail.definitions.length > 1 ? wordDetail.definitions.slice(1) : []
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 6

                    Text {
                        text: modelData.partOfSpeech
                        color: "#cc60a5fa"
                        font.pixelSize: 10
                        font.family: "Consolas"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.meaning
                        color: "#b2ffffff"
                        font.pixelSize: 11
                        font.family: "Segoe UI"
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    // === 双语例句 ===
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: wordDetail.examples.length > 0

        Text {
            text: "双语例句"
            color: DesignTokens.textPlaceholder
            font.pixelSize: 9
            font.weight: Font.SemiBold
            font.letterSpacing: 1
            font.capitalization: Font.AllUppercase
        }

        Repeater {
            model: wordDetail.examples.slice(0, 2)
            delegate: Rectangle {
                Layout.fillWidth: true
                radius: 8
                color: "#08ffffff"
                border.color: DesignTokens.borderSubtle
                border.width: 1
                implicitHeight: exampleColumn.implicitHeight + 16

                ColumnLayout {
                    id: exampleColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: modelData.src
                        color: "#e6ffffff"
                        font.pixelSize: 11
                        font.family: "Georgia"
                        wrapMode: Text.Wrap
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.dst
                        color: "#80ffffff"
                        font.pixelSize: 10
                        font.family: "Segoe UI"
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    // === 同反义词 ===
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: wordDetail.synonyms.length > 0

        Text {
            text: "同反义词"
            color: DesignTokens.textPlaceholder
            font.pixelSize: 9
            font.weight: Font.SemiBold
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
                        onEntered: parent.color = "#26ffffff"
                        onExited: parent.color = "#0dffffff"
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}
