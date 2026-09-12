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
        property int translateCalls: 0
        property bool musicPlaying: false
        property bool systemMediaConnected: true
        property string trackTitle: ""
        property string trackArtist: ""
        property string trackAlbum: ""
        property int trackDuration: 100
        property int trackPosition: 100
        property string currentLyric: ""
        property string currentLyricTranslation: ""
        property string coverArtUrl: ""
        property var musicLyrics: []
        property int currentLyricIndex: -1
        property bool lyricsSynchronized: false
        property bool pillMusicMode: false
        property var ocrLines: []
        property string ocrImagePreview: ""
        property bool isOcrProcessing: false
        property string ocrStatus: ""
        property bool screenshotMode: false
        function setSourceText(text) { sourceText = text }
        function clearText() {
            sourceText = ""
            translatedText = ""
            definitions = []
            examples = []
            synonyms = []
            antonyms = []
            wordForms = []
        }
        function translate() { translateCalls += 1 }
        function completeTranslation() { return translatedText }
        function exitScreenshotMode() { screenshotMode = false }
        function openHistoryItem(item) {}
    }
    CardView {
        id: card
        width: 380
        height: 490
        onTranslateRequested: appState.translate()
    }
    SignalSpy { id: settingsSpy; target: card; signalName: "settingsRequested" }
    SignalSpy { id: musicSpy; target: card; signalName: "musicPanelRequested" }
    SignalSpy { id: moveSpy; target: card; signalName: "moveRequested" }
    SignalSpy { id: layoutPanelSpy; target: card; signalName: "layoutPanelRequested" }
    SignalSpy { id: screenshotPreviewSpy; target: card; signalName: "screenshotPreviewRequested" }
    function initTestCase() { wait(100) }
    function init() {
        card.isResizing = true
        card.handlePointerLeave()
        card.width = 380
        card.height = 490
        waitForRendering(card)
        card.isResizing = false
    }
    function nearWhite(color) {
        return color.r >= 0.99 && color.g >= 0.99 && color.b >= 0.99 && color.a >= 0.99
    }
    function test_smallCorners_data() {
        return [{tag:"160x95",w:160,h:95},{tag:"160x130",w:160,h:130},
                {tag:"220x160",w:220,h:160},{tag:"380x180",w:380,h:180}]
    }
    function test_smallCorners(data) {
        card.isResizing = true
        card.width=data.w; card.height=data.h
        waitForRendering(card)
        var shot=grabImage(card)
        for(var x=0;x<32;++x) for(var y=0;y<32;++y) {
            if(Math.hypot(31.5-x,31.5-y)<33) continue
            verify(nearWhite(shot.pixel(x,y)), "top left")
            verify(nearWhite(shot.pixel(data.w-1-x,y)), "top right")
            verify(nearWhite(shot.pixel(x,data.h-1-y)), "bottom left")
            verify(nearWhite(shot.pixel(data.w-1-x,data.h-1-y)), "bottom right")
        }
        card.height=490
        card.isResizing = false
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
        card.isResizing = true
        card.width = data.w
        waitForRendering(card) // Assert the first rendered frame, not a settled animation.
        var header = findChild(card, "cardHeader")
        var body = findChild(card, "cardBody")
        var footer = findChild(card, "cardFooter")
        var actions = findChild(card, "footerActions")
        var status = findChild(card, "footerStatus")
        var middle = findChild(card, "headerMiddle")
        var rightTools = findChild(card, "headerIcons")
        verify(body.y >= header.y + header.height)
        verify(body.y + body.height <= footer.y + 0.1)
        var middlePos = middle.mapToItem(card, 0, 0)
        verify(middlePos.x >= card.gutter + card.trafficSlotWidth,
               "Centered language group must not cover the compact traffic-light slot")
        var rightPos = rightTools.mapToItem(card, 0, 0)
        verify(rightPos.x >= middlePos.x + middle.width - 0.1, "Right tools must follow language and engine")
        verify(rightPos.x + rightTools.width <= card.width - card.gutter + 0.1, "Clipped tools stay inside the card")
        fuzzyCompare(middle.width, card.baseMiddleWidth, 0.1)
        fuzzyCompare(rightTools.width, card.baseRightWidth, 0.1)
        var settings = findChild(card, "cardSettings")
        verify(settings.visible, "The rightmost settings icon remains as the hover target")
        var statusPos = status.mapToItem(card, 0, 0)
        var actionsPos = actions.mapToItem(card, 0, 0)
        verify(actionsPos.x >= statusPos.x + status.width, "Footer actions must not overlap Smart-Select")
        verify(actionsPos.x + actions.width <= card.width - card.gutter + 0.1)
        verify(findChild(card, "footerFont").visible, "Font control stays in the functional footer")
        compare(findChild(card, "footerInfo"), null, "The redundant bottom status row is removed")
        card.isResizing = false
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
    function test_settingsClick() {
        card.width = 380
        card.height = 490
        waitForRendering(card)
        settingsSpy.clear()
        var settings = findChild(card, "cardSettings")
        verify(settings.visible)
        var center = settings.mapToItem(card, settings.width / 2, settings.height / 2)
        mouseClick(card, center.x, center.y, Qt.LeftButton)
        compare(settingsSpy.count, 1, "Settings button must open preferences directly")
    }
    function test_musicClick() {
        card.width = 380
        card.height = 490
        waitForRendering(card)
        musicSpy.clear()
        var music = findChild(card, "cardMusic")
        tryVerify(function() { return music.visible }, 500,
                  "Music action appears after its complete slot finishes expanding")
        var center = music.mapToItem(card, music.width / 2, music.height / 2)
        mouseClick(card, center.x, center.y, Qt.LeftButton)
        compare(musicSpy.count, 1, "Music button must open music controls")
    }
    function test_footerFontClick() {
        card.width = 380
        card.height = 200
        waitForRendering(card)
        layoutPanelSpy.clear()
        var fontButton = findChild(card, "footerFont")
        verify(fontButton.visible)
        var center = fontButton.mapToItem(card, fontButton.width / 2, fontButton.height / 2)
        mouseClick(card, center.x, center.y, Qt.LeftButton)
        compare(layoutPanelSpy.count, 1,
                "Footer font button requests the external below-card panel")
        card.height = 490
    }
    function test_footerUsesAvailableSpace() {
        appState.sourceText = "Hello"
        appState.translatedText = "你好"
        card.width = 220
        card.height = 180
        waitForRendering(card)
        verify(findChild(card, "cardFooter").height > 0, "Functional footer remains visible when vertical space is available")
        verify(findChild(card, "cardCopy").visible)
        verify(findChild(card, "cardSpeak").visible)
        verify(findChild(card, "cardFavorite").visible)
        verify(findChild(card, "cardHistory").visible)
        verify(findChild(card, "footerFont").visible)
        card.height = 490
        card.width = 380
    }
    function test_searchInputSubmitsTranslation() {
        appState.sourceText = ""
        appState.translateCalls = 0
        card.width = 380
        card.height = 490
        waitForRendering(card)
        var editor = findChild(card, "searchTextField")
        verify(editor !== null, "Search editor must exist")
        var center = editor.mapToItem(card, editor.width / 2, editor.height / 2)
        mouseClick(card, center.x, center.y, Qt.LeftButton)
        verify(editor.activeFocus, "Search editor must accept keyboard focus")
        var aurora = findChild(card, "cardAuroraBorder")
        verify(aurora.active, "Focusing the search field wakes the auroral edge")
        verify(aurora.auraOpacity >= 0.10, "Focus produces immediate visible edge energy")
        keyClick(Qt.Key_H)
        keyClick(Qt.Key_E)
        keyClick(Qt.Key_L)
        keyClick(Qt.Key_L)
        keyClick(Qt.Key_O)
        compare(appState.sourceText, "hello", "Typing must update AppState")
        verify(!card.prepareKeyboardFocus(card.width / 2, card.height - 50))
        verify(!editor.activeFocus, "Clicking outside the search editor releases its caret")
        verify(!aurora.active, "Leaving the search field begins the edge-light dissolve")
        verify(findChild(card, "auroraTwilight").running)
        editor.forceActiveFocus()
        keyClick(Qt.Key_Return)
        compare(appState.translateCalls, 1, "Enter must submit one translation")
        editor.focus = false
        card.forceActiveFocus()
        appState.sourceText = "Hello"
        appState.translatedText = "你好"
        waitForRendering(card)
    }

    function test_translationMotionAndResultReveal() {
        card.width = 340
        card.height = 260
        appState.sourceText = "hello"
        appState.translatedText = ""
        appState.isTranslating = true
        waitForRendering(card)

        var loading = findChild(card, "cardTranslationMotion")
        var loadingDot = findChild(card, "cardTranslationDot0")
        var aurora = findChild(card, "cardAuroraBorder")
        var dawn = findChild(card, "auroraDawn")
        var breathing = findChild(card, "auroraBreathing")
        var twilight = findChild(card, "auroraTwilight")
        verify(loading.visible, "Card translation uses the animated progress indicator")
        verify(aurora.active, "Translation wakes the auroral edge")
        verify(aurora.auraOpacity > 0, "The auroral edge starts fading in immediately")
        verify(dawn.running, "The 700ms dawn lifecycle starts with translation")
        tryVerify(function() { return loadingDot.y < 0 || loadingDot.opacity > 0.4 }, 250)

        tryVerify(function() { return !dawn.running }, 900)
        verify(breathing.running, "Dawn hands off to the 3.8s breathing lifecycle")

        appState.isTranslating = false
        appState.translatedText = "你好"
        wait(20)
        verify(twilight.running, "Finishing translation starts the 850ms twilight lifecycle")
        var result = findChild(card, "cardTranslatedResult")
        verify(result.visible)
        verify(result.opacity < 1, "A completed translation starts below full opacity")
        tryCompare(result, "opacity", 1, 400)
        card.width = 380
        card.height = 490
    }

    function test_minimalCardKeepsTranslationInPlace() {
        card.width = 220
        card.height = 130
        appState.sourceText = "compact"
        appState.translatedText = ""
        appState.isTranslating = true
        waitForRendering(card)

        appState.isTranslating = false
        appState.translatedText = "紧凑的"
        wait(30)
        compare(card.width, 220)
        compare(card.height, 130)
        var compactResult = findChild(card, "compactTranslation")
        verify(compactResult.visible,
               "Minimal-card translation stays in the current card body")
        compare(compactResult.text, "紧凑的",
                "Native translation updates are rendered in the minimal card")
        var resultPoint = compactResult.mapToItem(card, 0, 0)
        verify(resultPoint.y >= 33 && resultPoint.y < card.height,
               "Minimal result occupies the visible area below the search")

        card.width = 380
        card.height = 490
        appState.sourceText = "Hello"
        appState.translatedText = "你好"
    }

    function test_emptyPromptIsCenteredAndAnimated() {
        appState.isTranslating = false
        appState.translatedText = ""
        appState.sourceText = ""
        card.width = 220
        card.height = 200
        waitForRendering(card)

        var scroll = findChild(card, "cardScroll")
        var prompt = findChild(card, "cardEmptyPrompt")
        var promptContent = findChild(card, "cardEmptyPromptContent")
        verify(prompt.visible)
        verify(Math.abs(prompt.y + prompt.height / 2 - scroll.height / 2) <= 1.0,
               "Empty prompt occupies the visual center of the content page")
        fuzzyCompare(promptContent.x + promptContent.width / 2, prompt.width / 2, 0.1)
        compare(findChild(card, "cardEmptyPromptBreathing"), null,
                "Empty guidance settles after its entrance instead of moving forever")
        compare(findChild(card, "cardEmptyPromptTitle").text, "开始翻译")
        compare(findChild(card, "cardEmptyPromptHint").text, "输入文字，或直接划词")
        card.width = 380
        card.height = 490
        appState.sourceText = "Hello"
        appState.translatedText = "你好"
    }

    function test_rightToolbarOnlyShowsWholeIcons() {
        card.height = 490
        card.isResizing = true
        var actions = findChild(card, "headerIcons")
        var reveals = [
            { item: findChild(card, "cardScreenshot"), threshold: 103.5 },
            { item: findChild(card, "cardPin"), threshold: 77.5 },
            { item: findChild(card, "cardMusic"), threshold: 51.5 },
            { item: findChild(card, "cardSettings"), threshold: 25.5 }
        ]
        for (var width of [160, 180, 200, 220, 240, 280, 340]) {
            card.width = width
            waitForRendering(card)
            for (var reveal of reveals)
                compare(reveal.item.visible, actions.width >= reveal.threshold,
                        "Toolbar actions appear only after their complete slot fits")
        }
        card.width = 380
        card.isResizing = false
    }

    function test_selectionAppearsInSearchAndClearRemovesResult() {
        appState.sourceText = "selected phrase"
        appState.translatedText = "选中的短语"
        appState.definitions = [{partOfSpeech: "n.", meaning: "选中的短语"}]
        waitForRendering(card)
        var editor = findChild(card, "searchTextField")
        compare(editor.text, "selected phrase", "External selection text appears in the card search")
        var clearButton = findChild(card, "searchClear")
        verify(clearButton !== null, "Card search exposes one clear action")
        var center = clearButton.mapToItem(card, clearButton.width / 2, clearButton.height / 2)
        mouseClick(card, center.x, center.y, Qt.LeftButton)
        compare(appState.sourceText, "")
        compare(appState.translatedText, "", "Clearing the search also clears the result")
        compare(appState.definitions.length, 0)
    }
    function test_overflowShowsScrollbar() {
        appState.isWord = true
        appState.sourceText = "useful"
        appState.translatedText = "有用的"
        appState.definitions = [{partOfSpeech: "adj.", meaning: "有帮助的；有实际用途的"}]
        appState.examples = [
            {src: "This is a useful example for everyday work.", dst: "这是一个适合日常工作的实用例句。"},
            {src: "The guide contains useful information.", dst: "这份指南包含有用的信息。"}
        ]
        appState.synonyms = ["helpful", "practical", "valuable"]
        appState.antonyms = ["useless"]
        appState.wordForms = [{name: "副词", value: "usefully"}]
        card.width = 300
        card.height = 240
        waitForRendering(card)
        var bar = findChild(card, "cardScrollBar")
        verify(bar !== null, "Content area must expose a vertical scrollbar")
        verify(bar.visible, "Scrollbar must be visible when dictionary content overflows")
        verify(bar.size < 1, "Scrollbar thumb must represent the overflow range")
        wait(DesignTokens.durationFast + 20)
        compare(bar.contentItem.opacity, 0, "Idle scrollbar must be visually hidden")
        var content = findChild(card, "cardScroll")
        content.contentY = 0
        mouseWheel(content, content.width / 2, content.height / 2, 0, -120)
        wait(DesignTokens.durationFast + 20)
        verify(content.contentY > 0, "Mouse wheel must scroll without dragging the scrollbar")
        verify(bar.contentItem.opacity > 0, "Wheel scrolling must reveal the scrollbar")
        appState.isWord = false
        appState.definitions = []
        appState.examples = []
        appState.synonyms = []
        appState.antonyms = []
        appState.wordForms = []
        appState.sourceText = "Hello"
        appState.translatedText = "你好"
        card.width = 380
        card.height = 490
    }
    function test_toolbarHoverExpansion() {
        card.isResizing = true
        card.width = 180
        card.height = 490
        waitForRendering(card)
        card.isResizing = false
        var header = findChild(card, "cardHeader")
        var traffic = findChild(card, "headerTraffic")
        var middle = findChild(card, "headerMiddle")
        var language = findChild(card, "headerLanguage")
        var engine = findChild(card, "headerEngine")
        var rightTools = findChild(card, "headerIcons")
        var screenshotReveal = findChild(card, "cardScreenshotReveal")
        verify(screenshotReveal !== null,
               "Card actions expose the same reveal wrapper used by the pill motion model")
        compare(screenshotReveal.scale, 1,
                "Card action reveal does not add a separate scale motion")
        var baseMiddle = card.baseMiddleWidth
        var baseRight = card.baseRightWidth
        var baseLanguage = language.width
        var baseEngine = engine.width
        var trafficPosition = traffic.mapToItem(card, 0, 0)

        var languageCenter = language.mapToItem(card, language.width / 2, language.height / 2)
        mouseMove(card, languageCenter.x, languageCenter.y)
        wait(180)
        verify(language.width > baseLanguage, "Hover expands only the compressed language selector")
        compare(engine.width, baseEngine, "Language hover must not expand the engine")
        verify(middle.width > baseMiddle, "Language expansion grows the middle allocation")
        verify(rightTools.width < baseRight, "Right tools yield space to the language selector")
        compare(traffic.width, card.trafficSlotWidth, "Traffic lights keep their reserved width")
        fuzzyCompare(traffic.mapToItem(card, 0, 0).x, trafficPosition.x, 0.1)

        mouseMove(card, card.width / 2, 120)
        tryVerify(function() { return Math.abs(middle.width - card.baseMiddleWidth) < 0.5 }, 500)
        tryCompare(rightTools, "width", card.baseRightWidth, 500)

        var engineCenter = engine.mapToItem(card, engine.width / 2, engine.height / 2)
        mouseMove(card, engineCenter.x, engineCenter.y)
        wait(180)
        compare(language.width, baseLanguage, "Engine hover must not expand the language selector")
        verify(engine.width > baseEngine, "Hover expands only the engine indicator")
        verify(rightTools.width < baseRight, "Right tools yield space to the engine")
        compare(traffic.width, card.trafficSlotWidth)

        mouseMove(card, card.width / 2, 120)
        tryVerify(function() { return Math.abs(middle.width - card.baseMiddleWidth) < 0.5 }, 500)
        tryCompare(rightTools, "width", card.baseRightWidth, 500)

        mouseMove(card, card.width - card.gutter - 13, header.height / 2)
        fuzzyCompare(rightTools.width, baseRight, 0.5,
                     "Normal-card reveal observes hover intent before expanding")
        wait(80)
        fuzzyCompare(rightTools.width, baseRight, 0.5,
                     "Passing across the corner does not immediately rearrange the toolbar")
        wait(120)
        verify(rightTools.width > baseRight, "Far-right hover expands the clipped tool group")
        verify(middle.width < baseMiddle, "Middle group yields space while right tools are expanded")
        compare(traffic.width, card.trafficSlotWidth, "Right tool expansion must not affect traffic lights")
        fuzzyCompare(traffic.mapToItem(card, 0, 0).x, trafficPosition.x, 0.1)

        mouseMove(card, card.width / 2, 120)
        tryCompare(rightTools, "width", card.baseRightWidth, 500)
        card.width = 380
    }

    function test_middleControlsStayCenteredBetweenSideGroupsDuringResize() {
        card.height = 490
        card.isResizing = true
        var traffic = findChild(card, "headerTraffic")
        var middle = findChild(card, "headerMiddle")
        var language = findChild(card, "headerLanguage")
        var engine = findChild(card, "headerEngine")
        var actions = findChild(card, "headerIcons")
        for (var width of [160, 180, 220, 260, 300, 340, 380, 480]) {
            card.width = width
            waitForRendering(card)
            var trafficRight = traffic.mapToItem(card, traffic.width, 0).x
            var actionsLeft = actions.mapToItem(card, 0, 0).x
            var availableCenter = (trafficRight + actionsLeft) / 2
            var middleCenter = middle.mapToItem(card, middle.width / 2, 0).x
            fuzzyCompare(middleCenter, availableCenter, 0.51,
                         "The middle allocation stays centered between both side groups")
            var languageLeft = language.mapToItem(card, 0, 0).x
            var engineRight = engine.mapToItem(card, engine.width, 0).x
            fuzzyCompare((languageLeft + engineRight) / 2, availableCenter, 0.51,
                         "Language and status stay visually centered inside the live gap")
        }
        card.width = 220
        waitForRendering(card)
        compare(engine.width, 14, "The compressed status carrier uses the smaller footprint")
        compare(engine.height, 14, "The compressed status carrier remains circular")
        card.width = 380
        card.isResizing = false
    }

    function test_cardSearchUsesAnimatedCaret() {
        var search = findChild(card, "cardSearch")
        search.focusEditor()
        wait(20)
        var caretBlink = findChild(card, "cardCaretBlink")
        verify(caretBlink !== null,
               "The card editor provides the same animated caret as the pill")
        verify(caretBlink.running, "The card caret blinks while the editor owns focus")
        search.blurEditor()
    }

    function test_cardSearchMatchesPillGlassShape() {
        card.width = 220
        card.height = 200
        waitForRendering(card)
        var search = findChild(card, "cardSearch")
        compare(search.height, 26, "Card and pill search controls share the same height")
        compare(search.radius, 13, "Card and pill search controls share the same capsule radius")
        verify(findChild(search, "cardSearchGlass") !== null,
               "Card search uses the shared liquid-glass optical layer")
        verify(search.width >= 190, "The card keeps the available search length")
    }

    function test_minimalCardSearchAcceptsPointerFocus() {
        card.width = 220
        card.height = 130
        waitForRendering(card)
        var editor = findChild(card, "searchTextField")
        var center = editor.mapToItem(card, editor.width / 2, editor.height / 2)
        mouseClick(card, center.x, center.y, Qt.LeftButton)
        tryCompare(editor, "activeFocus", true, 300)
        verify(editor.activeFocus,
               "The minimal header drag layer must not intercept the search editor")
        editor.focus = false
        card.forceActiveFocus()
        card.width = 380
        card.height = 490
    }

    function test_cardHeaderUsesSeparatedGlassControlGroups() {
        card.width = 380
        card.height = 200
        waitForRendering(card)
        var divider = findChild(card, "cardHeaderDivider")
        var search = findChild(card, "cardSearch")
        var dividerPoint = divider.mapToItem(card, 0, divider.height)
        var searchPoint = search.mapToItem(card, 0, 0)
        fuzzyCompare(searchPoint.y - dividerPoint.y, 5, 0.1,
                     "The full-width divider keeps an exact 5px lower gap")
        fuzzyCompare(divider.width, card.width - 10, 0.1,
                     "The header divider stays long with a 5px corner-safe inset")
        var lights = findChild(card, "cardTrafficLights")
        compare(lights.indicatorSize, 5,
                "Idle card traffic lights use the new micro size")
        var actionsGlass = findChild(card, "cardActionsGlass")
        verify(actionsGlass !== null)
        verify(!actionsGlass.visible,
               "Normal-card actions keep the original frameless presentation")
        var language = findChild(card, "headerLanguage")
        var engine = findChild(card, "headerEngine")
        compare(language.height, engine.height,
                "Language and engine controls share one visual height")
        var settings = findChild(card, "cardSettings")
        var settingsBottom = settings.mapToItem(card, 0, settings.height).y
        var dividerTop = divider.mapToItem(card, 0, 0).y
        verify(dividerTop - settingsBottom <= 5,
               "The divider follows the actual bottom of the right-side icons")
        var screenshot = findChild(card, "cardScreenshot")
        var pin = findChild(card, "cardPin")
        var screenshotRight = screenshot.mapToItem(card, screenshot.width, 0).x
        var pinLeft = pin.mapToItem(card, 0, 0).x
        verify(screenshotRight <= pinLeft,
               "Screenshot and pin hit targets never overlap")
        card.width = 380
        card.height = 490
    }

    function test_minimalCardTopCornersRevealControls() {
        card.width = 220
        card.height = 130
        waitForRendering(card)
        var search = findChild(card, "cardSearch")
        var searchTop = search.mapToItem(card, 0, 0).y
        fuzzyCompare(searchTop, 5, 0.1,
                     "Minimal-card search keeps symmetric 5px vertical padding")
        verify(!card.showMinimalTraffic)
        verify(!card.showMinimalActions)

        card.handlePointerMove(8, 8)
        verify(!card.showMinimalTraffic, "Corner reveal waits briefly before opening")
        wait(80)
        verify(!card.showMinimalTraffic, "Incidental pointer movement does not open controls")
        wait(60)
        verify(card.showMinimalTraffic, "The top-left corner reveals traffic lights")
        verify(!card.showMinimalActions)
        verify(findChild(card, "cardTrafficLights").glassBackground,
               "Minimal and normal cards reuse the same traffic-light frame")
        wait(170)
        verify(search.muted,
               "The search remains visible as subdued glass behind revealed controls")
        compare(search.opacity, 1,
                "The minimal search is weakened rather than fully hidden")

        card.handlePointerMove(card.width - 8, 8)
        verify(!card.showMinimalTraffic)
        verify(!card.showMinimalActions, "Switching corners also observes hover intent")
        wait(140)
        verify(card.showMinimalActions, "The top-right corner reveals card actions")
        verify(findChild(card, "cardActionsGlass").visible,
               "Only the minimal-card reveal uses a light glass carrier")

        card.handlePointerLeave()
        verify(!card.showMinimalTraffic)
        verify(!card.showMinimalActions)
        card.height = 490
        card.width = 380
    }

    function test_minimalRevealStartsOnlyNearTopEdge() {
        card.width = 220
        card.height = 130
        card.handlePointerMove(card.width - 8, 24)
        wait(140)
        verify(!card.showMinimalActions,
               "The collapsed reveal trigger stays close to the top edge")
        card.handlePointerMove(card.width - 8, 8)
        wait(140)
        verify(card.showMinimalActions)
        card.handlePointerLeave()
        card.width = 380
        card.height = 490
    }

    function test_footerLeftControlKeepsSafeInset() {
        card.width = 220
        card.height = 200
        waitForRendering(card)
        var status = findChild(card, "footerStatus")
        verify(status.mapToItem(card, 0, 0).x >= 12,
               "The lower-left control keeps a comfortable border inset")
        card.width = 380
        card.height = 490
    }

    function test_screenshotResultReusesCardBody() {
        appState.sourceText = "existing search"
        appState.translatedText = "已有译文"
        appState.ocrImagePreview = "qrc:/qt/qml/Linguist/resources/icons/crop.svg"
        appState.ocrLines = [
            { src: "The first line.", dst: "第一行。" },
            { src: "The second line.", dst: "第二行。" }
        ]
        appState.screenshotMode = true
        waitForRendering(card)
        compare(findChild(card, "cardSearch").visible, false)
        compare(findChild(card, "cardScroll").visible, false)
        compare(findChild(card, "cardScreenshotResult").visible, true)

        var thumbnail = findChild(card, "screenshotThumbnail")
        verify(thumbnail.visible, "The source image thumbnail is visible by default")
        tryVerify(function() { return thumbnail.height > 20 }, 800,
                  "The source image thumbnail finishes its opening animation")
        verify(thumbnail.height <= 82, "The source image stays compact above the translation")

        var firstPair = findChild(card, "screenshotPair0")
        var secondPair = findChild(card, "screenshotPair1")
        verify(firstPair !== null && secondPair !== null)
        verify(secondPair.y - (firstPair.y + firstPair.height) <= 3,
               "Consecutive bilingual pairs use compact reading spacing")

        screenshotPreviewSpy.clear()
        var thumbnailOpen = findChild(card, "screenshotThumbnailOpen")
        var thumbnailPoint = thumbnailOpen.mapToItem(card,
                                                     thumbnailOpen.width / 2,
                                                     thumbnailOpen.height / 2)
        mouseClick(card, thumbnailPoint.x, thumbnailPoint.y, Qt.LeftButton)
        compare(screenshotPreviewSpy.count, 1,
                "Clicking the thumbnail requests the enlarged source preview")

        var previewToggle = findChild(card, "screenshotPreviewToggle")
        var togglePoint = previewToggle.mapToItem(card,
                                                  previewToggle.width / 2,
                                                  previewToggle.height / 2)
        mouseClick(card, togglePoint.x, togglePoint.y, Qt.LeftButton)
        tryCompare(thumbnail, "visible", false)
        mouseClick(card, togglePoint.x, togglePoint.y, Qt.LeftButton)
        tryCompare(thumbnail, "visible", true)

        appState.screenshotMode = false
        appState.ocrLines = []
        appState.ocrImagePreview = ""
        compare(appState.sourceText, "existing search",
                "Screenshot results do not replace the normal search query")
        compare(appState.translatedText, "已有译文",
                "Screenshot results do not replace the normal text translation")
    }

    function test_longPressOnEmptyBodyRequestsWindowMove() {
        appState.screenshotMode = false
        appState.sourceText = ""
        appState.translatedText = ""
        appState.examples = []
        appState.synonyms = []
        appState.antonyms = []
        appState.wordForms = []
        card.width = 350
        card.height = 300
        waitForRendering(card)
        var body = findChild(card, "cardBody")
        var point = body.mapToItem(card, body.width / 2, body.height / 2)
        moveSpy.clear()
        mousePress(card, point.x, point.y, Qt.LeftButton)
        wait(360)
        compare(moveSpy.count, 1, "Long-pressing empty card space must start window movement")
        mouseRelease(card, point.x, point.y, Qt.LeftButton)
    }

    function test_adaptiveHeightFollowsTranslationContent() {
        card.width = 380
        card.height = 490
        appState.isTranslating = false
        appState.isWord = false
        appState.sourceText = ""
        appState.translatedText = ""
        appState.definitions = []
        appState.examples = []
        appState.synonyms = []
        appState.antonyms = []
        appState.wordForms = []
        waitForRendering(card)
        compare(card.desiredWindowHeight, 200, "An empty card starts at the compact reference height")
        compare(card.desiredWindowWidth, 220)

        appState.isWord = true
        appState.sourceText = "efficient"
        appState.translatedText = "高效的；效率高的"
        appState.definitions = [{partOfSpeech: "adj.", meaning: "高效的；效率高的"}]
        waitForRendering(card)
        compare(card.desiredWindowHeight, 200, "A short dictionary result stays compact")
        compare(card.desiredWindowWidth, 220)

        appState.englishDefinition = "working well without wasting time or energy"
        appState.examples = [
            {src: "We weren't afraid.", dst: "我们没怕。"},
            {src: "Don't be afraid!", dst: "不要害怕！"},
            {src: "She was afraid to ask for help.", dst: "她不敢寻求帮助。"}
        ]
        appState.synonyms = ["concerned", "disinclined", "fearful"]
        appState.antonyms = ["confident", "unafraid"]
        appState.wordForms = [{name: "比较级", value: "more afraid"}]
        waitForRendering(card)
        compare(card.desiredWindowWidth, 350, "Rich content uses the compact reading width")
        compare(card.desiredWindowHeight, 420, "Rich content uses the compact reading height")
    }
}
