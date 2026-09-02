import "DateFormatter.js" as DateFormatter
import QtMultimedia
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Static compiled format detection regexes
    readonly property var regexSeconds: /[sX]/
    readonly property var regexMinutes: /i|MN/
    readonly property var regexHours: /[hHAa]/
    property var currentTime: new Date()
    property bool anyRowHasSeconds: {
        const rows = (activeSettings && activeSettings.rows) ? activeSettings.rows : [];
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            if (r && r.format && regexSeconds.test(r.format))
                return true;

        }
        return false;
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
        var ovO = -1;
        var ovF = "";
        if (isEd) {
            jsonStr = (pCfg && pCfg.editingRowsJson) ? pCfg.editingRowsJson : "";
            fontFam = (pCfg && pCfg.editingFontFamily) ? pCfg.editingFontFamily : "";
            bgT = (pCfg && pCfg.editingBgType !== undefined && pCfg.editingBgType !== -1) ? pCfg.editingBgType : -1;
            bgC = (pCfg && pCfg.editingBgColor) ? pCfg.editingBgColor : "";
            ovT = (pCfg && pCfg.editingOverlayType !== undefined && pCfg.editingOverlayType !== -1) ? pCfg.editingOverlayType : -1;
            ovC = (pCfg && pCfg.editingOverlayColor) ? pCfg.editingOverlayColor : "";
            ovO = (pCfg && pCfg.editingOverlayOpacity !== undefined && pCfg.editingOverlayOpacity !== -1) ? pCfg.editingOverlayOpacity : -1;
            ovF = (pCfg && pCfg.editingOverlayFile) ? pCfg.editingOverlayFile : "";
        }
        if (!jsonStr)
            jsonStr = (pCfg && pCfg.rowsJson) ? pCfg.rowsJson : "";

        if (!fontFam)
            fontFam = (pCfg && pCfg.fontFamily) ? pCfg.fontFamily : "Sans Serif";

        if (bgT === -1)
            bgT = (pCfg && pCfg.bgType !== undefined) ? pCfg.bgType : 2;

        if (!bgC)
            bgC = (pCfg && pCfg.bgColor) ? pCfg.bgColor : "#1e293b";

        if (ovT === -1)
            ovT = (pCfg && pCfg.overlayType !== undefined) ? pCfg.overlayType : 0;

        if (!ovC)
            ovC = (pCfg && pCfg.overlayColor) ? pCfg.overlayColor : "#000000";

        if (ovO === -1)
            ovO = (pCfg && pCfg.overlayOpacity !== undefined) ? pCfg.overlayOpacity : 0.5;

        if (!ovF)
            ovF = (pCfg && pCfg.overlayFile) ? pCfg.overlayFile : "";

        var parsedRows = cachedParsedRows;
        if (jsonStr !== cachedJsonStr) {
            cachedJsonStr = jsonStr;
            if (jsonStr && jsonStr.trim().length > 0) {
                try {
                    parsedRows = JSON.parse(jsonStr);
                } catch (e) {
                    console.error("Error parsing rows JSON:", e);
                }
            }
            if (!parsedRows || parsedRows.length === 0)
                parsedRows = [{
                    "format": "dddd",
                    "align": "center",
                    "fontSize": 18,
                    "color": "#ffffff",
                    "effectColor": "",
                    "weight": 400,
                    "effect": "none",
                    "opacity": 1,
                    "timeZone": ""
                }, {
                    "format": "dd mmm yyy",
                    "align": "center",
                    "fontSize": 28,
                    "color": "#ffffff",
                    "effectColor": "",
                    "weight": 400,
                    "effect": "none",
                    "opacity": 1,
                    "timeZone": ""
                }, {
                    "format": "H:i",
                    "align": "center",
                    "fontSize": 48,
                    "color": "#ffffff",
                    "weight": 600,
                    "effect": "none",
                    "opacity": 1,
                    "timeZone": ""
                }];

            // Guarantee every row has a unique incrementing rowId
            var usedRowIds = {};
            for (var rIdx = 0; rIdx < parsedRows.length; rIdx++) {
                var rowObj = parsedRows[rIdx];
                if (!rowObj || typeof rowObj !== "object") continue;
                if (rowObj.rowId === undefined || rowObj.rowId === null || String(rowObj.rowId) === "" || usedRowIds[String(rowObj.rowId)]) {
                    var candidateRowId = rIdx;
                    while (usedRowIds[String(candidateRowId)]) {
                        candidateRowId++;
                    }
                    rowObj.rowId = candidateRowId;
                }
                usedRowIds[String(rowObj.rowId)] = true;
            }

            cachedParsedRows = parsedRows;
        }
        var bgOp = (pCfg && pCfg.bgOpacity !== undefined) ? pCfg.bgOpacity : 0.8;
        var bRad = (pCfg && pCfg.borderRadius !== undefined) ? pCfg.borderRadius : 16;
        // Skip object identity re-creation if all state values are identical
        if (activeSettings.isEditing === isEd && activeSettings.rows === parsedRows && activeSettings.fontFamily === fontFam && activeSettings.bgType === bgT && activeSettings.bgColor === bgC && activeSettings.bgOpacity === bgOp && activeSettings.borderRadius === bRad && activeSettings.overlayType === ovT && activeSettings.overlayColor === ovC && activeSettings.overlayOpacity === ovO && activeSettings.overlayFile === ovF)
            return ;

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

    // Disable Plasma 6 default system background frame
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    fullRepresentation: widgetContent
    Component.onCompleted: {
        try {
            if (plasmoid.configuration) {
                plasmoid.configuration.isEditing = false;
                plasmoid.configuration.editingRowsJson = "";
                plasmoid.configuration.editingOverlayType = -1;
                plasmoid.configuration.editingOverlayColor = "";
                plasmoid.configuration.editingOverlayOpacity = -1;
                plasmoid.configuration.editingOverlayFile = "";
            }
        } catch (e) {
        }
        updateActiveSettings();
    }

    function setWidgetProperty(propName, propVal, targetId) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg)
            return ;

        var myWidgetId = pCfg.widgetId || "";
        if (targetId && targetId !== "" && myWidgetId !== "" && targetId !== myWidgetId)
            return ;

        if (propName === "rowsJson") {
            setRowsJsonUpdate(propVal);
        } else {
            pCfg[propName] = propVal;
            updateActiveSettings();
        }
    }

    function setWidgetProperties(propsObj, targetId) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg || !propsObj)
            return ;

        var myWidgetId = pCfg.widgetId || "";
        if (targetId && targetId !== "" && myWidgetId !== "" && targetId !== myWidgetId)
            return ;

        for (var key in propsObj) {
            if (key === "rowsJson")
                setRowsJsonUpdate(propsObj[key]);
            else
                pCfg[key] = propsObj[key];
        }
        updateActiveSettings();
        return null;
    }

    function getWidgetProperty(propName, targetId) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg)
            return null;

        var myWidgetId = pCfg.widgetId || "";
        if (targetId && targetId !== "" && myWidgetId !== "" && targetId !== myWidgetId)
            return null;

        switch (propName) {
            case "rowsJson":
                return pCfg.rowsJson;
            case "widgetId":
                return myWidgetId;
            default:
                return pCfg[propName] !== undefined ? pCfg[propName] : null;
        }
    }

    function setRowsJsonUpdate(incomingRowsData) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg)
            return ;

        var currentJson = pCfg.rowsJson || "[]";
        var existingRows = [];
        try {
            existingRows = JSON.parse(currentJson);
        } catch (e) {
            existingRows = [];
        }
        var incomingList = incomingRowsData;
        if (typeof incomingRowsData === "string") {
            try {
                incomingList = JSON.parse(incomingRowsData);
            } catch (e) {
                incomingList = [];
            }
        }
        if (!Array.isArray(incomingList))
            return ;

        for (var i = 0; i < incomingList.length; i++) {
            var item = incomingList[i];
            if (!item || typeof item !== "object")
                continue;

            var matchedIndex = -1;
            if (item.rowId !== undefined && item.rowId !== null && String(item.rowId) !== "") {
                var targetRowId = String(item.rowId);
                for (var r = 0; r < existingRows.length; r++) {
                    var exId = existingRows[r].rowId !== undefined ? String(existingRows[r].rowId) : "";
                    if (exId !== "" && exId === targetRowId) {
                        matchedIndex = r;
                        break;
                    }
                }
                if (matchedIndex === -1 && !isNaN(item.rowId)) {
                    var idxNum = parseInt(item.rowId, 10);
                    if (idxNum >= 0 && idxNum < existingRows.length)
                        matchedIndex = idxNum;

                }
            } else if (item.index !== undefined && !isNaN(item.index)) {
                var idx = parseInt(item.index, 10);
                if (idx >= 0 && idx < existingRows.length)
                    matchedIndex = idx;

            } else if (i < existingRows.length) {
                matchedIndex = i;
            }
            if (matchedIndex >= 0 && matchedIndex < existingRows.length) {
                for (var k in item) {
                    existingRows[matchedIndex][k] = item[k];
                    if (k === "icon" && (existingRows[matchedIndex]["format"] === undefined || existingRows[matchedIndex]["format"] === "" || existingRows[matchedIndex]["icon"] !== undefined))
                        existingRows[matchedIndex]["format"] = item[k];

                }
            }
        }
        var updatedJson = JSON.stringify(existingRows);
        pCfg.rowsJson = updatedJson;
        updateActiveSettings();
    }

    function getRowProperty(rowId, propName, targetId) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg)
            return null;

        var myWidgetId = pCfg.widgetId || "";
        if (targetId && targetId !== "" && myWidgetId !== "" && targetId !== myWidgetId)
            return null;

        var rows = (activeSettings && activeSettings.rows) ? activeSettings.rows : [];
        var targetStr = String(rowId);
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i];
            var rId = (r && r.rowId !== undefined && r.rowId !== null) ? String(r.rowId) : String(i);
            if (rId === targetStr) {
                if (!propName || propName === "")
                    return JSON.stringify(r);
                return r[propName] !== undefined ? r[propName] : null;
            }
        }
        return null;
    }

    function addRow(rowObjOrJson, targetId) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg)
            return null;

        var myWidgetId = pCfg.widgetId || "";
        if (targetId && targetId !== "" && myWidgetId !== "" && targetId !== myWidgetId)
            return null;

        var currentJson = pCfg.rowsJson || "[]";
        var existingRows = [];
        try {
            existingRows = JSON.parse(currentJson);
        } catch (e) {
            existingRows = [];
        }

        var newRow = rowObjOrJson;
        if (typeof rowObjOrJson === "string") {
            try {
                newRow = JSON.parse(rowObjOrJson);
            } catch (e) {
                return null;
            }
        }

        if (!newRow || typeof newRow !== "object")
            return null;

        if (newRow.rowId === undefined || newRow.rowId === null || String(newRow.rowId) === "") {
            var maxId = -1;
            for (var i = 0; i < existingRows.length; i++) {
                var curId = parseInt(existingRows[i].rowId, 10);
                if (!isNaN(curId) && curId > maxId) maxId = curId;
            }
            var candidateId = maxId + 1;
            while (existingRows.some(function(r) { return r && String(r.rowId) === String(candidateId); })) {
                candidateId++;
            }
            newRow.rowId = candidateId;
        }

        existingRows.push(newRow);
        pCfg.rowsJson = JSON.stringify(existingRows);
        updateActiveSettings();
        return newRow.rowId;
    }

    function removeRow(rowId, targetId) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg)
            return false;

        var myWidgetId = pCfg.widgetId || "";
        if (targetId && targetId !== "" && myWidgetId !== "" && targetId !== myWidgetId)
            return false;

        var currentJson = pCfg.rowsJson || "[]";
        var existingRows = [];
        try {
            existingRows = JSON.parse(currentJson);
        } catch (e) {
            return false;
        }

        var targetStr = String(rowId);
        var removed = false;
        var newRows = [];
        for (var i = 0; i < existingRows.length; i++) {
            var rId = (existingRows[i].rowId !== undefined && existingRows[i].rowId !== null) ? String(existingRows[i].rowId) : String(i);
            if (rId === targetStr) {
                removed = true;
            } else {
                newRows.push(existingRows[i]);
            }
        }

        if (removed) {
            pCfg.rowsJson = JSON.stringify(newRows);
            updateActiveSettings();
        }
        return removed;
    }

    function setRowProperty(rowId, propName, propVal, targetId) {
        var pCfg = (plasmoid && plasmoid.configuration) ? plasmoid.configuration : null;
        if (!pCfg || !propName)
            return false;

        var myWidgetId = pCfg.widgetId || "";
        if (targetId && targetId !== "" && myWidgetId !== "" && targetId !== myWidgetId)
            return false;

        var updateObj = { "rowId": rowId };
        updateObj[propName] = propVal;
        setRowsJsonUpdate([updateObj]);
        return true;
    }

    // ExecutableDataSource for launching per-row custom click commands
    Plasma5Support.DataSource {
        id: executableSource

        function sanitizeCommand(cmd) {
            if (!cmd || typeof cmd !== "string")
                return null;

            const trimmed = cmd.trim();
            if (trimmed.length === 0)
                return null;

            return trimmed;
        }

        function exec(cmd) {
            const safeCmd = sanitizeCommand(cmd);
            if (safeCmd) {
                const execStr = "sh -c " + JSON.stringify(safeCmd);
                disconnectSource(execStr);
                connectSource(execStr);
            }
        }

        engine: "executable"
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
        }
    }

    function tickClock() {
        const now = new Date();
        root.currentTime = now;
        const ms = now.getMilliseconds();
        if (root.anyRowHasSeconds) {
            // Phase-lock to top of every second (000ms boundary)
            masterClockTimer.interval = Math.max(10, 1000 - ms);
        } else {
            // Phase-lock to top of every minute (00s 000ms boundary)
            const sec = now.getSeconds();
            masterClockTimer.interval = Math.max(50, (60 - sec) * 1000 - ms);
        }
    }

    Timer {
        id: masterClockTimer

        interval: 1000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.tickClock()
    }

    onVisibleChanged: {
        if (root.visible) {
            root.tickClock();
        }
    }

    Connections {
        function onRowsJsonChanged() {
            root.updateActiveSettings();
        }

        function onEditingRowsJsonChanged() {
            root.updateActiveSettings();
        }

        function onIsEditingChanged() {
            root.updateActiveSettings();
        }

        function onEditingFontFamilyChanged() {
            root.updateActiveSettings();
        }

        function onEditingBgTypeChanged() {
            root.updateActiveSettings();
        }

        function onEditingBgColorChanged() {
            root.updateActiveSettings();
        }

        function onFontFamilyChanged() {
            root.updateActiveSettings();
        }

        function onBgTypeChanged() {
            root.updateActiveSettings();
        }

        function onBgColorChanged() {
            root.updateActiveSettings();
        }

        function onOverlayTypeChanged() {
            root.updateActiveSettings();
        }

        function onOverlayColorChanged() {
            root.updateActiveSettings();
        }

        function onOverlayOpacityChanged() {
            root.updateActiveSettings();
        }

        function onOverlayFileChanged() {
            root.updateActiveSettings();
        }

        function onEditingOverlayTypeChanged() {
            root.updateActiveSettings();
        }

        function onEditingOverlayColorChanged() {
            root.updateActiveSettings();
        }

        function onEditingOverlayOpacityChanged() {
            root.updateActiveSettings();
        }

        function onEditingOverlayFileChanged() {
            root.updateActiveSettings();
        }

        target: plasmoid.configuration
        ignoreUnknownSignals: true
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
                    // Security & Execution Policy:
                    // Users retain 100% freedom to configure custom shell commands, binaries, or scripts for row clicks.
                    // User-authored commands entered in the KCM are trusted.
                    // Third-party JSON layout imports with clickCommands are intercepted by the KCM Security Audit
                    // Scanner (ConfigGeneral.qml), displaying an interactive command review dialog that lets users
                    // inspect, approve, or strip imported commands before saving.

                    model: root.activeSettings.rows

                    delegate: Item {
                        id: rowContainer

                        property var rowItem: modelData
                        property bool isShapeItem: rowContainer.rowItem && (rowContainer.rowItem.isShape === true || rowContainer.rowItem.isShape === "true") && (!rowContainer.rowItem.format || rowContainer.rowItem.format === "")
                        property real itemRotation: (rowContainer.rowItem && rowContainer.rowItem.rotation !== undefined) ? Number(rowContainer.rowItem.rotation) : 0
                        property real strokeMargin: 0
                        property real unrotatedW: isShapeItem ? (rowContainer.rowItem.shapeWidth || 100) : (mainText ? Math.max(10, mainText.implicitWidth) : 100)
                        property real unrotatedH: isShapeItem ? (rowContainer.rowItem.shapeHeight || 100) : (mainText ? Math.max(10, mainText.implicitHeight) : 30)
                        property real rotRad: itemRotation * Math.PI / 180
                        property real boundingW: itemRotation === 0 ? Math.ceil(unrotatedW) : Math.ceil(Math.abs(Math.cos(rotRad)) * unrotatedW + Math.abs(Math.sin(rotRad)) * unrotatedH)
                        property real boundingH: itemRotation === 0 ? Math.ceil(unrotatedH) : Math.ceil(Math.abs(Math.sin(rotRad)) * unrotatedW + Math.abs(Math.cos(rotRad)) * unrotatedH)
                        property bool isFromCenter: rowContainer.rowItem && (rowContainer.rowItem.fromCenter === true || rowContainer.rowItem.fromCenter === "true")
                        property real rawOffX: rowContainer.rowItem.offsetWidth !== undefined ? rowContainer.rowItem.offsetWidth : (rowContainer.rowItem.offsetX !== undefined ? rowContainer.rowItem.offsetX : 0)
                        property real rawOffY: rowContainer.rowItem.offsetHeight !== undefined ? rowContainer.rowItem.offsetHeight : (rowContainer.rowItem.topMargin !== undefined ? rowContainer.rowItem.topMargin : 0)
                        property string formattedText: ""
                        property string formattedOverlayFile: {
                            if (!rowContainer.rowItem || !rowContainer.rowItem.overlayFile)
                                return "";

                            var file = String(rowContainer.rowItem.overlayFile).trim();
                            if (file === "")
                                return "";

                            if (file.indexOf(":/") === -1 && file.indexOf("/") === 0)
                                return "file://" + file;

                            return file;
                        }
                        property string currentFmt: (rowContainer.rowItem && rowContainer.rowItem.format) ? rowContainer.rowItem.format : ""
                        property string currentTz: (rowContainer.rowItem && rowContainer.rowItem.timeZone) ? rowContainer.rowItem.timeZone : ""
                        property string currentLoc: (rowContainer.rowItem && rowContainer.rowItem.locale) ? rowContainer.rowItem.locale : ""
                        property int lastMin: -1
                        property int lastHr: -1
                        property int lastDay: -1
                        property bool hasSecondsToken: root.regexSeconds.test(currentFmt)
                        property bool hasMinutesToken: root.regexMinutes.test(currentFmt)
                        property bool hasHoursToken: root.regexHours.test(currentFmt)
                        property var fontFam: (rowContainer.rowItem.fontFamily && rowContainer.rowItem.fontFamily.length > 0) ? rowContainer.rowItem.fontFamily : root.activeSettings.fontFamily
                        property int fontW: {
                            var w = parseInt(rowContainer.rowItem.weight || 400);
                            if (w >= 900)
                                return Font.Black;

                            if (w >= 700)
                                return Font.Bold;

                            if (w >= 600)
                                return Font.DemiBold;

                            if (w >= 300)
                                return Font.Light;

                            return Font.Normal;
                        }
                        property int hAlign: {
                            var a = rowContainer.rowItem.align || "center";
                            if (a === "left")
                                return Text.AlignLeft;

                            if (a === "right")
                                return Text.AlignRight;

                            return Text.AlignHCenter;
                        }
                        property color effColor: {
                            var eff = rowContainer.rowItem.effect || (rowContainer.rowItem.glow ? "glow" : "none");
                            if (eff === "none")
                                return "transparent";

                            var customEc = rowContainer.rowItem.effectColor && rowContainer.rowItem.effectColor.length > 0 ? rowContainer.rowItem.effectColor : "";
                            if (customEc !== "")
                                return customEc;

                            if (eff === "glow")
                                return rowContainer.rowItem.color || "#ffffff";

                            return "#000000";
                        }
                        property int effSize: rowContainer.rowItem.effectSize !== undefined ? rowContainer.rowItem.effectSize : 2
                        property string effType: rowContainer.rowItem.effect || (rowContainer.rowItem.glow ? "glow" : "none")
                        property Item activeShaderSource: rowContainer.isShapeItem ? vectorShape : mainText
                        property Item overlayMaskSource: rowContainer.isShapeItem ? vectorShape : rowMaskTextureGrabber
                        property Item overlayPaddedMaskSource: rowContainer.isShapeItem ? vectorShape : rowPaddedMaskTextureGrabber

                        function updateRowText(force) {
                            if (rowContainer.isShapeItem || !currentFmt)
                                return ;

                            var now = root.currentTime;
                            if (!force && !hasSecondsToken) {
                                if (hasMinutesToken) {
                                    var m = now.getMinutes();
                                    if (m === lastMin && formattedText !== "")
                                        return ;

                                    lastMin = m;
                                } else if (hasHoursToken) {
                                    var h = now.getHours();
                                    if (h === lastHr && formattedText !== "")
                                        return ;

                                    lastHr = h;
                                } else {
                                    var d = now.getDate();
                                    if (d === lastDay && formattedText !== "")
                                        return ;

                                    lastDay = d;
                                }
                            }
                            var newTxt = DateFormatter.format(now, currentFmt, currentTz, currentLoc);
                            if (newTxt !== formattedText)
                                formattedText = newTxt;

                        }

                        width: isFromCenter ? Math.max(10, boundingW) : undefined
                        height: isFromCenter ? Math.max(10, boundingH) : undefined
                        implicitWidth: isFromCenter ? 0 : Math.max(100, boundingW)
                        implicitHeight: isFromCenter ? 0 : Math.max(20, boundingH)
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.fillWidth: !isFromCenter
                        z: index
                        Layout.topMargin: isFromCenter ? 0 : rawOffY
                        onCurrentFmtChanged: updateRowText(true)
                        onCurrentTzChanged: updateRowText(true)
                        onCurrentLocChanged: updateRowText(true)
                        Component.onCompleted: {
                            rowContainer.updateRowText(true);
                        }
                        onRowItemChanged: {
                            rowContainer.updateRowText(true);
                        }

                        Connections {
                            function onCurrentTimeChanged() {
                                rowContainer.updateRowText(false);
                            }

                            target: root
                        }

                        property bool hasValidCmd: rowContainer.rowItem && rowContainer.rowItem.clickCommand && rowContainer.rowItem.clickCommand.trim().length > 0

                        function contains(point) {
                            if (!hasValidCmd)
                                return false;

                            var pInRotator = itemRotator.mapFromItem(rowContainer, point);
                            return pInRotator.x >= 0 && pInRotator.x <= itemRotator.width && pInRotator.y >= 0 && pInRotator.y <= itemRotator.height;
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

                            // Click Handler positioned directly inside the rotated/offset container
                            MouseArea {
                                property bool clickAllowed: true

                                enabled: rowContainer.hasValidCmd
                                hoverEnabled: true
                                z: 10
                                anchors.fill: parent
                                cursorShape: rowContainer.hasValidCmd ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (rowContainer.hasValidCmd && clickAllowed) {
                                        clickAllowed = false;
                                        clickDebounceTimer.start();
                                        executableSource.exec(rowContainer.rowItem.clickCommand);
                                    }
                                }

                                Timer {
                                    id: clickDebounceTimer

                                    interval: 350
                                    repeat: false
                                    onTriggered: parent.clickAllowed = true
                                }

                            }

                            // Row Overlay Layer Source (Placed inline, but hidden from screen via ShaderEffectSource)
                            Item {
                                id: rowOverlayContent

                                property real pad: rowContainer.isShapeItem ? 0 : 50

                                x: -pad
                                y: -pad
                                width: parent.width + (pad * 2)
                                height: parent.height + (pad * 2)
                                visible: rowContainer.rowItem && rowContainer.rowItem.overlayType !== undefined && rowContainer.rowItem.overlayType !== 0

                                // Option 1: Solid Color
                                Rectangle {
                                    id: rowOverlayColorRect

                                    anchors.fill: parent
                                    visible: rowContainer.rowItem && rowContainer.rowItem.overlayType === 1
                                    color: (rowContainer.rowItem && rowContainer.rowItem.overlayColor) ? rowContainer.rowItem.overlayColor : "#000000"
                                }

                                // Option 2: Media (Image/Video)
                                Loader {
                                    id: rowOverlayMediaLoader

                                    anchors.fill: parent
                                    visible: rowContainer.rowItem && rowContainer.rowItem.overlayType === 2
                                    sourceComponent: {
                                        if (!rowContainer.rowItem || !rowContainer.formattedOverlayFile)
                                            return null;

                                        var file = rowContainer.formattedOverlayFile;
                                        var isVideo = /\.(mp4|webm|ogv|mov|avi|3gp|mkv)$/i.test(file);
                                        return isVideo ? rowVideoComponent : rowImageComponent;
                                    }
                                }

                            }

                            // Capture live video/color frames and hide the original source from direct layout drawing
                            ShaderEffectSource {
                                id: rowOverlaySourceGrabber

                                sourceItem: {
                                    if (!rowContainer.rowItem)
                                        return null;

                                    if (rowContainer.rowItem.overlayType === 1)
                                        return rowOverlayColorRect;

                                    if (rowContainer.rowItem.overlayType === 2) {
                                        var it = rowOverlayMediaLoader.item;
                                        if (!it)
                                            return null;

                                        return it.videoSink !== undefined ? it.videoSink : it;
                                    }
                                    return null;
                                }
                                width: sourceItem ? sourceItem.width : 0
                                height: sourceItem ? sourceItem.height : 0
                                hideSource: true
                                live: (rowContainer.rowItem !== undefined && rowContainer.rowItem !== null && rowContainer.rowItem.overlayType === 2)
                                visible: false
                            }

                            // Render masked overlay texture directly on top of the text/shape
                            MultiEffect {
                                id: rowOverlayMultiEffect

                                property real pad: rowContainer.isShapeItem ? 0 : 50

                                x: -pad
                                y: -pad
                                width: parent.width + (pad * 2)
                                height: parent.height + (pad * 2)
                                source: rowOverlaySourceGrabber
                                visible: rowContainer.rowItem && rowContainer.rowItem.overlayType !== undefined && rowContainer.rowItem.overlayType !== 0
                                opacity: rowContainer.rowItem && rowContainer.rowItem.overlayOpacity !== undefined ? rowContainer.rowItem.overlayOpacity : 0.5
                                maskEnabled: true
                                maskSource: rowContainer.overlayMaskSource
                                autoPaddingEnabled: false
                                z: 2
                            }

                            Component {
                                id: rowImageComponent

                                Image {
                                    anchors.fill: parent
                                    source: rowContainer.formattedOverlayFile
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                            }

                            Component {
                                id: rowVideoComponent

                                Item {
                                    property Item videoSink: videoOutput

                                    anchors.fill: parent

                                    MediaPlayer {
                                        id: rowMediaPlayer

                                        source: rowContainer.formattedOverlayFile
                                        videoOutput: videoOutput
                                        loops: MediaPlayer.Infinite
                                        Component.onCompleted: {
                                            play();
                                        }

                                        audioOutput: AudioOutput {
                                            volume: 0
                                        }

                                    }

                                    VideoOutput {
                                        id: videoOutput

                                        anchors.fill: parent
                                        fillMode: VideoOutput.PreserveAspectCrop
                                        visible: false
                                        layer.enabled: true
                                        layer.smooth: true
                                    }

                                    Connections {
                                        function onFormattedOverlayFileChanged() {
                                            rowMediaPlayer.play();
                                        }

                                        target: rowContainer
                                    }

                                }

                            }

                            // Vector Shape Rendering Item (QtQuick.Shapes Hardware SceneGraph with Texture Caching)
                            Shape {
                                id: vectorShape

                                property string sType: rowContainer.rowItem.shapeType || "circle"
                                property color sColor: rowContainer.rowItem.color || "#3b82f6"
                                property int w: width
                                property int h: height
                                readonly property var sidesLookup: ({
                                    "triangle": 3,
                                    "pentagon": 5,
                                    "hexagon": 6,
                                    "heptagon": 7,
                                    "octagon": 8,
                                    "nonagon": 9,
                                    "decagon": 10
                                })
                                property real m: rowContainer.strokeMargin
                                property real shapeW: rowContainer.rowItem.shapeWidth || 100
                                property real shapeH: rowContainer.rowItem.shapeHeight || 100
                                property string cachedSvgPath: {
                                    var st = vectorShape.sType;
                                    var rawW = Math.round(vectorShape.shapeW);
                                    var rawH = Math.round(vectorShape.shapeH);
                                    if (rawW <= 0 || rawH <= 0)
                                        return "";

                                    // Force even integer dimensions via bitwise AND so w / 2 and h / 2 are exact whole integers
                                    var w = rawW & ~1;
                                    var h = rawH & ~1;
                                    if (w <= 0 || h <= 0)
                                        return "";
                                    var m = Math.round(vectorShape.m);

                                    var cx = m + (w / 2);
                                    var cy = m + (h / 2);
                                    if (st === "circle" || st === "ellipse" || st === "oblong") {
                                        var rx = w / 2;
                                        var ry = h / 2;
                                        return "M " + cx + " " + (cy - ry) + " A " + rx + " " + ry + " 0 1 0 " + cx + " " + (cy + ry) + " A " + rx + " " + ry + " 0 1 0 " + cx + " " + (cy - ry) + " Z";
                                    }
                                    if (st === "square" || st === "rectangle")
                                        return "M " + m + " " + m + " L " + (m + w) + " " + m + " L " + (m + w) + " " + (m + h) + " L " + m + " " + (m + h) + " Z";

                                    if (st === "pill" || st === "capsule") {
                                        var minDim = Math.min(w, h);
                                        var evenMin = minDim & ~1;
                                        var r = evenMin / 2;
                                        if (w >= h)
                                            return "M " + (m + r) + " " + m + " L " + (m + w - r) + " " + m + " A " + r + " " + r + " 0 0 1 " + (m + w - r) + " " + (m + h) + " L " + (m + r) + " " + (m + h) + " A " + r + " " + r + " 0 0 1 " + (m + r) + " " + m + " Z";
                                        else
                                            return "M " + m + " " + (m + r) + " A " + r + " " + r + " 0 0 1 " + (m + w) + " " + (m + r) + " L " + (m + w) + " " + (m + h - r) + " A " + r + " " + r + " 0 0 1 " + m + " " + (m + h - r) + " Z";
                                    }
                                    if (st === "triangle")
                                        return "M " + cx + " " + m + " L " + (m + w) + " " + (m + h) + " L " + m + " " + (m + h) + " Z";

                                    var sides = vectorShape.sidesLookup[st] || 3;
                                    var radiusX = w / 2;
                                    var radiusY = h / 2;
                                    var str = "";
                                    for (var i = 0; i < sides; i++) {
                                        var angle = i * (2 * Math.PI / sides) - Math.PI / 2;
                                        var x = Math.round(cx + radiusX * Math.cos(angle));
                                        var y = Math.round(cy + radiusY * Math.sin(angle));
                                        if (i === 0)
                                            str += "M " + x + " " + y;
                                        else
                                            str += " L " + x + " " + y;
                                    }
                                    str += " Z";
                                    return str;
                                }

                                visible: rowContainer.isShapeItem
                                anchors.fill: parent
                                opacity: rowContainer.rowItem.opacity !== undefined ? rowContainer.rowItem.opacity : 1
                                // Enable SceneGraph Hardware Layer Caching for static vector shapes
                                layer.enabled: rowContainer.isShapeItem
                                layer.smooth: true

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

                            // Native QML Text Outer Stroke Container (dilated native QML Text items for 100% pixel-perfect font metric alignment)
                            Item {
                                id: mainTextStrokeContainer

                                property real pad: rowContainer.effSize * 2

                                visible: !rowContainer.isShapeItem && rowContainer.effType === "stroke" && rowContainer.effSize > 0
                                x: -pad
                                y: -pad
                                width: parent.width + (pad * 2)
                                height: parent.height + (pad * 2)
                                opacity: rowContainer.rowItem && rowContainer.rowItem.effectOpacity !== undefined ? rowContainer.rowItem.effectOpacity : 1

                                Repeater {
                                    model: [{
                                        "dx": -1,
                                        "dy": 0
                                    }, {
                                        "dx": 1,
                                        "dy": 0
                                    }, {
                                        "dx": 0,
                                        "dy": -1
                                    }, {
                                        "dx": 0,
                                        "dy": 1
                                    }, {
                                        "dx": -0.92,
                                        "dy": -0.38
                                    }, {
                                        "dx": 0.92,
                                        "dy": -0.38
                                    }, {
                                        "dx": -0.92,
                                        "dy": 0.38
                                    }, {
                                        "dx": 0.92,
                                        "dy": 0.38
                                    }, {
                                        "dx": -0.38,
                                        "dy": -0.92
                                    }, {
                                        "dx": 0.38,
                                        "dy": -0.92
                                    }, {
                                        "dx": -0.38,
                                        "dy": 0.92
                                    }, {
                                        "dx": 0.38,
                                        "dy": 0.92
                                    }, {
                                        "dx": -0.707,
                                        "dy": -0.707
                                    }, {
                                        "dx": 0.707,
                                        "dy": -0.707
                                    }, {
                                        "dx": -0.707,
                                        "dy": 0.707
                                    }, {
                                        "dx": 0.707,
                                        "dy": 0.707
                                    }]

                                    Text {
                                        x: mainTextStrokeContainer.pad + (modelData.dx * rowContainer.effSize)
                                        y: mainTextStrokeContainer.pad + (modelData.dy * rowContainer.effSize)
                                        width: parent.width - (mainTextStrokeContainer.pad * 2)
                                        height: parent.height - (mainTextStrokeContainer.pad * 2)
                                        text: rowContainer.formattedText
                                        horizontalAlignment: rowContainer.hAlign
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: rowContainer.rowItem.fontSize || 24
                                        font.family: rowContainer.fontFam
                                        font.weight: rowContainer.fontW
                                        font.letterSpacing: rowContainer.rowItem.letterSpacing !== undefined ? rowContainer.rowItem.letterSpacing : 0
                                        color: rowContainer.effColor
                                    }

                                }

                            }

                            // Hidden unpadded text mask for the overlay
                            Item {
                                id: mainTextMaskUnpaddedContainer

                                property real pad: rowContainer.isShapeItem ? 0 : 50

                                x: -pad
                                y: -pad
                                width: parent.width + (pad * 2)
                                height: parent.height + (pad * 2)
                                visible: true

                                Text {
                                    id: mainTextMaskUnpadded

                                    text: rowContainer.formattedText
                                    anchors.fill: parent
                                    anchors.margins: mainTextMaskUnpaddedContainer.pad
                                    horizontalAlignment: rowContainer.hAlign
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: rowContainer.rowItem.fontSize || 24
                                    font.family: rowContainer.fontFam
                                    font.weight: rowContainer.fontW
                                    font.letterSpacing: rowContainer.rowItem.letterSpacing !== undefined ? rowContainer.rowItem.letterSpacing : 0
                                    color: "#ffffff"
                                }

                            }

                            ShaderEffectSource {
                                id: rowMaskTextureGrabber

                                sourceItem: mainTextMaskUnpaddedContainer
                                width: mainTextMaskUnpaddedContainer.width
                                height: mainTextMaskUnpaddedContainer.height
                                hideSource: true
                                live: (rowContainer.rowItem !== undefined && rowContainer.rowItem !== null && rowContainer.rowItem.overlayType > 0)
                                visible: false
                            }

                            // Hidden padded text element container that is always white and fully opaque to serve as a perfect mask
                            Item {
                                id: mainTextMaskContainer

                                property real pad: rowContainer.effType !== "none" ? rowContainer.effSize * 2 : 0

                                x: -pad
                                y: -pad
                                width: parent.width + (pad * 2)
                                height: parent.height + (pad * 2)
                                visible: true

                                Text {
                                    id: mainTextMask

                                    text: rowContainer.formattedText
                                    anchors.fill: parent
                                    anchors.margins: mainTextMaskContainer.pad
                                    horizontalAlignment: rowContainer.hAlign
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: rowContainer.rowItem.fontSize || 24
                                    font.family: rowContainer.fontFam
                                    font.weight: rowContainer.fontW
                                    font.letterSpacing: rowContainer.rowItem.letterSpacing !== undefined ? rowContainer.rowItem.letterSpacing : 0
                                    color: "#ffffff"
                                }

                            }

                            ShaderEffectSource {
                                id: rowPaddedMaskTextureGrabber

                                sourceItem: mainTextMaskContainer
                                width: mainTextMaskContainer.width
                                height: mainTextMaskContainer.height
                                hideSource: true
                                live: (rowContainer.effType !== "none" && rowContainer.effType !== "stroke")
                                visible: false
                            }

                            // Main Foreground Vector Text
                            Text {
                                id: mainText

                                visible: !rowContainer.isShapeItem
                                anchors.fill: parent
                                text: rowContainer.formattedText
                                opacity: rowContainer.rowItem.opacity !== undefined ? rowContainer.rowItem.opacity : 1
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
                                property real pad: rowContainer.effType !== "none" ? rowContainer.effSize * 2 : 0

                                x: -pad
                                y: -pad
                                width: parent.width + (pad * 2)
                                height: parent.height + (pad * 2)
                                opacity: rowContainer.rowItem && rowContainer.rowItem.effectOpacity !== undefined ? rowContainer.rowItem.effectOpacity : 1
                                active: rowContainer.effType === "glow" || rowContainer.effType === "shadow" || rowContainer.effType === "normalShadow"
                                sourceComponent: {
                                    var t = rowContainer.effType;
                                    if (t === "glow")
                                        return glowComp;

                                    if (t === "shadow")
                                        return softShadowComp;

                                    if (t === "normalShadow")
                                        return normalShadowComp;

                                    return null;
                                }
                            }

                            transform: Translate {
                                x: rowContainer.isFromCenter ? (((Math.round(contentColumn.width - itemRotator.width) & ~1) / 2) + Math.round(rowContainer.rawOffX) - Math.round(itemRotator.x) - Math.round(rowContainer.x)) : Math.round(rowContainer.rawOffX)
                                y: rowContainer.isFromCenter ? (((Math.round(contentColumn.height - itemRotator.height) & ~1) / 2) + Math.round(rowContainer.rawOffY) - Math.round(itemRotator.y) - Math.round(rowContainer.y)) : 0
                            }

                        }

                        Component {
                            id: glowComp

                            MultiEffect {
                                anchors.fill: parent
                                source: rowContainer.overlayPaddedMaskSource
                                shadowEnabled: true
                                shadowColor: rowContainer.effColor
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                                shadowBlur: Math.min(1, Math.max(0.2, rowContainer.effSize / 5))
                                blurEnabled: true
                                blur: Math.min(1, Math.max(0.1, rowContainer.effSize / 10))
                                maskEnabled: true
                                maskSource: rowContainer.overlayPaddedMaskSource
                                maskInverted: true
                                autoPaddingEnabled: false
                            }

                        }

                        Component {
                            id: softShadowComp

                            MultiEffect {
                                anchors.fill: parent
                                source: rowContainer.overlayPaddedMaskSource
                                shadowEnabled: true
                                shadowColor: rowContainer.effColor
                                shadowHorizontalOffset: rowContainer.effSize
                                shadowVerticalOffset: rowContainer.effSize
                                shadowBlur: Math.min(1, Math.max(0.2, rowContainer.effSize / 8))
                                maskEnabled: true
                                maskSource: rowContainer.overlayPaddedMaskSource
                                maskInverted: true
                                autoPaddingEnabled: false
                            }

                        }

                        Component {
                            id: normalShadowComp

                            MultiEffect {
                                anchors.fill: parent
                                source: rowContainer.overlayPaddedMaskSource
                                shadowEnabled: true
                                shadowColor: rowContainer.effColor
                                shadowHorizontalOffset: rowContainer.effSize
                                shadowVerticalOffset: rowContainer.effSize
                                shadowBlur: 0.1
                                maskEnabled: true
                                maskSource: rowContainer.overlayPaddedMaskSource
                                maskInverted: true
                                autoPaddingEnabled: false
                            }

                        }

                    }

                }

            }

        }

    }

}
