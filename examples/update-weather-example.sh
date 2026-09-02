#!/usr/bin/env bash
# Example: Update the weather widget using the helper script "plasmoid-set-widget"
# This script demonstrates how to send a JSON payload to update rows on a widget named "weather".

# Define the rows JSON (modify as needed)
ROWS_JSON='[{"rowId":0,"icon":"☀️"},{"rowId":1,"format":"22°C"}]'

# Call the helper script. Ensure it is in your PATH (e.g., ~/.local/bin).
plasmoid-set-widget "weather" "$ROWS_JSON"
