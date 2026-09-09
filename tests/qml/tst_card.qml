import QtQuick
import QtQuick.Controls
import QtTest
TestCase {
    name: "CardToolbarGeometry"
    width: 900; height: 600; visible: true
    when: windowShown
    QtObject {
        id: appState
        property string sourceText: "Hello"
        property string translatedText: "你好"
        property string sourceLang: "EN"
        property string targetLang: "ZH"
        property bool isTranslating: false
        property bool isWord: false
        property string phoneticUs: ""
        property string phoneticUk: ""
        property bool isFavorite: false
        property string engine: "offline"
        property bool justCopied: false
        property bool isPinned: false
        property bool compactMode: false
        property bool selectionTranslation: false
        property string selectionTriggerMode: ""
        property bool autoSpeak: false
        property real cardOpacity: 1
        property int fontSizePercent: 100
        property var definitions: []
        property var examples: []
        property var synonyms: []
        property var antonyms: []
        property var wordForms: []
        property var tags: []
        property string englishDefinition: ""
        property var history: []
        property var favorites: []
        property string errorMessage: ""
        property bool hasError: false
        property bool didCrashLastRun: false
        property string lastCrashInfo: ""
        property bool musicPlaying: false
        property string trackTitle: ""
        property string trackArtist: ""
        property string trackAlbum: ""
        property int trackDuration: 100
        property int trackPosition: 100
        property string currentLyric: ""
        property string currentLyricTranslation: ""
        property bool pillMusicMode: false
        property var ocrLines: []
        property string ocrImagePreview: ""
        function setSourceText(text) { sourceText = text }
        function completeTranslation() { return translatedText }
    }
    CardView { id: card; width: 380; height: 490 }
    function initTestCase() { wait(100) }
    function test_smallCorners_data() {
        return [{tag:"160x95",w:160,h:95},{tag:"160x130",w:160,h:130},
                {tag:"220x160",w:220,h:160},{tag:"380x180",w:380,h:180}]
    }
    function test_smallCorners(data) {
        card.width=data.w; card.height=data.h
        waitForRendering(card)
        var shot=grabImage(card)
        for(var x=0;x<32;++x) for(var y=0;y<32;++y) {
            if(Math.hypot(31.5-x,31.5-y)<33) continue
            compare(shot.pixel(x,y),Qt.rgba(1,1,1,1),"top left")
            compare(shot.pixel(data.w-1-x,y),Qt.rgba(1,1,1,1),"top right")
            compare(shot.pixel(x,data.h-1-y),Qt.rgba(1,1,1,1),"bottom left")
            compare(shot.pixel(data.w-1-x,data.h-1-y),Qt.rgba(1,1,1,1),"bottom right")
        }
        card.height=490
    }
    function test_layout_data() {
        var rows = []
        for (var state of ["result", "loading", "empty"])
            for (var w of [160, 220, 260, 300, 380, 480, 800])
                rows.push({ tag: state + "-" + w, w: w, state: state })
        return rows
    }
    function test_layout(data) {
        appState.translatedText = data.state === "empty" ? "" : "你好"
        appState.isTranslating = data.state === "loading"
        card.width = data.w
        waitForRendering(card) // Assert the first rendered frame, not a settled animation.
        var header = findChild(card, "cardHeader")
        var body = findChild(card, "cardBody")
        var footer = findChild(card, "cardFooter")
        var actions = findChild(card, "footerActions")
        var status = findChild(card, "footerStatus")
        var topActions = findChild(card, "headerActions")
        verify(body.y >= header.y + header.height)
        verify(body.y + body.height <= footer.y + 0.1)
        verify(actions.x >= status.x + status.width, "Footer actions must not overlap status")
        verify(actions.x + actions.width <= card.width - card.gutter + 0.1)
        verify(topActions.x >= card.gutter + 48, "Header must preserve traffic light area")
        verify(topActions.x + topActions.width <= card.width - card.gutter + 0.1)
        verify(findChild(card, "cardMore").visible, "More actions must remain available at every width")
        if (data.state === "result") {
            wait(80) // Capture settled color feedback; geometry was asserted above.
            var shot = grabImage(card)
            shot.save("toolbar-" + data.w + ".png")
            for (var x=0; x<32; ++x) for (var y=0; y<32; ++y) {
                if (Math.hypot(31.5-x,31.5-y) < 33) continue // Leave antialiasing fringe.
                compare(shot.pixel(x,y), Qt.rgba(1,1,1,1), "top left must reveal background")
                compare(shot.pixel(data.w-1-x,y), Qt.rgba(1,1,1,1), "top right")
                compare(shot.pixel(x,card.height-1-y), Qt.rgba(1,1,1,1), "bottom left")
                compare(shot.pixel(data.w-1-x,card.height-1-y), Qt.rgba(1,1,1,1), "bottom right")
            }
        }
    }
}
