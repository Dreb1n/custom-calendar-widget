import QtQuick 2.15
import QtTest 1.15

TestCase {
    name: "OverlayAlignmentTests"

    Component {
        id: strokeTestComp
        Item {
            id: rootItem
            width: 200
            height: 50
            property bool isShapeItem: false
            property string effType: "stroke"
            property real effSize: 7
            property real pad: isShapeItem ? 0 : (effType === "stroke" ? effSize * 2 : 50)

            Item {
                id: mainTextStrokeContainer
                property real pad: rootItem.pad
                x: -pad
                y: -pad
                width: parent.width + (pad * 2)
                height: parent.height + (pad * 2)

                Repeater {
                    id: strokeRepeater
                    model: [
                        {dx: -1, dy: 0}, {dx: 1, dy: 0}, {dx: 0, dy: -1}, {dx: 0, dy: 1},
                        {dx: -0.92, dy: -0.38}, {dx: 0.92, dy: -0.38}, {dx: -0.92, dy: 0.38}, {dx: 0.92, dy: 0.38},
                        {dx: -0.38, dy: -0.92}, {dx: 0.38, dy: -0.92}, {dx: -0.38, dy: 0.92}, {dx: 0.38, dy: 0.92},
                        {dx: -0.707, dy: -0.707}, {dx: 0.707, dy: -0.707}, {dx: -0.707, dy: 0.707}, {dx: 0.707, dy: 0.707}
                    ]
                    Text {
                        x: mainTextStrokeContainer.pad + (modelData.dx * rootItem.effSize)
                        y: mainTextStrokeContainer.pad + (modelData.dy * rootItem.effSize)
                        width: parent.width - (mainTextStrokeContainer.pad * 2)
                        height: parent.height - (mainTextStrokeContainer.pad * 2)
                        text: "test"
                    }
                }
            }

            function verifyStrokeDilationOffsets() {
                const container = mainTextStrokeContainer;
                const textItems = [];
                for (let i = 0; i < container.children.length; i++) {
                    const child = container.children[i];
                    if (child && child.text !== undefined) {
                        textItems.push(child);
                    }
                }
                if (textItems.length < 16) return false;
                
                // Index 0: {dx: -1, dy: 0} -> x offset should be pad - effSize (14 - 7 = 7)
                const itemLeft = textItems[0];
                const expectedLeftX = container.pad + (-1 * rootItem.effSize);
                const expectedLeftY = container.pad + (0 * rootItem.effSize);

                // Index 1: {dx: 1, dy: 0} -> x offset should be pad + effSize (14 + 7 = 21)
                const itemRight = textItems[1];
                const expectedRightX = container.pad + (1 * rootItem.effSize);

                return (Math.abs(itemLeft.x - expectedLeftX) < 0.01) &&
                       (Math.abs(itemLeft.y - expectedLeftY) < 0.01) &&
                       (Math.abs(itemRight.x - expectedRightX) < 0.01) &&
                       (itemLeft.x !== container.pad) &&
                       (itemRight.x !== container.pad);
            }
        }
    }

    function test_text_overlay_alignment() {
        const item = createTemporaryObject(strokeTestComp, this, { isShapeItem: false, effType: "none" });
        compare(item.pad, 50, "Standard text overlay padding must be 50px to prevent slanted font clipping");
    }

    function test_shape_overlay_alignment() {
        const item = createTemporaryObject(strokeTestComp, this, { isShapeItem: true });
        compare(item.pad, 0, "Shape overlay padding must be 0px to prevent vector shape stretching");
    }

    function test_outer_stroke_dilation_positions() {
        const item = createTemporaryObject(strokeTestComp, this, { isShapeItem: false, effType: "stroke", effSize: 7 });
        verify(item.verifyStrokeDilationOffsets(), "Stroke dilator items must calculate non-zero radial x and y offsets relative to pad");
        compare(item.pad, 14, "Outer stroke padding must equal effSize * 2 (14px for effSize 7)");
    }
}
