import QtQuick
import QtQuick.Controls
import QtTest
TestCase {
    name: "NarrowContent"
    width: 900; height: 700; visible: true
    when: windowShown
    QtObject {
        id: appState
        property string sourceText: "Extraordinarily"
        property string translatedText: "非常；格外地"
        property string sourceLang: "EN"
        property string targetLang: "ZH"
        property bool isTranslating: false
        property bool pillMusicMode: false
        property bool musicPlaying: false
        property bool systemMediaConnected: true
        property real trackPosition: 0
        property real trackDuration: 100
        property string trackTitle: "测试歌曲"
        property string trackArtist: "测试歌手"
        property string coverArtUrl: ""
        property string currentLyric: "当前歌词"
        property var musicLyrics: [{timeMs: 0, text: "当前歌词"}]
        property int currentLyricIndex: 0
        property bool lyricsSynchronized: true
        property int fontSizePercent: 100
        property real cardOpacity: 1
        property int translateCalls: 0
        property int copyCalls: 0
        property int musicModeCalls: 0
        property int speakCalls: 0
        property int previousCalls: 0
        property bool justCopied: false
        property var definitions: [{partOfSpeech: "adv.", meaning: "非常；格外地；异乎寻常地"}]
        function setSourceText(t) { sourceText=t }
        function completeTranslation() { return translatedText }
        function translate() { translateCalls += 1 }
        function copyTranslation() { copyCalls += 1 }
        function togglePillMusicMode() { musicModeCalls += 1 }
        function speak() { speakCalls += 1 }
        function toggleMusicPlay() {}
        function nextTrack() {}
        function prevTrack() { previousCalls += 1 }
    }
    Item {
        width: detail.width; height: detail.height
        Rectangle { anchors.fill: parent; color: "#101420" }
        WordDetailView {
            id: detail
            width: 144
            word: appState.sourceText
            phonetic: "/ɪkˈstrɔːdənərəli/"
            examples: [{src: "This is a useful example.", dst: "这是一个实用的例句。"}]
            wordForms: [{name: "过去式", value: "used"}]
            synonyms: ["remarkably", "exceptionally"]
            antonyms: ["ordinarily"]
        }
    }
    HoverScrollText { id: scrolling; x: 250; width: 144; height: 30; text: "A long translation that must scroll independently"; prefix: "/ɪkˈstrɔːdənərəli/" }
    PillView { id: pill; y: 550; width: 380; height: 46 }
    SignalSpy { id: pillExpandSpy; target: pill; signalName: "expandRequested" }
    SignalSpy { id: pillMinimizeSpy; target: pill; signalName: "minimizeToTaskbarRequested" }
    SignalSpy { id: pillSettingsSpy; target: pill; signalName: "settingsRequested" }
    SignalSpy { id: pillScreenshotSpy; target: pill; signalName: "screenshotRequested" }
    function allItems(root) {
        var result=[]
        for (var item of root.children) {
            result.push(item)
            result=result.concat(allItems(item))
        }
        return result
    }
    function test_wordHeader_data() {
        var data=[]
        for (var width of [128,144,204,284,380,600])
            for (var scale of [70,100,150]) data.push({tag:width+"-"+scale,w:width,scale:scale})
        return data
    }
    function test_wordHeader(data) {
        detail.width=data.w
        appState.fontSizePercent=data.scale
        detail.fontScale=data.scale/100.0
        waitForRendering(detail)
        compare(findChild(detail,"wordTitle").font.pixelSize, Math.round(20*data.scale/100))
        var textItems=allItems(detail).filter(function(i) { return i.text === detail.word || i.text === detail.phonetic })
        compare(textItems.length,2)
        for (var item of textItems) {
            var pos=item.mapToItem(detail,0,0)
            verify(pos.x>=0 && pos.x+item.width<=detail.width+0.1, "Word/phonetic must stay within the narrow card")
        }
        var speech=findChild(detail,"wordSpeechButtons")
        var sp=speech.mapToItem(detail,0,0)
        for (var item of textItems) {
            var tp=item.mapToItem(detail,0,0)
            verify(tp.y+item.height<=sp.y || sp.y+speech.height<=tp.y || tp.x+item.width<=sp.x || sp.x+speech.width<=tp.x, "Speech buttons must not overlap title or phonetic")
        }
        grabImage(detail.parent).save("word-"+data.w+"-"+data.scale+".png")
        var a=textItems[0], b=textItems[1]
        var ap=a.mapToItem(detail,0,0), bp=b.mapToItem(detail,0,0)
        verify(ap.y+a.height<=bp.y || bp.y+b.height<=ap.y || ap.x+a.width<=bp.x || bp.x+b.width<=ap.x, "Word and phonetic must not overlap")
        if (detail.singleLineHeader) {
            verify(Math.abs((ap.y + a.height / 2) - (sp.y + speech.height / 2)) <= 1.5,
                   "Word, phonetic and speech controls share one centered row when they fit")
            verify(Math.abs((bp.y + b.height / 2) - (sp.y + speech.height / 2)) <= 1.5,
                   "Phonetic stays centered with the speech controls when space is available")
        }
    }
    function test_scrollPrefix() {
        var items=allItems(scrolling)
        var text=items.filter(function(i){ return i.text===scrolling.text && i.visible })[0]
        var prefix=items.filter(function(i){ return i.text===scrolling.prefix && i.visible })[0]
        mouseMove(scrolling, scrolling.width / 2, scrolling.height / 2)
        wait(900)
        var t=text.mapToItem(scrolling,0,0), p=prefix.mapToItem(scrolling,0,0)
        // A separately clipped viewport is required: scrolling text may not paint over the prefix.
        verify(text.parent.clip && text.parent!==scrolling, "Scrolling text needs its own clip, separate from phonetic")
        verify(text.x < 0, "Overflow text moves only while its own content is hovered")
        mouseMove(pill, pill.width / 2, pill.height / 2)
        tryCompare(text, "x", 0, 200)
    }
    function test_pillTrafficLightsRevealAtMinimumWidth() {
        pill.width = 380
        waitForRendering(pill)
        var lights = findChild(pill, "pillTrafficLights")
        verify(lights !== null)
        tryCompare(lights, "opacity", 1, 300)
        verify(lights.enabled, "Normal pill keeps the traffic lights available")
        compare(lights.indicatorSize, 7, "Idle pill uses smaller traffic-light dots")
        var lightsCenter = lights.mapToItem(pill, lights.width / 2, lights.height / 2)
        compare(lights.width, 34, "Idle pill shrinks the complete traffic-light capsule")
        compare(lights.height, 18)
        mouseMove(pill, lightsCenter.x, lightsCenter.y)
        tryCompare(lights, "indicatorSize", 9, 250)
        tryCompare(lights, "width", 44, 250)
        tryCompare(lights, "height", 22, 250)

        pill.width = 160
        mouseMove(pill, pill.width / 2, pill.height / 2)
        tryCompare(lights, "opacity", 0, 300)
        verify(!lights.enabled, "Minimum pill hides idle traffic lights")

        mouseMove(pill, 4, pill.height / 2)
        tryCompare(lights, "opacity", 1, 300)
        verify(lights.enabled, "Hovering the minimum pill's left edge reveals traffic lights")
        verify(pill.leadingInset > 10, "Pill content yields space to revealed traffic lights")

        mouseMove(pill, pill.width - 8, pill.height / 2)
        tryCompare(lights, "opacity", 0, 300)
        pill.width = 380
    }
    function test_pillYellowLightRequestsTaskbarMinimize() {
        var lights = findChild(pill, "pillTrafficLights")
        pillExpandSpy.clear()
        pillMinimizeSpy.clear()
        lights.minimizeClicked()
        compare(pillMinimizeSpy.count, 1, "Yellow light must request taskbar minimization")
        compare(pillExpandSpy.count, 0, "Yellow light must not expand the pill into a card")
    }
    function test_pillSearchExpandsInline() {
        pill.width = 160
        pill.searchExpanded = false
        mouseMove(pill, pill.width / 2, pill.height / 2)
        waitForRendering(pill)
        pillExpandSpy.clear()
        var search = findChild(pill, "pillSearch")
        var input = findChild(pill, "pillSearchInput")
        var collapsedWidth = search.width
        var center = search.mapToItem(pill, search.width / 2, search.height / 2)
        mouseClick(pill, center.x, center.y, Qt.LeftButton)
        verify(pill.searchExpanded)
        tryCompare(search, "width", pill.searchExpandedTargetWidth, 400)
        tryCompare(findChild(pill, "pillActions"), "width", pill.rightBaseWidth, 400)
        tryCompare(input, "activeFocus", true, 300)
        tryCompare(input, "selectedText", input.text, 300)
        verify(input.visible, "Inline search editor must be visible")
        verify(findChild(pill, "pillTranslationContent").visible,
               "Editing in the pill must keep the translation visible")
        verify(findChild(pill, "pillTranslationContent").width >= 36,
               "Compact search must reserve readable translation space; actual="
               + findChild(pill, "pillTranslationContent").width + ", search=" + search.width
               + ", actions=" + findChild(pill, "pillActions").width)
        verify(findChild(pill, "pillActions").width >= 23,
               "Editing keeps the available right-side actions")
        compare(pillExpandSpy.count, 0, "Search click must stay in pill mode")
        keyClick(Qt.Key_Escape)
        verify(!pill.searchExpanded)
        pill.width = 380
    }

    function test_widePillSearchStillAcceptsTyping() {
        pill.width = 480
        pill.searchExpanded = false
        appState.sourceText = ""
        waitForRendering(pill)

        var search = findChild(pill, "pillSearch")
        var input = findChild(pill, "pillSearchInput")
        var center = search.mapToItem(pill, search.width / 2, search.height / 2)
        mouseClick(pill, center.x, center.y, Qt.LeftButton)

        verify(pill.searchExpanded, "A resized wide pill must still open its inline editor")
        tryCompare(input, "activeFocus", true, 300)
        keyClick(Qt.Key_A)
        compare(appState.sourceText, "a", "The wide pill editor must accept keyboard input")
        pill.width = 380
    }

    function test_pillSearchDoesNotExpandOnHover() {
        pill.width = 380
        pill.searchExpanded = false
        pill.rightActionsExpanded = false
        appState.sourceText = "cat"
        appState.translatedText = "猫"
        mouseMove(pill, pill.width / 2, pill.height - 2)
        tryCompare(findChild(pill, "pillSearch"), "width", pill.searchRestingWidth, 350)
        var search = findChild(pill, "pillSearch")
        var collapsedWidth = search.width
        var center = search.mapToItem(pill, search.width / 2, search.height / 2)
        mouseMove(pill, center.x, center.y)
        wait(220)
        compare(search.width, collapsedWidth,
                "Hovering the search pill must not change its width")
        verify(!pill.searchExpanded,
               "Hovering the search pill must not enter editing")
        verify(!findChild(pill, "pillSearchInput").visible,
               "The editor appears only after a click")
        verify(findChild(pill, "pillSearchSource").visible,
               "The resting search pill keeps the source word visible")
    }

    function test_pillSearchFocusRunsAuroraLifecycle() {
        pill.width = 380
        pill.searchExpanded = false
        appState.sourceText = ""
        appState.translatedText = ""
        wait(20)
        waitForRendering(pill)

        var search = findChild(pill, "pillSearch")
        var aurora = findChild(pill, "pillAuroraBorder")
        var center = search.mapToItem(pill, search.width / 2, search.height / 2)
        mouseClick(pill, center.x, center.y, Qt.LeftButton)
        tryCompare(findChild(pill, "pillSearchInput"), "activeFocus", true, 300)
        verify(aurora.active, "Clicking pill search wakes the auroral edge")
        verify(aurora.auraOpacity >= 0.10,
               "Pill search focus starts with immediate visible edge energy")

        pill.prepareKeyboardFocus(pill.width / 2, pill.height - 2)
        verify(!pill.searchExpanded,
               "An empty editor returns to the minimum search pill after losing focus")
        verify(!aurora.active, "Leaving an empty pill search dissolves the auroral edge")
        verify(findChild(pill, "auroraTwilight").running)
    }

    function test_minimumSearchStaysOutsideTrafficLightRevealZone() {
        pill.width = 160
        pill.searchExpanded = false
        appState.sourceText = ""
        appState.translatedText = ""
        wait(20)
        var search = findChild(pill, "pillSearch")
        var position = search.mapToItem(pill, 0, 0)
        verify(position.x >= 20,
               "The minimum search control must sit clear of the 16px traffic-light reveal zone")
        verify(findChild(pill, "pillSearchGlass") !== null,
               "The minimum search control uses its own liquid-glass optical layer")
        pill.width = 380
    }

    function test_pillSearchBlurCollapsesAndStopsBreathing() {
        pill.width = 380
        appState.sourceText = ""
        appState.translatedText = ""
        wait(20)
        pill.openInlineSearch()
        var input = findChild(pill, "pillSearchInput")
        tryCompare(input, "activeFocus", true, 300)
        var caretBlink = findChild(pill, "pillCaretBlink")
        verify(caretBlink !== null,
               "The pill editor provides an animated caret")
        verify(caretBlink.running, "The pill caret blinks while the editor owns focus")
        input.focus = false
        tryCompare(pill, "searchExpanded", false, 300)
        verify(!findChild(pill, "pillAuroraBorder").active,
               "A collapsed minimum search no longer keeps the breathing glow active")
    }

    function test_pillSearchWidthFollowsWordLengthWithinCap() {
        pill.width = 380
        pill.searchExpanded = false
        pill.rightActionsExpanded = false
        appState.translatedText = "清晰"

        appState.sourceText = "cat"
        wait(180)
        var search = findChild(pill, "pillSearch")
        var shortWidth = search.width

        appState.sourceText = "extraordinary"
        tryVerify(function() { return search.width > shortWidth }, 350)
        verify(search.width <= pill.searchExpandedTargetWidth,
               "A result search pill never exceeds the normal search width")

        appState.sourceText = "pneumonoultramicroscopicsilicovolcanoconiosis"
        tryCompare(search, "width", pill.searchExpandedTargetWidth, 350)
    }

    function test_selectionAppearsInPillSearchBeforeTranslationCompletes() {
        pill.width = 380
        pill.searchExpanded = false
        appState.sourceText = "selected phrase"
        appState.translatedText = ""
        appState.isTranslating = true
        waitForRendering(pill)
        var source = findChild(pill, "pillSearchSource")
        verify(source.visible, "Selection text is visible while translation is still running")
        compare(source.text, "selected phrase")
        verify(findChild(pill, "pillSearch").width > 26,
               "A selected phrase expands the resting search enough to show its text")
        appState.isTranslating = false
    }

    function test_emptyPillSearchReturnsToMinimum() {
        pill.width = 380
        appState.sourceText = "temporary"
        appState.translatedText = "临时"
        pill.searchExpanded = true
        waitForRendering(pill)
        appState.sourceText = ""
        appState.translatedText = ""
        tryCompare(pill, "searchExpanded", false, 300)
        tryCompare(findChild(pill, "pillSearch"), "width", 26, 350)
    }

    function test_pillShowsOnlyPrimaryColoredMeaning() {
        pill.width = 380
        appState.sourceText = "extraordinarily"
        appState.translatedText = "非常；格外地；异乎寻常地"
        appState.definitions = [{partOfSpeech: "adv.", meaning: "非常；格外地；异乎寻常地"}]
        waitForRendering(pill)

        var translation = findChild(pill, "pillImportantTranslation")
        compare(translation.prefix, "adv.")
        compare(translation.text, "非常")
        compare(translation.prefixColor, DesignTokens.accentBlue)
        compare(translation.textColor, DesignTokens.textPrimary)
        compare(translation.stacked, false)
        var prefixItem = findChild(translation, "scrollPrefix")
        var valueItem = findChild(translation, "scrollValue")
        var prefixCenter = prefixItem.mapToItem(translation, 0, prefixItem.height / 2).y
        var valueCenter = valueItem.mapToItem(translation, 0, valueItem.height / 2).y
        verify(Math.abs(prefixCenter - valueCenter) <= 1,
               "Part of speech and primary meaning stay vertically centered on one row")
    }

    function test_pillLoadingUsesMotionInsteadOfStatusText() {
        pill.width = 380
        appState.isTranslating = true
        waitForRendering(pill)

        verify(findChild(pill, "pillTranslationMotion").visible)
        var dot = findChild(pill, "pillTranslationDot0")
        verify(dot !== null)
        tryVerify(function() { return dot.y < 0 || dot.opacity > 0.4 }, 250)
        verify(!findChild(pill, "pillImportantTranslation").visible)
        verify(allItems(pill).every(function(item) { return item.text !== "翻译中…" && item.text !== "翻译中..." }))
        appState.isTranslating = false
    }

    function test_pillActionsInvokeTheirFunctions() {
        pill.width = 340
        pill.searchExpanded = false
        pill.rightActionsExpanded = true
        appState.copyCalls = 0
        appState.musicModeCalls = 0
        appState.speakCalls = 0
        pillExpandSpy.clear()
        pillSettingsSpy.clear()
        pillScreenshotSpy.clear()
        wait(220)

        function byTooltip(label) {
            return allItems(pill).filter(function(item) { return item.tooltip === label })[0]
        }
        byTooltip("复制").clicked()
        byTooltip("截图翻译").clicked()
        byTooltip("音乐控制").clicked()
        byTooltip("偏好设置").clicked()
        byTooltip("朗读").clicked()
        byTooltip("展开卡片").clicked()

        compare(appState.copyCalls, 1)
        compare(pillScreenshotSpy.count, 1)
        compare(appState.musicModeCalls, 1)
        compare(appState.speakCalls, 1)
        compare(pillSettingsSpy.count, 1)
        compare(pillExpandSpy.count, 1)
        pill.rightActionsExpanded = false
    }
    function test_pillMusicShowsPreviousTrackControl() {
        pill.width = 380
        appState.previousCalls = 0
        appState.pillMusicMode = true
        waitForRendering(pill)
        var previous = findChild(pill, "pillMusicPrevious")
        verify(previous !== null && previous.visible,
               "Normal music pill exposes the previous-track action")
        previous.clicked()
        compare(appState.previousCalls, 1)
        appState.pillMusicMode = false
    }
    function test_pillRightActionsExpandWithoutOverlap() {
        pill.width = 340
        pill.height = 46
        pill.searchExpanded = false
        mouseMove(pill, pill.width / 2, pill.height / 2)
        wait(200)
        var actions = findChild(pill, "pillActions")
        var translation = findChild(pill, "pillTranslationContent")
        var search = findChild(pill, "pillSearch")
        var baseWidth = actions.width
        var baseTranslationWidth = translation.width
        var rightEdge = actions.mapToItem(pill, actions.width, 0).x

        mouseMove(pill, pill.width - 2, pill.height / 2)
        tryCompare(actions, "width", pill.rightFullWidth, 400)
        verify(!search.visible, "The compact search is pushed away while all right actions are open")
        verify(translation.width >= baseTranslationWidth,
               "Translation keeps priority while secondary controls yield space")
        fuzzyCompare(actions.mapToItem(pill, actions.width, 0).x, rightEdge, 0.5)

        var searchPos = search.mapToItem(pill, 0, 0)
        var translationPos = translation.mapToItem(pill, 0, 0)
        var actionsPos = actions.mapToItem(pill, 0, 0)
        verify(translationPos.x + translation.width <= actionsPos.x + 0.1,
               "Expanded actions must not overlap translation")

        mouseMove(pill, pill.width / 2, pill.height - 2)
        tryCompare(actions, "width", baseWidth, 500)
        pill.width = 380
    }

    function test_normalPillPrioritizesContentBeforeActions() {
        pill.width = 380
        pill.height = 46
        pill.searchExpanded = false
        pill.rightActionsExpanded = false
        appState.sourceText = "pneumonoultramicroscopicsilicovolcanoconiosis"
        appState.translatedText = "非常；格外地"
        appState.definitions = [{partOfSpeech: "adv.", meaning: "非常；格外地"}]
        mouseMove(pill, pill.width / 2, pill.height / 2)
        wait(220)

        var actions = findChild(pill, "pillActions")
        var translation = findChild(pill, "pillTranslationContent")
        var search = findChild(pill, "pillSearch")
        var lights = findChild(pill, "pillTrafficLights")
        var baseActionWidth = actions.width
        var baseTranslationWidth = translation.width
        verify(actions.width < pill.rightFullWidth,
               "Secondary actions yield space when the word and translation need it")
        verify(translation.width >= pill.preferredTranslationWidth,
               "The concise translation receives its measured readable width")

        mouseMove(pill, pill.width - 2, pill.height / 2)
        wait(220)
        verify(pill.rightHoverExpanded,
               "The right edge expands controls after content has hidden actions")
        tryCompare(actions, "width", pill.rightFullWidth, 350)
        verify(!search.visible)
        verify(translation.width > 0)
        tryCompare(lights, "opacity", 1, 200)
        verify(lights.enabled, "Right-side expansion keeps the traffic lights interactive")
        pill.handlePointerLeave()
        pill.handlePointerMove(pill.width / 2, pill.height / 2)
    }

    function test_searchSettlesAfterTranslationOutsidePill() {
        pill.width = 380
        pill.searchExpanded = true
        appState.isTranslating = true
        appState.translatedText = ""
        mouseMove(detail, 12, 12)

        appState.translatedText = "高效的"
        appState.isTranslating = false
        tryCompare(pill, "searchExpanded", false, 300)

        var search = findChild(pill, "pillSearch")
        var source = findChild(pill, "pillSearchSource")
        tryCompare(search, "width", pill.searchRestingWidth, 350)
        verify(source.visible, "Collapsed search keeps the translated source word visible")
        compare(source.text, appState.sourceText)
    }

    function test_windowLeaveClearsPillInteractionState() {
        pill.width = 160
        appState.sourceText = "edge"
        appState.translatedText = "边缘"
        pill.searchExpanded = false
        pill.rightActionsExpanded = true
        pill.pointerInsideWindow = true
        pill.handlePointerLeave()

        verify(!pill.pointerInsideWindow)
        verify(!pill.rightActionsExpanded)
        verify(!pill.rightHoverExpanded)

        pill.handlePointerMove(pill.width - 2, pill.height / 2)
        verify(pill.pointerInsideWindow)
        verify(pill.nativeRightRevealActive)
        verify(pill.rightActionsExpanded,
               "A real pointer move at the right edge expands hidden actions")
        pill.handlePointerLeave()
        verify(!pill.nativeRightRevealActive)
        pill.width = 380
    }

    function test_minimumPillLeftEdgeRevealsTrafficLights() {
        pill.width = 160
        pill.searchExpanded = false
        pill.handlePointerLeave()
        verify(!pill.showTrafficLights)

        pill.handlePointerMove(2, pill.height / 2)
        verify(pill.nativeLeftRevealActive)
        verify(pill.leftLightsRevealed)
        verify(pill.showTrafficLights,
               "The minimum pill reveals traffic lights from its native left edge")

        pill.handlePointerMove(pill.width / 2, pill.height / 2)
        verify(!pill.nativeLeftRevealActive)
        verify(!pill.showTrafficLights)
        pill.width = 380
    }
    function test_richDictionarySections() {
        detail.width = 284
        waitForRendering(detail)
        verify(findChild(detail, "bilingualExamples").visible, "Bilingual examples must render")
        verify(findChild(detail, "wordFormsSection").visible, "Word forms must render")
        verify(findChild(detail, "synonymSection").visible, "Synonyms must render")
        verify(findChild(detail, "antonymSection").visible, "Antonyms must render")
        var labels = allItems(detail).filter(function(item) { return item.text !== undefined }).map(function(item) { return item.text })
        verify(labels.indexOf("This is a useful example.") >= 0)
        verify(labels.indexOf("这是一个实用的例句。") >= 0)
        verify(labels.indexOf("remarkably") >= 0)
        verify(labels.indexOf("ordinarily") >= 0)
        var examplesPosition = findChild(detail, "bilingualExamples").mapToItem(detail, 0, 0)
        var formsPosition = findChild(detail, "wordFormsSection").mapToItem(detail, 0, 0)
        verify(formsPosition.y >= examplesPosition.y + findChild(detail, "bilingualExamples").height,
               "Word forms must follow bilingual examples")
    }
    function test_wideLexicalSectionsUseHorizontalSpace() {
        detail.width = 600
        waitForRendering(detail)
        var forms = findChild(detail, "wordFormsSection").mapToItem(detail, 0, 0)
        var synonyms = findChild(detail, "synonymSection").mapToItem(detail, 0, 0)
        var antonyms = findChild(detail, "antonymSection").mapToItem(detail, 0, 0)
        fuzzyCompare(forms.y, synonyms.y, 0.5)
        fuzzyCompare(forms.y, antonyms.y, 0.5)
        verify(forms.x < synonyms.x && synonyms.x < antonyms.x,
               "Wide cards must distribute lexical sections across columns")
    }
    function test_lexicalColumnsFollowAvailableWidth_data() {
        return [
            {tag: "one-column", width: 280, columns: 1},
            {tag: "two-columns", width: 360, columns: 2},
            {tag: "three-columns", width: 480, columns: 3}
        ]
    }
    function test_lexicalColumnsFollowAvailableWidth(data) {
        detail.width = data.width
        waitForRendering(detail)
        compare(findChild(detail, "lexicalGrid").columns, data.columns)
    }
    function test_pillIcons_data() {
        var data=[]
        for (var width of [160,180,220,280,339,340,380,440,480,600])
            for (var height of [38,46,60]) data.push({tag:width+"x"+height,w:width,h:height})
        return data
    }
    function test_pillIcons(data) {
        pill.width=data.w
        pill.height=data.h
        pill.searchExpanded=false
        pill.rightActionsExpanded=false
        mouseMove(pill, pill.width / 2, pill.height / 2)
        wait(250)
        var icons=allItems(pill).filter(function(i){ return i.visible && i.iconSource!==undefined })
        verify(icons.length>=1)
        verify(findChild(pill,"pillSearch").visible,
               "Compact pill keeps the search entry beside the right-edge action")
        var expand=findChild(pill,"pillExpand")
        verify(expand.visible)
        var expandPos=expand.mapToItem(pill,0,0)
        verify(expandPos.x>=0 && expandPos.x+expand.width<=pill.width)
        verify(expandPos.y>=0 && expandPos.y+expand.height<=pill.height)
        grabImage(pill).save("pill-"+data.w+"x"+data.h+".png")
        for (var icon of icons) {
            var ancestor=icon.parent
            while(ancestor && ancestor!==pill) {
                if(ancestor.clip) {
                    var pos=icon.mapToItem(ancestor,0,0)
                    verify(pos.x>=-0.1 && pos.x+icon.width<=ancestor.width+0.1, "Pill icon clipped by allocated action width")
                }
                ancestor=ancestor.parent
            }
        }
    }
}
