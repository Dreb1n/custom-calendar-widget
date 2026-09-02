#!/usr/bin/env bash
# Plasmoid Widget Container Property CLI Setter
# Usage:
#   plasmoid-set-widget <targetWidgetId> <property> <value>
#   plasmoid-set-widget <targetWidgetId> '<jsonPropertiesObject>'

TARGET_WIDGET="${1:-}"
PROP_NAME="${2:-}"
PROP_VAL="${3:-}"

if [ -z "$PROP_NAME" ]; then
    echo "Usage: plasmoid-set-widget <targetWidgetId> <property> <value>"
    echo "       plasmoid-set-widget <targetWidgetId> '<jsonPropertiesObject>'"
    exit 1
fi

json_encode() {
    local s="$1"
    if [[ "$s" =~ ^[a-zA-Z0-9_-]*$ ]]; then
        printf '"%s"' "$s"
    else
        python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$s"
    fi
}

JS_WIDGET=$(json_encode "$TARGET_WIDGET")
JS_PROP=$(json_encode "$PROP_NAME")
JS_VAL=$(json_encode "$PROP_VAL")

IS_JSON=0
if [[ "$PROP_NAME" =~ ^\{.*\}$ ]]; then
    IS_JSON=1
fi

if [ "$IS_JSON" -eq 1 ]; then
    JS_SCRIPT="
var targetWid = ${JS_WIDGET};
var propStr = ${JS_PROP};
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    var w = ds[i].widgets();
    for (var j = 0; j < w.length; j++) {
        if (w[j].type === 'org.kde.customcalendarwidget') {
            w[j].currentConfigGroup = ['General'];
            var wid = w[j].readConfig('widgetId');
            if (!targetWid || wid === targetWid) {
                if (w[j].rootItem && w[j].rootItem.setWidgetProperties) {
                    w[j].rootItem.setWidgetProperties(JSON.parse(propStr), targetWid);
                }
            }
        }
    }
}
"
else
    JS_SCRIPT="
var targetWid = ${JS_WIDGET};
var propName = ${JS_PROP};
var valStr = ${JS_VAL};
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    var w = ds[i].widgets();
    for (var j = 0; j < w.length; j++) {
        if (w[j].type === 'org.kde.customcalendarwidget') {
            w[j].currentConfigGroup = ['General'];
            var wid = w[j].readConfig('widgetId');
            if (!targetWid || wid === targetWid) {
                if (w[j].rootItem && w[j].rootItem.setWidgetProperty) {
                    var val = valStr;
                    if (val === 'true') val = true;
                    else if (val === 'false') val = false;
                    else if (!isNaN(val) && val.trim() !== '') val = parseFloat(val);
                    w[j].rootItem.setWidgetProperty(propName, val, targetWid);
                }
            }
        }
    }
}
"
fi

busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$JS_SCRIPT"
