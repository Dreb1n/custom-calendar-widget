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
                var trimmed = cmd.trim();
                disconnectSource(trimmed);
                connectSource(trimmed);
            }
        }
    }

    // Static compiled format detection regexes
    readonly property var regexSeconds: /[sX]/i
    readonly property var regexMinutes: /[hHiMN]/i

    // Parsed rows configuration model
    property var rowsData: []

    function updateRowsData() {
        try {
            var isEd = plasmoid.configuration.isEditing;
            var edRows = plasmoid.configuration.editingRowsJson;
            var jsonStr = (isEd && edRows && edRows.length > 0) ? edRows : plasmoid.configuration.rowsJson;
            if (jsonStr && jsonStr.length > 0) {
                rowsData = JSON.parse(jsonStr);
            } else {
                rowsData = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#ffffff", "effectColor": "", "weight": 400, "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": 400, "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#ffffff", "weight": 600, "effect": "none", "opacity": 1.0, "timeZone": "" }
                ];
            }
        } catch (e) {
            console.error("Error parsing rowsJson:", e);
        }
    }

    Component.onCompleted: {
        try {
            plasmoid.configuration.isEditing = false;
            plasmoid.configuration.editingRowsJson = "";
        } catch(e) {}
        updateRowsData();
    }

    Connections {
        target: plasmoid.configuration
        function onRowsJsonChanged() { root.updateRowsData(); }
        function onEditingRowsJsonChanged() { root.updateRowsData(); }
        function onIsEditingChanged() { root.updateRowsData(); }
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

            property int effectiveBgType: (plasmoid.configuration.isEditing && plasmoid.configuration.editingBgType !== -1) ? plasmoid.configuration.editingBgType : (plasmoid.configuration.bgType !== undefined ? plasmoid.configuration.bgType : 2)
            property string effectiveBgColor: (plasmoid.configuration.isEditing && plasmoid.configuration.editingBgColor && plasmoid.configuration.editingBgColor.length > 0) ? plasmoid.configuration.editingBgColor : (plasmoid.configuration.bgColor || "#1e293b")
            property string effectiveFontFamily: (plasmoid.configuration.isEditing && plasmoid.configuration.editingFontFamily && plasmoid.configuration.editingFontFamily.length > 0) ? plasmoid.configuration.editingFontFamily : (plasmoid.configuration.fontFamily || "Sans Serif")

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
                        property string formattedText: ""

                        function calculateNextDelay(fmt, date) {
                            if (!fmt) return 1000;
                            var hasSeconds = root.regexSeconds.test(fmt);
                            var hasMinutes = root.regexMinutes.test(fmt);
                            var ms = date.getMilliseconds();
                            var sec = date.getSeconds();

                            if (hasSeconds) {
                                return Math.max(20, 1000 - ms);
                            } else if (hasMinutes) {
                                return Math.max(100, (60 - sec) * 1000 - ms);
                            } else {
                                return Math.max(1000, (60 - sec) * 1000 - ms);
                            }
                        }

                        function updateRowText() {
                            var now = new Date();
                            formattedText = DateFormatter.format(now, rowItem.format || "", rowItem.timeZone || "", rowItem.locale || "");
                            rowTimer.interval = calculateNextDelay(rowItem.format || "", now);
                        }

                        Timer {
                            id: rowTimer
                            repeat: true
                            running: true
                            onTriggered: {
                                rowContainer.updateRowText();
                            }
                        }

                        Component.onCompleted: {
                            rowContainer.updateRowText();
                        }

                        onRowItemChanged: {
                            rowContainer.updateRowText();
                        }

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

                        // Lazy-loaded Shader Effect (only created if an effect is active)
                        Loader {
                            anchors.fill: mainText
                            active: rowContainer.effType !== "none"
                            sourceComponent: {
                                var t = rowContainer.effType;
                                if (t === "glow") return glowComp;
                                if (t === "shadow") return softShadowComp;
                                if (t === "normalShadow") return normalShadowComp;
                                if (t === "stroke") return strokeComp;
                                return null;
                            }
                        }

                        Component {
                            id: glowComp
                            Glow {
                                source: mainText
                                radius: Math.max(2, rowContainer.effSize * 2)
                                samples: Math.min(32, rowContainer.effSize * 3 + 1)
                                color: rowContainer.effColor
                                transparentBorder: true
                            }
                        }

                        Component {
                            id: softShadowComp
                            DropShadow {
                                source: mainText
                                horizontalOffset: rowContainer.effSize
                                verticalOffset: rowContainer.effSize
                                radius: Math.max(2, rowContainer.effSize)
                                samples: Math.min(32, rowContainer.effSize * 2 + 1)
                                color: rowContainer.effColor
                                transparentBorder: true
                            }
                        }

                        Component {
                            id: normalShadowComp
                            DropShadow {
                                source: mainText
                                horizontalOffset: rowContainer.effSize
                                verticalOffset: rowContainer.effSize
                                radius: 1
                                samples: 3
                                color: rowContainer.effColor
                                transparentBorder: true
                            }
                        }

                        Component {
                            id: strokeComp
                            Glow {
                                source: mainText
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
}
