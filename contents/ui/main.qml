import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects
import QtMultimedia
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
    readonly property var regexSeconds: /[sX]/
    readonly property var regexMinutes: /i|MN/
    readonly property var regexHours: /[hHAa]/

    property var currentTime: new Date()

    property bool anyRowHasSeconds: {
        var rows = (activeSettings && activeSettings.rows) ? activeSettings.rows : [];
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i];
            if (r && r.format && regexSeconds.test(r.format)) return true;
        }
        return false;
    }

    Timer {
        id: masterClockTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.currentTime = now;
            var ms = now.getMilliseconds();

            if (root.anyRowHasSeconds) {
                // Phase-lock to top of every second (000ms boundary)
                masterClockTimer.interval = Math.max(10, 1000 - ms);
            } else {
                // Phase-lock to top of every minute (00s 000ms boundary)
                var sec = now.getSeconds();
                masterClockTimer.interval = Math.max(50, (60 - sec) * 1000 - ms);
            }
        }
    }

    // Consolidated active settings state object computed ONCE when configuration updates
    property var activeSettings: ({
        "isEditing": false,
        "rows": [],
        "fontFamily": "Sans Serif",
        "bgType": 2,
        "bgColor": "#1e293b",
        "bgOpacity": 0.8,
        "borderRadius": 16,
        "overlayType": 0,
        "overlayColor": "#000000",
        "overlayOpacity": 0.5,
        "overlayFile": ""
    })

    // In-memory cache for parsed JSON rows to eliminate JSON.parse churn
    property string cachedJsonStr: ""
    property var cachedParsedRows: []

    function updateActiveSettings() {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        var isEd = pCfg ? (pCfg.isEditing === true || pCfg.isEditing === "true") : false;

        var jsonStr = "";
        var fontFam = "";
        var bgT = -1;
        var bgC = "";
        var ovT = -1;
        var ovC = "";
        var ovO = -1.0;
        var ovF = "";

        if (isEd) {
            jsonStr = (pCfg && pCfg.editingRowsJson) ? pCfg.editingRowsJson : "";
            fontFam = (pCfg && pCfg.editingFontFamily) ? pCfg.editingFontFamily : "";
            bgT = (pCfg && pCfg.editingBgType !== undefined && pCfg.editingBgType !== -1) ? pCfg.editingBgType : -1;
            bgC = (pCfg && pCfg.editingBgColor) ? pCfg.editingBgColor : "";
            ovT = (pCfg && pCfg.editingOverlayType !== undefined && pCfg.editingOverlayType !== -1) ? pCfg.editingOverlayType : -1;
            ovC = (pCfg && pCfg.editingOverlayColor) ? pCfg.editingOverlayColor : "";
            ovO = (pCfg && pCfg.editingOverlayOpacity !== undefined && pCfg.editingOverlayOpacity !== -1.0) ? pCfg.editingOverlayOpacity : -1.0;
            ovF = (pCfg && pCfg.editingOverlayFile) ? pCfg.editingOverlayFile : "";
        }

        if (!jsonStr) jsonStr = (pCfg && pCfg.rowsJson) ? pCfg.rowsJson : "";
        if (!fontFam) fontFam = (pCfg && pCfg.fontFamily) ? pCfg.fontFamily : "Sans Serif";
        if (bgT === -1) bgT = (pCfg && pCfg.bgType !== undefined) ? pCfg.bgType : 2;
        if (!bgC) bgC = (pCfg && pCfg.bgColor) ? pCfg.bgColor : "#1e293b";
        if (ovT === -1) ovT = (pCfg && pCfg.overlayType !== undefined) ? pCfg.overlayType : 0;
        if (!ovC) ovC = (pCfg && pCfg.overlayColor) ? pCfg.overlayColor : "#000000";
        if (ovO === -1.0) ovO = (pCfg && pCfg.overlayOpacity !== undefined) ? pCfg.overlayOpacity : 0.5;
        if (!ovF) ovF = (pCfg && pCfg.overlayFile) ? pCfg.overlayFile : "";

        var parsedRows = cachedParsedRows;
        if (jsonStr !== cachedJsonStr) {
            cachedJsonStr = jsonStr;
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
            cachedParsedRows = parsedRows;
        }

        var bgOp = (pCfg && pCfg.bgOpacity !== undefined) ? pCfg.bgOpacity : 0.8;
        var bRad = (pCfg && pCfg.borderRadius !== undefined) ? pCfg.borderRadius : 16;

        // Skip object identity re-creation if all state values are identical
        if (activeSettings.isEditing === isEd &&
            activeSettings.rows === parsedRows &&
            activeSettings.fontFamily === fontFam &&
            activeSettings.bgType === bgT &&
            activeSettings.bgColor === bgC &&
            activeSettings.bgOpacity === bgOp &&
            activeSettings.borderRadius === bRad &&
            activeSettings.overlayType === ovT &&
            activeSettings.overlayColor === ovC &&
            activeSettings.overlayOpacity === ovO &&
            activeSettings.overlayFile === ovF) {
            return;
        }

        activeSettings = {
            "isEditing": isEd,
            "rows": parsedRows,
            "fontFamily": fontFam,
            "bgType": bgT,
            "bgColor": bgC,
            "bgOpacity": bgOp,
            "borderRadius": bRad,
            "overlayType": ovT,
            "overlayColor": ovC,
            "overlayOpacity": ovO,
            "overlayFile": ovF
        };
    }

    Component.onCompleted: {
        try {
            if (plasmoid.configuration) {
                plasmoid.configuration.isEditing = false;
                plasmoid.configuration.editingRowsJson = "";
                plasmoid.configuration.editingOverlayType = -1;
                plasmoid.configuration.editingOverlayColor = "";
                plasmoid.configuration.editingOverlayOpacity = -1.0;
                plasmoid.configuration.editingOverlayFile = "";
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
        function onOverlayTypeChanged() { root.updateActiveSettings(); }
        function onOverlayColorChanged() { root.updateActiveSettings(); }
        function onOverlayOpacityChanged() { root.updateActiveSettings(); }
        function onOverlayFileChanged() { root.updateActiveSettings(); }
        function onEditingOverlayTypeChanged() { root.updateActiveSettings(); }
        function onEditingOverlayColorChanged() { root.updateActiveSettings(); }
        function onEditingOverlayOpacityChanged() { root.updateActiveSettings(); }
        function onEditingOverlayFileChanged() { root.updateActiveSettings(); }
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

                        property real strokeMargin: (rowContainer.effType === "stroke") ? Math.max(1, rowContainer.effSize) : 0
                        property real unrotatedW: isShapeItem ? ((rowContainer.rowItem.shapeWidth || 100) + strokeMargin * 2) : ((mainText ? Math.max(10, mainText.implicitWidth) : 100) + strokeMargin * 2)
                        property real unrotatedH: isShapeItem ? ((rowContainer.rowItem.shapeHeight || 100) + strokeMargin * 2) : ((mainText ? Math.max(10, mainText.implicitHeight) : 30) + strokeMargin * 2)
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

                        property string currentFmt: (rowContainer.rowItem && rowContainer.rowItem.format) ? rowContainer.rowItem.format : ""
                        property string currentTz: (rowContainer.rowItem && rowContainer.rowItem.timeZone) ? rowContainer.rowItem.timeZone : ""
                        property string currentLoc: (rowContainer.rowItem && rowContainer.rowItem.locale) ? rowContainer.rowItem.locale : ""

                        property int lastMin: -1
                        property int lastHr: -1
                        property int lastDay: -1
                        property bool hasSecondsToken: root.regexSeconds.test(currentFmt)
                        property bool hasMinutesToken: root.regexMinutes.test(currentFmt)
                        property bool hasHoursToken: root.regexHours.test(currentFmt)

                        onCurrentFmtChanged: updateRowText(true)
                        onCurrentTzChanged: updateRowText(true)
                        onCurrentLocChanged: updateRowText(true)

                        Connections {
                            target: root
                            function onCurrentTimeChanged() {
                                rowContainer.updateRowText(false);
                            }
                        }

                        function updateRowText(force) {
                            if (rowContainer.isShapeItem || !currentFmt) return;
                            var now = root.currentTime;

                            if (!force && !hasSecondsToken) {
                                if (hasMinutesToken) {
                                    var m = now.getMinutes();
                                    if (m === lastMin && formattedText !== "") return;
                                    lastMin = m;
                                } else if (hasHoursToken) {
                                    var h = now.getHours();
                                    if (h === lastHr && formattedText !== "") return;
                                    lastHr = h;
                                } else {
                                    var d = now.getDate();
                                    if (d === lastDay && formattedText !== "") return;
                                    lastDay = d;
                                }
                            }

                            var newTxt = DateFormatter.format(now, currentFmt, currentTz, currentLoc);
                            if (newTxt !== formattedText) {
                                formattedText = newTxt;
                            }
                        }

                        Component.onCompleted: {
                            rowContainer.updateRowText(true);
                        }

                        onRowItemChanged: {
                            rowContainer.updateRowText(true);
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

                        // Security & Execution Policy:
                        // Users retain 100% freedom to configure custom shell commands, binaries, or scripts for row clicks.
                        // User-authored commands entered in the KCM are trusted.
                        // Third-party JSON layout imports with clickCommands are intercepted by the KCM Security Audit
                        // Scanner (ConfigGeneral.qml), displaying an interactive command review dialog that lets users
                        // inspect, approve, or strip imported commands before saving.
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

                            // Row Overlay Layer Source (Placed inline, but hidden from screen via ShaderEffectSource)
                            Item {
                                id: rowOverlayContent
                                anchors.fill: rowContainer.activeShaderSource
                                visible: rowContainer.rowItem && rowContainer.rowItem.overlayType !== undefined && rowContainer.rowItem.overlayType !== 0

                                // Option 1: Solid Color
                                Rectangle {
                                    anchors.fill: parent
                                    visible: rowContainer.rowItem && rowContainer.rowItem.overlayType === 1
                                    color: (rowContainer.rowItem && rowContainer.rowItem.overlayColor) ? rowContainer.rowItem.overlayColor : "#000000"
                                }

                                // Option 2: Media (Image/Video)
                                Loader {
                                    anchors.fill: parent
                                    visible: rowContainer.rowItem && rowContainer.rowItem.overlayType === 2
                                    sourceComponent: {
                                        if (!rowContainer.rowItem || !rowContainer.rowItem.overlayFile) return null;
                                        var file = String(rowContainer.rowItem.overlayFile);
                                        var isVideo = /\.(mp4|webm|ogv|mov|avi|3gp|mkv)$/i.test(file);
                                        return isVideo ? rowVideoComponent : rowImageComponent;
                                    }
                                }
                            }

                            // Capture live video/color frames and hide the original source from direct layout drawing
                            ShaderEffectSource {
                                id: rowOverlaySourceGrabber
                                sourceItem: rowOverlayContent
                                hideSource: true
                                live: true
                                visible: false
                            }

                            // Render masked overlay texture directly on top of the text/shape
                            MultiEffect {
                                anchors.fill: rowContainer.activeShaderSource
                                source: rowOverlaySourceGrabber
                                visible: rowContainer.rowItem && rowContainer.rowItem.overlayType !== undefined && rowContainer.rowItem.overlayType !== 0
                                opacity: rowContainer.rowItem && rowContainer.rowItem.overlayOpacity !== undefined ? rowContainer.rowItem.overlayOpacity : 0.5
                                maskEnabled: true
                                maskSource: rowContainer.activeShaderSource
                                z: 2
                            }

                            Component {
                                id: rowImageComponent
                                Image {
                                    anchors.fill: parent
                                    source: (rowContainer.rowItem && rowContainer.rowItem.overlayFile) ? rowContainer.rowItem.overlayFile : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }
                            }

                            Component {
                                id: rowVideoComponent
                                Video {
                                    anchors.fill: parent
                                    source: (rowContainer.rowItem && rowContainer.rowItem.overlayFile) ? rowContainer.rowItem.overlayFile : ""
                                    fillMode: VideoOutput.PreserveAspectCrop
                                    loops: MediaPlayer.Infinite
                                    volume: 0
                                    
                                    Component.onCompleted: {
                                        play();
                                    }
                                }
                            }

                            // Vector Shape Rendering Item (QtQuick.Shapes Hardware SceneGraph with Texture Caching)
                            Shape {
                                id: vectorShape
                                visible: rowContainer.isShapeItem
                                anchors.fill: parent
                                opacity: rowContainer.rowItem.opacity !== undefined ? rowContainer.rowItem.opacity : 1.0

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
                                    joinStyle: ShapePath.RoundJoin
                                    capStyle: ShapePath.RoundCap
                                    fillColor: vectorShape.sColor

                                    PathSvg {
                                        path: vectorShape.cachedSvgPath
                                    }
                                }
                            }

                            // True Native Vector RoundJoin Text Stroke Canvas
                            Canvas {
                                id: textStrokeCanvas
                                visible: !rowContainer.isShapeItem && rowContainer.effType === "stroke"
                                layer.enabled: rowContainer.rowItem && rowContainer.rowItem.overlayType !== undefined && rowContainer.rowItem.overlayType !== 0
                                layer.smooth: true
                                property real pad: rowContainer.effSize * 2
                                x: -pad
                                y: -pad
                                width: parent.width + (pad * 2)
                                height: parent.height + (pad * 2)
                                renderTarget: Canvas.Image

                                property string txt: rowContainer.formattedText
                                property string fontFam: rowContainer.fontFam
                                property int fontSize: rowContainer.rowItem.fontSize || 24
                                property int fontWeight: rowContainer.rowItem.weight || 400
                                property color txtColor: rowContainer.rowItem.color || "#ffffff"
                                property color strokeColor: rowContainer.effColor
                                property int strokeWidth: rowContainer.effSize
                                property int hAlign: rowContainer.hAlign

                                onTxtChanged: requestPaint()
                                onFontSizeChanged: requestPaint()
                                onFontFamChanged: requestPaint()
                                onStrokeWidthChanged: requestPaint()
                                onStrokeColorChanged: requestPaint()
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    if (!txt) return;

                                    var wStr = (fontWeight >= 700) ? "bold " : "";
                                    ctx.font = wStr + fontSize + "px " + (fontFam || "sans-serif");

                                    var align = "center";
                                    var cx = width / 2;
                                    if (hAlign === Text.AlignLeft) {
                                        align = "left";
                                        cx = pad;
                                    } else if (hAlign === Text.AlignRight) {
                                        align = "right";
                                        cx = width - pad;
                                    }
                                    ctx.textAlign = align;
                                    ctx.textBaseline = "middle";

                                    var cy = height / 2;

                                    if (strokeWidth > 0) {
                                        ctx.lineWidth = strokeWidth * 2;
                                        ctx.lineJoin = "round";
                                        ctx.lineCap = "round";
                                        ctx.strokeStyle = strokeColor;
                                        ctx.strokeText(txt, cx, cy);
                                    }

                                    ctx.fillStyle = txtColor;
                                    ctx.fillText(txt, cx, cy);
                                }
                            }

                            // Main Foreground Vector Text
                            Text {
                                id: mainText
                                visible: !rowContainer.isShapeItem && rowContainer.effType !== "stroke"
                                anchors.fill: parent
                                layer.enabled: rowContainer.rowItem && rowContainer.rowItem.overlayType !== undefined && rowContainer.rowItem.overlayType !== 0
                                layer.smooth: true
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

                        property Item activeShaderSource: rowContainer.isShapeItem ? vectorShape : (rowContainer.effType === "stroke" ? textStrokeCanvas : mainText)

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
