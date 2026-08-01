import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_fontFamily: fontCombo.selectedFont
    property alias cfg_bgType: bgTypeCombo.currentIndex
    property alias cfg_bgColor: bgColorInput.text
    property alias cfg_rowsJson: rowsJsonHidden.text

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

    readonly property var systemFonts: {
        var rawFonts = Qt.fontFamilies();
        var seen = {};
        var cleanList = [];
        var allLower = {};

        var weightSuffixRegex = /\s+(Thin|ExtraLight|UltraLight|Light|Book|Regular|Medium|SemiBold|DemiBold|Bold|ExtraBold|UltraBold|Black|Heavy|Hair|Four|Eight)$/i;

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
                if (allLower[baseName.toLowerCase()]) {
                    continue;
                }
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

        return cleanList;
    }

    function loadRowsFromJson() {
        try {
            if (cfg_rowsJson && cfg_rowsJson.length > 0) {
                rowsList = JSON.parse(cfg_rowsJson);
            } else {
                rowsList = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#ffffff", "effectColor": "", "weight": "400", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": "400", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#ffffff", "effectColor": "", "weight": "600", "effect": "none", "opacity": 1.0, "timeZone": "" }
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
            rowsModel.append(item);
        }
        isLoaded = true;
    }

    function saveRowsToJson() {
        if (!isLoaded) return;
        var arr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            var item = rowsModel.get(i);
            arr.push({
                "format": item.format,
                "align": item.align || "center",
                "fontSize": item.fontSize || 24,
                "color": item.color || "#ffffff",
                "effectColor": item.effectColor || "",
                "weight": item.weight || "400",
                "effect": item.effect || "none",
                "opacity": item.opacity !== undefined ? item.opacity : 1.0,
                "timeZone": item.timeZone || "",
                "glow": item.effect === "glow"
            });
        }
        var jsonStr = JSON.stringify(arr);
        rowsJsonHidden.text = jsonStr;
        // NOTE FOR DEVELOPERS:
        // Plasma 6 KCMUtils auto-save tracking only listens for native user input signals.
        // Calling .textEdited() manually forces KCMUtils to recognize programmatically updated
        // rowsJson and enables ("lights up") the Plasma Apply button instantly.
        rowsJsonHidden.textEdited();
    }

    Component.onCompleted: {
        loadRowsFromJson();
    }

    ListModel {
        id: rowsModel
    }

    TextField {
        id: rowsJsonHidden
        visible: false
    }

    Kirigami.FormLayout {
        id: formLayout

        ComboBox {
            id: fontCombo
            Kirigami.FormData.label: i18n("Font Family:")

            property string selectedFont: "Sans Serif"
            model: configPage.systemFonts

            font.family: selectedFont

            Component.onCompleted: syncIndex()
            onModelChanged: syncIndex()
            onSelectedFontChanged: syncIndex()

            function syncIndex() {
                if (!model || model.length === 0) return;
                var idx = model.indexOf(selectedFont);
                if (idx >= 0 && currentIndex !== idx) {
                    currentIndex = idx;
                }
            }

            onActivated: function(index) {
                selectedFont = model[index];
            }

            delegate: ItemDelegate {
                id: fontDelegate
                width: fontCombo.width
                implicitHeight: 36
                clip: true
                required property string modelData
                required property int index

                contentItem: Label {
                    text: fontDelegate.modelData
                    font.family: fontDelegate.modelData
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
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
                        });
                    }
                }
            }

            TextField {
                id: bgColorInput
                Layout.fillWidth: true
                placeholderText: "#1e293b"
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
                                    rowsModel.move(index, index - 1, 1);
                                    saveRowsToJson();
                                }
                            }
                            Button {
                                text: i18n("▼")
                                enabled: index < rowsModel.count - 1
                                onClicked: {
                                    rowsModel.move(index, index + 1, 1);
                                    saveRowsToJson();
                                }
                            }
                            Button {
                                text: i18n("Remove")
                                enabled: rowsModel.count > 1
                                onClicked: {
                                    rowsModel.remove(index);
                                    saveRowsToJson();
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: i18n("Format:") }
                            TextField {
                                Layout.fillWidth: true
                                text: model.format
                                placeholderText: "e.g. dddd, dd mmm yyy, H:i"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "format", text);
                                        saveRowsToJson();
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: i18n("Timezone:") }
                            TextField {
                                Layout.fillWidth: true
                                text: model.timeZone || ""
                                placeholderText: "Local (or UTC, America/New_York, Europe/London, Asia/Tokyo...)"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "timeZone", text);
                                        saveRowsToJson();
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: i18n("Alignment:") }
                            ComboBox {
                                id: alignCombo
                                model: ["center", "left", "right"]
                                currentIndex: {
                                    var a = model.align || "center";
                                    if (a === "left") return 1;
                                    if (a === "right") return 2;
                                    return 0;
                                }
                                onActivated: function(idx) {
                                    var selectedAlign = alignCombo.model[idx];
                                    rowsModel.setProperty(index, "align", selectedAlign);
                                    saveRowsToJson();
                                }
                            }

                            Label { text: i18n("Font Size:") }
                            SpinBox {
                                from: 10
                                to: 120
                                value: model.fontSize || 24
                                onValueModified: {
                                    rowsModel.setProperty(index, "fontSize", value);
                                    saveRowsToJson();
                                }
                            }

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
                                currentIndex: {
                                    var w = String(model.weight || "400");
                                    if (w === "300") return 0;
                                    if (w === "400") return 1;
                                    if (w === "600") return 2;
                                    if (w === "700") return 3;
                                    if (w === "900") return 4;
                                    return 1;
                                }
                                onActivated: function(idx) {
                                    var selectedWeight = weightCombo.model[idx].value;
                                    rowsModel.setProperty(index, "weight", selectedWeight);
                                    saveRowsToJson();
                                }
                            }

                            Label { text: i18n("Opacity (%):") }
                            SpinBox {
                                from: 10
                                to: 100
                                stepSize: 5
                                value: Math.round((model.opacity !== undefined ? model.opacity : 1.0) * 100)
                                onValueModified: {
                                    rowsModel.setProperty(index, "opacity", value / 100.0);
                                    saveRowsToJson();
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: i18n("Text Color:") }
                            RowLayout {
                                spacing: 4
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
                                                    saveRowsToJson();
                                                }
                                            });
                                        }
                                    }
                                }
                                TextField {
                                    text: model.color || "#ffffff"
                                    placeholderText: "#ffffff"
                                    onTextEdited: {
                                        if (configPage.isLoaded) {
                                            rowsModel.setProperty(index, "color", text);
                                            saveRowsToJson();
                                        }
                                    }
                                }
                            }

                            Label { text: i18n("Effect Color:") }
                            RowLayout {
                                spacing: 4
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
                                                    saveRowsToJson();
                                                }
                                            });
                                        }
                                    }
                                }
                                TextField {
                                    text: model.effectColor || ""
                                    placeholderText: "#000000"
                                    onTextEdited: {
                                        if (configPage.isLoaded) {
                                            rowsModel.setProperty(index, "effectColor", text);
                                            saveRowsToJson();
                                        }
                                    }
                                }
                            }

                            Label { text: i18n("Text Effect:") }
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
                                currentIndex: {
                                    var e = model.effect || "none";
                                    if (e === "glow") return 1;
                                    if (e === "normalShadow") return 2;
                                    if (e === "shadow") return 3;
                                    if (e === "stroke") return 4;
                                    return 0;
                                }
                                onActivated: function(idx) {
                                    var selectedEffect = effectCombo.model[idx].value;
                                    rowsModel.setProperty(index, "effect", selectedEffect);
                                    saveRowsToJson();
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
                        "timeZone": ""
                    });
                    saveRowsToJson();
                }
            }
        }
    }
}
