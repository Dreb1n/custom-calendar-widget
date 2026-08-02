import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: configPage

    property alias cfg_fontFamily: fontCombo.selectedFont
    property alias cfg_bgType: bgTypeCombo.currentIndex
    property alias cfg_bgColor: bgColorInput.text
    property alias cfg_rowsJson: rowsJsonHolder.text

    Item {
        id: rowsJsonHolder
        property string text: ""
    }

    property var activeColorCallback: null

    function colorToHex(col) {
        var c = Qt.color(col);
        var r = Math.round(c.r * 255).toString(16);
        var g = Math.round(c.g * 255).toString(16);
        var b = Math.round(c.b * 255).toString(16);
        if (r.length === 1) r = "0" + r;
        if (g.length === 1) g = "0" + g;
        if (b.length === 1) b = "0" + b;
        return "#" + r + g + b;
    }

    ColorDialog {
        id: colorPickerDialog
        title: i18n("Select Color")
        onAccepted: {
            if (configPage.activeColorCallback) {
                configPage.activeColorCallback(configPage.colorToHex(selectedColor));
            }
        }
    }

    function openColorPicker(currentColor, callback) {
        try {
            colorPickerDialog.selectedColor = Qt.color(currentColor || "#ffffff");
        } catch(e) {
            colorPickerDialog.selectedColor = Qt.color("#ffffff");
        }
        activeColorCallback = callback;
        colorPickerDialog.open();
    }

    property var rowsList: []
    property bool isLoaded: false
    property bool isSaving: false

    ListModel {
        id: sharedFontModel
        ListElement { text: "(Default)"; fontName: "" }
        ListElement { text: "Sans Serif"; fontName: "Sans Serif" }
        ListElement { text: "Serif"; fontName: "Serif" }
        ListElement { text: "Monospace"; fontName: "Monospace" }
    }

    ListModel {
        id: sharedFontOnlyModel
        ListElement { text: "Sans Serif"; fontName: "Sans Serif" }
        ListElement { text: "Serif"; fontName: "Serif" }
        ListElement { text: "Monospace"; fontName: "Monospace" }
    }

    onCfg_rowsJsonChanged: {
        if (!isSaving) {
            loadRowsFromJson();
        }
    }

    function getPlasmoidConfig() {
        try {
            if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration) return plasmoid.configuration;
            if (typeof kcm !== "undefined" && kcm && kcm.plasmoid && kcm.plasmoid.configuration) return kcm.plasmoid.configuration;
            if (typeof kcm !== "undefined" && kcm && kcm.widget && kcm.widget.configuration) return kcm.widget.configuration;
            if (configPage.parent && configPage.parent.plasmoid && configPage.parent.plasmoid.configuration) return configPage.parent.plasmoid.configuration;
        } catch(e) {}
        return null;
    }

    function pushLivePreview() {
        if (!isLoaded) return;
        try {
            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.rowsJson = cfg_rowsJson;
                if (fontCombo && fontCombo.selectedFont) pConfig.fontFamily = fontCombo.selectedFont;
                if (bgTypeCombo) pConfig.bgType = bgTypeCombo.currentIndex;
                if (bgColorInput) pConfig.bgColor = bgColorInput.text;
            }
        } catch(e) {}
    }

    Component.onCompleted: {
        loadRowsFromJson();
    }



    function buildSharedFontModels() {
        if (sharedFontModel.count > 5) return; // Already loaded
        var rawFonts = Qt.fontFamilies();
        var seen = {};
        var cleanList = [];
        var weightSuffixRegex = /\s+(Thin|ExtraLight|UltraLight|Light|Book|Regular|Medium|SemiBold|DemiBold|Bold|ExtraBold|UltraBold|Black|Heavy|Hair|Four|Eight)$/i;
        var allLower = {};

        for (var i = 0; i < rawFonts.length; i++) {
            var f = rawFonts[i].trim();
            if (f) allLower[f.toLowerCase()] = f;
        }

        for (var j = 0; j < rawFonts.length; j++) {
            var fontName = rawFonts[j].trim();
            if (!fontName) continue;

            var match = fontName.match(weightSuffixRegex);
            if (match) {
                var baseName = fontName.substring(0, match.index).trim();
                if (allLower[baseName.toLowerCase()]) continue;
            }

            var key = fontName.toLowerCase();
            if (!seen[key]) {
                seen[key] = true;
                cleanList.push(fontName);
            }
        }

        cleanList.sort(function(a, b) {
            return a.localeCompare(b, undefined, { sensitivity: 'base' });
        });

        sharedFontModel.clear();
        sharedFontOnlyModel.clear();

        sharedFontModel.append({ "text": "(Default)", "fontName": "" });

        for (var k = 0; k < cleanList.length; k++) {
            var fn = cleanList[k];
            sharedFontModel.append({ "text": fn, "fontName": fn });
            sharedFontOnlyModel.append({ "text": fn, "fontName": fn });
        }
    }

    function loadRowsFromJson() {
        try {
            if (cfg_rowsJson && cfg_rowsJson.length > 0) {
                rowsList = JSON.parse(cfg_rowsJson);
            } else {
                rowsList = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#ffffff", "effectColor": "", "weight": "400", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": "400", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#ffffff", "weight": "600", "effect": "none", "opacity": 1.0, "timeZone": "" }
                ];
            }
        } catch(e) {
            rowsList = [];
        }
        rowsModel.clear();
        for (var i = 0; i < rowsList.length; i++) {
            var item = rowsList[i];
            if (!item.effect) {
                item.effect = item.glow ? "glow" : "none";
            }
            if (item.opacity === undefined) {
                item.opacity = 1.0;
            }
            if (!item.effectColor) {
                item.effectColor = "";
            }
            if (!item.timeZone) {
                item.timeZone = "";
            }
            if (!item.weight) {
                item.weight = "400";
            }
            if (!item.fontFamily) {
                item.fontFamily = "";
            }
            var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX !== undefined ? item.offsetX : 0);
            var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin !== undefined ? item.topMargin : 0);
            item.offsetWidth = offX;
            item.offsetX = offX;
            item.offsetHeight = offY;
            item.topMargin = offY;

            if (item.letterSpacing === undefined) {
                item.letterSpacing = 0;
            }
            if (item.effectSize === undefined) {
                item.effectSize = 2;
            }
            if (!item.clickCommand) {
                item.clickCommand = "";
            }
            if (!item.locale) {
                item.locale = "";
            }

            item.showTimeZone = item.timeZone !== "";
            item.showLocale = item.locale !== "";
            item.showClickCommand = item.clickCommand !== "";
            item.showFontFamily = item.fontFamily !== "";
            item.showWeight = String(item.weight) !== "400";
            item.showAlign = item.align !== undefined && item.align !== "center";
            item.showOpacity = item.opacity !== 1.0;
            item.showOffsets = (offX !== 0 || offY !== 0);
            item.showLetterSpacing = item.letterSpacing !== 0;
            item.showEffect = item.effect !== "none";

            rowsModel.append(item);
        }
        isLoaded = true;
    }

    function cleanStockDefaults() {
        for (var i = 0; i < rowsModel.count; i++) {
            var item = rowsModel.get(i);
            var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX || 0);
            var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin || 0);
            if (offX === 0 && offY === 0) rowsModel.setProperty(i, "showOffsets", false);
            if (item.letterSpacing === 0) rowsModel.setProperty(i, "showLetterSpacing", false);
            if (item.opacity === 1.0) rowsModel.setProperty(i, "showOpacity", false);
            if (String(item.weight) === "400") rowsModel.setProperty(i, "showWeight", false);
            if (item.align === "center") rowsModel.setProperty(i, "showAlign", false);
            if (!item.fontFamily || item.fontFamily === "") rowsModel.setProperty(i, "showFontFamily", false);
            if (!item.timeZone || item.timeZone === "") rowsModel.setProperty(i, "showTimeZone", false);
            if (!item.locale || item.locale === "") rowsModel.setProperty(i, "showLocale", false);
            if (!item.clickCommand || item.clickCommand === "") rowsModel.setProperty(i, "showClickCommand", false);
            if (!item.effect || item.effect === "none") rowsModel.setProperty(i, "showEffect", false);
        }
    }

    function markChanged() {
        if (!isLoaded) return;
        isApplyingOrSaved = false;
        try { configPage.needsSave = true; } catch(e) {}
        try { configPage.unrepresentedNeedsSave = true; } catch(e) {}
        try {
            if (typeof kcm !== "undefined" && kcm) {
                kcm.needsSave = true;
                kcm.unrepresentedNeedsSave = true;
            }
        } catch(e) {}
    }

    function saveRowsToJson() {
        if (!isLoaded) return;
        var arr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            var item = rowsModel.get(i);
            var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX !== undefined ? item.offsetX : 0);
            var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin !== undefined ? item.topMargin : 0);
            arr.push({
                "format": item.format,
                "fontFamily": item.showFontFamily ? (item.fontFamily || "") : "",
                "align": item.showAlign ? (item.align || "center") : "center",
                "fontSize": item.fontSize || 24,
                "color": item.color || "#ffffff",
                "effectColor": item.showEffect ? (item.effectColor || "") : "",
                "weight": item.showWeight ? (item.weight || "400") : "400",
                "effect": item.showEffect ? (item.effect || "none") : "none",
                "opacity": item.showOpacity && item.opacity !== undefined ? item.opacity : 1.0,
                "offsetWidth": item.showOffsets ? offX : 0,
                "offsetHeight": item.showOffsets ? offY : 0,
                "offsetX": item.showOffsets ? offX : 0,
                "topMargin": item.showOffsets ? offY : 0,
                "letterSpacing": item.showLetterSpacing && item.letterSpacing !== undefined ? item.letterSpacing : 0,
                "effectSize": item.showEffect && item.effectSize !== undefined ? item.effectSize : 2,
                "timeZone": item.showTimeZone ? (item.timeZone || "") : "",
                "locale": item.showLocale ? (item.locale || "") : "",
                "clickCommand": item.showClickCommand ? (item.clickCommand || "") : "",
                "glow": item.showEffect && item.effect === "glow"
            });
        }
        var jsonStr = JSON.stringify(arr);
        isSaving = true;
        rowsJsonHolder.text = jsonStr;
        pushLivePreview();
        markChanged();
        isSaving = false;
    }

    function save() {
        cleanStockDefaults();
        saveRowsToJson();
        try {
            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.rowsJson = cfg_rowsJson;
                if (fontCombo && fontCombo.selectedFont) pConfig.fontFamily = fontCombo.selectedFont;
                if (bgTypeCombo) pConfig.bgType = bgTypeCombo.currentIndex;
                if (bgColorInput) pConfig.bgColor = bgColorInput.text;
            }
        } catch(e) {}
    }

    function load() {
        loadRowsFromJson();
        pushLivePreview();
    }

    ListModel {
        id: rowsModel

        function removeRow(idx) {
            if (count > 1 && idx >= 0 && idx < count) {
                remove(idx);
                saveToJson();
            }
        }

        function moveRow(fromIdx, toIdx) {
            if (fromIdx >= 0 && fromIdx < count && toIdx >= 0 && toIdx < count) {
                move(fromIdx, toIdx, 1);
                saveToJson();
            }
        }

        function saveToJson() {
            saveRowsToJson();
        }
    }

    Kirigami.FormLayout {
        id: formLayout

        ComboBox {
            id: fontCombo
            Kirigami.FormData.label: i18n("Font Family:")

            property string selectedFont: "Sans Serif"
            model: sharedFontOnlyModel
            textRole: "text"
            valueRole: "fontName"

            onPressedChanged: {
                if (pressed) buildSharedFontModels();
            }

            Binding on currentIndex {
                value: {
                    if (!fontCombo.selectedFont) return 0;
                    for (var m = 0; m < sharedFontOnlyModel.count; m++) {
                        if (sharedFontOnlyModel.get(m).fontName === fontCombo.selectedFont) return m;
                    }
                    return 0;
                }
            }

            onActivated: function(index) {
                if (index >= 0 && index < sharedFontOnlyModel.count) {
                    selectedFont = sharedFontOnlyModel.get(index).fontName;
                    pushLivePreview();
                    markChanged();
                }
            }
        }

        ComboBox {
            id: bgTypeCombo
            Kirigami.FormData.label: i18n("Background Style:")
            model: [
                i18n("Blurred Glass"),
                i18n("Solid Color"),
                i18n("Transparent (No Background)")
            ]
            onActivated: function(index) {
                pushLivePreview();
                markChanged();
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background Color:")

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
                            pushLivePreview();
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
                    pushLivePreview();
                    markChanged();
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Row Configuration")
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Rows:")
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: rowsModel

                delegate: Frame {
                    Layout.fillWidth: true
                    padding: 8

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        // Header Row (Row title + Reorder & Remove controls)
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: i18n("Row ") + (index + 1)
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: i18n("▲")
                                enabled: index > 0
                                onClicked: {
                                    rowsModel.moveRow(index, index - 1);
                                }
                            }
                            Button {
                                text: i18n("▼")
                                enabled: index < rowsModel.count - 1
                                onClicked: {
                                    rowsModel.moveRow(index, index + 1);
                                }
                            }
                            Button {
                                text: i18n("Remove")
                                enabled: rowsModel.count > 1
                                onClicked: {
                                    rowsModel.removeRow(index);
                                }
                            }
                        }

                        // Core Always-Visible Controls (Format, Font Size, Text Color, + Add Option...)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label { text: i18n("Format:") }
                            TextField {
                                Layout.fillWidth: true
                                Binding on text { value: model.format || "" }
                                placeholderText: "e.g. dddd, dd mmm yyy, H:i"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "format", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            Label { text: i18n("Size:") }
                            SpinBox {
                                from: 1
                                to: 1000
                                value: model.fontSize || 24
                                onValueModified: {
                                    rowsModel.setProperty(index, "fontSize", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("Color:") }
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 4
                                color: model.color || "#ffffff"
                                border.color: Kirigami.Theme.disabledTextColor
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        configPage.openColorPicker(model.color || "#ffffff", function(hex) {
                                            if (configPage.isLoaded) {
                                                rowsModel.setProperty(index, "color", hex);
                                                rowsModel.saveToJson();
                                            }
                                        });
                                    }
                                }
                            }
                            TextField {
                                Layout.preferredWidth: 80
                                Binding on text { value: model.color || "#ffffff" }
                                placeholderText: "#ffffff"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "color", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            ComboBox {
                                id: addOptionCombo
                                textRole: "text"
                                model: [
                                    { text: i18n("+ Add Option..."), value: "" },
                                    { text: i18n("Timezone"), value: "timeZone" },
                                    { text: i18n("Locale"), value: "locale" },
                                    { text: i18n("Click Command"), value: "clickCommand" },
                                    { text: i18n("Font Family"), value: "fontFamily" },
                                    { text: i18n("Font Weight"), value: "weight" },
                                    { text: i18n("Alignment"), value: "align" },
                                    { text: i18n("Opacity"), value: "opacity" },
                                    { text: i18n("Offsets (X/Y)"), value: "offsets" },
                                    { text: i18n("Letter Spacing"), value: "letterSpacing" },
                                    { text: i18n("Text Effect"), value: "effect" }
                                ]
                                currentIndex: 0
                                onActivated: function(idx) {
                                    if (idx <= 0) return;
                                    var val = addOptionCombo.model[idx].value;
                                    if (val === "timeZone") { rowsModel.setProperty(index, "timeZone", "UTC"); rowsModel.setProperty(index, "showTimeZone", true); }
                                    else if (val === "locale") { rowsModel.setProperty(index, "locale", "ja_JP"); rowsModel.setProperty(index, "showLocale", true); }
                                    else if (val === "clickCommand") { rowsModel.setProperty(index, "clickCommand", "kcalc"); rowsModel.setProperty(index, "showClickCommand", true); }
                                    else if (val === "fontFamily") { rowsModel.setProperty(index, "fontFamily", sharedFontModel.count > 1 ? sharedFontModel.get(1).fontName : "Sans Serif"); rowsModel.setProperty(index, "showFontFamily", true); }
                                    else if (val === "weight") { rowsModel.setProperty(index, "weight", "700"); rowsModel.setProperty(index, "showWeight", true); }
                                    else if (val === "align") { rowsModel.setProperty(index, "align", "left"); rowsModel.setProperty(index, "showAlign", true); }
                                    else if (val === "opacity") { rowsModel.setProperty(index, "opacity", 0.8); rowsModel.setProperty(index, "showOpacity", true); }
                                    else if (val === "offsets") {
                                        rowsModel.setProperty(index, "offsetWidth", 10);
                                        rowsModel.setProperty(index, "offsetX", 10);
                                        rowsModel.setProperty(index, "offsetHeight", -10);
                                        rowsModel.setProperty(index, "topMargin", -10);
                                        rowsModel.setProperty(index, "showOffsets", true);
                                    }
                                    else if (val === "letterSpacing") { rowsModel.setProperty(index, "letterSpacing", 2); rowsModel.setProperty(index, "showLetterSpacing", true); }
                                    else if (val === "effect") { rowsModel.setProperty(index, "effect", "glow"); rowsModel.setProperty(index, "showEffect", true); }
                                    rowsModel.saveToJson();
                                    currentIndex = 0;
                                }
                            }
                        }

                        // --- Dynamic Optional Setting Rows (Only visible when set) ---

                        // 1. Timezone
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showTimeZone === true
                            Label { text: i18n("Timezone:") }
                            TextField {
                                Layout.fillWidth: true
                                Binding on text { value: model.timeZone || "" }
                                placeholderText: "Local (or UTC, America/New_York, Europe/London, Asia/Tokyo...)"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "timeZone", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "timeZone", "");
                                    rowsModel.setProperty(index, "showTimeZone", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 2. Locale
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showLocale === true
                            Label { text: i18n("Locale:") }
                            TextField {
                                Layout.fillWidth: true
                                Binding on text { value: model.locale || "" }
                                placeholderText: "System Default (e.g. ja_JP, fr_FR, de_DE, es_ES, uk_UA, zh_CN)"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "locale", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "locale", "");
                                    rowsModel.setProperty(index, "showLocale", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 3. Click Command
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showClickCommand === true
                            Label { text: i18n("Click Command:") }
                            TextField {
                                Layout.fillWidth: true
                                Binding on text { value: model.clickCommand || "" }
                                placeholderText: "Executable command on click (e.g. kcalc, korganizer, brave)"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "clickCommand", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "clickCommand", "");
                                    rowsModel.setProperty(index, "showClickCommand", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 4. Custom Font Family
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showFontFamily === true
                            Label { text: i18n("Font Family:") }
                            ComboBox {
                                id: rowFontCombo
                                Layout.fillWidth: true
                                model: sharedFontModel
                                textRole: "text"
                                valueRole: "fontName"
                                onPressedChanged: {
                                    if (pressed) buildSharedFontModels();
                                }
                                Binding on currentIndex {
                                    value: {
                                        var f = model.fontFamily || "";
                                        if (!f || f === "") return 0;
                                        for (var m = 1; m < sharedFontModel.count; m++) {
                                            if (sharedFontModel.get(m).fontName === f) return m;
                                        }
                                        return 0;
                                    }
                                }
                                onActivated: function(idx) {
                                    var selected = (idx <= 0) ? "" : sharedFontModel.get(idx).fontName;
                                    rowsModel.setProperty(index, "fontFamily", selected);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "fontFamily", "");
                                    rowsModel.setProperty(index, "showFontFamily", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 5. Font Weight
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showWeight === true
                            Label { text: i18n("Font Weight:") }
                            ComboBox {
                                id: weightCombo
                                model: [
                                    { text: i18n("Light (300)"), value: "300" },
                                    { text: i18n("Normal (400)"), value: "400" },
                                    { text: i18n("SemiBold (600)"), value: "600" },
                                    { text: i18n("Bold (700)"), value: "700" },
                                    { text: i18n("Black (900)"), value: "900" }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                Binding on currentIndex {
                                    value: {
                                        var w = String(model.weight || "400");
                                        if (w === "300") return 0;
                                        if (w === "400") return 1;
                                        if (w === "600") return 2;
                                        if (w === "700") return 3;
                                        if (w === "900") return 4;
                                        return 1;
                                    }
                                }
                                onActivated: function(idx) {
                                    var selectedWeight = weightCombo.model[idx].value;
                                    rowsModel.setProperty(index, "weight", selectedWeight);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "weight", "400");
                                    rowsModel.setProperty(index, "showWeight", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 6. Alignment
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showAlign === true
                            Label { text: i18n("Alignment:") }
                            ComboBox {
                                id: alignCombo
                                model: ["center", "left", "right"]
                                Binding on currentIndex {
                                    value: {
                                        var a = model.align || "center";
                                        if (a === "left") return 1;
                                        if (a === "right") return 2;
                                        return 0;
                                    }
                                }
                                onActivated: function(idx) {
                                    var selectedAlign = alignCombo.model[idx];
                                    rowsModel.setProperty(index, "align", selectedAlign);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "align", "center");
                                    rowsModel.setProperty(index, "showAlign", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 7. Opacity
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showOpacity === true
                            Label { text: i18n("Opacity (%):") }
                            SpinBox {
                                from: 10
                                to: 100
                                stepSize: 5
                                value: Math.round((model.opacity !== undefined ? model.opacity : 1.0) * 100)
                                onValueModified: {
                                    rowsModel.setProperty(index, "opacity", value / 100.0);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "opacity", 1.0);
                                    rowsModel.setProperty(index, "showOpacity", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 8. Offsets (Width X / Height Y)
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showOffsets === true
                            spacing: 8

                            Label { text: i18n("Offset Width (X):") }
                            SpinBox {
                                from: -1000
                                to: 1000
                                stepSize: 2
                                value: model.offsetWidth !== undefined ? model.offsetWidth : (model.offsetX !== undefined ? model.offsetX : 0)
                                onValueModified: {
                                    rowsModel.setProperty(index, "offsetWidth", value);
                                    rowsModel.setProperty(index, "offsetX", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("Offset Height (Y):") }
                            SpinBox {
                                from: -1000
                                to: 1000
                                stepSize: 2
                                value: model.offsetHeight !== undefined ? model.offsetHeight : (model.topMargin !== undefined ? model.topMargin : 0)
                                onValueModified: {
                                    rowsModel.setProperty(index, "offsetHeight", value);
                                    rowsModel.setProperty(index, "topMargin", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "offsetWidth", 0);
                                    rowsModel.setProperty(index, "offsetX", 0);
                                    rowsModel.setProperty(index, "offsetHeight", 0);
                                    rowsModel.setProperty(index, "topMargin", 0);
                                    rowsModel.setProperty(index, "showOffsets", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 10. Letter Spacing
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showLetterSpacing === true
                            Label { text: i18n("Letter Spacing (px):") }
                            SpinBox {
                                from: -1000
                                to: 1000
                                stepSize: 1
                                value: model.letterSpacing !== undefined ? model.letterSpacing : 0
                                onValueModified: {
                                    rowsModel.setProperty(index, "letterSpacing", value);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "letterSpacing", 0);
                                    rowsModel.setProperty(index, "showLetterSpacing", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 11. Text Effect
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showEffect === true
                            spacing: 8

                            Label { text: i18n("Effect:") }
                            ComboBox {
                                id: effectCombo
                                model: [
                                    { text: i18n("None"), value: "none" },
                                    { text: i18n("Neon Glow"), value: "glow" },
                                    { text: i18n("Normal Shadow"), value: "normalShadow" },
                                    { text: i18n("Drop Shadow"), value: "shadow" },
                                    { text: i18n("Outer Stroke"), value: "stroke" }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                Binding on currentIndex {
                                    value: {
                                        var e = model.effect || "none";
                                        if (e === "glow") return 1;
                                        if (e === "normalShadow") return 2;
                                        if (e === "shadow") return 3;
                                        if (e === "stroke") return 4;
                                        return 0;
                                    }
                                }
                                onActivated: function(idx) {
                                    var selectedEffect = effectCombo.model[idx].value;
                                    rowsModel.setProperty(index, "effect", selectedEffect);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("Color:") }
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 4
                                color: model.effectColor && model.effectColor.length > 0 ? model.effectColor : "transparent"
                                border.color: Kirigami.Theme.disabledTextColor
                                border.width: 1

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 1
                                    color: "#ff0000"
                                    visible: !model.effectColor || model.effectColor.length === 0
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        configPage.openColorPicker(model.effectColor || "#000000", function(hex) {
                                            if (configPage.isLoaded) {
                                                rowsModel.setProperty(index, "effectColor", hex);
                                                rowsModel.saveToJson();
                                            }
                                        });
                                    }
                                }
                            }
                            TextField {
                                Layout.preferredWidth: 80
                                Binding on text { value: model.effectColor || "" }
                                placeholderText: "#000000"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "effectColor", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            Label { text: i18n("Size:") }
                            SpinBox {
                                from: 1
                                to: 50
                                stepSize: 1
                                value: model.effectSize !== undefined ? model.effectSize : 2
                                onValueModified: {
                                    rowsModel.setProperty(index, "effectSize", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "effect", "none");
                                    rowsModel.setProperty(index, "effectColor", "");
                                    rowsModel.setProperty(index, "effectSize", 2);
                                    rowsModel.setProperty(index, "showEffect", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                    }
                }
            }

            Button {
                text: i18n("+ Add Row")
                Layout.alignment: Qt.AlignLeft
                onClicked: {
                    rowsModel.append({
                        "format": "H:i:ss",
                        "align": "center",
                        "fontSize": 24,
                        "color": "#ffffff",
                        "effectColor": "",
                        "weight": "400",
                        "effect": "none",
                        "opacity": 1.0,
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
        }
    }
}
