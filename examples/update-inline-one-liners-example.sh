#!/usr/bin/env bash
# Example: Quick One-Liner Commands for Internal Inline Script Polling
# These one-liners can be entered directly into the widget configuration dialog (ConfigGeneral.qml)
# under "Inline Script Polling" without creating external bash files.

echo "=== Sample One-Liners for Inline Script Polling ==="
echo ""
echo "1. Weather One-Liner (wttr.in format=1):"
echo "   Command:  curl -s 'wttr.in?format=1'"
echo "   Interval: 30 minutes (1800000 ms)"
echo ""
echo "2. CPU Temperature (lm-sensors / sysfs):"
echo "   Command:  sensors | grep -m1 -E 'Package id 0:|Core 0:|temp1:|Tctl:' | awk '{print \$2}'"
echo "   Interval: 5 seconds (5000 ms)"
echo ""
echo "3. System Uptime (Pretty):"
echo "   Command:  uptime -p"
echo "   Interval: 1 minute (60000 ms)"
echo ""
echo "4. Memory Usage (MB free):"
echo "   Command:  free -h | awk '/Mem:/ {print \$3 \" / \" \$2}'"
echo "   Interval: 5 seconds (5000 ms)"
echo ""
echo "5. Root Storage Free Space:"
echo "   Command:  df -h / | awk 'NR==2 {print \$4 \" free\"}'"
echo "   Interval: 15 minutes (900000 ms)"
echo "==================================================="
