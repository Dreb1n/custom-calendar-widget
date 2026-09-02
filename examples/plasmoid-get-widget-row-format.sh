#!/usr/bin/env bash
# Example: Retrieve format string of a specific row by rowId (Convenience wrapper around plasmoid-get-widget-row-property.sh).
# Usage: plasmoid-get-widget-row-format.sh <targetWidgetId> <rowId>

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/plasmoid-get-widget-row-property.sh" "$1" "$2" "format"
