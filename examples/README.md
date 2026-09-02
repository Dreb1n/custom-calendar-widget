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

## Real-World Monitoring Use-Case Scripts

These ready-to-use scripts query system hardware or external APIs and dynamically push live telemetry updates to your desktop widgets:

| Script | Metrics Monitored | Output Row ID |
|---|---|---|
| **[`update-cpu-temp-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-cpu-temp-example.sh)** | CPU Core / Package Thermal Sensors | `cpu_row` |
| **[`update-memory-usage-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-memory-usage-example.sh)** | RAM Usage (Used / Total GB & %) | `mem_row` |
| **[`update-storage-usage-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-storage-usage-example.sh)** | Root Filesystem Free Space & Used % | `storage_row` |
| **[`update-gpu-stats-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-gpu-stats-example.sh)** | NVIDIA / AMD / Intel GPU Temp & Load | `gpu_row` |
| **[`update-system-monitor-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-system-monitor-example.sh)** | Consolidated All-in-One Dashboard (CPU, RAM, Disk, GPU) | `cpu_row`, `mem_row`, `storage_row`, `gpu_row` |
| **[`update-weather-example.sh`](file:///home/rusty/kde-plasma-widget/examples/update-weather-example.sh)** | Weather Icons & Temperature Readings | `rowId: 0`, `rowId: 1` |

### Setting Up Automatic Background Polling

To update your system monitor widget automatically every 5 seconds, add a simple loop or systemd user timer:

```bash
# Continuous monitoring loop
while true; do
    ./examples/update-system-monitor-example.sh "system_monitor"
    sleep 5
done
```
