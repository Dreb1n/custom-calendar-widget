import "ConfigData.js" as ConfigData
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: configPage

    property alias cfg_fontFamily: fontCombo.selectedFont
    property alias cfg_bgType: bgTypeCombo.currentIndex
    property alias cfg_bgColor: bgColorInput.text
    property alias cfg_bgOpacity: bgOpacityHolder.value
    property alias cfg_borderRadius: borderRadiusHolder.value
    property alias cfg_widgetPadding: widgetPaddingHolder.value
    property alias cfg_rowsJson: rowsJsonHolder.text
    property alias cfg_isEditing: isEditingHolder.value
    property alias cfg_editingRowsJson: editingRowsJsonHolder.text
    property alias cfg_editingFontFamily: editingFontFamilyHolder.text
    property alias cfg_editingBgType: editingBgTypeHolder.value
    property alias cfg_editingBgColor: editingBgColorHolder.text
    property int activeRowIndexForFileDialog: -1
    property var activeColorCallback: null
    property var timezoneOptions: ConfigData.timezoneOptions
    property var localeOptions: ConfigData.localeOptions
    readonly property var timezoneLabels: timezoneOptions.map(function(opt) {
        return opt.label;
    })
    readonly property var localeLabels: localeOptions.map(function(opt) {
        return opt.label;
    })
    property var rowsList: []
    property bool isLoaded: false
    property bool isSaving: false
    // Security & Import Architecture:
    // Power users have full freedom to author custom shell commands for row click actions.
    // To prevent silent command injection from third-party JSON presets (e.g. shared online),
    // applyImportedJson() performs an automated pre-import security audit scan on incoming JSON payloads.
    // If clickCommands are detected, import is paused and commandSecurityAuditDialog displays an interactive
    // line-by-line review allowing the user to explicitly Trust & Enable, Strip Commands, or Cancel Import.
    property var pendingImportPayload: null

    function colorToHex(col) {
        var c = Qt.color(col);
        var r = Math.round(c.r * 255).toString(16);
        var g = Math.round(c.g * 255).toString(16);
        var b = Math.round(c.b * 255).toString(16);
        if (r.length === 1)
            r = "0" + r;

        if (g.length === 1)
            g = "0" + g;

        if (b.length === 1)
            b = "0" + b;

        return "#" + r + g + b;
    }

    function openColorPicker(currentColor, callback) {
        try {
            colorPickerDialog.selectedColor = Qt.color(currentColor || "#ffffff");
        } catch (e) {
            colorPickerDialog.selectedColor = Qt.color("#ffffff");
        }
        activeColorCallback = callback;
        colorPickerDialog.open();
    }

    function getPlasmoidConfig() {
        try {
            if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration)
                return plasmoid.configuration;

            if (typeof kcm !== "undefined" && kcm && kcm.plasmoid && kcm.plasmoid.configuration)
                return kcm.plasmoid.configuration;

            if (typeof kcm !== "undefined" && kcm && kcm.widget && kcm.widget.configuration)
                return kcm.widget.configuration;

            if (configPage.Plasmoid && configPage.Plasmoid.configuration)
                return configPage.Plasmoid.configuration;

            if (configPage.parent && configPage.parent.plasmoid && configPage.parent.plasmoid.configuration)
                return configPage.parent.plasmoid.configuration;

        } catch (e) {
            console.debug("KCM: getPlasmoidConfig context lookup failed: " + e.message);
        }
        return null;
    }

    function getPlasmoidRoot() {
        try {
            if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.rootItem)
                return plasmoid.rootItem;

            if (configPage.parent && configPage.parent.plasmoid && configPage.parent.plasmoid.rootItem)
                return configPage.parent.plasmoid.rootItem;

        } catch (e) {
            console.debug("KCM: getPlasmoidRoot context lookup failed: " + e.message);
        }
        return null;
    }

    function pushLiveEditingState(overrideRowsJson) {
        if (!isLoaded)
            return ;

        liveEditDebounceTimer.pendingOverrideJson = overrideRowsJson;
        liveEditDebounceTimer.restart();
    }

    function pushLiveEditingStateNow(overrideRowsJson) {
        if (!isLoaded)
            return ;

        try {
            isEditingHolder.value = true;
            editingRowsJsonHolder.text = (overrideRowsJson !== undefined) ? overrideRowsJson : (rowsJsonHolder.text || cfg_rowsJson);
            editingFontFamilyHolder.text = (typeof fontCombo !== "undefined" && fontCombo && fontCombo.selectedFont) ? fontCombo.selectedFont : cfg_fontFamily;
            editingBgTypeHolder.value = (typeof bgTypeCombo !== "undefined" && bgTypeCombo && bgTypeCombo.currentIndex !== undefined) ? bgTypeCombo.currentIndex : cfg_bgType;
            editingBgColorHolder.text = (typeof bgColorInput !== "undefined" && bgColorInput && bgColorInput.text) ? bgColorInput.text : cfg_bgColor;
            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.isEditing = true;
                pConfig.editingRowsJson = editingRowsJsonHolder.text;
                pConfig.editingFontFamily = editingFontFamilyHolder.text;
                pConfig.editingBgType = editingBgTypeHolder.value;
                pConfig.editingBgColor = editingBgColorHolder.text;
            }
        } catch (e) {
            console.log("[CustomCalendar Config] Error in pushLiveEditingStateNow:", e);
        }
    }

    function clearEditingState() {
        try {
            isEditingHolder.value = false;
            editingRowsJsonHolder.text = "";
            editingFontFamilyHolder.text = "";
            editingBgTypeHolder.value = -1;
            editingBgColorHolder.text = "";
            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.isEditing = false;
                pConfig.editingRowsJson = "";
                pConfig.editingFontFamily = "";
                pConfig.editingBgType = -1;
                pConfig.editingBgColor = "";
            }
        } catch (e) {
            console.debug("KCM: clearEditingState failed: " + e.message);
        }
    }

    function syncToPlasmoidConfig() {
        if (!isLoaded)
            return ;

        try {
            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.rowsJson = rowsJsonHolder.text;
                pConfig.fontFamily = (typeof fontCombo !== "undefined" && fontCombo && fontCombo.selectedFont) ? fontCombo.selectedFont : cfg_fontFamily;
                pConfig.bgType = (typeof bgTypeCombo !== "undefined" && bgTypeCombo && bgTypeCombo.currentIndex !== undefined) ? bgTypeCombo.currentIndex : cfg_bgType;
                pConfig.bgColor = (typeof bgColorInput !== "undefined" && bgColorInput && bgColorInput.text) ? bgColorInput.text : cfg_bgColor;
            }
        } catch (e) {
            console.warn("KCM: syncToPlasmoidConfig failed: " + e.message);
        }
    }

    function ensureFontInModels(fontName) {
        if (!fontName || typeof fontName !== "string" || fontName.trim() === "")
            return ;

        var name = fontName.trim();
        var foundInShared = false;
        for (var i = 0; i < sharedFontModel.count; i++) {
            if (sharedFontModel.get(i).fontName.toLowerCase() === name.toLowerCase()) {
                foundInShared = true;
                break;
            }
        }
        if (!foundInShared)
            sharedFontModel.append({
                "text": name,
                "fontName": name
            });

        var foundInOnly = false;
        for (var j = 0; j < sharedFontOnlyModel.count; j++) {
            if (sharedFontOnlyModel.get(j).fontName.toLowerCase() === name.toLowerCase()) {
                foundInOnly = true;
                break;
            }
        }
        if (!foundInOnly)
            sharedFontOnlyModel.append({
                "text": name,
                "fontName": name
            });

    }

    function buildSharedFontModels() {
        if (sharedFontModel.count > 10)
            return ;
 // Already populated
        var rawFonts = Qt.fontFamilies();
        var seen = {
        };
        var cleanList = [];
        var weightSuffixRegex = /\s+(Thin|ExtraLight|UltraLight|Light|Book|Regular|Medium|SemiBold|DemiBold|Bold|ExtraBold|UltraBold|Black|Heavy|Hair|Four|Eight)$/i;
        // Preserve any preselected fonts already added to sharedFontModel
        for (var s = 0; s < sharedFontModel.count; s++) {
            var sf = sharedFontModel.get(s).fontName.trim();
            if (sf) {
                seen[sf.toLowerCase()] = true;
                cleanList.push(sf);
            }
        }
        for (var j = 0; j < rawFonts.length; j++) {
            var fontName = rawFonts[j].trim();
            if (!fontName)
                continue;

            // Filter out redundant Noto regional sub-fonts to keep font list ultra-fast and readable
            if (fontName.indexOf("Noto ") === 0 && fontName !== "Noto Sans" && fontName !== "Noto Serif" && fontName !== "Noto Mono" && fontName !== "Noto Color Emoji")
                continue;

            var match = fontName.match(weightSuffixRegex);
            if (match) {
                var baseName = fontName.substring(0, match.index).trim();
                if (seen[baseName.toLowerCase()])
                    continue;

            }
            var key = fontName.toLowerCase();
            if (!seen[key]) {
                seen[key] = true;
                cleanList.push(fontName);
            }
        }
        // Ultra-fast case-insensitive string sort
        cleanList.sort(function(a, b) {
            var la = a.toLowerCase();
            var lb = b.toLowerCase();
            return la < lb ? -1 : (la > lb ? 1 : 0);
        });
        sharedFontModel.clear();
        sharedFontOnlyModel.clear();
        sharedFontModel.append({
            "text": "(Default)",
            "fontName": ""
        });
        for (var k = 0; k < cleanList.length; k++) {
            var fn = cleanList[k];
            sharedFontModel.append({
                "text": fn,
                "fontName": fn
            });
            sharedFontOnlyModel.append({
                "text": fn,
                "fontName": fn
            });
        }
    }

    function loadRowsFromJson() {
        try {
            if (cfg_rowsJson && cfg_rowsJson.length > 0)
                rowsList = JSON.parse(cfg_rowsJson);
            else
                rowsList = [{
                    "format": "dddd",
                    "align": "center",
                    "fontSize": 18,
                    "color": "#ffffff",
                    "effectColor": "",
                    "weight": "400",
                    "effect": "none",
                    "opacity": 1,
                    "timeZone": ""
                }, {
                    "format": "dd mmm yyy",
                    "align": "center",
                    "fontSize": 28,
                    "color": "#ffffff",
                    "effectColor": "",
                    "weight": "400",
                    "effect": "none",
                    "opacity": 1,
                    "timeZone": ""
                }, {
                    "format": "H:i",
                    "align": "center",
                    "fontSize": 48,
                    "color": "#ffffff",
                    "weight": "600",
                    "effect": "none",
                    "opacity": 1,
                    "timeZone": ""
                }];
        } catch (e) {
            rowsList = [];
        }
        ensureFontInModels(cfg_fontFamily);
        rowsModel.clear();
        for (var i = 0; i < rowsList.length; i++) {
            var item = rowsList[i];
            if (item.fontFamily)
                ensureFontInModels(item.fontFamily);

            if (!item.effect)
                item.effect = item.glow ? "glow" : "none";

            if (item.opacity === undefined)
                item.opacity = 1;

            if (!item.effectColor)
                item.effectColor = "";

            if (!item.timeZone)
                item.timeZone = "";

            if (!item.weight)
                item.weight = "400";

            if (!item.fontFamily)
                item.fontFamily = "";

            var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX !== undefined ? item.offsetX : 0);
            var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin !== undefined ? item.topMargin : 0);
            item.offsetWidth = offX;
            item.offsetX = offX;
            item.offsetHeight = offY;
            item.topMargin = offY;
            if (item.rotation === undefined)
                item.rotation = 0;

            if (item.letterSpacing === undefined)
                item.letterSpacing = 0;

            if (item.effectSize === undefined)
                item.effectSize = 2;

            if (!item.clickCommand)
                item.clickCommand = "";

            var isSh = (item.isShape === true || item.isShape === "true") && (!item.format || item.format === "");
            item.isShape = isSh;
            if (isSh) {
                if (!item.shapeType)
                    item.shapeType = "circle";

                if (item.shapeWidth === undefined)
                    item.shapeWidth = 100;

                if (item.shapeHeight === undefined)
                    item.shapeHeight = 100;

                if (!item.color)
                    item.color = "#3b82f6";

                item.format = "";
                item.showTimeZone = false;
                item.showLocale = false;
                item.showFontFamily = false;
                item.showWeight = false;
                item.showLetterSpacing = false;
            } else {
                item.isShape = false;
                item.shapeType = "";
                if (!item.format)
                    item.format = "dddd";

            }
            item.fromCenter = (item.fromCenter === true || item.fromCenter === "true");
            item.showTimeZone = !item.isShape && item.timeZone !== "";
            item.showLocale = !item.isShape && item.locale !== "";
            item.showClickCommand = item.clickCommand !== "";
            item.showFontFamily = !item.isShape && item.fontFamily !== "";
            item.showWeight = !item.isShape && String(item.weight) !== "400";
            item.showAlign = item.align !== undefined && item.align !== "center";
            item.showOpacity = item.opacity !== 1;
            item.showOffsets = (offX !== 0 || offY !== 0 || item.fromCenter === true);
            item.showRotation = item.rotation !== 0;
            item.showEffect = item.effect !== "none";
            if (item.effectOpacity === undefined)
                item.effectOpacity = 1;

            if (item.overlayType === undefined)
                item.overlayType = 0;

            if (!item.overlayColor)
                item.overlayColor = "#000000";

            if (item.overlayOpacity === undefined)
                item.overlayOpacity = 0.5;

            if (!item.overlayFile)
                item.overlayFile = "";

            item.showOverlay = (item.showOverlay === true || item.showOverlay === "true" || item.overlayType !== 0);
            rowsModel.append(item);
        }
        isLoaded = true;
        saveRowsToJson(true);
    }

    function cleanStockDefaults() {
        for (var i = 0; i < rowsModel.count; i++) {
            var item = rowsModel.get(i);
            var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX || 0);
            var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin || 0);
            if (offX === 0 && offY === 0 && !item.fromCenter)
                rowsModel.setProperty(i, "showOffsets", false);

            if (item.rotation === 0)
                rowsModel.setProperty(i, "showRotation", false);

            if (item.letterSpacing === 0)
                rowsModel.setProperty(i, "showLetterSpacing", false);

            if (item.opacity === 1)
                rowsModel.setProperty(i, "showOpacity", false);

            if (String(item.weight) === "400")
                rowsModel.setProperty(i, "showWeight", false);

            if (item.align === "center")
                rowsModel.setProperty(i, "showAlign", false);

            if (!item.fontFamily || item.fontFamily === "")
                rowsModel.setProperty(i, "showFontFamily", false);

            if (!item.timeZone || item.timeZone === "")
                rowsModel.setProperty(i, "showTimeZone", false);

            if (!item.locale || item.locale === "")
                rowsModel.setProperty(i, "showLocale", false);

            if (!item.clickCommand || item.clickCommand === "")
                rowsModel.setProperty(i, "showClickCommand", false);

            if (!item.effect || item.effect === "none")
                rowsModel.setProperty(i, "showEffect", false);

            if (item.overlayType === 0)
                rowsModel.setProperty(i, "showOverlay", false);

        }
    }

    function markChanged() {
        if (!isLoaded)
            return ;

        try {
            configPage.needsSave = true;
        } catch (e) {
            console.debug("KCM: configPage.needsSave set failed: " + e.message);
        }
        try {
            configPage.unrepresentedNeedsSave = true;
        } catch (e) {
            console.debug("KCM: configPage.unrepresentedNeedsSave set failed: " + e.message);
        }
        try {
            if (typeof kcm !== "undefined" && kcm) {
                kcm.needsSave = true;
                kcm.unrepresentedNeedsSave = true;
            }
        } catch (e) {
            console.debug("KCM: container save flag set failed: " + e.message);
        }
    }

    function serializeRowItem(item) {
        var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX !== undefined ? item.offsetX : 0);
        var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin !== undefined ? item.topMargin : 0);
        var isSh = (item.isShape === true || item.isShape === "true") && (!item.format || item.format === "");
        if (isSh)
            return {
                "isShape": true,
                "shapeType": item.shapeType || "circle",
                "shapeWidth": item.shapeWidth || 100,
                "shapeHeight": item.shapeHeight || 100,
                "color": item.color || "#3b82f6",
                "align": item.showAlign ? (item.align || "center") : "center",
                "opacity": item.showOpacity && item.opacity !== undefined ? item.opacity : 1,
                "offsetWidth": item.showOffsets ? offX : 0,
                "offsetHeight": item.showOffsets ? offY : 0,
                "offsetX": item.showOffsets ? offX : 0,
                "topMargin": item.showOffsets ? offY : 0,
                "fromCenter": item.showOffsets && (item.fromCenter === true || item.fromCenter === "true"),
                "rotation": item.rotation !== undefined ? item.rotation : 0,
                "effect": item.showEffect ? (item.effect || "none") : "none",
                "effectColor": item.showEffect ? (item.effectColor || "") : "",
                "effectSize": item.showEffect && item.effectSize !== undefined ? item.effectSize : 2,
                "effectOpacity": item.showEffect && item.effectOpacity !== undefined ? item.effectOpacity : 1,
                "clickCommand": item.showClickCommand ? (item.clickCommand || "") : "",
                "overlayType": item.showOverlay ? (item.overlayType !== undefined ? item.overlayType : 0) : 0,
                "overlayColor": item.showOverlay ? (item.overlayColor || "#000000") : "#000000",
                "overlayOpacity": item.showOverlay && item.overlayOpacity !== undefined ? item.overlayOpacity : 0.5,
                "overlayFile": item.showOverlay ? (item.overlayFile || "") : "",
                "showOverlay": item.showOverlay === true
            };
        else
            return {
                "format": item.format || "",
                "fontFamily": item.showFontFamily ? (item.fontFamily || "") : "",
                "align": item.showAlign ? (item.align || "center") : "center",
                "fontSize": item.fontSize || 24,
                "color": item.color || "#ffffff",
                "effectColor": item.showEffect ? (item.effectColor || "") : "",
                "weight": item.showWeight ? String(item.weight || "400") : "400",
                "effect": item.showEffect ? (item.effect || "none") : "none",
                "opacity": item.showOpacity && item.opacity !== undefined ? item.opacity : 1,
                "offsetWidth": item.showOffsets ? offX : 0,
                "offsetHeight": item.showOffsets ? offY : 0,
                "offsetX": item.showOffsets ? offX : 0,
                "topMargin": item.showOffsets ? offY : 0,
                "fromCenter": item.showOffsets && (item.fromCenter === true || item.fromCenter === "true"),
                "rotation": item.rotation !== undefined ? item.rotation : 0,
                "letterSpacing": item.showLetterSpacing && item.letterSpacing !== undefined ? item.letterSpacing : 0,
                "effectSize": item.showEffect && item.effectSize !== undefined ? item.effectSize : 2,
                "effectOpacity": item.showEffect && item.effectOpacity !== undefined ? item.effectOpacity : 1,
                "timeZone": item.showTimeZone ? (item.timeZone || "") : "",
                "locale": item.showLocale ? (item.locale || "") : "",
                "clickCommand": item.showClickCommand ? (item.clickCommand || "") : "",
                "glow": item.showEffect && item.effect === "glow",
                "overlayType": item.showOverlay ? (item.overlayType !== undefined ? item.overlayType : 0) : 0,
                "overlayColor": item.showOverlay ? (item.overlayColor || "#000000") : "#000000",
                "overlayOpacity": item.showOverlay && item.overlayOpacity !== undefined ? item.overlayOpacity : 0.5,
                "overlayFile": item.showOverlay ? (item.overlayFile || "") : "",
                "showOverlay": item.showOverlay === true
            };
    }

    function saveRowsToJson(skipMarkChanged) {
        if (!isLoaded)
            return ;

        if (skipMarkChanged)
            saveRowsToJsonDirect(true);
        else
            debounceSaveTimer.restart();
    }

    function saveRowsToJsonDirect(skipMarkChanged) {
        if (!isLoaded)
            return ;

        var arr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            arr.push(serializeRowItem(rowsModel.get(i)));
        }
        var jsonStr = JSON.stringify(arr);
        isSaving = true;
        rowsJsonHolder.text = jsonStr;
        pushLiveEditingState(jsonStr);
        if (!skipMarkChanged)
            markChanged();

        isSaving = false;
    }

    function save() {
        cleanStockDefaults();
        if (!isLoaded)
            return ;

        var arr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            arr.push(serializeRowItem(rowsModel.get(i)));
        }
        var jsonStr = JSON.stringify(arr);
        isSaving = true;
        rowsJsonHolder.text = jsonStr;
        syncToPlasmoidConfig();
        clearEditingState();
        isSaving = false;
    }

    function getExportPresetJson() {
        var rowsArr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            rowsArr.push(serializeRowItem(rowsModel.get(i)));
        }
        var preset = {
            "generator": "Custom Calendar & Clock Plasmoid",
            "version": "1.3.0",
            "fontFamily": fontCombo.selectedFont,
            "bgType": bgTypeCombo.currentIndex,
            "bgColor": bgColorInput.text || "#1e293b",
            "rows": rowsArr
        };
        return JSON.stringify(preset, null, 2);
    }

    function applyImportedJson(jsonText) {
        try {
            if (!jsonText || jsonText.trim().length === 0) {
                importPresetDialog.statusMessage = i18n("Please paste or select a valid JSON preset.");
                importPresetDialog.isError = true;
                return ;
            }
            var data = JSON.parse(jsonText);
            var targetRows = [];
            if (Array.isArray(data)) {
                targetRows = data;
            } else if (typeof data === "object" && data !== null) {
                if (data.rows && Array.isArray(data.rows))
                    targetRows = data.rows;

            } else {
                importPresetDialog.statusMessage = i18n("Invalid JSON format.");
                importPresetDialog.isError = true;
                return ;
            }
            if (!targetRows || targetRows.length === 0) {
                importPresetDialog.statusMessage = i18n("No valid rows found in JSON preset.");
                importPresetDialog.isError = true;
                return ;
            }
            var commandsFound = [];
            for (var c = 0; c < targetRows.length; c++) {
                var rCmd = targetRows[c].clickCommand;
                if (rCmd && typeof rCmd === "string" && rCmd.trim().length > 0)
                    commandsFound.push({
                        "rowIndex": c + 1,
                        "fmt": targetRows[c].format || "Shape",
                        "cmd": rCmd.trim()
                    });

            }
            var payload = {
                "data": data,
                "targetRows": targetRows,
                "commands": commandsFound
            };
            if (commandsFound.length > 0) {
                configPage.pendingImportPayload = payload;
                commandSecurityAuditDialog.open();
            } else {
                executeImportData(payload, true);
            }
        } catch (e) {
            importPresetDialog.statusMessage = i18n("JSON Parsing Error: ") + e.message;
            importPresetDialog.isError = true;
        }
    }

    function executeImportData(payload, keepCommands) {
        if (!payload || !payload.targetRows)
            return ;

        try {
            var data = payload.data;
            var targetRows = payload.targetRows;
            if (!keepCommands) {
                for (var i = 0; i < targetRows.length; i++) {
                    targetRows[i].clickCommand = "";
                }
            }
            if (typeof data === "object" && !Array.isArray(data) && data !== null) {
                if (data.fontFamily !== undefined && data.fontFamily !== "")
                    fontCombo.selectedFont = data.fontFamily;

                if (data.bgType !== undefined && data.bgType >= 0 && data.bgType <= 2)
                    bgTypeCombo.currentIndex = data.bgType;

                if (data.bgColor !== undefined && data.bgColor !== "")
                    bgColorInput.text = data.bgColor;

            }
            cfg_rowsJson = JSON.stringify(targetRows);
            loadRowsFromJson();
            save();
            importPresetDialog.statusMessage = i18n("Preset applied successfully!");
            importPresetDialog.isError = false;
            importPresetDialog.close();
            configPage.pendingImportPayload = null;
        } catch (e) {
            importPresetDialog.statusMessage = i18n("Error applying preset: ") + e.message;
            importPresetDialog.isError = true;
        }
    }

    function readJsonFile(fileUrl) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", fileUrl, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    importJsonArea.text = xhr.responseText;
                    importPresetDialog.statusMessage = i18n("File loaded. Click 'Apply Preset' to import.");
                    importPresetDialog.isError = false;
                } else {
                    importPresetDialog.statusMessage = i18n("Failed to read file.");
                    importPresetDialog.isError = true;
                }
            }
        };
        xhr.send();
    }

    function writeJsonFile(fileUrl, content) {
        var xhr = new XMLHttpRequest();
        xhr.open("PUT", fileUrl, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0)
                    exportPresetDialog.title = i18n("Export Design Preset (Saved!)");

            }
        };
        try {
            xhr.send(content);
        } catch (e) {
            console.error("KCM: writeJsonFile failed: " + e.message);
        }
    }

    onCfg_rowsJsonChanged: {
        if (isLoaded && !isSaving)
            loadRowsFromJson();

    }
    Component.onCompleted: {
        loadRowsFromJson();
        pushLiveEditingState();
    }
    Component.onDestruction: {
        clearEditingState();
    }

    QtObject {
        id: rowsJsonHolder

        property string text: ""
    }

    QtObject {
        id: bgOpacityHolder

        property real value: 0.8
    }

    QtObject {
        id: borderRadiusHolder

        property int value: 16
    }

    QtObject {
        id: widgetPaddingHolder

        property int value: 16
    }

    QtObject {
        id: isEditingHolder

        property bool value: false
    }

    QtObject {
        id: editingRowsJsonHolder

        property string text: ""
    }

    QtObject {
        id: editingFontFamilyHolder

        property string text: ""
    }

    QtObject {
        id: editingBgTypeHolder

        property int value: -1
    }

    QtObject {
        id: editingBgColorHolder

        property string text: ""
    }

    ColorDialog {
        id: colorPickerDialog

        title: i18n("Select Color")
        onAccepted: {
            if (configPage.activeColorCallback)
                configPage.activeColorCallback(configPage.colorToHex(selectedColor));

        }
    }

    ListModel {
        id: sharedFontModel

        ListElement {
            text: "(Default)"
            fontName: ""
        }

        ListElement {
            text: "Sans Serif"
            fontName: "Sans Serif"
        }

        ListElement {
            text: "Serif"
            fontName: "Serif"
        }

        ListElement {
            text: "Monospace"
            fontName: "Monospace"
        }

    }

    ListModel {
        id: sharedFontOnlyModel

        ListElement {
            text: "Sans Serif"
            fontName: "Sans Serif"
        }

        ListElement {
            text: "Serif"
            fontName: "Serif"
        }

        ListElement {
            text: "Monospace"
            fontName: "Monospace"
        }

    }

    ListModel {
        id: shapeTypesModel

        ListElement {
            text: "Circle / Ellipse / Oblong"
            value: "circle"
        }

        ListElement {
            text: "Square / Rectangle"
            value: "square"
        }

        ListElement {
            text: "Pill / Capsule"
            value: "pill"
        }

        ListElement {
            text: "Triangle (3 sides)"
            value: "triangle"
        }

        ListElement {
            text: "Pentagon (5 sides)"
            value: "pentagon"
        }

        ListElement {
            text: "Hexagon (6 sides)"
            value: "hexagon"
        }

        ListElement {
            text: "Heptagon (7 sides)"
            value: "heptagon"
        }

        ListElement {
            text: "Octagon (8 sides)"
            value: "octagon"
        }

        ListElement {
            text: "Nonagon (9 sides)"
            value: "nonagon"
        }

        ListElement {
            text: "Decagon (10 sides)"
            value: "decagon"
        }

    }

    Timer {
        id: liveEditDebounceTimer

        property var pendingOverrideJson: undefined

        interval: 150 // 150ms debounce eliminates D-Bus payload spam on slider drag
        repeat: false
        onTriggered: {
            configPage.pushLiveEditingStateNow(pendingOverrideJson);
        }
    }

    Timer {
        id: debounceSaveTimer

        interval: 150
        repeat: false
        onTriggered: {
            saveRowsToJsonDirect(false);
        }
    }

    Dialog {
        id: exportPresetDialog

        title: i18n("Export Design Preset")
        modal: true
        anchors.centerIn: parent
        width: Math.min(configPage.width * 0.9, 580)
        height: Math.min(configPage.height * 0.9, 420)
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Label {
                text: i18n("Copy this JSON preset snippet to share your design with others:")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextEdit {
                    id: exportJsonArea

                    font.family: "Monospace"
                    font.pixelSize: 12
                    wrapMode: TextEdit.Wrap
                    readOnly: true
                    selectByMouse: true
                    color: Kirigami.Theme.textColor
                }

            }

            RowLayout {
                Layout.fillWidth: true

                Button {
                    text: i18n("📋 Copy to Clipboard")
                    icon.name: "edit-copy"
                    onClicked: {
                        exportJsonArea.selectAll();
                        exportJsonArea.copy();
                        copyNotification.visible = true;
                    }
                }

                Label {
                    id: copyNotification

                    text: i18n("Copied!")
                    color: Kirigami.Theme.positiveTextColor
                    visible: false
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: i18n("📂 Save to File...")
                    icon.name: "document-save-as"
                    onClicked: {
                        exportFileDialog.open();
                    }
                }

            }

        }

    }

    Dialog {
        id: importPresetDialog

        property string statusMessage: ""
        property bool isError: false

        title: i18n("Import Design Preset")
        modal: true
        anchors.centerIn: parent
        width: Math.min(configPage.width * 0.9, 580)
        height: Math.min(configPage.height * 0.9, 420)
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Label {
                text: i18n("Paste a JSON preset string below or load from a file:")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextEdit {
                    id: importJsonArea

                    font.family: "Monospace"
                    font.pixelSize: 12
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    color: Kirigami.Theme.textColor
                }

            }

            Label {
                text: importPresetDialog.statusMessage
                color: importPresetDialog.isError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                visible: importPresetDialog.statusMessage.length > 0
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                Button {
                    text: i18n("📂 Load from File...")
                    icon.name: "document-open"
                    onClicked: {
                        importFileDialog.open();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: i18n("🚀 Apply Preset")
                    icon.name: "dialog-ok-apply"
                    highlighted: true
                    onClicked: {
                        applyImportedJson(importJsonArea.text);
                    }
                }

            }

        }

    }

    FileDialog {
        id: importFileDialog

        title: i18n("Open Preset File")
        fileMode: FileDialog.OpenFile
        nameFilters: [i18n("JSON Files (*.json)"), i18n("All Files (*)")]
        onAccepted: {
            readJsonFile(selectedFile);
        }
    }

    FileDialog {
        id: exportFileDialog

        title: i18n("Save Preset File")
        fileMode: FileDialog.SaveFile
        nameFilters: [i18n("JSON Files (*.json)"), i18n("All Files (*)")]
        currentFile: "custom-calendar-preset.json"
        onAccepted: {
            writeJsonFile(selectedFile, exportJsonArea.text);
        }
    }

    FileDialog {
        id: overlayFileDialog

        title: i18n("Select Overlay Media File")
        fileMode: FileDialog.OpenFile
        nameFilters: [i18n("Media Files (*.png *.jpg *.jpeg *.gif *.webp *.mp4 *.webm *.ogv *.mov *.avi *.3gp *.mkv)"), i18n("Image Files (*.png *.jpg *.jpeg *.gif *.webp)"), i18n("Video Files (*.mp4 *.webm *.ogv *.mov *.avi *.3gp *.mkv)"), i18n("All Files (*)")]
        onAccepted: {
            var path = String(selectedFile);
            if (configPage.activeRowIndexForFileDialog !== -1) {
                rowsModel.setProperty(configPage.activeRowIndexForFileDialog, "overlayFile", path);
                rowsModel.saveToJson();
                configPage.activeRowIndexForFileDialog = -1;
            } else {
                overlayFileInput.text = path;
                pushLiveEditingState();
                markChanged();
            }
        }
    }

    Dialog {
        id: commandSecurityAuditDialog

        title: i18n("⚠️ Security Review: Executable Commands Detected")
        modal: true
        anchors.centerIn: parent
        width: Math.min(configPage.width * 0.95, 580)
        height: Math.min(configPage.height * 0.95, 450)
        standardButtons: Dialog.NoButton

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: i18n("The imported layout contains custom shell commands that will execute when rows are clicked. Please review them carefully:")
                wrapMode: Text.WordWrap
                font.bold: true
                color: Kirigami.Theme.warningTextColor
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: auditCommandsListView

                    model: configPage.pendingImportPayload ? configPage.pendingImportPayload.commands : []
                    clip: true
                    spacing: 6

                    delegate: Rectangle {
                        width: auditCommandsListView.width
                        implicitHeight: col.implicitHeight + 12
                        color: Kirigami.Theme.alternateBackgroundColor
                        border.color: Kirigami.Theme.focusColor
                        radius: 6

                        Column {
                            id: col

                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            Text {
                                text: "Row " + modelData.rowIndex + " ('" + modelData.fmt + "')"
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: modelData.cmd
                                color: Kirigami.Theme.negativeTextColor
                                font.family: "Monospace"
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                width: parent.width
                            }

                        }

                    }

                }

            }

            Label {
                text: i18n("Do you trust the author of this preset and want to enable these click commands?")
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: i18n("Cancel Import")
                    icon.name: "dialog-cancel"
                    onClicked: {
                        commandSecurityAuditDialog.close();
                        configPage.pendingImportPayload = null;
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: i18n("Import (Strip Commands)")
                    icon.name: "edit-clear"
                    onClicked: {
                        configPage.executeImportData(configPage.pendingImportPayload, false);
                        commandSecurityAuditDialog.close();
                    }
                }

                Button {
                    text: i18n("Trust & Enable Commands")
                    icon.name: "security-high"
                    highlighted: true
                    onClicked: {
                        configPage.executeImportData(configPage.pendingImportPayload, true);
                        commandSecurityAuditDialog.close();
                    }
                }

            }

        }

    }

    Timer {
        id: saveDebounceTimer
        interval: 150
        repeat: false
        onTriggered: {
            configPage.saveRowsToJsonDirect(true);
        }
    }

    ListModel {
        id: rowsModel

        function removeRow(idx) {
            if (count > 1 && idx >= 0 && idx < count) {
                remove(idx);
                saveToJson(true);
            }
        }

        function moveRow(fromIdx, toIdx) {
            if (fromIdx >= 0 && fromIdx < count && toIdx >= 0 && toIdx < count) {
                move(fromIdx, toIdx, 1);
                saveToJson(true);
            }
        }

        function saveToJson(immediate) {
            if (immediate === true) {
                saveDebounceTimer.stop();
                configPage.saveRowsToJsonDirect(true);
            } else {
                saveDebounceTimer.restart();
            }
        }

        dynamicRoles: true
    }

    Kirigami.FormLayout {
        id: formLayout

        RowLayout {
            Kirigami.FormData.label: i18n("Design Presets:")
            spacing: 8

            Button {
                text: i18n("📤 Export Preset")
                icon.name: "document-export"
                onClicked: {
                    exportJsonArea.text = getExportPresetJson();
                    copyNotification.visible = false;
                    exportPresetDialog.open();
                }
            }

            Button {
                text: i18n("📥 Import Preset")
                icon.name: "document-import"
                onClicked: {
                    importJsonArea.text = "";
                    importPresetDialog.statusMessage = "";
                    importPresetDialog.open();
                }
            }

        }

        ComboBox {
            id: fontCombo

            property string selectedFont: "Sans Serif"

            Kirigami.FormData.label: i18n("Font Family:")
            onPressedChanged: {
                if (pressed)
                    configPage.buildSharedFontModels();

            }
            model: sharedFontOnlyModel
            textRole: "text"
            valueRole: "fontName"
            onActivated: function(index) {
                if (index >= 0 && index < sharedFontOnlyModel.count) {
                    selectedFont = sharedFontOnlyModel.get(index).fontName;
                    pushLiveEditingState();
                    markChanged();
                }
            }

            delegate: ItemDelegate {
                width: parent ? parent.width : 200
                highlighted: fontCombo.currentIndex === index

                contentItem: Text {
                    text: model.text
                    font.family: (model.fontName && model.fontName !== "") ? model.fontName : fontCombo.font.family
                    font.pixelSize: 14
                    color: parent.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

            }

            Binding on currentIndex {
                value: {
                    var f = fontCombo.selectedFont;
                    if (!f)
                        return 0;

                    for (var m = 0; m < sharedFontOnlyModel.count; m++) {
                        if (sharedFontOnlyModel.get(m).fontName.toLowerCase() === f.toLowerCase())
                            return m;

                    }
                    return 0;
                }
            }

        }

        ComboBox {
            id: bgTypeCombo

            Kirigami.FormData.label: i18n("Background Style:")
            model: [i18n("Blurred Glass"), i18n("Solid Color"), i18n("Transparent (No Background)")]
            onActivated: function(index) {
                pushLiveEditingState();
                markChanged();
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background Color:")
            visible: bgTypeCombo.currentIndex !== 2

            Rectangle {
                id: bgColorSwatch

                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 4
                color: bgColorInput.text || "#1e293b"
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        configPage.openColorPicker(bgColorInput.text, function(hex) {
                            bgColorInput.text = hex;
                            bgColorInput.textEdited();
                            pushLiveEditingState();
                            markChanged();
                        });
                    }
                }

            }

            TextField {
                id: bgColorInput

                Layout.fillWidth: true
                placeholderText: "#1e293b"
                onTextEdited: {
                    pushLiveEditingState();
                    markChanged();
                }
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: rowsModel

                delegate: ConfigRowDelegate {
                }

            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignLeft

                Button {
                    text: i18n("+ Add Row")
                    icon.name: "list-add"
                    onClicked: {
                        rowsModel.append({
                            "isShape": false,
                            "format": "H:i:ss",
                            "align": "center",
                            "fontSize": 24,
                            "color": "#ffffff",
                            "effectColor": "",
                            "weight": "400",
                            "effect": "none",
                            "opacity": 1,
                            "topMargin": 0,
                            "offsetX": 0,
                            "offsetWidth": 0,
                            "offsetHeight": 0,
                            "letterSpacing": 0,
                            "effectSize": 2,
                            "timeZone": "",
                            "locale": "",
                            "clickCommand": "",
                            "showTimeZone": false,
                            "showLocale": false,
                            "showClickCommand": false,
                            "showFontFamily": false,
                            "showWeight": false,
                            "showAlign": false,
                            "showOpacity": false,
                            "showOffsets": false,
                            "showLetterSpacing": false,
                            "showEffect": false
                        });
                        rowsModel.saveToJson();
                    }
                }

                Button {
                    text: i18n("+ Add Shape")
                    icon.name: "draw-polygon"
                    onClicked: {
                        rowsModel.append({
                            "isShape": true,
                            "shapeType": "circle",
                            "shapeWidth": 100,
                            "shapeHeight": 100,
                            "color": "#3b82f6",
                            "align": "center",
                            "opacity": 1,
                            "topMargin": 0,
                            "offsetX": 0,
                            "offsetWidth": 0,
                            "offsetHeight": 0,
                            "effect": "none",
                            "effectColor": "",
                            "effectSize": 2,
                            "clickCommand": "",
                            "showTimeZone": false,
                            "showLocale": false,
                            "showClickCommand": false,
                            "showFontFamily": false,
                            "showWeight": false,
                            "showAlign": false,
                            "showOpacity": false,
                            "showOffsets": false,
                            "showLetterSpacing": false,
                            "showEffect": false
                        });
                        rowsModel.saveToJson();
                    }
                }

            }

        }

    }

}
