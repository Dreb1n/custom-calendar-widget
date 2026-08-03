# Contributing to Custom Calendar and Clock Plasmoid

Thank you for your interest in contributing to **Custom Calendar and Clock**! 🎉 

This project is in **active development**, and we are eager for any and all feedback. Every suggestion, bug report, pull request, and desktop screenshot is guaranteed to be read and responded to.

---

## 📋 Table of Contents

- [Ways to Contribute](#-ways-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Sharing Desktop Setups](#sharing-desktop-setups)
  - [Contributing Code](#contributing-code)
- [Local Development Setup](#-local-development-setup)
- [Linting & Code Quality](#-linting--code-quality)
- [Submitting a Pull Request (PR)](#-submitting-a-pull-request-pr)
- [Code of Conduct & Community Guidelines](#-code-of-conduct--community-guidelines)

---

## 🤝 Ways to Contribute

### Reporting Bugs
If you encounter a bug or unexpected behavior:
1. Search the [GitHub Issues](https://github.com/Dreb1n/custom-calendar-widget/issues) to see if it has already been reported.
2. If not, open a new issue using the bug template.
3. Include your **KDE Plasma version**, **Qt version**, Linux distribution, and steps to reproduce the issue (along with terminal logs if applicable).

### Suggesting Features
Have an idea for a new date/time format token, text effect, background mode, or layout feature?
- Open a feature request in [GitHub Issues](https://github.com/Dreb1n/custom-calendar-widget/issues).
- Describe the feature clearly and explain how it enhances the user experience.

### Sharing Desktop Setups
We love seeing how users customize their desktop!
- Post a screenshot of your custom calendar/clock layout in our pinned [Showcase Issue Thread](https://github.com/Dreb1n/custom-calendar-widget/issues).
- Feel free to include your font choices, color palettes, and configuration JSON snippets!

---

## 🛠️ Local Development Setup

### Prerequisites
- **KDE Plasma 6.0+**
- **Qt 6 Development Tools** (including `qmllint` for QML syntax validation)
- `kpackagetool6` (included with KDE Frameworks 6)

### 1. Clone the Repository
```bash
git clone https://github.com/Dreb1n/custom-calendar-widget.git
cd custom-calendar-widget
```

### 2. Install locally for Testing
To install the development version into your local Plasma environment:
```bash
kpackagetool6 --type Plasma/Applet --install .
```

If you already have the plasmoid installed and want to upgrade it with your changes:
```bash
kpackagetool6 --type Plasma/Applet --upgrade .
```

### 3. Reloading Plasma Shell (Optional)
To test visual changes live in Plasma:
```bash
kquitapp6 plasmashell && kstart plasmashell
```
*Or preview the applet using `plasmoidviewer`:*
```bash
plasmoidviewer -a .
```

---

## 🔍 Linting & Code Quality

Before opening a pull request, verify that your QML and JavaScript changes pass syntax checking.

### Run `qmllint`
```bash
qmllint contents/ui/config/ConfigGeneral.qml contents/ui/main.qml
```
Ensure there are no syntax errors or unresolved property warnings.

### Style Guidelines
- **QML Formatting:** Follow standard 4-space indentation. Keep component IDs clean and descriptive.
- **JavaScript (`DateFormatter.js`):** Write clean, modular, and performance-minded JS. Avoid unnecessary allocations in code paths that run every second.
- **Backward Compatibility:** When adding new configuration keys to `contents/config/main.xml`, ensure default values are provided so existing user configs do not break.

---

## 🚀 Submitting a Pull Request (PR)

1. **Fork the repository** on GitHub.
2. **Create a topic branch** from `main`:
   ```bash
   git checkout -b feature/my-new-feature
   # or
   git checkout -b fix/bug-description
   ```
3. **Commit your changes** with clear, descriptive commit messages.
4. **Push your branch** to your fork:
   ```bash
   git push origin feature/my-new-feature
   ```
5. **Open a Pull Request** against the `main` branch. 
6. Describe your changes, link relevant issue numbers, and include screenshots if UI elements were modified!

---

## 💬 Community & Support

Every pull request and issue is reviewed attentively. Thank you for helping make **Custom Calendar and Clock** the best customizable date & time plasmoid for KDE Plasma 6! 🚀
