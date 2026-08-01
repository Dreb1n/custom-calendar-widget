# Custom Calendar and Clock Plasmoid for KDE Plasma 6

[![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6.0%2B-blue.svg?logo=kde)](https://kde.org/plasma-desktop/)
[![License: GPL-2.0-or-later](https://img.shields.io/badge/License-GPL--2.0--or--later-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.2.0-orange.svg)](https://github.com/Dreb1n/custom-calendar-widget/releases)

A highly customizable, multi-row calendar and digital clock desktop widget (plasmoid) designed for **KDE Plasma 6**.

Configure individual rows with custom date/time format specifiers, typography, colors, opacities, text effects, and timezones. Includes a live system font preview picker and interactive color pickers.

---

## ✨ Features

- 🎨 **Live System Font Picker**: Preview and select any installed system font directly from a drop-down menu rendered in each font's native typeface.
- 🖌️ **Interactive Color Pickers**: Clickable color preview swatches integrated with native system `ColorDialog` for background, text, and effect colors.
- 🔍 **Clean Transparent Default Design**: Seamlessly blends into your desktop wallpaper with centered white typography out of the box.
- 🕒 **Multi-Timezone & Multi-Locale Support**: Assign independent timezones (e.g. `UTC`, `Asia/Tokyo`, `America/New_York`) and locales (e.g. `ja_JP`, `fr_FR`, `de_DE`, `es_ES`) to individual rows.
- 🖱️ **Per-Row Click Actions**: Assign executable launcher commands (e.g. `kcalc`, `korganizer`, `brave`, `plasma-systemmonitor`, custom shell scripts) to individual rows.
- 📝 **Per-Row Customization**:
  - Custom format strings with bracket escaping `[text]`.
  - Independent font family selection (overriding global font).
  - Font size (1px - 1000px) and font weight (Light 300 to Black 900).
  - Top Margin (-1000px to +1000px) & Left Offset (-1000px to +1000px) for 2D row placement & overlapping.
  - Letter Spacing (-1000px to +1000px) for kerning adjustment.
  - Natural z-index layer ordering (lower rows render on top of higher rows).
  - Horizontal alignment (Left, Center, Right).
  - Per-row opacity adjustments (10% - 100%).
  - Text effects: **None**, **Neon Glow**, **Normal Shadow**, **Drop Shadow**, and **Outer Stroke**.
- 🖼️ **Background Modes**: Choose between **Transparent**, **Blurred Glass**, or **Solid Color** with customizable radius and opacity.
- ⚡ **High Performance & Low Resource Footprint**: Built with optimized QML bindings and a pre-compiled ICU `Intl.DateTimeFormat` engine.

---

## 📖 Format Token Reference Table

Enclose literal text in square brackets `[Like This]` to prevent tokens from being parsed.

| Token | Description | Example Output |
| :--- | :--- | :--- |
| `dddd` / `EEEE` | Full day of week | `Saturday` |
| `ddd` / `EEE` | Short day of week | `Sat` |
| `mmmm` / `MMMM` | Full month name | `August` |
| `mmm` / `MMM` | Short month name | `Aug` |
| `mm` / `MM` | Zero-padded month | `08` |
| `yyyy` / `YYYY` | Full 4-digit year | `2026` |
| `yy` / `YY` | 2-digit year | `26` |
| `do` | Day of month with ordinal suffix | `1st`, `2nd`, `3rd`, `14th` |
| `dd` | Zero-padded day of month | `01` |
| `d` | Single/double digit day of month | `1` |
| `HH` | Zero-padded 24-hour clock | `09` |
| `H` | 24-hour clock | `9` |
| `hh` | Zero-padded 12-hour clock | `09` |
| `h` | 12-hour clock | `9` |
| `i` / `MN` | Zero-padded minutes | `05` |
| `ss` | Zero-padded seconds | `08` |
| `s` | Seconds | `8` |
| `A` | Uppercase AM/PM | `AM` / `PM` |
| `a` | Lowercase am/pm | `am` / `pm` |
| `WW` | Zero-padded ISO week number | `31` |
| `W` | ISO week number | `31` |
| `TZ` | Target timezone name | `Asia/Tokyo` |
| `X` | Unix epoch timestamp in seconds | `1785579846` |

### Example Format Strings:
- `dddd` ➔ `Saturday`
- `dd mmm yyy` ➔ `01 Aug 2026`
- `do [of] MMMM, yyyy` ➔ `1st of August, 2026`
- `HH:i:ss` ➔ `14:32:05`
- `hh:i A (TZ)` ➔ `02:32 PM (Asia/Tokyo)`

---

## 🚀 Installation

### Option 1: Via KDE Plasma (Recommended)
1. Right-click your desktop or panel ➔ **Add Widgets...**
2. Click **Get New Widgets...** ➔ **Download New Plasma Widgets**
3. Search for **Custom Calendar and Clock Widget**
4. Click **Install**.

### Option 2: CLI Installation (`.plasmoid` package)
Download the latest `.plasmoid` bundle from the [Releases](https://github.com/Dreb1n/custom-calendar-widget/releases) page and run:

```bash
kpackagetool6 --type Plasma/Applet --install org.kde.customcalendarwidget.plasmoid
```

To upgrade an existing installation:
```bash
kpackagetool6 --type Plasma/Applet --upgrade org.kde.customcalendarwidget.plasmoid
```

### Option 3: Install from Source
```bash
git clone https://github.com/Dreb1n/custom-calendar-widget.git
cd custom-calendar-widget
kpackagetool6 --type Plasma/Applet --install .
```

---

## 🛠️ Development & Building

### Project Structure
```
org.kde.customcalendarwidget/
├── metadata.json                 # Plasma 6 applet metadata
├── contents/
│   ├── config/
│   │   ├── main.xml              # KConfig schema defaults
│   │   └── config.qml            # Configuration categories model
│   └── ui/
│       ├── main.qml              # Main widget representation
│       ├── DateFormatter.js      # Optimized date & timezone formatting engine
│       └── config/
│           └── ConfigGeneral.qml # Plasma KCM settings interface
└── README.md
```

### Linting QML Code
Run Qt 6 `qmllint` to verify syntax and type safety:
```bash
qmllint contents/ui/config/ConfigGeneral.qml contents/ui/main.qml
```

---

## 📜 License

Distributed under the **GNU General Public License v2.0 or later (GPL-2.0-or-later)**. See [`LICENSE``](LICENSE) for more information.
