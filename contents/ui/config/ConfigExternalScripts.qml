import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

Kirigami.FormLayout {
    id: configScriptsPage

    property bool isLoaded: false

    ListModel {
        id: scriptsModel

        function getNextScriptId() {
            var maxId = 0;
            for (var i = 0; i < scriptsModel.count; i++) {
                var item = scriptsModel.get(i);
                var sid = item.scriptId;
                if (sid && sid.indexOf("script_") === 0) {
                    var num = parseInt(sid.substring(7), 10);
                    if (!isNaN(num) && num > maxId)
                        maxId = num;
                }
            }
            return "script_" + (maxId + 1);
        }

        function saveToJson() {
            if (!configScriptsPage.isLoaded)
                return;

            var list = [];
            for (var i = 0; i < scriptsModel.count; i++) {
                var item = scriptsModel.get(i);
                list.push({
                    "scriptId": item.scriptId || ("script_" + (i + 1)),
                    "name": item.name || "",
                    "scriptPath": item.scriptPath || "",
                    "runOnBoot": item.runOnBoot === true,
                    "interval": item.interval !== undefined ? item.interval : 0,
                    "enabled": item.enabled !== false
                });
            }
            plasmoid.configuration.externalScriptsJson = JSON.stringify(list);
        }
    }

    Component.onCompleted: {
        var rawJson = plasmoid.configuration.externalScriptsJson || "[]";
        var parsed = [];
        try {
            parsed = JSON.parse(rawJson);
        } catch (e) {
            parsed = [];
        }

        scriptsModel.clear();
        for (var i = 0; i < parsed.length; i++) {
            var s = parsed[i];
            scriptsModel.append({
                "scriptId": s.scriptId || ("script_" + (i + 1)),
                "name": s.name || "",
                "scriptPath": s.scriptPath || "",
                "runOnBoot": s.runOnBoot === true,
                "interval": s.interval !== undefined ? s.interval : 0,
                "enabled": s.enabled !== false
            });
        }
        configScriptsPage.isLoaded = true;
    }

    Plasma5Support.DataSource {
        id: testRunnerSource
        engine: "executable"

        property string currentTestingScript: ""

        function testRun(scriptPath) {
            if (!scriptPath || scriptPath.trim() === "")
                return;

            var trimmed = scriptPath.trim();
            currentTestingScript = trimmed;
            var cmdToExec = trimmed;
            if (cmdToExec.indexOf("~") === 0) {
                cmdToExec = cmdToExec.replace(/^~(?=\/|$)/, "$HOME");
            }
            var execStr = "sh -c " + JSON.stringify(cmdToExec);
            disconnectSource(execStr);
            connectSource(execStr);
            testResultDialog.statusMessage = i18n("Executing script: ") + trimmed;
            testResultDialog.isError = false;
            testResultDialog.open();
        }

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
            var exitCode = (data && data["exit code"] !== undefined) ? data["exit code"] : 0;
            var stdout = (data && data["stdout"] !== undefined) ? String(data["stdout"]).trim() : "";
            var stderr = (data && data["stderr"] !== undefined) ? String(data["stderr"]).trim() : "";

            if (exitCode === 0) {
                testResultDialog.statusMessage = i18n("Script executed successfully (Exit Code 0).\n\nOutput:\n") + (stdout || i18n("(No output)"));
                testResultDialog.isError = false;
            } else {
                testResultDialog.statusMessage = i18n("Script returned error code: ") + exitCode + "\n\nStderr:\n" + (stderr || i18n("(No stderr)"));
                testResultDialog.isError = true;
            }
        }
    }

    Dialog {
        id: testResultDialog

        property string statusMessage: ""
        property bool isError: false

        title: isError ? i18n("Script Test Failure") : i18n("Script Test Output")
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: Overlay.overlay

        contentItem: ColumnLayout {
            spacing: 12

            Label {
                text: testResultDialog.statusMessage
                wrapMode: Text.Wrap
                Layout.maximumWidth: 450
            }
        }
    }

    FileDialog {
        id: filePicker

        property int targetRowIndex: -1

        title: i18n("Select External Script")
        nameFilters: [i18n("Executable Scripts (*.sh *.py *.pl *.rb)"), i18n("All Files (*.*)")]
        onAccepted: {
            if (targetRowIndex >= 0 && targetRowIndex < scriptsModel.count) {
                var path = filePicker.selectedFile.toString();
                if (path.indexOf("file://") === 0)
                    path = path.substring(7);

                scriptsModel.setProperty(targetRowIndex, "scriptPath", path);
                scriptsModel.saveToJson();
            }
        }
    }

    ColumnLayout {
        Kirigami.FormData.label: i18n("External Scripts:")
        Layout.fillWidth: true
        spacing: 12

        Label {
            text: i18n("Configure external scripts to trigger on system boot/login and periodically in the background.")
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            color: Kirigami.Theme.disabledTextColor
            Layout.fillWidth: true
        }

        Repeater {
            model: scriptsModel

            delegate: Kirigami.AbstractCard {
                id: scriptCard

                Layout.fillWidth: true
                header: RowLayout {
                    spacing: 8

                    Kirigami.Icon {
                        source: "system-run"
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: i18n("Script Name (e.g. Weather Updater)")
                        font.bold: true
                        onTextEdited: {
                            if (configScriptsPage.isLoaded) {
                                scriptsModel.setProperty(index, "name", text);
                                scriptsModel.saveToJson();
                            }
                        }
                        Binding on text {
                            value: model.name || ""
                        }
                    }

                    Switch {
                        checked: model.enabled !== false
                        text: checked ? i18n("Enabled") : i18n("Disabled")
                        onCheckedChanged: {
                            if (configScriptsPage.isLoaded) {
                                scriptsModel.setProperty(index, "enabled", checked);
                                scriptsModel.saveToJson();
                            }
                        }
                    }

                    Button {
                        icon.name: "edit-delete"
                        text: i18n("Delete")
                        onClicked: {
                            scriptsModel.remove(index);
                            scriptsModel.saveToJson();
                        }
                    }
                }

                contentItem: ColumnLayout {
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: i18n("Script Path:")
                        }

                        TextField {
                            id: pathInput

                            Layout.fillWidth: true
                            placeholderText: i18n("Path to script (e.g. ~/.local/bin/update-weather.sh)")
                            onTextEdited: {
                                if (configScriptsPage.isLoaded) {
                                    scriptsModel.setProperty(index, "scriptPath", text);
                                    scriptsModel.saveToJson();
                                }
                            }
                            Binding on text {
                                value: model.scriptPath || ""
                            }
                        }

                        Button {
                            icon.name: "document-open"
                            text: i18n("Browse...")
                            onClicked: {
                                filePicker.targetRowIndex = index;
                                filePicker.open();
                            }
                        }

                        Button {
                            icon.name: "media-playback-start"
                            text: i18n("Test Run")
                            onClicked: {
                                testRunnerSource.testRun(model.scriptPath);
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        CheckBox {
                            checked: model.runOnBoot === true
                            text: i18n("Run on Boot / Login")
                            onCheckedChanged: {
                                if (configScriptsPage.isLoaded) {
                                    scriptsModel.setProperty(index, "runOnBoot", checked);
                                    scriptsModel.saveToJson();
                                }
                            }
                        }

                        RowLayout {
                            spacing: 8

                            Label {
                                text: i18n("Refresh Rate:")
                            }

                            ComboBox {
                                id: refreshCombo

                                model: [
                                    { "text": i18n("Never"), "val": 0 },
                                    { "text": i18n("1 minute"), "val": 60000 },
                                    { "text": i18n("5 minutes"), "val": 300000 },
                                    { "text": i18n("10 minutes"), "val": 600000 },
                                    { "text": i18n("20 minutes"), "val": 1200000 },
                                    { "text": i18n("30 minutes"), "val": 1800000 },
                                    { "text": i18n("1 hour"), "val": 3600000 },
                                    { "text": i18n("2 hours"), "val": 7200000 },
                                    { "text": i18n("5 hours"), "val": 18000000 },
                                    { "text": i18n("12 hours"), "val": 43200000 },
                                    { "text": i18n("24 hours"), "val": 86400000 }
                                ]
                                textRole: "text"

                                currentIndex: {
                                    var curVal = model.interval !== undefined ? model.interval : 0;
                                    for (var i = 0; i < refreshCombo.model.length; i++) {
                                        if (refreshCombo.model[i].val === curVal)
                                            return i;
                                    }
                                    return 0;
                                }

                                onActivated: function(idx) {
                                    if (configScriptsPage.isLoaded) {
                                        var selectedVal = refreshCombo.model[idx].val;
                                        scriptsModel.setProperty(index, "interval", selectedVal);
                                        scriptsModel.saveToJson();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Button {
            text: i18n("+ Add External Script")
            icon.name: "list-add"
            Layout.alignment: Qt.AlignLeft
            onClicked: {
                scriptsModel.append({
                    "scriptId": scriptsModel.getNextScriptId(),
                    "name": i18n("New External Script"),
                    "scriptPath": "",
                    "runOnBoot": true,
                    "interval": 3600000,
                    "enabled": true
                });
                scriptsModel.saveToJson();
            }
        }
    }
}
