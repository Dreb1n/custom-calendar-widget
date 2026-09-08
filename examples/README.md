# KDE Plasma Custom Widget CLI Helper & Monitoring Scripts

This directory contains standalone bash scripts for controlling and configuring instances of the custom Plasma widget via DBus from external scripts, cron jobs, or terminal commands.

---

## Prerequisites

- **KDE Plasma Shell** (Plasma 5 or Plasma 6) running.
- `busctl` (part of `systemd`) and `python3` installed on your system.
- Optional: Copy or symlink these scripts into your `~/bin` or `~/.local/bin` directory (and ensure it is on your `PATH`).

```bash
chmod +x examples/*.sh
cp examples/plasmoid-*.sh ~/.local/bin/
```

## Dual Script Integration Modes

The widget supports two complementary ways to execute and update custom scripts:

### Option A: External Push API (DBus + Systemd Timers)
- Standalone bash/python scripts run in the background (via systemd timers or cron) and push telemetry updates via DBus using `plasmoid-set-widget` or `plasmoid-set-row-property`.
- Ideal for complex multi-row dashboards, external API integration, store metrics, and system monitoring.

### Option C: GUI External Scripts Tab (Boot & Refresh Scheduler)
- Configure external Bash or Python scripts (`~/.local/bin/update-weather.sh`, `/path/to/script.py`) directly inside the widget settings dialog under the **External Scripts** tab.
- Check **Run on Boot / Login** to trigger on startup.
- Set automatic refresh rates (`Never`, `1m`, `5m`, `10m`, `20m`, `30m`, `1h`, `2h`, `5h`, `12h`, `24h`) without setting up systemd timers or cron manually.
- Built-in **Test Run** button to test script output and exit codes interactively.

---

## Architecture: Dual Live Memory & Disk Synchronization

All CLI helper scripts (`plasmoid-set-widget.sh`, `plasmoid-set-row-property.sh`, `plasmoid-add-row.sh`, `plasmoid-remove-row.sh`) execute atomic dual-layer synchronization:
1. **Live QML In-Memory Update:** Updates the QML SceneGraph in memory for instant, zero-latency desktop rendering.
2. **KConfig Disk Persistence (`writeConfig`):** Reads back merged properties from QML memory and persists them to PlasmaShell's `appletsrc` configuration file on disk.

Custom scripts (weather monitoring, system telemetry, cron jobs) calling these CLI helpers automatically receive **instant in-memory UI updates + persistent disk storage** without needing to implement config management inside individual scripts.

---

## CLI Helper Suite

### 1. Widget Instance Management

#### `plasmoid-create-widget.sh`
Create a new widget instance on the desktop, configure its `widgetId`, and optionally position and size it.

```bash
plasmoid-create-widget <widgetId> [x] [y] [width] [height]
```

**Examples:**
```bash
# Create a new widget instance named "system_monitor"
plasmoid-create-widget "system_monitor"

# Create a widget named "clock_widget" placed at x=100, y=200 with width=400, height=300
plasmoid-create-widget "clock_widget" 100 200 400 300
```

---

### 2. Main Widget Options (Read & Write)

#### `plasmoid-get-widget.sh`
Retrieve top-level widget configuration properties (e.g., `fontFamily`, `bgColor`, `bgOpacity`, `borderRadius`, `rowsJson`).

```bash
plasmoid-get-widget <targetWidgetId> <propertyName>
```

#### `plasmoid-set-widget.sh`
Modify top-level widget configuration properties or batch-update properties using a JSON payload.

```bash
plasmoid-set-widget <targetWidgetId> <propertyName> <value>
plasmoid-set-widget <targetWidgetId> '<jsonPropertiesObject>'
```

---

### 3. Rows & Shapes Operations (CRUD)

#### `plasmoid-add-row.sh`
Append a new text row or vector shape to a widget.

```bash
plasmoid-add-row <targetWidgetId> '<jsonRowObject>'
```

#### `plasmoid-remove-row.sh`
Delete a specific row or shape from a widget by its `rowId`.

```bash
plasmoid-remove-row <targetWidgetId> <rowId>
```

#### `plasmoid-get-widget-row-property.sh`
Retrieve a single property or full row JSON for a row matching `rowId`.

```bash
plasmoid-get-widget-row-property <targetWidgetId> <rowId> [propertyName]
```

#### `plasmoid-set-row-property.sh`
Update a single property on a specific row or shape by `rowId`.

```bash
plasmoid-set-row-property <targetWidgetId> <rowId> <propertyName> <value>
```

---

## 4. Complete Row & Shape Property Reference Index

Every property below can be queried or modified by name via `plasmoid-get-widget-row-property.sh` and `plasmoid-set-row-property.sh`.

### A. Text Row Properties

| Property Name | Type | Description / Example Values |
|---|---|---|
| `rowId` | String / Number | Unique identifier (e.g., `"temp"`, `"cpu_row"`, `0`) |
| `format` | String | Format pattern or text (e.g., `"HH:i:ss"`, `"22°C"`, `"☁️"`) |
| `fontFamily` | String | Font family name (e.g., `"Roboto"`, `"Angels"`, `"Sans Serif"`) |
| `fontSize` | Number | Font size in pixels (e.g., `24`, `48`, `72`) |
| `weight` | String | Font weight (`"100"`, `"400"`, `"600"`, `"700"`, `"900"`) |
| `color` | String | Hex color string (e.g., `"#ffffff"`, `"#10b981"`, `"#38bdf8"`) |
| `align` | String | Horizontal alignment (`"left"`, `"center"`, `"right"`) |
| `opacity` | Number | Opacity (`0.0` transparent to `1.0` opaque) |
| `letterSpacing` | Number | Spacing between characters in pixels |
| `effect` | String | Visual effect (`"none"`, `"glow"`, `"shadow"`, `"normalShadow"`, `"stroke"`) |
| `effectColor` | String | Effect color hex string |
| `effectSize` | Number | Effect radius or spread size |
| `effectOpacity` | Number | Effect opacity (`0.0` to `1.0`) |
| `timeZone` | String | IANA time zone (e.g., `"UTC"`, `"America/New_York"`, `"Europe/London"`) |
| `locale` | String | Language/country locale (e.g., `"en_GB"`, `"de_DE"`, `"fr_FR"`) |
| `clickCommand` | String | Executable shell command run on click (e.g., `"bash ~/script.sh"`) |
| `rotation` | Number | Rotation angle in degrees (`0`, `45`, `90`, `180`) |
| `fromCenter` | Boolean | Center alignment offset flag (`true` or `false`) |
| `offsetX` / `offsetWidth` | Number | Horizontal position offset in pixels |
| `topMargin` / `offsetHeight` | Number | Vertical position offset in pixels |
| `overlayType` | Number | Mask mode (`0` = None, `1` = Color, `2` = Image/Video texture) |
| `overlayColor` | String | Texture mask color hex |
| `overlayOpacity` | Number | Texture mask opacity (`0.0` to `1.0`) |
| `overlayFile` | String | File URL for media texture (`"file:///home/user/image.png"`) |
| `showOverlay` | Boolean | Enable texture overlay mask (`true` or `false`) |

### B. Vector Shape Properties

| Property Name | Type | Description / Example Values |
|---|---|---|
| `isShape` | Boolean | Must be set to `true` for vector shapes |
| `shapeType` | String | Geometry (`"circle"`, `"ellipse"`, `"oblong"`, `"square"`, `"rectangle"`, `"pill"`, `"capsule"`, `"triangle"`, `"pentagon"`, `"hexagon"`, `"heptagon"`, `"octagon"`, `"nonagon"`, `"decagon"`) |
| `shapeWidth` | Number | Vector shape width in pixels (e.g., `100`, `200`) |
| `shapeHeight` | Number | Vector shape height in pixels (e.g., `100`, `200`) |
| `color` | String | Shape fill color (e.g., `"#3b82f6"`, `"#ef4444"`) |
| `align`, `opacity`, `rotation`, `clickCommand`, `overlayType`, `overlayFile` | ... | Inherits all layout, position offset, effect, and media mask properties |

---

## Real-World Monitoring Use-Case Scripts

These ready-to-use scripts query system hardware or external APIs and dynamically push live telemetry updates to your desktop widgets:

| Script | Metrics Monitored | Output Row ID |
|---|---|---|
| **[`update-cpu-temp-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-cpu-temp-example.sh)** | CPU Core / Package Thermal Sensors | `cpu_row` |
| **[`update-memory-usage-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-memory-usage-example.sh)** | RAM Usage (Used / Total GB & %) | `mem_row` |
| **[`update-storage-usage-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-storage-usage-example.sh)** | Root Filesystem Free Space & Used % | `storage_row` |
| **[`update-gpu-stats-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-gpu-stats-example.sh)** | NVIDIA / AMD / Intel GPU Temp & Load | `gpu_row` |
| **[`update-system-monitor-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-system-monitor-example.sh)** | Consolidated All-in-One Dashboard (CPU, RAM, Disk, GPU) | `cpu_row`, `mem_row`, `storage_row`, `gpu_row` |
| **[`update-weather-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-weather-example.sh)** | Live Met Office Weather Fetch (Buckingham Palace, London / SW1A 1AA or custom postcode) | `icon`, `temp` |

### Setting Up Automatic Background Polling

To update your system monitor widget automatically, you can run a continuous loop, a cron job, or a systemd user timer:

#### Option A: Continuous Loop
```bash
while true; do
    ./examples/update-system-monitor-example.sh "system_monitor"
    sleep 5
done
```

#### Option B: Systemd User Timer (Recommended)
Systemd user timers provide resource-efficient background execution. Create two files under `~/.config/systemd/user/`:

1. **`~/.config/systemd/user/widget-monitor.service`**:
```ini
[Unit]
Description=Update Desktop System Monitor Widget

[Service]
Type=oneshot
ExecStart=%h/.local/bin/update-system-monitor-example.sh system_monitor
```

2. **`~/.config/systemd/user/widget-monitor.timer`**:
```ini
[Unit]
Description=Trigger Desktop System Monitor Widget Update

[Timer]
OnBootSec=5s
OnUnitActiveSec=5s

[Install]
WantedBy=timers.target
```

Enable and start the timer:
```bash
systemctl --user daemon-reload
systemctl --user enable --now widget-monitor.timer
```

---

## 5. Troubleshooting & Diagnostics

### A. Testing DBus Connectivity
Run this command in a terminal to verify PlasmaShell DBus script evaluation:
```bash
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s 'print("DBus OK");'
```

### B. Finding Active `widgetId`s on Desktop
To list all active custom widget instances on your desktop and inspect their assigned `widgetId`s:
```bash
grep -E "(plugin=org.kde.customcalendarwidget|widgetId=)" ~/.config/plasma-org.kde.plasma.desktop-appletsrc
```

### C. Resetting a Widget Instance
If a widget configuration needs to be reset to factory defaults, set `rowsJson` to an empty array:
```bash
plasmoid-set-widget <targetWidgetId> "rowsJson" "[]"
```
