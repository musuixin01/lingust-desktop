import QtQuick
import QtTest
TestCase {
    name: "ToolbarResponse"
    width: 400; height: 100; visible: true
    when: windowShown
    QtObject {
        id: mediaFixture
        property bool musicPlaying: true
        property bool systemMediaConnected: true
        property string trackTitle: "测试歌曲"
        property string trackArtist: "测试歌手"
        property string trackAlbum: "测试专辑"
        property string coverArtUrl: ""
        property int trackDuration: 180
        property int trackPosition: 60
        property var musicLyrics: [
            {timeMs: 0, text: "第一行歌词"},
            {timeMs: 60000, text: "当前歌词"},
            {timeMs: 90000, text: "下一行歌词"}
        ]
        property int currentLyricIndex: 1
        function seekTrack(seconds) {}
        function prevTrack() {}
        function toggleMusicPlay() {}
        function nextTrack() {}
    }
    LanguageSelector { id: selector; x: 100; y: 30 }
    MusicIslandCard { id: musicCard; visible: false; appState: mediaFixture }
    function test_musicComponentLoads() { compare(musicCard.implicitWidth, 340) }
    function test_musicLyricsAreScrollableAndCurrentLineSelected() {
        var list = findChild(musicCard, "musicLyricsList")
        compare(list.count, 3)
        compare(list.currentIndex, 1)
        verify(list.interactive)
    }
    function test_musicArtworkRotatesAndProgressRingTracksPlayback() {
        musicCard.visible = true
        var disc = findChild(musicCard, "musicCardAlbumDisc")
        var rotation = findChild(musicCard, "musicCardDiscRotation")
        var ring = findChild(musicCard, "musicCardProgressRing")
        verify(disc !== null)
        compare(rotation.running, true,
                "Playing media must keep the album-disc animator active")
        compare(Math.round(ring.progress * 100), 33)
        musicCard.visible = false
    }
    TrafficLights { id: lights; y: 70 }
    IconButton { id: button; x: 200; y: 30 }
    SignalSpy { id: closeSpy; target: lights; signalName: "closeClicked" }
    SignalSpy { id: swapSpy; target: selector; signalName: "swapClicked" }
    SignalSpy { id: sourceLanguageSpy; target: selector; signalName: "sourceSelected" }
    SignalSpy { id: targetLanguageSpy; target: selector; signalName: "targetSelected" }
    SignalSpy { id: clickSpy; target: button; signalName: "clicked" }
    function test_keyboardActivation() {
        button.enabled = true
        clickSpy.clear()
        button.forceActiveFocus()
        keyClick(Qt.Key_Space)
        compare(clickSpy.count, 1)
        button.enabled = false
        mouseClick(button, 14, 14)
        compare(clickSpy.count, 1, "Disabled actions must not fire")
        button.enabled = true
    }
    function test_lightsClick() {
        closeSpy.clear()
        mouseClick(lights, 10, 12)
        compare(closeSpy.count, 1)
    }
    function test_pressImmediate() {
        mousePress(button, 14, 14)
        compare(button.children[0].scale, 0.94)
        compare(button.scale, 1, "Hit region stays fixed")
        mouseRelease(button, 14, 14)
    }

    function test_clickShowsExecutionFeedback() {
        mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton)
        verify(button.feedbackActive, "A completed icon action needs visible execution feedback")
        tryCompare(button, "feedbackActive", false, 500)
    }
    function test_resizeImmediate() {
        selector.textOnly = false; wait(250)
        selector.textOnly = true
        compare(selector.width, 36, "Compact geometry must update in the same turn")
    }
    function test_swapClick() {
        selector.textOnly = false; wait(250)
        swapSpy.clear()
        mouseClick(selector, selector.width / 2, selector.height / 2)
        compare(swapSpy.count, 1, "Hover detection must not swallow clicks")
    }
    function test_multilingualPickerIncludesAutoDetection() {
        compare(selector.shortLabel("auto"), "AUTO")
        compare(selector.shortLabel("zh"), "ZH")
        compare(selector.shortLabel("ja"), "JA")
        sourceLanguageSpy.clear()
        targetLanguageSpy.clear()
        selector.openPicker("source")
        selector.chooseLanguage("auto")
        compare(sourceLanguageSpy.count, 1)
        compare(sourceLanguageSpy.signalArguments[0][0], "auto")

        selector.openPicker("target")
        selector.chooseLanguage("ja")
        compare(targetLanguageSpy.count, 1)
        compare(targetLanguageSpy.signalArguments[0][0], "ja")
        verify(selector.languages.length >= 10,
               "The language picker exposes a practical multilingual set")
    }
}

