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
        property real trackPosition: 0
        property real trackDuration: 100
        property int fontSizePercent: 100
        property real cardOpacity: 1
        function setSourceText(t) { sourceText=t }
        function completeTranslation() { return translatedText }
    }
    Item {
        width: detail.width; height: detail.height
        Rectangle { anchors.fill: parent; color: "#101420" }
        WordDetailView { id: detail; width: 144; word: appState.sourceText; phonetic: "/ɪkˈstrɔːdənərəli/" }
    }
    HoverScrollText { id: scrolling; x: 250; width: 144; height: 30; text: "A long translation that must scroll independently"; prefix: "/ɪkˈstrɔːdənərəli/" }
    PillView { id: pill; y: 550; width: 380; height: 46 }
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
    }
    function test_scrollPrefix() {
        scrolling.hovered=true
        wait(900)
        var items=allItems(scrolling)
        var text=items.filter(function(i){ return i.text===scrolling.text && i.visible })[0]
        var prefix=items.filter(function(i){ return i.text===scrolling.prefix && i.visible })[0]
        var t=text.mapToItem(scrolling,0,0), p=prefix.mapToItem(scrolling,0,0)
        // A separately clipped viewport is required: scrolling text may not paint over the prefix.
        verify(text.parent.clip && text.parent!==scrolling, "Scrolling text needs its own clip, separate from phonetic")
        scrolling.hovered=false
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
        wait(250)
        var icons=allItems(pill).filter(function(i){ return i.visible && i.iconSource!==undefined })
        verify(icons.length>=2)
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
