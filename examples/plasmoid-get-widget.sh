#!/usr/bin/env bash
# Plasmoid Widget Property Getter (DBus)
# Usage:
#   plasmoid-get-widget <targetWidgetId> <property>
#   targetWidgetId can be empty string "" to target all widgets.
# The script prints the property value returned by the widget's getWidgetProperty method.

TARGET_WIDGET="${1:-}"
PROP_NAME="${2:-}"

if [ -z "$PROP_NAME" ]; then
    echo "Usage: plasmoid-get-widget <targetWidgetId> <property>"
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

JS_SCRIPT="
var targetWid = ${JS_WIDGET};
var propName = ${JS_PROP};
var ds = desktops();
if (!ds || ds.length === 0) {
    try { ds = desktopsForActivity(currentActivity()); } catch (e) { ds = []; }
}
var ps = [];
try { ps = panels(); } catch (e) { ps = []; }
var allContainers = ds.concat(ps);

var result = null;
for (var i = 0; i < allContainers.length; i++) {
    var w = allContainers[i].widgets();
    for (var j = 0; j < w.length; j++) {
        if (w[j].type === 'org.kde.customcalendarwidget') {
            w[j].currentConfigGroup = ['General'];
            var wid = w[j].readConfig('widgetId');
            if (!targetWid || wid === targetWid) {
                if (w[j].rootItem && w[j].rootItem.getWidgetProperty) {
                    result = w[j].rootItem.getWidgetProperty(propName, targetWid);
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
