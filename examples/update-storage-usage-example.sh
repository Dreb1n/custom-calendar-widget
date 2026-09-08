#!/usr/bin/env bash
# Example: Periodically update root storage disk usage on a desktop widget instance.
# Usage:
#   Target widgetId: "system_monitor" (default) or pass custom widgetId as $1

TARGET_WIDGET="${1:-system_monitor}"
MOUNT_POINT="${2:-/}"

# Fetch filesystem usage using df
DF_OUTPUT=$(df -h "$MOUNT_POINT" | tail -n1)
USAGE_PCT=$(echo "$DF_OUTPUT" | awk '{print $5}')
AVAIL_STORAGE=$(echo "$DF_OUTPUT" | awk '{print $4}')

DISPLAY_TEXT="Disk: ${AVAIL_STORAGE} free (${USAGE_PCT} used)"

ROWS_JSON=$(cat <<EOF
[
  {"rowId": "storage_row", "icon": "💾", "format": "${DISPLAY_TEXT}"}
]
EOF
)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v plasmoid-set-widget &>/dev/null; then
    plasmoid-set-widget "$TARGET_WIDGET" "$ROWS_JSON"
else
    "$DIR/plasmoid-set-widget.sh" "$TARGET_WIDGET" "$ROWS_JSON"
fi
