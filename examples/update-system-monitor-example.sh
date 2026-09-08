#!/usr/bin/env bash
# Example: Comprehensive System Monitor Dashboard Updater
# Queries CPU, GPU, Memory, and Disk metrics and updates a widget named "system_monitor"
# in a single batch DBus call. Perfect for cron or systemd timer loops every 5-10s.
# Usage:
#   update-system-monitor-example.sh [targetWidgetId]

TARGET_WIDGET="${1:-system_monitor}"
MOUNT_POINT="${2:-/}"

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

# 1. CPU Temp
if TEMP_VAL=$(get_cpu_temp_celsius); then
    CPU_TXT="CPU: ${TEMP_VAL}°C"
else
    CPU_TXT="CPU: N/A"
fi

# 2. RAM Memory Usage
if [ -f /proc/meminfo ]; then
    MEM_TOTAL=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
    MEM_AVAIL=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
    MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
    MEM_PCT=$((100 * MEM_USED / MEM_TOTAL))
    USED_GB=$(python3 -c "print(f'{$MEM_USED/1048576:.1f}')")
    TOTAL_GB=$(python3 -c "print(f'{$MEM_TOTAL/1048576:.1f}')")
    MEM_TXT="RAM: ${USED_GB}/${TOTAL_GB} GB (${MEM_PCT}%)"
else
    MEM_TXT="RAM: N/A"
fi

# 3. Disk Storage
DF_OUT=$(df -h "$MOUNT_POINT" | tail -n1)
DISK_FREE=$(echo "$DF_OUT" | awk '{print $4}')
DISK_PCT=$(echo "$DF_OUT" | awk '{print $5}')
DISK_TXT="Disk: ${DISK_FREE} free (${DISK_PCT} used)"

# 4. GPU Stats
GPU_TXT="GPU: N/A"
if command -v nvidia-smi &>/dev/null; then
    NVIDIA_OUT=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
    [ -n "$NVIDIA_OUT" ] && GPU_TXT="GPU: ${NVIDIA_OUT}°C"
else
    for hwmon in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input; do
        if [ -f "$hwmon" ]; then
            AMD_RAW=$(cat "$hwmon" 2>/dev/null)
            if [ -n "$AMD_RAW" ] && [ "$AMD_RAW" -gt 0 ]; then
                GPU_TXT="GPU: $((AMD_RAW / 1000))°C"
                break
            fi
        fi
    done
fi

# Construct batch JSON payload for all 4 rows
ROWS_JSON=$(python3 -c '
import json, sys
data = [
    {"rowId": "cpu_row", "icon": "🔥", "format": sys.argv[1]},
    {"rowId": "mem_row", "icon": "🧠", "format": sys.argv[2]},
    {"rowId": "storage_row", "icon": "💾", "format": sys.argv[3]},
    {"rowId": "gpu_row", "icon": "🎮", "format": sys.argv[4]}
]
print(json.dumps(data))
' "$CPU_TXT" "$MEM_TXT" "$DISK_TXT" "$GPU_TXT")

# Execute batch update
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v plasmoid-set-widget &>/dev/null; then
    plasmoid-set-widget "$TARGET_WIDGET" "$ROWS_JSON"
else
    "$DIR/plasmoid-set-widget.sh" "$TARGET_WIDGET" "$ROWS_JSON"
fi
