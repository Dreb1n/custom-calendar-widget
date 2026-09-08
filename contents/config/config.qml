import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance & Rows")
        icon: "preferences-desktop-theme"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("External Scripts")
        icon: "system-run"
        source: "config/ConfigExternalScripts.qml"
    }
    ConfigCategory {
        name: i18n("Format Tokens")
        icon: "dialog-information"
        source: "config/ConfigFormatTokens.qml"
    }
}
