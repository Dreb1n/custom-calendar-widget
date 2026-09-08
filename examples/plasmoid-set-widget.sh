#!/usr/bin/env bash
# Update top-level widget configuration or batch update properties
# Usage:
#   plasmoid-set-widget <targetWidgetId> <propertyName> <value>
#   plasmoid-set-widget <targetWidgetId> '<jsonPropertiesObject>'

TARGET_WIDGET="${1:-}"
PROP_NAME="${2:-}"
PROP_VAL="${3:-}"

if [ -z "$PROP_NAME" ]; then
    echo "Usage: plasmoid-set-widget <targetWidgetId> <propertyName> <value>"
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
if (!ds || ds.length === 0) {
    try { ds = desktopsForActivity(currentActivity()); } catch (e) { ds = []; }
}
var ps = [];
try { ps = panels(); } catch (e) { ps = []; }
var allContainers = ds.concat(ps);

for (var i = 0; i < allContainers.length; i++) {
    var w = allContainers[i].widgets();
    for (var j = 0; j < w.length; j++) {
        if (w[j].type === 'org.kde.customcalendarwidget') {
            w[j].currentConfigGroup = ['General'];
            var wid = w[j].readConfig('widgetId');
            if (!targetWid || wid === targetWid) {
                var pObj = JSON.parse(propStr);
                if (pObj.rowsJson !== undefined) {
                    var curJson = w[j].readConfig('rowsJson') || '[]';
                    var existingRows = [];
                    try { existingRows = JSON.parse(curJson); } catch (e) { existingRows = []; }
                    var incomingRows = pObj.rowsJson;
                    if (typeof incomingRows === 'string') {
                        try { incomingRows = JSON.parse(incomingRows); } catch (e) { incomingRows = []; }
                    }
                    if (Array.isArray(incomingRows)) {
                        for (var r = 0; r < incomingRows.length; r++) {
                            var item = incomingRows[r];
                            if (!item || typeof item !== 'object') continue;
                            var matchedIndex = -1;
                            if (item.rowId !== undefined && item.rowId !== null && String(item.rowId) !== '') {
                                var targetRowId = String(item.rowId);
                                for (var ex = 0; ex < existingRows.length; ex++) {
                                    var exId = existingRows[ex].rowId !== undefined ? String(existingRows[ex].rowId) : String(ex);
                                    if (exId === targetRowId) { matchedIndex = ex; break; }
                                }
                                if (matchedIndex === -1 && !isNaN(item.rowId)) {
                                    var idxNum = parseInt(item.rowId, 10);
                                    if (idxNum >= 0 && idxNum < existingRows.length) matchedIndex = idxNum;
                                }
                            } else if (r < existingRows.length) {
                                matchedIndex = r;
                            }
                            if (matchedIndex >= 0 && matchedIndex < existingRows.length) {
                                for (var k in item) {
                                    existingRows[matchedIndex][k] = item[k];
                                    if (k === 'icon' && (existingRows[matchedIndex]['format'] === undefined || existingRows[matchedIndex]['format'] === ''))
                                        existingRows[matchedIndex]['format'] = item[k];
                                }
                            } else {
                                existingRows.push(item);
                            }
                        }
                        w[j].writeConfig('rowsJson', JSON.stringify(existingRows));
                    }
                }
                for (var pk in pObj) {
                    if (pk !== 'rowsJson') {
                        var v = pObj[pk];
                        var pVal = (v !== null && typeof v === 'object') ? JSON.stringify(v) : String(v);
                        w[j].writeConfig(pk, pVal);
                    }
                }
                if (w[j].rootItem && w[j].rootItem.setWidgetProperties) {
                    try { w[j].rootItem.setWidgetProperties(pObj, targetWid); } catch (e) {}
                }
                if (w[j].reloadConfig) {
                    try { w[j].reloadConfig(); } catch (e) {}
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
if (!ds || ds.length === 0) {
    try { ds = desktopsForActivity(currentActivity()); } catch (e) { ds = []; }
}
var ps = [];
try { ps = panels(); } catch (e) { ps = []; }
var allContainers = ds.concat(ps);

for (var i = 0; i < allContainers.length; i++) {
    var w = allContainers[i].widgets();
    for (var j = 0; j < w.length; j++) {
        if (w[j].type === 'org.kde.customcalendarwidget') {
            w[j].currentConfigGroup = ['General'];
            var wid = w[j].readConfig('widgetId');
            if (!targetWid || wid === targetWid) {
                var val = valStr;
                if (val === 'true') val = true;
                else if (val === 'false') val = false;
                else if (!isNaN(val) && val.trim() !== '') val = parseFloat(val);
                w[j].writeConfig(propName, valStr);
                if (w[j].rootItem && w[j].rootItem.setWidgetProperty) {
                    try { w[j].rootItem.setWidgetProperty(propName, val, targetWid); } catch (e) {}
                }
                if (w[j].reloadConfig) {
                    try { w[j].reloadConfig(); } catch (e) {}
                }
            }
        }
    }
}
"
fi

busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$JS_SCRIPT"
