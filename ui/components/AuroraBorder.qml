import QtQuick

Item {
    id: aurora
    objectName: "auroraBorder"

    property bool active: false
    property bool processing: false
    property real auraOpacity: 0
    property real bloom: 0
    property real sharpness: 0
    property real phase: 0

    visible: false
    enabled: false

    function requestSurfaceFrame() {
        if (typeof translatorWindow !== "undefined" && translatorWindow
                && translatorWindow.requestSurfaceFrame)
            translatorWindow.requestSurfaceFrame()
    }

    function awaken() {
        twilight.stop()
        rotation.stop()
        rotation.start()
        auraOpacity = Math.max(auraOpacity, 0.10)
        bloom = Math.max(bloom, 0.28)
        dawn.restart()
    }

    function dissolve() {
        dawn.stop()
        twilight.restart()
    }

    onActiveChanged: active ? awaken() : dissolve()
    onProcessingChanged: {
        if (active)
            dawn.restart()
    }
    onAuraOpacityChanged: requestSurfaceFrame()
    onBloomChanged: requestSurfaceFrame()
    onPhaseChanged: requestSurfaceFrame()

    ParallelAnimation {
        id: dawn
        objectName: "auroraDawn"
        NumberAnimation { target: aurora; property: "auraOpacity"; to: aurora.processing ? 1 : 0.74; duration: 700; easing.type: Easing.OutSine }
        NumberAnimation { target: aurora; property: "bloom"; to: aurora.processing ? 1 : 0.84; duration: 700; easing.type: Easing.OutCubic }
        NumberAnimation { target: aurora; property: "sharpness"; to: 1; duration: 700; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: breathing
        objectName: "auroraBreathing"
        running: aurora.active && !dawn.running
        loops: Animation.Infinite
        NumberAnimation { target: aurora; property: "bloom"; to: aurora.processing ? 0.62 : 0.76; duration: 1900; easing.type: Easing.InOutSine }
        NumberAnimation { target: aurora; property: "bloom"; to: aurora.processing ? 1 : 0.90; duration: 1900; easing.type: Easing.InOutSine }
    }

    NumberAnimation {
        id: rotation
        target: aurora
        property: "phase"
        from: 0
        to: 1
        duration: 14800
        loops: Animation.Infinite
    }

    ParallelAnimation {
        id: twilight
        objectName: "auroraTwilight"
        NumberAnimation { target: aurora; property: "auraOpacity"; to: 0; duration: 850; easing.type: Easing.OutSine }
        NumberAnimation { target: aurora; property: "bloom"; to: 0.18; duration: 850; easing.type: Easing.OutSine }
        NumberAnimation { target: aurora; property: "sharpness"; to: 0; duration: 850; easing.type: Easing.OutSine }
        onFinished: rotation.stop()
    }
}
