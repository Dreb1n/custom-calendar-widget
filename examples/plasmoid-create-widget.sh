#!/usr/bin/env bash
# Create a new widget instance, set its widgetId, and optionally set screen position
# Usage:
#   plasmoid-create-widget <widgetId> [x] [y] [width] [height]

WIDGET_ID="${1:-}"
POS_X="${2:-}"
POS_Y="${3:-}"
WIDTH="${4:-}"
HEIGHT="${5:-}"

if [ -z "$WIDGET_ID" ]; then
    echo "Usage: plasmoid-create-widget <widgetId> [x] [y] [width] [height]"
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

json_number() {
    local n="$1"
    if [[ "$n" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$n"
    else
        echo "null"
    fi
}

JS_WIDGET_ID=$(json_encode "$WIDGET_ID")
JS_X=$(json_number "$POS_X")
JS_Y=$(json_number "$POS_Y")
JS_W=$(json_number "$WIDTH")
JS_H=$(json_number "$HEIGHT")

JS_SCRIPT="
var wid = ${JS_WIDGET_ID};
var posX = ${JS_X};
var posY = ${JS_Y};
var posW = ${JS_W};
var posH = ${JS_H};

var ds = desktops();
if (ds.length > 0) {
    var w = ds[0].addWidget('org.kde.customcalendarwidget');
    if (w) {
        w.currentConfigGroup = ['General'];
        w.writeConfig('widgetId', wid);
        if (posX !== null && posY !== null) {
            var rect = { x: posX, y: posY };
            if (posW !== null && posH !== null) {
                rect.width = posW;
                rect.height = posH;
            }
            w.geometry = rect;
        }
        'Widget created: ' + wid;
    }
}
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
