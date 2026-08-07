import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

Frame {
    id: delegateFrame

    property bool isItemShape: (model.isShape === true || model.isShape === "true") && (model.format === undefined || model.format === "")

    Layout.fillWidth: true
    padding: 8

    ColumnLayout {
        // --- Dynamic Optional Setting Rows (Only visible when set) ---

        anchors.fill: parent
        spacing: 6

        // Header Row (Row title + Reorder & Remove controls)
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: delegateFrame.isItemShape ? (i18n("Shape ") + (index + 1)) : (i18n("Row ") + (index + 1))
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

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

        // Shape Always-Visible Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: delegateFrame.isItemShape

            Label {
                text: i18n("Shape:")
            }

            ComboBox {
                id: shapeCombo

                textRole: "text"
                valueRole: "value"
                model: shapeTypesModel
                currentIndex: {
                    var st = model.shapeType || "circle";
                    for (var s = 0; s < shapeTypesModel.count; s++) {
                        if (shapeTypesModel.get(s).value === st)
                            return s;

                    }
                    return 0;
                }
                onActivated: function(sIdx) {
                    if (sIdx >= 0 && sIdx < shapeTypesModel.count) {
                        rowsModel.setProperty(index, "shapeType", shapeTypesModel.get(sIdx).value);
                        rowsModel.saveToJson();
                    }
                }
            }

            Label {
                text: i18n("W:")
            }

            SpinBox {
                from: 1
                to: 1000
                stepSize: 5
                value: model.shapeWidth || 100
                onValueModified: {
                    rowsModel.setProperty(index, "shapeWidth", value);
                    rowsModel.saveToJson();
                }
            }

            Label {
                text: i18n("H:")
            }

            SpinBox {
                from: 1
                to: 1000
                stepSize: 5
                value: model.shapeHeight || 100
                onValueModified: {
                    rowsModel.setProperty(index, "shapeHeight", value);
                    rowsModel.saveToJson();
                }
            }

            Label {
                text: i18n("Color:")
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 4
                color: model.color || "#3b82f6"
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        configPage.openColorPicker(model.color || "#3b82f6", function(hex) {
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
                placeholderText: "#3b82f6"
                onTextEdited: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "color", text);
                        rowsModel.saveToJson();
                    }
                }

                Binding on text {
                    value: model.color || "#3b82f6"
                }

            }

            ComboBox {
                id: addShapeOptionCombo

                textRole: "text"
                model: [{
                    "text": i18n("+ Add Option..."),
                    "value": ""
                }, {
                    "text": i18n("Click Command"),
                    "value": "clickCommand"
                }, {
                    "text": i18n("Alignment"),
                    "value": "align"
                }, {
                    "text": i18n("Opacity"),
                    "value": "opacity"
                }, {
                    "text": i18n("Offsets (X/Y)"),
                    "value": "offsets"
                }, {
                    "text": i18n("Rotation (°)"),
                    "value": "rotation"
                }, {
                    "text": i18n("Shape Effect"),
                    "value": "effect"
                }, {
                    "text": i18n("Overlay Layer"),
                    "value": "overlay"
                }]
                currentIndex: 0
                onActivated: function(idx) {
                    if (idx <= 0)
                        return ;

                    var val = addShapeOptionCombo.model[idx].value;
                    if (val === "clickCommand") {
                        rowsModel.setProperty(index, "clickCommand", "kcalc");
                        rowsModel.setProperty(index, "showClickCommand", true);
                    } else if (val === "align") {
                        rowsModel.setProperty(index, "align", "left");
                        rowsModel.setProperty(index, "showAlign", true);
                    } else if (val === "opacity") {
                        rowsModel.setProperty(index, "opacity", 0.8);
                        rowsModel.setProperty(index, "showOpacity", true);
                    } else if (val === "offsets") {
                        rowsModel.setProperty(index, "offsetWidth", 10);
                        rowsModel.setProperty(index, "offsetX", 10);
                        rowsModel.setProperty(index, "offsetHeight", -10);
                        rowsModel.setProperty(index, "topMargin", -10);
                        rowsModel.setProperty(index, "showOffsets", true);
                    } else if (val === "rotation") {
                        rowsModel.setProperty(index, "rotation", 45);
                        rowsModel.setProperty(index, "showRotation", true);
                    } else if (val === "effect") {
                        rowsModel.setProperty(index, "effect", "glow");
                        rowsModel.setProperty(index, "effectOpacity", 1);
                        rowsModel.setProperty(index, "showEffect", true);
                    } else if (val === "overlay") {
                        rowsModel.setProperty(index, "overlayType", 1);
                        rowsModel.setProperty(index, "overlayColor", "#000000");
                        rowsModel.setProperty(index, "overlayOpacity", 0.5);
                        rowsModel.setProperty(index, "overlayFile", "");
                        rowsModel.setProperty(index, "showOverlay", true);
                    }
                    rowsModel.saveToJson();
                    currentIndex = 0;
                }
            }

        }

        // Core Always-Visible Controls (Format, Font Size, Text Color, + Add Option...)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: !delegateFrame.isItemShape

            Label {
                text: i18n("Format:")
            }

            TextField {
                Layout.fillWidth: true
                placeholderText: "e.g. dddd, dd mmm yyy, H:i"
                onTextEdited: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "format", text);
                        rowsModel.saveToJson();
                    }
                }

                Binding on text {
                    value: model.format || ""
                }

            }

            Label {
                text: i18n("Size:")
            }

            SpinBox {
                from: 1
                to: 1000
                value: model.fontSize || 24
                onValueModified: {
                    rowsModel.setProperty(index, "fontSize", value);
                    rowsModel.saveToJson();
                }
            }

            Label {
                text: i18n("Color:")
            }

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
                placeholderText: "#ffffff"
                onTextEdited: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "color", text);
                        rowsModel.saveToJson();
                    }
                }

                Binding on text {
                    value: model.color || "#ffffff"
                }

            }

            ComboBox {
                id: addOptionCombo

                textRole: "text"
                valueRole: "value"
                model: [{
                    "text": i18n("+ Add Option..."),
                    "value": ""
                }, {
                    "text": i18n("Timezone"),
                    "value": "timeZone"
                }, {
                    "text": i18n("Locale"),
                    "value": "locale"
                }, {
                    "text": i18n("Click Command"),
                    "value": "clickCommand"
                }, {
                    "text": i18n("Font Family"),
                    "value": "fontFamily"
                }, {
                    "text": i18n("Font Weight"),
                    "value": "weight"
                }, {
                    "text": i18n("Alignment"),
                    "value": "align"
                }, {
                    "text": i18n("Opacity"),
                    "value": "opacity"
                }, {
                    "text": i18n("Offsets (X/Y)"),
                    "value": "offsets"
                }, {
                    "text": i18n("Rotation (°)"),
                    "value": "rotation"
                }, {
                    "text": i18n("Letter Spacing"),
                    "value": "letterSpacing"
                }, {
                    "text": i18n("Text Effect"),
                    "value": "effect"
                }, {
                    "text": i18n("Overlay Layer"),
                    "value": "overlay"
                }]
                currentIndex: 0
                onActivated: function(idx) {
                    if (idx <= 0)
                        return ;

                    var val = addOptionCombo.model[idx].value;
                    if (val === "timeZone") {
                        rowsModel.setProperty(index, "timeZone", "UTC");
                        rowsModel.setProperty(index, "showTimeZone", true);
                    } else if (val === "locale") {
                        rowsModel.setProperty(index, "locale", "ja_JP");
                        rowsModel.setProperty(index, "showLocale", true);
                    } else if (val === "clickCommand") {
                        rowsModel.setProperty(index, "clickCommand", "kcalc");
                        rowsModel.setProperty(index, "showClickCommand", true);
                    } else if (val === "fontFamily") {
                        rowsModel.setProperty(index, "fontFamily", sharedFontModel.count > 1 ? sharedFontModel.get(1).fontName : "Sans Serif");
                        rowsModel.setProperty(index, "showFontFamily", true);
                    } else if (val === "weight") {
                        rowsModel.setProperty(index, "weight", "700");
                        rowsModel.setProperty(index, "showWeight", true);
                    } else if (val === "align") {
                        rowsModel.setProperty(index, "align", "left");
                        rowsModel.setProperty(index, "showAlign", true);
                    } else if (val === "opacity") {
                        rowsModel.setProperty(index, "opacity", 0.8);
                        rowsModel.setProperty(index, "showOpacity", true);
                    } else if (val === "offsets") {
                        rowsModel.setProperty(index, "offsetWidth", 10);
                        rowsModel.setProperty(index, "offsetX", 10);
                        rowsModel.setProperty(index, "offsetHeight", -10);
                        rowsModel.setProperty(index, "topMargin", -10);
                        rowsModel.setProperty(index, "showOffsets", true);
                    } else if (val === "rotation") {
                        rowsModel.setProperty(index, "rotation", 45);
                        rowsModel.setProperty(index, "showRotation", true);
                    } else if (val === "letterSpacing") {
                        rowsModel.setProperty(index, "letterSpacing", 2);
                        rowsModel.setProperty(index, "showLetterSpacing", true);
                    } else if (val === "effect") {
                        rowsModel.setProperty(index, "effect", "glow");
                        rowsModel.setProperty(index, "effectOpacity", 1);
                        rowsModel.setProperty(index, "showEffect", true);
                    } else if (val === "overlay") {
                        rowsModel.setProperty(index, "overlayType", 1);
                        rowsModel.setProperty(index, "overlayColor", "#000000");
                        rowsModel.setProperty(index, "overlayOpacity", 0.5);
                        rowsModel.setProperty(index, "overlayFile", "");
                        rowsModel.setProperty(index, "showOverlay", true);
                    }
                    rowsModel.saveToJson();
                    currentIndex = 0;
                }
            }

        }

        // 9. Rotation
        RowLayout {
            Layout.fillWidth: true
            visible: model.showRotation === true
            spacing: 8

            Label {
                text: i18n("Rotation (°):")
            }

            SpinBox {
                from: -360
                to: 360
                stepSize: 5
                value: model.rotation !== undefined ? model.rotation : 0
                onValueModified: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "rotation", value);
                        rowsModel.saveToJson();
                    }
                }
            }

            Slider {
                Layout.fillWidth: true
                from: -180
                to: 180
                stepSize: 1
                value: model.rotation !== undefined ? model.rotation : 0
                onMoved: {
                    if (configPage.isLoaded) {
                        var v = Math.round(value);
                        rowsModel.setProperty(index, "rotation", v);
                        rowsModel.saveToJson();
                    }
                }
            }

            Button {
                text: "✕"
                onClicked: {
                    rowsModel.setProperty(index, "rotation", 0);
                    rowsModel.setProperty(index, "showRotation", false);
                    rowsModel.saveToJson();
                }
            }

        }

        // 1. Timezone
        ColumnLayout {
            Layout.fillWidth: true
            visible: !delegateFrame.isItemShape && (rowsModel.get(index) ? (rowsModel.get(index).showTimeZone === true || rowsModel.get(index).showTimeZone === "true") : false)
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: i18n("Timezone:")
                }

                ComboBox {
                    id: tzCombo

                    property string currentTzVal: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).timeZone || "") : ""

                    function getIndexForValue(val) {
                        var clean = (val || "").trim().toUpperCase();
                        for (var k = 0; k < configPage.timezoneOptions.length - 1; k++) {
                            if (configPage.timezoneOptions[k].value.toUpperCase() === clean)
                                return k;

                        }
                        return configPage.timezoneOptions.length - 1;
                    }

                    Layout.fillWidth: true
                    model: configPage.timezoneLabels
                    currentIndex: getIndexForValue(currentTzVal)
                    onActivated: function(comboIdx) {
                        if (configPage.isLoaded) {
                            var rIdx = index;
                            var selVal = configPage.timezoneOptions[comboIdx].value;
                            if (selVal !== "__CUSTOM__") {
                                rowsModel.setProperty(rIdx, "timeZone", selVal);
                                rowsModel.setProperty(rIdx, "showTimeZone", true);
                                rowsModel.saveToJson();
                            }
                        }
                    }
                }

                Button {
                    text: "✕"
                    onClicked: {
                        var rIdx = index;
                        rowsModel.setProperty(rIdx, "timeZone", "");
                        rowsModel.setProperty(rIdx, "showTimeZone", false);
                        rowsModel.saveToJson();
                    }
                }

            }

            TextField {
                Layout.fillWidth: true
                visible: tzCombo.currentIndex === configPage.timezoneOptions.length - 1
                text: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).timeZone || "") : ""
                placeholderText: "e.g. Europe/Madrid, America/Sao_Paulo, UTC+3:30..."
                onTextEdited: {
                    if (configPage.isLoaded) {
                        var rIdx = index;
                        rowsModel.setProperty(rIdx, "timeZone", text);
                        rowsModel.setProperty(rIdx, "showTimeZone", true);
                        rowsModel.saveToJson();
                    }
                }
            }

        }

        // 2. Locale
        ColumnLayout {
            Layout.fillWidth: true
            visible: !delegateFrame.isItemShape && (rowsModel.get(index) ? (rowsModel.get(index).showLocale === true || rowsModel.get(index).showLocale === "true") : false)
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: i18n("Locale:")
                }

                ComboBox {
                    id: locCombo

                    property string currentLocVal: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).locale || "") : ""

                    function getIndexForValue(val) {
                        var clean = (val || "").trim().toLowerCase();
                        for (var k = 0; k < configPage.localeOptions.length - 1; k++) {
                            if (configPage.localeOptions[k].value.toLowerCase() === clean)
                                return k;

                        }
                        return configPage.localeOptions.length - 1;
                    }

                    Layout.fillWidth: true
                    model: configPage.localeLabels
                    currentIndex: getIndexForValue(currentLocVal)
                    onActivated: function(comboIdx) {
                        if (configPage.isLoaded) {
                            var rIdx = index;
                            var selVal = configPage.localeOptions[comboIdx].value;
                            if (selVal !== "__CUSTOM__") {
                                rowsModel.setProperty(rIdx, "locale", selVal);
                                rowsModel.setProperty(rIdx, "showLocale", true);
                                rowsModel.saveToJson();
                            }
                        }
                    }
                }

                Button {
                    text: "✕"
                    onClicked: {
                        var rIdx = index;
                        rowsModel.setProperty(rIdx, "locale", "");
                        rowsModel.setProperty(rIdx, "showLocale", false);
                        rowsModel.saveToJson();
                    }
                }

            }

            TextField {
                Layout.fillWidth: true
                visible: locCombo.currentIndex === configPage.localeOptions.length - 1
                text: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).locale || "") : ""
                placeholderText: "e.g. ja_JP, fr_FR, de_DE, es_ES, uk_UA, zh_CN..."
                onTextEdited: {
                    if (configPage.isLoaded) {
                        var rIdx = index;
                        rowsModel.setProperty(rIdx, "locale", text);
                        rowsModel.setProperty(rIdx, "showLocale", true);
                        rowsModel.saveToJson();
                    }
                }
            }

        }

        // 3. Click Command
        RowLayout {
            Layout.fillWidth: true
            visible: model.showClickCommand === true

            Label {
                text: i18n("Click Command:")
            }

            TextField {
                Layout.fillWidth: true
                placeholderText: "Executable command on click (e.g. kcalc, korganizer, brave)"
                onTextEdited: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "clickCommand", text);
                        rowsModel.saveToJson();
                    }
                }

                Binding on text {
                    value: model.clickCommand || ""
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
            visible: !delegateFrame.isItemShape && (rowsModel.get(index) ? (rowsModel.get(index).showFontFamily === true || rowsModel.get(index).showFontFamily === "true") : false)

            Label {
                text: i18n("Font Family:")
            }

            ComboBox {
                id: rowFontCombo

                property string currentFVal: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).fontFamily || "") : ""

                Layout.fillWidth: true
                model: sharedFontModel
                textRole: "text"
                valueRole: "fontName"
                onPressedChanged: {
                    if (pressed)
                        configPage.buildSharedFontModels();

                }
                onActivated: function(idx) {
                    var rIdx = index;
                    var selected = (idx <= 0) ? "" : sharedFontModel.get(idx).fontName;
                    rowsModel.setProperty(rIdx, "fontFamily", selected);
                    rowsModel.saveToJson();
                }

                delegate: ItemDelegate {
                    width: parent ? parent.width : 200
                    highlighted: rowFontCombo.currentIndex === index

                    contentItem: Text {
                        text: model.text
                        font.family: (model.fontName && model.fontName !== "") ? model.fontName : rowFontCombo.font.family
                        font.pixelSize: 14
                        color: parent.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                }

                Binding on currentIndex {
                    value: {
                        var f = rowFontCombo.currentFVal;
                        if (!f || f === "")
                            return 0;

                        for (var m = 1; m < sharedFontModel.count; m++) {
                            if (sharedFontModel.get(m).fontName.toLowerCase() === f.toLowerCase())
                                return m;

                        }
                        return 0;
                    }
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
            visible: !delegateFrame.isItemShape && model.showWeight === true

            Label {
                text: i18n("Font Weight:")
            }

            ComboBox {
                id: weightCombo

                model: [{
                    "text": i18n("Light (300)"),
                    "value": "300"
                }, {
                    "text": i18n("Normal (400)"),
                    "value": "400"
                }, {
                    "text": i18n("SemiBold (600)"),
                    "value": "600"
                }, {
                    "text": i18n("Bold (700)"),
                    "value": "700"
                }, {
                    "text": i18n("Black (900)"),
                    "value": "900"
                }]
                textRole: "text"
                valueRole: "value"
                onActivated: function(idx) {
                    var selectedWeight = weightCombo.model[idx].value;
                    rowsModel.setProperty(index, "weight", selectedWeight);
                    rowsModel.saveToJson();
                }

                Binding on currentIndex {
                    value: {
                        var w = String(model.weight || "400");
                        if (w === "300")
                            return 0;

                        if (w === "400")
                            return 1;

                        if (w === "600")
                            return 2;

                        if (w === "700")
                            return 3;

                        if (w === "900")
                            return 4;

                        return 1;
                    }
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

            Label {
                text: i18n("Alignment:")
            }

            ComboBox {
                id: alignCombo

                model: ["center", "left", "right"]
                onActivated: function(idx) {
                    var selectedAlign = alignCombo.model[idx];
                    rowsModel.setProperty(index, "align", selectedAlign);
                    rowsModel.saveToJson();
                }

                Binding on currentIndex {
                    value: {
                        var a = model.align || "center";
                        if (a === "left")
                            return 1;

                        if (a === "right")
                            return 2;

                        return 0;
                    }
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

            Label {
                text: i18n("Opacity (%):")
            }

            Slider {
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.05
                value: model.opacity !== undefined ? model.opacity : 1
                onMoved: {
                    rowsModel.setProperty(index, "opacity", value);
                    rowsModel.saveToJson();
                }
            }

            Label {
                text: Math.round((model.opacity !== undefined ? model.opacity : 1) * 100) + "%"
                Layout.preferredWidth: 35
            }

            Button {
                text: "✕"
                onClicked: {
                    rowsModel.setProperty(index, "opacity", 1);
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

            Label {
                text: i18n("Offset Width (X):")
            }

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

            Label {
                text: i18n("Offset Height (Y):")
            }

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

            CheckBox {
                text: i18n("From Direct Center")
                checked: model.fromCenter === true || model.fromCenter === "true"
                onCheckedChanged: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "fromCenter", checked);
                        rowsModel.saveToJson();
                    }
                }
            }

            Button {
                text: "✕"
                onClicked: {
                    rowsModel.setProperty(index, "offsetWidth", 0);
                    rowsModel.setProperty(index, "offsetX", 0);
                    rowsModel.setProperty(index, "offsetHeight", 0);
                    rowsModel.setProperty(index, "topMargin", 0);
                    rowsModel.setProperty(index, "fromCenter", false);
                    rowsModel.setProperty(index, "showOffsets", false);
                    rowsModel.saveToJson();
                }
            }

        }

        // 10. Letter Spacing
        RowLayout {
            Layout.fillWidth: true
            visible: !delegateFrame.isItemShape && model.showLetterSpacing === true

            Label {
                text: i18n("Letter Spacing (px):")
            }

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

            Label {
                text: i18n("Effect:")
            }

            ComboBox {
                id: effectCombo

                model: [{
                    "text": i18n("None"),
                    "value": "none"
                }, {
                    "text": i18n("Neon Glow"),
                    "value": "glow"
                }, {
                    "text": i18n("Normal Shadow"),
                    "value": "normalShadow"
                }, {
                    "text": i18n("Drop Shadow"),
                    "value": "shadow"
                }, {
                    "text": i18n("Outer Stroke"),
                    "value": "stroke"
                }]
                textRole: "text"
                valueRole: "value"
                onActivated: function(idx) {
                    var selectedEffect = effectCombo.model[idx].value;
                    rowsModel.setProperty(index, "effect", selectedEffect);
                    rowsModel.saveToJson();
                }

                Binding on currentIndex {
                    value: {
                        var e = model.effect || "none";
                        if (e === "glow")
                            return 1;

                        if (e === "normalShadow")
                            return 2;

                        if (e === "shadow")
                            return 3;

                        if (e === "stroke")
                            return 4;

                        return 0;
                    }
                }

            }

            Label {
                text: i18n("Color:")
            }

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
                placeholderText: "#000000"
                onTextEdited: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "effectColor", text);
                        rowsModel.saveToJson();
                    }
                }

                Binding on text {
                    value: model.effectColor || ""
                }

            }

            Label {
                text: i18n("Size:")
            }

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

            Label {
                text: i18n("Effect Opacity:")
            }

            Slider {
                Layout.preferredWidth: 100
                from: 0
                to: 1
                stepSize: 0.05
                value: model.effectOpacity !== undefined ? model.effectOpacity : 1
                onMoved: {
                    if (configPage.isLoaded) {
                        rowsModel.setProperty(index, "effectOpacity", value);
                        rowsModel.saveToJson();
                    }
                }
            }

            Label {
                text: Math.round((model.effectOpacity !== undefined ? model.effectOpacity : 1) * 100) + "%"
                Layout.preferredWidth: 35
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

        // 12. Overlay Layer
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: model.showOverlay === true

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: i18n("Overlay Type:")
                }

                ComboBox {
                    id: rowOverlayTypeCombo

                    Layout.fillWidth: true
                    model: [i18n("None"), i18n("Solid Color"), i18n("Media File (Image/GIF/Video)")]
                    onActivated: function(oIdx) {
                        if (configPage.isLoaded) {
                            rowsModel.setProperty(index, "overlayType", oIdx);
                            rowsModel.saveToJson();
                        }
                    }

                    Binding on currentIndex {
                        value: model.overlayType !== undefined ? model.overlayType : 0
                    }

                }

                Button {
                    text: "✕"
                    onClicked: {
                        rowsModel.setProperty(index, "overlayType", 0);
                        rowsModel.setProperty(index, "overlayColor", "#000000");
                        rowsModel.setProperty(index, "overlayOpacity", 0.5);
                        rowsModel.setProperty(index, "overlayFile", "");
                        rowsModel.setProperty(index, "showOverlay", false);
                        rowsModel.saveToJson();
                    }
                }

            }

            RowLayout {
                Layout.fillWidth: true
                visible: (model.overlayType !== undefined ? model.overlayType : 0) === 1

                Label {
                    text: i18n("Overlay Color:")
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 4
                    color: model.overlayColor || "#000000"
                    border.color: Kirigami.Theme.disabledTextColor
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            configPage.openColorPicker(model.overlayColor || "#000000", function(hex) {
                                if (configPage.isLoaded) {
                                    rowsModel.setProperty(index, "overlayColor", hex);
                                    rowsModel.saveToJson();
                                }
                            });
                        }
                    }

                }

                TextField {
                    Layout.fillWidth: true
                    placeholderText: "#000000"
                    onTextEdited: {
                        if (configPage.isLoaded) {
                            rowsModel.setProperty(index, "overlayColor", text);
                            rowsModel.saveToJson();
                        }
                    }

                    Binding on text {
                        value: model.overlayColor || "#000000"
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                visible: (model.overlayType !== undefined ? model.overlayType : 0) === 2

                Label {
                    text: i18n("Media File:")
                }

                TextField {
                    id: rowOverlayFileInput

                    Layout.fillWidth: true
                    placeholderText: i18n("Select local image, GIF, or video...")
                    onTextEdited: {
                        if (configPage.isLoaded) {
                            rowsModel.setProperty(index, "overlayFile", text);
                            rowsModel.saveToJson();
                        }
                    }

                    Binding on text {
                        value: model.overlayFile || ""
                    }

                }

                Button {
                    text: i18n("Browse...")
                    icon.name: "document-open"
                    onClicked: {
                        configPage.activeRowIndexForFileDialog = index;
                        overlayFileDialog.open();
                    }
                }

            }

            RowLayout {
                Layout.fillWidth: true
                visible: (model.overlayType !== undefined ? model.overlayType : 0) !== 0

                Label {
                    text: i18n("Opacity:")
                }

                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    stepSize: 0.05
                    value: model.overlayOpacity !== undefined ? model.overlayOpacity : 0.5
                    onMoved: {
                        if (configPage.isLoaded) {
                            rowsModel.setProperty(index, "overlayOpacity", value);
                            rowsModel.saveToJson();
                        }
                    }
                }

                Label {
                    text: Math.round((model.overlayOpacity !== undefined ? model.overlayOpacity : 0.5) * 100) + "%"
                    Layout.preferredWidth: 35
                }

            }

        }

    }

}
