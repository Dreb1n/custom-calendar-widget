#!/usr/bin/env bash
# Example: Periodically update CPU temperature on a desktop widget instance.
# Usage:
#   Target widgetId: "system_monitor" (default) or pass custom widgetId as $1

TARGET_WIDGET="${1:-system_monitor}"

get_cpu_temp_celsius() {
    # 1. Iterate sysfs thermal zones searching for CPU package sensors
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -f "$zone/type" ] && [ -f "$zone/temp" ]; then
            local ztype
            ztype=$(cat "$zone/type" 2>/dev/null)
            if [[ "$ztype" =~ (x86_pkg_temp|k10temp|cpu-thermal|cpu_thermal|coretemp|acpitz) ]]; then
                local raw
                raw=$(cat "$zone/temp" 2>/dev/null)
                if [ -n "$raw" ] && [ "$raw" -gt 0 ]; then
                    echo "$((raw / 1000))"
                    return 0
                fi
            fi
        fi
    done

    # 2. Try lm-sensors output
    if command -v sensors &>/dev/null; then
        local stemp
        stemp=$(sensors 2>/dev/null | grep -m1 -E "Package id 0:|Core 0:|temp1:|Tctl:" | awk '{print $2}' | tr -d '+°C')
        if [ -n "$stemp" ]; then
            printf "%.0f" "$stemp" 2>/dev/null && return 0
        fi
    fi

    # 3. Fallback to thermal_zone0
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local raw0
        raw0=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        if [ -n "$raw0" ] && [ "$raw0" -gt 0 ]; then
            echo "$((raw0 / 1000))"
            return 0
        fi
    fi

    return 1
}

if TEMP_VAL=$(get_cpu_temp_celsius); then
    DISPLAY_TEXT="CPU: ${TEMP_VAL}°C"
else
    DISPLAY_TEXT="CPU: N/A"
fi

# Build payload updating rowId "cpu_row"
ROWS_JSON=$(cat <<EOF
[
  {"rowId": "cpu_row", "icon": "🔥", "format": "${DISPLAY_TEXT}"}
]
EOF
)

# Invoke setter helper script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v plasmoid-set-widget &>/dev/null; then
    plasmoid-set-widget "$TARGET_WIDGET" "$ROWS_JSON"
else
    "$DIR/plasmoid-set-widget.sh" "$TARGET_WIDGET" "$ROWS_JSON"
fi
