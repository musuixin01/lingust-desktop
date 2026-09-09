import QtQuick
import QtTest
TestCase {
    name: "ToolbarResponse"
    width: 400; height: 100; visible: true
    when: windowShown
    LanguageSelector { id: selector; x: 100; y: 30 }
    MusicIslandCard { id: musicCard; visible: false }
    function test_musicComponentLoads() { compare(musicCard.implicitWidth, 340) }
    TrafficLights { id: lights; y: 70 }
    IconButton { id: button; x: 200; y: 30 }
    SignalSpy { id: closeSpy; target: lights; signalName: "closeClicked" }
    SignalSpy { id: swapSpy; target: selector; signalName: "swapClicked" }
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
        compare(button.children[0].scale, 0.9)
        compare(button.scale, 1, "Hit region stays fixed")
        mouseRelease(button, 14, 14)
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
}

