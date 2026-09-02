#!/usr/bin/env bash
# Update a single property on a row or shape by rowId
# Usage:
#   plasmoid-set-row-property <targetWidgetId> <rowId> <propertyName> <value>

TARGET_WIDGET="${1:-}"
ROW_ID="${2:-}"
PROP_NAME="${3:-}"
PROP_VAL="${4:-}"

if [ -z "$ROW_ID" ] || [ -z "$PROP_NAME" ]; then
    echo "Usage: plasmoid-set-row-property <targetWidgetId> <rowId> <propertyName> <value>"
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
JS_ROW_ID=$(json_encode "$ROW_ID")
JS_PROP=$(json_encode "$PROP_NAME")
JS_VAL=$(json_encode "$PROP_VAL")

JS_SCRIPT="
var targetWid = ${JS_WIDGET};
var rowId = ${JS_ROW_ID};
var propName = ${JS_PROP};
var valStr = ${JS_VAL};
var val = valStr;
if (val === 'true') val = true;
else if (val === 'false') val = false;
else if (!isNaN(val) && val.trim() !== '') val = parseFloat(val);

var ds = desktops();
var result = false;
for (var i = 0; i < ds.length; i++) {
    var w = ds[i].widgets();
    for (var j = 0; j < w.length; j++) {
        if (w[j].type === 'org.kde.customcalendarwidget') {
            w[j].currentConfigGroup = ['General'];
            var wid = w[j].readConfig('widgetId');
            if (!targetWid || wid === targetWid) {
                if (w[j].rootItem && w[j].rootItem.setRowProperty) {
                    result = w[j].rootItem.setRowProperty(rowId, propName, val, targetWid);
                }
            }
        }
    }
}
result;
"

RAW_OUTPUT=$(busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$JS_SCRIPT" 2>/dev/null)

if [ -n "$RAW_OUTPUT" ]; then
    python3 -c '
import sys, re
raw = sys.stdin.read().strip()
m = re.match(r"^s\s+\"(.*)\"$", raw, re.DOTALL)
if m:
    print(m.group(1).encode("raw_unicode_escape").decode("unicode_escape"))
elif raw:
    print(raw)
' <<<"$RAW_OUTPUT"
fi
