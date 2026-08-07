import QtQuick 2.15
import QtTest 1.15

TestCase {
    name: "TextEffectMaskTests"

    Component {
        id: textEffectMaskTestComp
        Item {
            id: rootItem
            width: 300
            height: 60

            property string formattedText: "Friday, Aug 7"
            property string fontFam: "Sans Serif"
            property int fontW: 400
            property int fontSize: 28
            property int letterSpacing: 2
            property int hAlign: Text.AlignHCenter

            property string effType: "none"
            property real effSize: 6

            Text {
                id: mainText
                text: rootItem.formattedText
                anchors.fill: parent
                horizontalAlignment: rootItem.hAlign
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: rootItem.fontSize
                font.family: rootItem.fontFam
                font.weight: rootItem.fontW
                font.letterSpacing: rootItem.letterSpacing
            }

            Item {
                id: maskContainer
                property real pad: rootItem.effType === "stroke" ? rootItem.effSize * 2 : 50
                x: -pad
                y: -pad
                width: parent.width + (pad * 2)
                height: parent.height + (pad * 2)

                Text {
                    id: maskText
                    text: rootItem.formattedText
                    anchors.fill: parent
                    anchors.margins: maskContainer.pad
                    horizontalAlignment: rootItem.hAlign
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: rootItem.fontSize
                    font.family: rootItem.fontFam
                    font.weight: rootItem.fontW
                    font.letterSpacing: rootItem.letterSpacing
                }
            }

            function verifyFontMatching() {
                return (mainText.font.pixelSize === maskText.font.pixelSize) &&
                       (mainText.font.family === maskText.font.family) &&
                       (mainText.font.weight === maskText.font.weight) &&
                       (mainText.font.letterSpacing === maskText.font.letterSpacing) &&
                       (mainText.text === maskText.text) &&
                       (mainText.horizontalAlignment === maskText.horizontalAlignment) &&
                       (mainText.verticalAlignment === maskText.verticalAlignment);
            }

            function verifyTextBoundingBox() {
                const innerWidth = maskContainer.width - (maskContainer.pad * 2);
                const innerHeight = maskContainer.height - (maskContainer.pad * 2);
                return (innerWidth === mainText.width) && (innerHeight === mainText.height);
            }
        }
    }

    function test_font_property_mirroring() {
        const item = createTemporaryObject(textEffectMaskTestComp, this, {});
        verify(item.verifyFontMatching(), "Mask text font properties (size, family, weight, spacing, alignment) must mirror main text 1:1");
    }

    function test_mask_bounding_box_alignment() {
        const item = createTemporaryObject(textEffectMaskTestComp, this, {});
        verify(item.verifyTextBoundingBox(), "Mask text inner bounds must match main text dimensions exactly");
    }

    function test_outer_stroke_mask_bounds() {
        const item = createTemporaryObject(textEffectMaskTestComp, this, { effType: "stroke", effSize: 6 });
        verify(item.verifyFontMatching(), "Outer stroke mask text must mirror font metrics 1:1");
        compare(item.verifyTextBoundingBox(), true, "Outer stroke mask inner bounds must match main text dimensions exactly");
    }
}
