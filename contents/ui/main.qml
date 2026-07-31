import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "DateFormatter.js" as DateFormatter

PlasmoidItem {
    id: root

    // Disable Plasma 6 default system background frame
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    preferredRepresentation: fullRepresentation
    fullRepresentation: widgetContent

    // Current Date/Time state
    property date currentDate: new Date()

    // Timer updating every second
    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentDate = new Date()
        }
    }

    // Parsed rows configuration model
    property var rowsData: []

    function updateRowsData() {
        try {
            var jsonStr = plasmoid.configuration.rowsJson;
            if (jsonStr && jsonStr.length > 0) {
                rowsData = JSON.parse(jsonStr);
            } else {
                rowsData = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#818cf8", "effectColor": "", "weight": 600, "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": 700, "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#38bdf8", "effectColor": "#38bdf8", "weight": 800, "effect": "glow", "opacity": 1.0, "timeZone": "" }
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

            // Custom Background Box (Hidden completely when bgType is 2: Transparent)
            Rectangle {
                id: bgRect
                anchors.fill: parent
                visible: plasmoid.configuration.bgType !== 2
                radius: plasmoid.configuration.borderRadius !== undefined ? plasmoid.configuration.borderRadius : 16
                color: plasmoid.configuration.bgColor || "#1e293b"
                opacity: plasmoid.configuration.bgOpacity !== undefined ? plasmoid.configuration.bgOpacity : 0.8
                border.color: plasmoid.configuration.bgType === 2 ? "transparent" : "#334155"
                border.width: plasmoid.configuration.bgType === 2 ? 0 : 1
            }

            // Rows Layout Column Centered in Widget
            ColumnLayout {
                id: contentColumn
                anchors.centerIn: parent
                width: Math.max(100, parent.width - 32)
                spacing: 4

                Repeater {
                    model: root.rowsData

                    delegate: Text {
                        id: rowText
                        width: contentColumn.width
                        Layout.fillWidth: true

                        property var rowItem: modelData

                        text: DateFormatter.format(root.currentDate, rowItem.format || "", rowItem.timeZone || "")

                        // Per-row Opacity
                        opacity: rowItem.opacity !== undefined ? rowItem.opacity : 1.0

                        // Per-row Alignment
                        horizontalAlignment: {
                            var a = rowItem.align || "center";
                            if (a === "left") return Text.AlignLeft;
                            if (a === "right") return Text.AlignRight;
                            return Text.AlignHCenter;
                        }

                        // Per-row Font Size & Family
                        font.pixelSize: rowItem.fontSize || 24
                        font.family: plasmoid.configuration.fontFamily || "Sans Serif"
                        font.weight: {
                            var w = parseInt(rowItem.weight || 400);
                            if (w >= 900) return Font.Black;
                            if (w >= 700) return Font.Bold;
                            if (w >= 600) return Font.DemiBold;
                            if (w >= 300) return Font.Light;
                            return Font.Normal;
                        }

                        // Per-row Color
                        color: rowItem.color || "#ffffff"

                        // Text Effect (None, Neon Glow, Normal Shadow, Drop Shadow, Outer Stroke)
                        style: {
                            var eff = rowItem.effect || (rowItem.glow ? "glow" : "none");
                            if (eff === "glow" || eff === "stroke") return Text.Outline;
                            if (eff === "shadow") return Text.Sunken;
                            if (eff === "normalShadow") return Text.Raised;
                            return Text.Normal;
                        }

                        styleColor: {
                            var eff = rowItem.effect || (rowItem.glow ? "glow" : "none");
                            if (eff === "none") return "transparent";

                            var customEc = rowItem.effectColor && rowItem.effectColor.length > 0 ? rowItem.effectColor : "";
                            if (customEc !== "") return customEc;

                            if (eff === "glow") return rowItem.color || "#ffffff";
                            if (eff === "stroke") return "#000000";
                            if (eff === "shadow" || eff === "normalShadow") return "#000000";
                            return "transparent";
                        }
                    }
                }
            }
        }
    }
}
