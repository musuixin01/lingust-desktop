import QtQuick
import QtTest
TestCase {
    name: "TransparentCorners"
    width: 600; height: 600; visible: true
    when: windowShown
    GlassSurface { id: surface; width: 380; height: 490 }
    function test_corners_data() {
        return [{tag:"card", w:380,h:490,pill:false},
                {tag:"minimum",w:160,h:95,pill:false},
                {tag:"pill",w:160,h:38,pill:true}]
    }
    function test_corners(data) {
        surface.width=data.w; surface.height=data.h; surface.isPill=data.pill
        waitForRendering(surface)
        var shot=grabImage(surface)
        shot.save("corners-"+data.tag+".png")
        for (var x of [0, 2]) for (var y of [0, 2]) {
            compare(shot.pixel(x,y),Qt.rgba(1,1,1,1),"top left")
            compare(shot.pixel(data.w-1-x,y),Qt.rgba(1,1,1,1),"top right")
            compare(shot.pixel(x,data.h-1-y),Qt.rgba(1,1,1,1),"bottom left")
            compare(shot.pixel(data.w-1-x,data.h-1-y),Qt.rgba(1,1,1,1),"bottom right")
        }
        verify(shot.pixel(data.w/2,data.h/2) !== Qt.rgba(1,1,1,1))
    }
    function test_resizeSilhouetteIsStable() {
        surface.width=380; surface.height=490; surface.isPill=false
        waitForRendering(surface)
        var before=grabImage(surface)
        for (var resizing of [true, false]) {
            surface.isResizing=resizing
            waitForRendering(surface)
            var after=grabImage(surface)
            compare(surface.cornerRadius,DesignTokens.radiusCard)
            for (var x=0;x<40;++x) for (var y=0;y<40;++y)
                compare(after.pixel(379-x,489-y),before.pixel(379-x,489-y),
                        "Press/release must not change the bottom-right silhouette")
        }
    }
}
