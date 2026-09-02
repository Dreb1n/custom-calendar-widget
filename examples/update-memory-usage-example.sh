#!/usr/bin/env bash
# Example: Periodically update RAM memory usage metrics on a desktop widget instance.
# Usage:
#   Target widgetId: "system_monitor" (default) or pass custom widgetId as $1

TARGET_WIDGET="${1:-system_monitor}"

# Fetch memory metrics from /proc/meminfo
if [ -f /proc/meminfo ]; then
    MEM_TOTAL_KB=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
    MEM_AVAIL_KB=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
    
    USED_GB=$(python3 -c "print(f'{$MEM_USED_KB/1048576:.1f}')")
    TOTAL_GB=$(python3 -c "print(f'{$MEM_TOTAL_KB/1048576:.1f}')")
    PERCENT=$((100 * MEM_USED_KB / MEM_TOTAL_KB))
    
    DISPLAY_TEXT="RAM: ${USED_GB} / ${TOTAL_GB} GB (${PERCENT}%)"
else
    DISPLAY_TEXT="RAM: N/A"
fi

ROWS_JSON=$(cat <<EOF
[
  {"rowId": "mem_row", "icon": "🧠", "format": "${DISPLAY_TEXT}"}
]
EOF
)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v plasmoid-set-widget &>/dev/null; then
    plasmoid-set-widget "$TARGET_WIDGET" "$ROWS_JSON"
else
    "$DIR/plasmoid-set-widget.sh" "$TARGET_WIDGET" "$ROWS_JSON"
fi
