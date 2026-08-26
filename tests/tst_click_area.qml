import QtQuick 2.15
import QtTest 1.15

TestCase {
    name: "ClickAreaOffsetTests"
    when: windowShown

    Component {
        id: clickTestComp
        Item {
            id: container
            width: 400
            height: 300

            property bool clicked: false

            Item {
                id: rowContainer
                width: 10
                height: 10
                x: 0
                y: 0
                property string clickCommand: ""

                function contains(point) {
                    if (!clickCommand || clickCommand === "")
                        return false;

                    var pInRotator = itemRotator.mapFromItem(rowContainer, point);
                    return pInRotator.x >= 0 && pInRotator.x <= itemRotator.width && pInRotator.y >= 0 && pInRotator.y <= itemRotator.height;
                }

                Item {
                    id: itemRotator
                    width: 100
                    height: 50
                    transform: Translate { x: 150; y: 100 }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: container.clicked = true
                    }
                }
            }
        }
    }

    function test_offset_click_propagation() {
        var obj = createTemporaryObject(clickTestComp, null);
        verify(obj !== null);
        
        var rc = obj.children[0];
        var rot = rc.children[0];

        // Point inside itemRotator translated bounds (x: 150..250, y: 100..150)
        var insidePoint = Qt.point(200, 125);
        // Point outside itemRotator bounds (e.g. x: 50, y: 50)
        var outsidePoint = Qt.point(50, 50);

        // 1. Without click command: contains should return false even inside bounds (pass through)
        compare(rc.contains(insidePoint), false, "Without click command, rowContainer should NOT intercept point");

        // 2. With click command: contains should return true when inside itemRotator bounds
        rc.clickCommand = "kcalc";
        compare(rc.contains(insidePoint), true, "With click command, rowContainer SHOULD intercept point inside itemRotator bounds");
        compare(rc.contains(outsidePoint), false, "With click command, rowContainer should NOT intercept point outside itemRotator bounds");
    }

    function test_rotation_click_propagation() {
        var obj = createTemporaryObject(clickTestComp, null);
        verify(obj !== null);

        var rc = obj.children[0];
        var rot = rc.children[0];
        rot.rotation = 90; // Rotate itemRotator by 90 degrees around center
        rc.clickCommand = "kcalc";

        // itemRotator center is at (200, 125). Originally 100x50. Rotated 90 deg, bounds become 50x100.
        // Center (200, 125) should still be contained.
        var centerPoint = Qt.point(200, 125);
        compare(rc.contains(centerPoint), true, "Center point of rotated itemRotator should be contained");

        // Far corner (245, 105) was inside unrotated 100x50, but outside 50x100 rotated box
        var originalCorner = Qt.point(245, 105);
        compare(rc.contains(originalCorner), false, "Point outside rotated bounding box should not be contained");
    }
}
