import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

import "DateFormatter.js" as DateFormatter

PlasmoidItem {
    id: root

    // Disable Plasma 6 default system background frame
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    preferredRepresentation: fullRepresentation
    fullRepresentation: widgetContent

    // ExecutableDataSource for launching per-row custom click commands
    Plasma5Support.DataSource {
        id: executableSource
        engine: "executable"
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
        }
        function exec(cmd) {
            if (cmd && cmd.trim().length > 0) {
                connectSource(cmd.trim());
            }
        }
    }

    // Current Date/Time state
    property date currentDate: new Date()

    // Smart battery-saving check: only tick every second if seconds format specifier ('s' or 'X') is present
    property bool hasSeconds: {
        for (var i = 0; i < rowsData.length; i++) {
            var fmt = rowsData[i].format || "";
            if (/[sX]/i.test(fmt)) return true;
        }
        return false;
    }

    // Smart Timer
    Timer {
        id: timer
        interval: root.hasSeconds ? 1000 : 10000
        running: true
        repeat: true
        onTriggered: {
            root.currentDate = new Date()
        }
    }

    // Transient live preview properties (active only while Config dialog is editing)
    property string livePreviewRowsJson: ""
    property string livePreviewFontFamily: ""
    property int livePreviewBgType: -1
    property string livePreviewBgColor: ""

    onLivePreviewRowsJsonChanged: updateRowsData()

    // Parsed rows configuration model
    property var rowsData: []

    function updateRowsData() {
        try {
            var jsonStr = (livePreviewRowsJson && livePreviewRowsJson.length > 0) ? livePreviewRowsJson : plasmoid.configuration.rowsJson;
            if (jsonStr && jsonStr.length > 0) {
                rowsData = JSON.parse(jsonStr);
            } else {
                rowsData = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#ffffff", "effectColor": "", "weight": 400, "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": 400, "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#ffffff", "effectColor": "", "weight": 600, "effect": "none", "opacity": 1.0, "timeZone": "" }
                ];
            }
        } catch (e) {
            console.error("Error parsing rowsJson:", e);
        }
    }

    Component.onCompleted: {
        updateRowsData();
    }

    Connections {
        target: plasmoid.configuration
        function onRowsJsonChanged() {
            root.updateRowsData();
        }
    }

    Component {
        id: widgetContent

        Item {
            id: fullRepItem
            anchors.fill: parent

            Layout.minimumWidth: contentColumn.implicitWidth + 32
            Layout.minimumHeight: contentColumn.implicitHeight + 32
            Layout.preferredWidth: Layout.minimumWidth
            Layout.preferredHeight: Layout.minimumHeight
            Layout.fillWidth: true
            Layout.fillHeight: true

            property int effectiveBgType: root.livePreviewBgType !== -1 ? root.livePreviewBgType : (plasmoid.configuration.bgType !== undefined ? plasmoid.configuration.bgType : 2)
            property string effectiveBgColor: (root.livePreviewBgColor && root.livePreviewBgColor.length > 0) ? root.livePreviewBgColor : (plasmoid.configuration.bgColor || "#1e293b")
            property string effectiveFontFamily: (root.livePreviewFontFamily && root.livePreviewFontFamily.length > 0) ? root.livePreviewFontFamily : (plasmoid.configuration.fontFamily || "Sans Serif")

            // Custom Background Box (Hidden completely when bgType is 2: Transparent)
            Rectangle {
                id: bgRect
                anchors.fill: parent
                visible: fullRepItem.effectiveBgType !== 2
                radius: plasmoid.configuration.borderRadius !== undefined ? plasmoid.configuration.borderRadius : 16
                color: fullRepItem.effectiveBgColor
                opacity: plasmoid.configuration.bgOpacity !== undefined ? plasmoid.configuration.bgOpacity : 0.8
                border.color: fullRepItem.effectiveBgType === 2 ? "transparent" : "#334155"
                border.width: fullRepItem.effectiveBgType === 2 ? 0 : 1
            }

            // Rows Layout Column Centered in Widget
            ColumnLayout {
                id: contentColumn
                anchors.centerIn: parent
                width: Math.max(100, parent.width - 32)
                spacing: 4

                Repeater {
                    model: root.rowsData

                    delegate: Item {
                        id: rowContainer
                        width: contentColumn.width
                        implicitHeight: mainText.implicitHeight
                        Layout.fillWidth: true

                        z: index
                        Layout.topMargin: rowContainer.rowItem.offsetHeight !== undefined ? rowContainer.rowItem.offsetHeight : (rowContainer.rowItem.topMargin !== undefined ? rowContainer.rowItem.topMargin : 0)

                        transform: Translate {
                            x: rowContainer.rowItem.offsetWidth !== undefined ? rowContainer.rowItem.offsetWidth : (rowContainer.rowItem.offsetX !== undefined ? rowContainer.rowItem.offsetX : 0)
                        }

                        property var rowItem: modelData
                        property string formattedText: DateFormatter.format(root.currentDate, rowContainer.rowItem.format || "", rowContainer.rowItem.timeZone || "", rowContainer.rowItem.locale || "")

                        property var fontFam: (rowContainer.rowItem.fontFamily && rowContainer.rowItem.fontFamily.length > 0) ? rowContainer.rowItem.fontFamily : fullRepItem.effectiveFontFamily
                        property int fontW: {
                            var w = parseInt(rowContainer.rowItem.weight || 400);
                            if (w >= 900) return Font.Black;
                            if (w >= 700) return Font.Bold;
                            if (w >= 600) return Font.DemiBold;
                            if (w >= 300) return Font.Light;
                            return Font.Normal;
                        }
                        property int hAlign: {
                            var a = rowContainer.rowItem.align || "center";
                            if (a === "left") return Text.AlignLeft;
                            if (a === "right") return Text.AlignRight;
                            return Text.AlignHCenter;
                        }
                        property color effColor: {
                            var eff = rowContainer.rowItem.effect || (rowContainer.rowItem.glow ? "glow" : "none");
                            if (eff === "none") return "transparent";
                            var customEc = rowContainer.rowItem.effectColor && rowContainer.rowItem.effectColor.length > 0 ? rowContainer.rowItem.effectColor : "";
                            if (customEc !== "") return customEc;
                            if (eff === "glow") return rowContainer.rowItem.color || "#ffffff";
                            return "#000000";
                        }
                        property int effSize: rowContainer.rowItem.effectSize !== undefined ? rowContainer.rowItem.effectSize : 2
                        property string effType: rowContainer.rowItem.effect || (rowContainer.rowItem.glow ? "glow" : "none")

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: (rowContainer.rowItem.clickCommand && rowContainer.rowItem.clickCommand.trim().length > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (rowContainer.rowItem.clickCommand && rowContainer.rowItem.clickCommand.trim().length > 0) {
                                    executableSource.exec(rowContainer.rowItem.clickCommand);
                                }
                            }
                        }

                        // Main Foreground Vector Text
                        Text {
                            id: mainText
                            anchors.fill: parent
                            text: rowContainer.formattedText
                            opacity: rowContainer.rowItem.opacity !== undefined ? rowContainer.rowItem.opacity : 1.0
                            horizontalAlignment: rowContainer.hAlign
                            font.pixelSize: rowContainer.rowItem.fontSize || 24
                            font.family: rowContainer.fontFam
                            font.weight: rowContainer.fontW
                            font.letterSpacing: rowContainer.rowItem.letterSpacing !== undefined ? rowContainer.rowItem.letterSpacing : 0
                            color: rowContainer.rowItem.color || "#ffffff"
                        }

                        // 1. Soft Neon Glow Shader Effect
                        Glow {
                            anchors.fill: mainText
                            source: mainText
                            visible: rowContainer.effType === "glow"
                            radius: Math.max(2, rowContainer.effSize * 2)
                            samples: Math.min(32, rowContainer.effSize * 3 + 1)
                            color: rowContainer.effColor
                            transparentBorder: true
                        }

                        // 2. Soft Drop Shadow Shader Effect
                        DropShadow {
                            anchors.fill: mainText
                            source: mainText
                            visible: rowContainer.effType === "shadow"
                            horizontalOffset: rowContainer.effSize
                            verticalOffset: rowContainer.effSize
                            radius: Math.max(2, rowContainer.effSize)
                            samples: Math.min(32, rowContainer.effSize * 2 + 1)
                            color: rowContainer.effColor
                            transparentBorder: true
                        }

                        // 3. Normal Shadow Shader Effect
                        DropShadow {
                            anchors.fill: mainText
                            source: mainText
                            visible: rowContainer.effType === "normalShadow"
                            horizontalOffset: rowContainer.effSize
                            verticalOffset: rowContainer.effSize
                            radius: 1
                            samples: 3
                            color: rowContainer.effColor
                            transparentBorder: true
                        }

                        // 4. Outer Stroke Shader Effect
                        Glow {
                            anchors.fill: mainText
                            source: mainText
                            visible: rowContainer.effType === "stroke"
                            radius: rowContainer.effSize
                            samples: Math.min(32, rowContainer.effSize * 3 + 1)
                            color: rowContainer.effColor
                            spread: 0.8
                            transparentBorder: true
                        }
                    }
                }
            }
        }
    }
}
