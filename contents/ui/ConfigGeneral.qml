import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: appearancePage

    property alias cfg_fontFamily: fontInput.text
    property alias cfg_bgType: bgTypeCombo.currentText
    property alias cfg_bgColor: bgColorInput.text
    property alias cfg_rowsJson: rowsJsonHidden.text

    property var rowsList: []

    function loadRowsFromJson() {
        try {
            if (cfg_rowsJson && cfg_rowsJson.length > 0) {
                rowsList = JSON.parse(cfg_rowsJson);
            } else {
                rowsList = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#818cf8", "weight": "600", "glow": false },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "weight": "700", "glow": false },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#38bdf8", "weight": "800", "glow": true }
                ];
            }
        } catch(e) {
            rowsList = [];
        }
        rowsModel.clear();
        for (var i = 0; i < rowsList.length; i++) {
            rowsModel.append(rowsList[i]);
        }
    }

    function saveRowsToJson() {
        var arr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            var item = rowsModel.get(i);
            arr.push({
                "format": item.format,
                "align": item.align,
                "fontSize": item.fontSize,
                "color": item.color,
                "weight": item.weight,
                "glow": item.glow
            });
        }
        cfg_rowsJson = JSON.stringify(arr);
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
            model: ["glass", "solid", "transparent"]
        }

        TextField {
            id: bgColorInput
            Kirigami.FormData.label: i18n("Background Color:")
            placeholderText: "#1e293b"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            label: i18n("Row Configuration")
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
                                    rowsModel.setProperty(index, "format", text);
                                    saveRowsToJson();
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: i18n("Alignment:") }
                            ComboBox {
                                model: ["center", "left", "right"]
                                currentIndex: model.align === "left" ? 1 : (model.align === "right" ? 2 : 0)
                                onActivated: {
                                    rowsModel.setProperty(index, "align", currentText);
                                    saveRowsToJson();
                                }
                            }

                            Label { text: i18n("Font Size:") }
                            SpinBox {
                                from: 10
                                to: 100
                                value: model.fontSize
                                onValueChanged: {
                                    rowsModel.setProperty(index, "fontSize", value);
                                    saveRowsToJson();
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: i18n("Text Color:") }
                            TextField {
                                text: model.color
                                placeholderText: "#ffffff"
                                onTextChanged: {
                                    rowsModel.setProperty(index, "color", text);
                                    saveRowsToJson();
                                }
                            }

                            CheckBox {
                                text: i18n("Neon Glow")
                                checked: model.glow
                                onCheckedChanged: {
                                    rowsModel.setProperty(index, "glow", checked);
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
                        "weight": "600",
                        "glow": false
                    });
                    saveRowsToJson();
                }
            }
        }
    }
}
