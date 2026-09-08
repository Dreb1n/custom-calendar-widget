#!/usr/bin/env bash
# Example: Periodically update live weather on a desktop widget instance.
# Fetches live Met Office (ukmo_seamless) weather data for Buckingham Palace, London (SW1A 1AA).
# Usage:
#   update-weather-example.sh [targetWidgetId] [postcode]

TARGET_WIDGET="${1:-weather}"
POSTCODE="${2:-SW1A1AA}"
DEFAULT_LAT="51.5014"
DEFAULT_LON="-0.1419"

# 1. Fetch exact coordinates from Postcode API
GEO_JSON=$(curl -s --max-time 5 "https://api.postcodes.io/postcodes/${POSTCODE}" || echo "")
LAT=$(echo "$GEO_JSON" | python3 -c "import sys, json; s=sys.stdin.read().strip(); res = (json.loads(s).get('result') or {}) if s else {}; print(res.get('latitude') or '${DEFAULT_LAT}')" 2>/dev/null)
LON=$(echo "$GEO_JSON" | python3 -c "import sys, json; s=sys.stdin.read().strip(); res = (json.loads(s).get('longitude') or {}) if s else {}; print(res.get('longitude') or '${DEFAULT_LON}')" 2>/dev/null)

if [ -z "$LAT" ] || [ "$LAT" = "None" ]; then LAT="$DEFAULT_LAT"; fi
if [ -z "$LON" ] || [ "$LON" = "None" ]; then LON="$DEFAULT_LON"; fi

# 2. Fetch live Met Office model (ukmo_seamless) temperature & WMO weather code from Open-Meteo
WX_JSON=$(curl -s --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,apparent_temperature,weather_code,is_day&models=ukmo_seamless")

RES=$(echo "$WX_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    data = {}
curr = data.get('current', {})
if 'temperature_2m' in curr:
    temp = float(curr.get('temperature_2m', 0.0))
    code = curr.get('weather_code', 0)
    is_day = curr.get('is_day', 1)

    def get_icon(c, day):
        if c == 0: return '☀️' if day else '🌙'
        elif c in [1, 2]: return '⛅' if day else '☁️'
        elif c == 3: return '☁️'
        elif c in [45, 48]: return '🌫️'
        elif c in [51, 53, 55, 56, 57, 61, 63, 65, 80, 81, 82]: return '🌧️'
        elif c in [71, 73, 75, 77, 85, 86]: return '❄️'
        elif c in [95, 96, 99]: return '⛈️'
        return '🌡️'

    icon = get_icon(code, is_day)
    
    if temp < 15.0:
        color = '#38bdf8'
    elif temp <= 22.0:
        color = '#10b981'
    else:
        color = '#ef4444'

    t_val = round(temp, 1)
    t_str = str(int(t_val)) if t_val.is_integer() else f'{t_val:.1f}'
    print(f'{icon}|{t_str}°C|{color}')
else:
    print('')
" 2>/dev/null)

if [ -n "$RES" ]; then
    IFS='|' read -r WX_ICON WX_TEMP WX_COLOR <<< "$RES"

    ROWS_JSON=$(cat <<EOF
[
  {"rowId":"icon","icon":"$WX_ICON"},
  {"rowId":"temp","format":"$WX_TEMP","color":"$WX_COLOR"}
]
EOF
    )

    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if command -v plasmoid-set-widget &>/dev/null; then
        plasmoid-set-widget "$TARGET_WIDGET" "{\"rowsJson\":$ROWS_JSON}"
    else
        "$DIR/plasmoid-set-widget.sh" "$TARGET_WIDGET" "{\"rowsJson\":$ROWS_JSON}"
    fi
    echo "Updated Buckingham Palace (SW1A 1AA) weather -> Icon: ${WX_ICON}, Temp: ${WX_TEMP}, Color: ${WX_COLOR}"
else
    echo "Failed to fetch weather data for Buckingham Palace"
fi
