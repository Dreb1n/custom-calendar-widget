import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_fontFamily: fontInput.text
    property alias cfg_bgType: bgTypeCombo.currentIndex
    property alias cfg_bgColor: bgColorInput.text
    property alias cfg_rowsJson: rowsJsonHidden.text

    property var rowsList: []
    property bool isLoaded: false

    function loadRowsFromJson() {
        try {
            if (cfg_rowsJson && cfg_rowsJson.length > 0) {
                rowsList = JSON.parse(cfg_rowsJson);
            } else {
                rowsList = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#818cf8", "effectColor": "", "weight": "600", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": "700", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#38bdf8", "effectColor": "#38bdf8", "weight": "800", "effect": "glow", "opacity": 1.0, "timeZone": "" }
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
                "weight": item.weight || "600",
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

        TextField {
            id: fontInput
            Kirigami.FormData.label: i18n("Font Family:")
            placeholderText: "Sans Serif, Inter, Roboto, Orbitron..."
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

        TextField {
            id: bgColorInput
            Kirigami.FormData.label: i18n("Background Color:")
            placeholderText: "#1e293b"
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
                                onTextChanged: {
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
                                onTextChanged: {
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
                            TextField {
                                text: model.color || "#ffffff"
                                placeholderText: "#ffffff"
                                onTextChanged: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "color", text);
                                        saveRowsToJson();
                                    }
                                }
                            }

                            Label { text: i18n("Effect Color:") }
                            TextField {
                                text: model.effectColor || ""
                                placeholderText: "#000000"
                                onTextChanged: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "effectColor", text);
                                        saveRowsToJson();
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
                        "weight": "600",
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
