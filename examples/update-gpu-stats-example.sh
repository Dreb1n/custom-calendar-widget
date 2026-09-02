#!/usr/bin/env bash
# Example: Update GPU temperature and load on a desktop widget instance.
# Usage:
#   Target widgetId: "system_monitor" (default) or pass custom widgetId as $1

TARGET_WIDGET="${1:-system_monitor}"

DISPLAY_TEXT="GPU: N/A"

# Check for NVIDIA GPU
if command -v nvidia-smi &>/dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [ -n "$GPU_INFO" ]; then
        TEMP=$(echo "$GPU_INFO" | cut -d',' -f1 | tr -d ' ')
        UTIL=$(echo "$GPU_INFO" | cut -d',' -f2 | tr -d ' ')
        DISPLAY_TEXT="GPU: ${TEMP}°C (${UTIL}% load)"
    fi
# Check for AMD/Intel GPU hwmon thermal sysfs
elif [ -d /sys/class/drm/card0/device/hwmon ]; then
    HWMON_TEMP=$(cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
    if [ -n "$HWMON_TEMP" ]; then
        TEMP_C=$((HWMON_TEMP / 1000))
        DISPLAY_TEXT="GPU: ${TEMP_C}°C"
    fi
fi

ROWS_JSON=$(cat <<EOF
[
  {"rowId": "gpu_row", "icon": "🎮", "format": "${DISPLAY_TEXT}"}
]
EOF
)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v plasmoid-set-widget &>/dev/null; then
    plasmoid-set-widget "$TARGET_WIDGET" "$ROWS_JSON"
else
    "$DIR/plasmoid-set-widget.sh" "$TARGET_WIDGET" "$ROWS_JSON"
fi
