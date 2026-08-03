import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects
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

        function sanitizeCommand(cmd) {
            if (!cmd || typeof cmd !== "string") return null;
            var trimmed = cmd.trim();
            if (trimmed.length === 0) return null;

            // Reject command injection attempts containing shell chaining operators
            if (/[;&|`$><\r\n]/.test(trimmed)) {
                console.warn("Custom Calendar Plasmoid: Blocked command containing unsafe shell characters:", trimmed);
                return null;
            }
            return trimmed;
        }

        function exec(cmd) {
            var safeCmd = sanitizeCommand(cmd);
            if (safeCmd) {
                disconnectSource(safeCmd);
                connectSource(safeCmd);
            }
        }
    }

    // Static compiled format detection regexes
    readonly property var regexSeconds: /[sX]/i
    readonly property var regexMinutes: /[hHiMN]/i

    // Consolidated active settings state object computed ONCE when configuration updates
    property var activeSettings: ({
        "isEditing": false,
        "rows": [],
        "fontFamily": "Sans Serif",
        "bgType": 2,
        "bgColor": "#1e293b",
        "bgOpacity": 0.8,
        "borderRadius": 16
    })

    // Cached pre-computed stroke offsets (eliminates GC heap allocation churn)
    readonly property var strokeOffsetsCache: ({})
    function getStrokeOffsets(effSize) {
        var radius = Math.max(1, Math.min(15, Math.round(effSize)));
        if (strokeOffsetsCache[radius]) return strokeOffsetsCache[radius];
        var list = [];
        for (var r = 1; r <= radius; r++) {
            var steps = Math.max(8, r * 4);
            for (var s = 0; s < steps; s++) {
                var angle = s * (2 * Math.PI / steps);
                var ox = Math.round(r * Math.cos(angle));
                var oy = Math.round(r * Math.sin(angle));
                list.push({ "x": ox, "y": oy });
            }
        }
        strokeOffsetsCache[radius] = list;
        return list;
    }

    function updateActiveSettings() {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        var isEd = pCfg ? (pCfg.isEditing === true || pCfg.isEditing === "true") : false;

        var jsonStr = "";
        var fontFam = "";
        var bgT = -1;
        var bgC = "";

        if (isEd) {
            jsonStr = (pCfg && pCfg.editingRowsJson) ? pCfg.editingRowsJson : "";
            fontFam = (pCfg && pCfg.editingFontFamily) ? pCfg.editingFontFamily : "";
            bgT = (pCfg && pCfg.editingBgType !== undefined && pCfg.editingBgType !== -1) ? pCfg.editingBgType : -1;
            bgC = (pCfg && pCfg.editingBgColor) ? pCfg.editingBgColor : "";
        }

        if (!jsonStr) jsonStr = (pCfg && pCfg.rowsJson) ? pCfg.rowsJson : "";
        if (!fontFam) fontFam = (pCfg && pCfg.fontFamily) ? pCfg.fontFamily : "Sans Serif";
        if (bgT === -1) bgT = (pCfg && pCfg.bgType !== undefined) ? pCfg.bgType : 2;
        if (!bgC) bgC = (pCfg && pCfg.bgColor) ? pCfg.bgColor : "#1e293b";

        var parsedRows = [];
        if (jsonStr && jsonStr.trim().length > 0) {
            try {
                parsedRows = JSON.parse(jsonStr);
            } catch(e) {
                console.error("Error parsing rows JSON:", e);
            }
        }
        if (!parsedRows || parsedRows.length === 0) {
            parsedRows = [
                { "format": "dddd", "align": "center", "fontSize": 18, "color": "#ffffff", "effectColor": "", "weight": 400, "effect": "none", "opacity": 1.0, "timeZone": "" },
                { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": 400, "effect": "none", "opacity": 1.0, "timeZone": "" },
                { "format": "H:i", "align": "center", "fontSize": 48, "color": "#ffffff", "weight": 600, "effect": "none", "opacity": 1.0, "timeZone": "" }
            ];
        }

        activeSettings = {
            "isEditing": isEd,
            "rows": parsedRows,
            "fontFamily": fontFam,
            "bgType": bgT,
            "bgColor": bgC,
            "bgOpacity": (pCfg && pCfg.bgOpacity !== undefined) ? pCfg.bgOpacity : 0.8,
            "borderRadius": (pCfg && pCfg.borderRadius !== undefined) ? pCfg.borderRadius : 16
        };
    }

    Component.onCompleted: {
        try {
            if (plasmoid.configuration) {
                plasmoid.configuration.isEditing = false;
                plasmoid.configuration.editingRowsJson = "";
            }
        } catch(e) {}
        updateActiveSettings();
    }

    Connections {
        target: plasmoid.configuration
        ignoreUnknownSignals: true
        function onRowsJsonChanged() { root.updateActiveSettings(); }
        function onEditingRowsJsonChanged() { root.updateActiveSettings(); }
        function onIsEditingChanged() { root.updateActiveSettings(); }
        function onEditingFontFamilyChanged() { root.updateActiveSettings(); }
        function onEditingBgTypeChanged() { root.updateActiveSettings(); }
        function onEditingBgColorChanged() { root.updateActiveSettings(); }
        function onFontFamilyChanged() { root.updateActiveSettings(); }
        function onBgTypeChanged() { root.updateActiveSettings(); }
        function onBgColorChanged() { root.updateActiveSettings(); }
        function onValueChanged(key, value) { root.updateActiveSettings(); }
    }

    Component {
        id: widgetContent

        Item {
            id: fullRepItem
            anchors.fill: parent

            Layout.minimumWidth: Math.max(120, contentColumn.implicitWidth + 32)
            Layout.minimumHeight: Math.max(120, contentColumn.implicitHeight + 32)
            Layout.preferredWidth: Layout.minimumWidth
            Layout.preferredHeight: Layout.minimumHeight
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Custom Background Box (Hidden completely when bgType is 2: Transparent)
            Rectangle {
                id: bgRect
                anchors.fill: parent
                visible: root.activeSettings.bgType !== 2
                radius: root.activeSettings.borderRadius
                color: root.activeSettings.bgColor
                opacity: root.activeSettings.bgOpacity
                border.color: root.activeSettings.bgType === 2 ? "transparent" : "#334155"
                border.width: root.activeSettings.bgType === 2 ? 0 : 1
            }

            // Rows Layout Column Centered in Widget
            ColumnLayout {
                id: contentColumn
                anchors.centerIn: parent
                width: Math.max(100, parent.width - 32)
                spacing: 4

                Repeater {
                    model: root.activeSettings.rows

                    delegate: Item {
                        id: rowContainer
                        property var rowItem: modelData
                        property bool isShapeItem: rowContainer.rowItem && (rowContainer.rowItem.isShape === true || rowContainer.rowItem.isShape === "true") && (!rowContainer.rowItem.format || rowContainer.rowItem.format === "")
                        property real itemRotation: (rowContainer.rowItem && rowContainer.rowItem.rotation !== undefined) ? Number(rowContainer.rowItem.rotation) : 0

                        property real strokeMargin: (rowContainer.isShapeItem && rowContainer.effType === "stroke") ? Math.max(1, rowContainer.effSize) : 0
                        property real unrotatedW: isShapeItem ? ((rowContainer.rowItem.shapeWidth || 100) + strokeMargin * 2) : (mainText ? Math.max(10, mainText.implicitWidth) : 100)
                        property real unrotatedH: isShapeItem ? ((rowContainer.rowItem.shapeHeight || 100) + strokeMargin * 2) : (mainText ? Math.max(10, mainText.implicitHeight) : 30)
                        property real rotRad: itemRotation * Math.PI / 180.0
                        property real boundingW: itemRotation === 0 ? unrotatedW : (Math.abs(Math.cos(rotRad)) * unrotatedW + Math.abs(Math.sin(rotRad)) * unrotatedH)
                        property real boundingH: itemRotation === 0 ? unrotatedH : (Math.abs(Math.sin(rotRad)) * unrotatedW + Math.abs(Math.cos(rotRad)) * unrotatedH)

                        property bool isFromCenter: rowContainer.rowItem && (rowContainer.rowItem.fromCenter === true || rowContainer.rowItem.fromCenter === "true")
                        property real rawOffX: rowContainer.rowItem.offsetWidth !== undefined ? rowContainer.rowItem.offsetWidth : (rowContainer.rowItem.offsetX !== undefined ? rowContainer.rowItem.offsetX : 0)
                        property real rawOffY: rowContainer.rowItem.offsetHeight !== undefined ? rowContainer.rowItem.offsetHeight : (rowContainer.rowItem.topMargin !== undefined ? rowContainer.rowItem.topMargin : 0)

                        width: isFromCenter ? Math.max(10, boundingW) : undefined
                        height: isFromCenter ? Math.max(10, boundingH) : undefined

                        implicitWidth: isFromCenter ? 0 : Math.max(100, boundingW)
                        implicitHeight: isFromCenter ? 0 : Math.max(20, boundingH)
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.fillWidth: !isFromCenter

                        z: index
                        Layout.topMargin: isFromCenter ? 0 : rawOffY

                        transform: Translate {
                            x: rowContainer.isFromCenter ? ((contentColumn.width - rowContainer.width) / 2 + rowContainer.rawOffX - rowContainer.x) : rowContainer.rawOffX
                            y: rowContainer.isFromCenter ? ((contentColumn.height - rowContainer.height) / 2 + rowContainer.rawOffY - rowContainer.y) : 0
                        }

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
                            if (rowContainer.isShapeItem) return;
                            var now = new Date();
                            formattedText = DateFormatter.format(now, rowItem.format || "", rowItem.timeZone || "", rowItem.locale || "");
                            rowTimer.interval = calculateNextDelay(rowItem.format || "", now);
                        }

                        Timer {
                            id: rowTimer
                            repeat: true
                            running: !rowContainer.isShapeItem
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

                        property var fontFam: (rowContainer.rowItem.fontFamily && rowContainer.rowItem.fontFamily.length > 0) ? rowContainer.rowItem.fontFamily : root.activeSettings.fontFamily
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

                        readonly property var strokeOffsets: (rowContainer.isShapeItem || rowContainer.effType !== "stroke") ? [] : root.getStrokeOffsets(rowContainer.effSize)

                        MouseArea {
                            anchors.fill: parent
                            property bool hasValidCmd: executableSource.sanitizeCommand(rowContainer.rowItem.clickCommand) !== null
                            cursorShape: hasValidCmd ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (hasValidCmd) {
                                    executableSource.exec(rowContainer.rowItem.clickCommand);
                                }
                            }
                        }

                        // Unified Hardware SceneGraph Rotator (Positioned in rowContainer by Alignment)
                        Item {
                            id: itemRotator
                            width: rowContainer.unrotatedW
                            height: rowContainer.unrotatedH

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: (rowContainer.rowItem && rowContainer.rowItem.align === "left") ? parent.left : undefined
                            anchors.right: (rowContainer.rowItem && rowContainer.rowItem.align === "right") ? parent.right : undefined
                            anchors.horizontalCenter: (!rowContainer.rowItem || !rowContainer.rowItem.align || rowContainer.rowItem.align === "center") ? parent.horizontalCenter : undefined

                            rotation: rowContainer.itemRotation
                            transformOrigin: Item.Center

                            // Vector Shape Rendering Item (QtQuick.Shapes Hardware SceneGraph with Texture Caching)
                            Shape {
                                id: vectorShape
                                visible: rowContainer.isShapeItem
                                anchors.fill: parent
                                opacity: rowContainer.rowItem.opacity !== undefined ? rowContainer.rowItem.opacity : 1.0
                                asynchronous: true

                                // Enable SceneGraph Hardware Layer Caching for static vector shapes
                                layer.enabled: rowContainer.isShapeItem
                                layer.smooth: true

                                property string sType: rowContainer.rowItem.shapeType || "circle"
                                property color sColor: rowContainer.rowItem.color || "#3b82f6"
                                property int w: width
                                property int h: height

                                readonly property var sidesLookup: ({
                                    "triangle": 3, "pentagon": 5, "hexagon": 6, "heptagon": 7,
                                    "octagon": 8, "nonagon": 9, "decagon": 10
                                })

                                property real m: rowContainer.strokeMargin
                                property real shapeW: rowContainer.rowItem.shapeWidth || 100
                                property real shapeH: rowContainer.rowItem.shapeHeight || 100

                                property string cachedSvgPath: {
                                    var st = vectorShape.sType;
                                    var w = vectorShape.shapeW;
                                    var h = vectorShape.shapeH;
                                    var m = vectorShape.m;
                                    if (w <= 0 || h <= 0) return "";
                                    var cx = m + w / 2;
                                    var cy = m + h / 2;
                                    if (st === "circle" || st === "ellipse" || st === "oblong") {
                                        var rx = w / 2;
                                        var ry = h / 2;
                                        return "M " + cx + " " + (cy - ry) + " A " + rx + " " + ry + " 0 1 0 " + cx + " " + (cy + ry) + " A " + rx + " " + ry + " 0 1 0 " + cx + " " + (cy - ry) + " Z";
                                    }
                                    if (st === "square" || st === "rectangle") {
                                        return "M " + m + " " + m + " L " + (m + w) + " " + m + " L " + (m + w) + " " + (m + h) + " L " + m + " " + (m + h) + " Z";
                                    }
                                    if (st === "pill" || st === "capsule") {
                                        var r = Math.min(w, h) / 2;
                                        if (w >= h) {
                                            return "M " + (m + r) + " " + m + " L " + (m + w - r) + " " + m + " A " + r + " " + r + " 0 0 1 " + (m + w - r) + " " + (m + h) + " L " + (m + r) + " " + (m + h) + " A " + r + " " + r + " 0 0 1 " + (m + r) + " " + m + " Z";
                                        } else {
                                            return "M " + m + " " + (m + r) + " A " + r + " " + r + " 0 0 1 " + (m + w) + " " + (m + r) + " L " + (m + w) + " " + (m + h - r) + " A " + r + " " + r + " 0 0 1 " + m + " " + (m + h - r) + " Z";
                                        }
                                    }
                                    if (st === "triangle") {
                                        return "M " + cx + " " + m + " L " + (m + w) + " " + (m + h) + " L " + m + " " + (m + h) + " Z";
                                    }
                                    var sides = vectorShape.sidesLookup[st] || 3;
                                    var radiusX = w / 2;
                                    var radiusY = h / 2;
                                    var str = "";
                                    for (var i = 0; i < sides; i++) {
                                        var angle = i * (2 * Math.PI / sides) - Math.PI / 2;
                                        var x = cx + radiusX * Math.cos(angle);
                                        var y = cy + radiusY * Math.sin(angle);
                                        if (i === 0) str += "M " + x + " " + y;
                                        else str += " L " + x + " " + y;
                                    }
                                    str += " Z";
                                    return str;
                                }

                                ShapePath {
                                    strokeColor: (rowContainer.effType === "stroke") ? rowContainer.effColor : "transparent"
                                    strokeWidth: (rowContainer.effType === "stroke") ? Math.max(1, rowContainer.effSize * 2) : 0
                                    fillColor: vectorShape.sColor

                                    PathSvg {
                                        path: vectorShape.cachedSvgPath
                                    }
                                }
                            }

                            // Dense Concentric Ring Text Outline (Fills 1px to effSize solidly)
                            Repeater {
                                model: rowContainer.strokeOffsets
                                delegate: Text {
                                    anchors.fill: parent
                                    text: rowContainer.formattedText
                                    opacity: rowContainer.rowItem.opacity !== undefined ? rowContainer.rowItem.opacity : 1.0
                                    horizontalAlignment: rowContainer.hAlign
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: rowContainer.rowItem.fontSize || 24
                                    font.family: rowContainer.fontFam
                                    font.weight: rowContainer.fontW
                                    font.letterSpacing: rowContainer.rowItem.letterSpacing !== undefined ? rowContainer.rowItem.letterSpacing : 0
                                    color: rowContainer.effColor
                                    z: 0

                                    transform: Translate {
                                        x: modelData.x
                                        y: modelData.y
                                    }
                                }
                            }

                            // Main Foreground Vector Text
                            Text {
                                id: mainText
                                visible: !rowContainer.isShapeItem
                                anchors.fill: parent
                                text: rowContainer.formattedText
                                opacity: rowContainer.rowItem.opacity !== undefined ? rowContainer.rowItem.opacity : 1.0
                                horizontalAlignment: rowContainer.hAlign
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: rowContainer.rowItem.fontSize || 24
                                font.family: rowContainer.fontFam
                                font.weight: rowContainer.fontW
                                font.letterSpacing: rowContainer.rowItem.letterSpacing !== undefined ? rowContainer.rowItem.letterSpacing : 0
                                color: rowContainer.rowItem.color || "#ffffff"
                                z: 1
                            }

                            // Lazy-loaded Shader Effect inside itemRotator
                            Loader {
                                anchors.fill: parent
                                active: rowContainer.effType === "glow" || rowContainer.effType === "shadow" || rowContainer.effType === "normalShadow"
                                sourceComponent: {
                                    var t = rowContainer.effType;
                                    if (t === "glow") return glowComp;
                                    if (t === "shadow") return softShadowComp;
                                    if (t === "normalShadow") return normalShadowComp;
                                    return null;
                                }
                            }
                        }

                        property Item activeShaderSource: rowContainer.isShapeItem ? vectorShape : mainText

                        Component {
                            id: glowComp
                            MultiEffect {
                                anchors.fill: parent
                                source: rowContainer.activeShaderSource
                                shadowEnabled: true
                                shadowColor: rowContainer.effColor
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                                shadowBlur: Math.min(1.0, Math.max(0.2, rowContainer.effSize / 5.0))
                                blurEnabled: true
                                blur: Math.min(1.0, Math.max(0.1, rowContainer.effSize / 10.0))
                            }
                        }

                        Component {
                            id: softShadowComp
                            MultiEffect {
                                anchors.fill: parent
                                source: rowContainer.activeShaderSource
                                shadowEnabled: true
                                shadowColor: rowContainer.effColor
                                shadowHorizontalOffset: rowContainer.effSize
                                shadowVerticalOffset: rowContainer.effSize
                                shadowBlur: Math.min(1.0, Math.max(0.2, rowContainer.effSize / 8.0))
                            }
                        }

                        Component {
                            id: normalShadowComp
                            MultiEffect {
                                anchors.fill: parent
                                source: rowContainer.activeShaderSource
                                shadowEnabled: true
                                shadowColor: rowContainer.effColor
                                shadowHorizontalOffset: rowContainer.effSize
                                shadowVerticalOffset: rowContainer.effSize
                                shadowBlur: 0.1
                            }
                        }
                    }
                }
            }
        }
    }
}
