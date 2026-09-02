#!/usr/bin/env bash
# Retrieve a specific property (or full JSON) from a row identified by rowId
# Usage:
#   plasmoid-get-widget-row-property <targetWidgetId> <rowId> [propertyName]

TARGET_WIDGET="${1:-}"
ROW_ID="${2:-}"
PROP_NAME="${3:-}"

if [ -z "$ROW_ID" ]; then
    echo "Usage: plasmoid-get-widget-row-property <targetWidgetId> <rowId> [propertyName]"
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

JS_SCRIPT="
var targetWid = ${JS_WIDGET};
var rowId = ${JS_ROW_ID};
var propName = ${JS_PROP};
var ds = desktops();
var result = null;
for (var i = 0; i < ds.length; i++) {
    var w = ds[i].widgets();
    for (var j = 0; j < w.length; j++) {
        if (w[j].type === 'org.kde.customcalendarwidget') {
            w[j].currentConfigGroup = ['General'];
            var wid = w[j].readConfig('widgetId');
            if (!targetWid || wid === targetWid) {
                if (w[j].rootItem && w[j].rootItem.getRowProperty) {
                    result = w[j].rootItem.getRowProperty(rowId, propName, targetWid);
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
    val = m.group(1).encode("raw_unicode_escape").decode("unicode_escape")
    print(val)
elif raw:
    print(raw)
' <<<"$RAW_OUTPUT"
fi
