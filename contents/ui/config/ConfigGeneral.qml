import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: configPage

    property alias cfg_fontFamily: fontCombo.selectedFont
    property alias cfg_bgType: bgTypeCombo.currentIndex
    property alias cfg_bgColor: bgColorInput.text
    property alias cfg_bgOpacity: bgOpacityHolder.value
    property alias cfg_borderRadius: borderRadiusHolder.value
    property alias cfg_widgetPadding: widgetPaddingHolder.value
    property alias cfg_rowsJson: rowsJsonHolder.text
    property alias cfg_isEditing: isEditingHolder.value
    property alias cfg_editingRowsJson: editingRowsJsonHolder.text
    property alias cfg_editingFontFamily: editingFontFamilyHolder.text
    property alias cfg_editingBgType: editingBgTypeHolder.value
    property alias cfg_editingBgColor: editingBgColorHolder.text

    property alias cfg_overlayType: overlayTypeCombo.currentIndex
    property alias cfg_overlayColor: overlayColorInput.text
    property alias cfg_overlayOpacity: overlayOpacityHolder.value
    property alias cfg_overlayFile: overlayFileInput.text
    property alias cfg_editingOverlayType: editingOverlayTypeHolder.value
    property alias cfg_editingOverlayColor: editingOverlayColorHolder.text
    property alias cfg_editingOverlayOpacity: editingOverlayOpacityHolder.value
    property alias cfg_editingOverlayFile: editingOverlayFileHolder.text

    QtObject { id: rowsJsonHolder; property string text: "" }
    QtObject { id: bgOpacityHolder; property real value: 0.8 }
    QtObject { id: borderRadiusHolder; property int value: 16 }
    QtObject { id: widgetPaddingHolder; property int value: 16 }
    QtObject { id: isEditingHolder; property bool value: false }
    QtObject { id: editingRowsJsonHolder; property string text: "" }
    QtObject { id: editingFontFamilyHolder; property string text: "" }
    QtObject { id: editingBgTypeHolder; property int value: -1 }
    QtObject { id: editingBgColorHolder; property string text: "" }

    QtObject { id: overlayOpacityHolder; property real value: 0.5 }
    QtObject { id: editingOverlayTypeHolder; property int value: -1 }
    QtObject { id: editingOverlayColorHolder; property string text: "" }
    QtObject { id: editingOverlayOpacityHolder; property real value: -1.0 }
    QtObject { id: editingOverlayFileHolder; property string text: "" }

    property var activeColorCallback: null

    property var timezoneOptions: [
        // System & Universal
        { label: "Local (System Default)", value: "" },
        { label: "UTC / GMT (Coordinated Universal Time)", value: "UTC" },

        // Africa
        { label: "🇪🇬 Africa/Cairo (Egypt - EET / EEST)", value: "Africa/Cairo" },
        { label: "🇿🇦 Africa/Johannesburg (South Africa - SAST)", value: "Africa/Johannesburg" },
        { label: "🇳🇬 Africa/Lagos (West Africa - WAT)", value: "Africa/Lagos" },
        { label: "🇰🇪 Africa/Nairobi (East Africa - EAT)", value: "Africa/Nairobi" },
        { label: "🇲🇦 Africa/Casablanca (Morocco - WET / WEST)", value: "Africa/Casablanca" },
        { label: "🇩🇿 Africa/Algiers (Central Africa - CET)", value: "Africa/Algiers" },

        // Americas - North
        { label: "🇺🇸 America/New_York (US Eastern - EST / EDT)", value: "America/New_York" },
        { label: "🇺🇸 America/Chicago (US Central - CST / CDT)", value: "America/Chicago" },
        { label: "🇺🇸 America/Denver (US Mountain - MST / MDT)", value: "America/Denver" },
        { label: "🇺🇸 America/Phoenix (US Arizona - MST no DST)", value: "America/Phoenix" },
        { label: "🇺🇸 America/Los_Angeles (US Pacific - PST / PDT)", value: "America/Los_Angeles" },
        { label: "🇺🇸 America/Anchorage (Alaska - AKST / AKDT)", value: "America/Anchorage" },
        { label: "🇺🇸 Pacific/Honolulu (Hawaii - HST)", value: "Pacific/Honolulu" },
        { label: "🇨🇦 America/Toronto (Canada Eastern)", value: "America/Toronto" },
        { label: "🇨🇦 America/Vancouver (Canada Pacific)", value: "America/Vancouver" },

        // Americas - Central & South
        { label: "🇲🇽 America/Mexico_City (Mexico - CST)", value: "America/Mexico_City" },
        { label: "🇧🇷 America/Sao_Paulo (Brazil - BRT)", value: "America/Sao_Paulo" },
        { label: "🇦🇷 America/Argentina/Buenos_Aires (Argentina - ART)", value: "America/Argentina/Buenos_Aires" },
        { label: "🇨🇱 America/Santiago (Chile - CLT / CLST)", value: "America/Santiago" },
        { label: "🇨🇴 America/Bogota (Colombia - COT)", value: "America/Bogota" },
        { label: "🇵🇪 America/Lima (Peru - PET)", value: "America/Lima" },
        { label: "🇻🇪 America/Caracas (Venezuela - VET)", value: "America/Caracas" },

        // Asia & Middle East
        { label: "🇯🇵 Asia/Tokyo (Japan - JST)", value: "Asia/Tokyo" },
        { label: "🇰🇷 Asia/Seoul (South Korea - KST)", value: "Asia/Seoul" },
        { label: "🇨🇳 Asia/Shanghai (China - CST)", value: "Asia/Shanghai" },
        { label: "🇭🇰 Asia/Hong_Kong (Hong Kong - HKT)", value: "Asia/Hong_Kong" },
        { label: "🇸🇬 Asia/Singapore (Singapore - SGT)", value: "Asia/Singapore" },
        { label: "🇹🇼 Asia/Taipei (Taiwan - CST)", value: "Asia/Taipei" },
        { label: "🇮🇩 Asia/Jakarta (Indonesia Western - WIB)", value: "Asia/Jakarta" },
        { label: "🇹🇭 Asia/Bangkok (Thailand, Vietnam - ICT)", value: "Asia/Bangkok" },
        { label: "🇮🇳 Asia/Kolkata (India - IST)", value: "Asia/Kolkata" },
        { label: "🇵🇰 Asia/Karachi (Pakistan - PKT)", value: "Asia/Karachi" },
        { label: "🇧🇩 Asia/Dhaka (Bangladesh - BST)", value: "Asia/Dhaka" },
        { label: "🇦🇪 Asia/Dubai (UAE, Gulf - GST)", value: "Asia/Dubai" },
        { label: "🇸🇦 Asia/Riyadh (Saudi Arabia - AST)", value: "Asia/Riyadh" },
        { label: "🇮🇱 Asia/Jerusalem (Israel - IST / IDT)", value: "Asia/Jerusalem" },
        { label: "🇮🇷 Asia/Tehran (Iran - IRST / IRDT)", value: "Asia/Tehran" },
        { label: "🇶🇦 Asia/Qatar (Qatar - AST)", value: "Asia/Qatar" },

        // Australia & Pacific
        { label: "🇦🇺 Australia/Sydney (NSW, VIC, ACT, TAS - AEST / AEDT)", value: "Australia/Sydney" },
        { label: "🇦🇺 Australia/Melbourne (Victoria - AEST / AEDT)", value: "Australia/Melbourne" },
        { label: "🇦🇺 Australia/Adelaide (South Australia - ACST / ACDT)", value: "Australia/Adelaide" },
        { label: "🇦🇺 Australia/Darwin (Northern Territory - ACST)", value: "Australia/Darwin" },
        { label: "🇦🇺 Australia/Brisbane (Queensland - AEST)", value: "Australia/Brisbane" },
        { label: "🇦🇺 Australia/Perth (Western Australia - AWST)", value: "Australia/Perth" },
        { label: "🇦🇺 Australia/Hobart (Tasmania - AEST / AEDT)", value: "Australia/Hobart" },
        { label: "🇦🇺 Australia/Lord_Howe (Lord Howe Island)", value: "Australia/Lord_Howe" },
        { label: "🇳🇿 Pacific/Auckland (New Zealand - NZST / NZDT)", value: "Pacific/Auckland" },
        { label: "🇫🇯 Pacific/Fiji (Fiji - FJT / FJST)", value: "Pacific/Fiji" },

        // Europe & Russia
        { label: "🇬🇧 Europe/London (UK - GMT / BST)", value: "Europe/London" },
        { label: "🇮🇪 Europe/Dublin (Ireland - GMT / IST)", value: "Europe/Dublin" },
        { label: "🇫🇷 Europe/Paris (France - CET / CEST)", value: "Europe/Paris" },
        { label: "🇩🇪 Europe/Berlin (Germany - CET / CEST)", value: "Europe/Berlin" },
        { label: "🇪🇸 Europe/Madrid (Spain - CET / CEST)", value: "Europe/Madrid" },
        { label: "🇮🇹 Europe/Rome (Italy - CET / CEST)", value: "Europe/Rome" },
        { label: "🇳🇱 Europe/Amsterdam (Netherlands - CET / CEST)", value: "Europe/Amsterdam" },
        { label: "🇧🇪 Europe/Brussels (Belgium - CET / CEST)", value: "Europe/Brussels" },
        { label: "🇨🇭 Europe/Zurich (Switzerland - CET / CEST)", value: "Europe/Zurich" },
        { label: "🇦🇹 Europe/Vienna (Austria - CET / CEST)", value: "Europe/Vienna" },
        { label: "🇸🇪 Europe/Stockholm (Sweden - CET / CEST)", value: "Europe/Stockholm" },
        { label: "🇳🇴 Europe/Oslo (Norway - CET / CEST)", value: "Europe/Oslo" },
        { label: "🇩🇰 Europe/Copenhagen (Denmark - CET / CEST)", value: "Europe/Copenhagen" },
        { label: "🇵🇱 Europe/Warsaw (Poland - CET / CEST)", value: "Europe/Warsaw" },
        { label: "🇨🇿 Europe/Prague (Czechia - CET / CEST)", value: "Europe/Prague" },
        { label: "🇭🇺 Europe/Budapest (Hungary - CET / CEST)", value: "Europe/Budapest" },
        { label: "🇬🇷 Europe/Athens (Greece - EET / EEST)", value: "Europe/Athens" },
        { label: "🇫🇮 Europe/Helsinki (Finland - EET / EEST)", value: "Europe/Helsinki" },
        { label: "🇷🇴 Europe/Bucharest (Romania - EET / EEST)", value: "Europe/Bucharest" },
        { label: "🇺🇦 Europe/Kyiv (Ukraine - EET / EEST)", value: "Europe/Kyiv" },
        { label: "🇹🇷 Europe/Istanbul (Turkey - TRT)", value: "Europe/Istanbul" },
        { label: "🇷🇺 Europe/Moscow (Russia - MSK)", value: "Europe/Moscow" },

        // Fixed UTC Offsets (UTC-12 to UTC+14)
        { label: "UTC+14:00 (Line Islands, Kiribati)", value: "UTC+14" },
        { label: "UTC+13:00 (Tonga, Samoa)", value: "UTC+13" },
        { label: "UTC+12:45 (Chatham Islands)", value: "UTC+12:45" },
        { label: "UTC+12:00 (Marshall Islands, Tuvalu)", value: "UTC+12" },
        { label: "UTC+11:00 (Solomon Islands, Vanuatu)", value: "UTC+11" },
        { label: "UTC+10:30 (Lord Howe Standard)", value: "UTC+10:30" },
        { label: "UTC+10:00 (Guam, Papua New Guinea)", value: "UTC+10" },
        { label: "UTC+09:30 (Australian Central Standard)", value: "UTC+9:30" },
        { label: "UTC+09:00 (East Timor, Palau)", value: "UTC+9" },
        { label: "UTC+08:45 (Australian Central Western)", value: "UTC+8:45" },
        { label: "UTC+08:00 (Perth, Singapore, Beijing)", value: "UTC+8" },
        { label: "UTC+07:00 (Bangkok, Jakarta, Hanoi)", value: "UTC+7" },
        { label: "UTC+06:30 (Myanmar, Cocos Islands)", value: "UTC+6:30" },
        { label: "UTC+06:00 (Dhaka, Almaty)", value: "UTC+6" },
        { label: "UTC+05:45 (Nepal Standard)", value: "UTC+5:45" },
        { label: "UTC+05:30 (India Standard, Sri Lanka)", value: "UTC+5:30" },
        { label: "UTC+05:00 (Pakistan, Tashkent, Maldives)", value: "UTC+5" },
        { label: "UTC+04:30 (Afghanistan)", value: "UTC+4:30" },
        { label: "UTC+04:00 (Dubai, Baku, Yerevan, Tbilisi)", value: "UTC+4" },
        { label: "UTC+03:30 (Iran Standard)", value: "UTC+3:30" },
        { label: "UTC+03:00 (Moscow, Riyadh, Nairobi, Baghdad)", value: "UTC+3" },
        { label: "UTC+02:00 (Athens, Cairo, Helsinki, Johannesburg)", value: "UTC+2" },
        { label: "UTC+01:00 (Paris, Berlin, Rome, Madrid, Lagos)", value: "UTC+1" },
        { label: "UTC+00:00 (UTC, GMT, London, Reykjavik, Accra)", value: "UTC+0" },
        { label: "UTC-01:00 (Cabo Verde, Azores)", value: "UTC-1" },
        { label: "UTC-02:00 (South Georgia, Fernando de Noronha)", value: "UTC-2" },
        { label: "UTC-03:00 (Buenos Aires, Sao Paulo, Montevideo)", value: "UTC-3" },
        { label: "UTC-03:30 (Newfoundland Standard)", value: "UTC-3:30" },
        { label: "UTC-04:00 (Santiago, Caracas, Halifax, Manaus)", value: "UTC-4" },
        { label: "UTC-05:00 (New York, Toronto, Bogota, Lima)", value: "UTC-5" },
        { label: "UTC-06:00 (Chicago, Mexico City, Guatemala)", value: "UTC-6" },
        { label: "UTC-07:00 (Denver, Phoenix, Edmonton)", value: "UTC-7" },
        { label: "UTC-08:00 (Los Angeles, Vancouver, Tijuana)", value: "UTC-8" },
        { label: "UTC-09:00 (Anchorage, Gambier Islands)", value: "UTC-9" },
        { label: "UTC-09:30 (Marquesas Islands)", value: "UTC-9:30" },
        { label: "UTC-10:00 (Honolulu, Tahiti, Rarotonga)", value: "UTC-10" },
        { label: "UTC-11:00 (American Samoa, Niue, Midway)", value: "UTC-11" },

        // Custom Write-In Option
        { label: "✏️ Custom Timezone / City / Offset...", value: "__CUSTOM__" }
    ]

    property var localeOptions: [
        { label: "System Default", value: "" },
        { label: "🇬🇧 English (US / UK - en_US / en_GB)", value: "en_US" },
        { label: "🇫🇷 French (France - fr_FR)", value: "fr_FR" },
        { label: "🇩🇪 German (Germany - de_DE)", value: "de_DE" },
        { label: "🇪🇸 Spanish (Spain - es_ES)", value: "es_ES" },
        { label: "🇲🇽 Spanish (Mexico - es_MX)", value: "es_MX" },
        { label: "🇮🇹 Italian (Italy - it_IT)", value: "it_IT" },
        { label: "🇵🇹 Portuguese (Portugal - pt_PT)", value: "pt_PT" },
        { label: "🇧🇷 Portuguese (Brazil - pt_BR)", value: "pt_BR" },
        { label: "🇯🇵 Japanese (Japan - ja_JP)", value: "ja_JP" },
        { label: "🇰🇷 Korean (South Korea - ko_KR)", value: "ko_KR" },
        { label: "🇨🇳 Chinese (Simplified - zh_CN)", value: "zh_CN" },
        { label: "🇹🇼 Chinese (Traditional - zh_TW)", value: "zh_TW" },
        { label: "🇷🇺 Russian (Russia - ru_RU)", value: "ru_RU" },
        { label: "🇺🇦 Ukrainian (Ukraine - uk_UA)", value: "uk_UA" },
        { label: "🇵🇱 Polish (Poland - pl_PL)", value: "pl_PL" },
        { label: "🇳🇱 Dutch (Netherlands - nl_NL)", value: "nl_NL" },
        { label: "🇸🇪 Swedish (Sweden - sv_SE)", value: "sv_SE" },
        { label: "🇳🇴 Norwegian (Norway - nb_NO)", value: "nb_NO" },
        { label: "🇩🇰 Danish (Denmark - da_DK)", value: "da_DK" },
        { label: "🇫🇮 Finnish (Finland - fi_FI)", value: "fi_FI" },
        { label: "🇨🇿 Czech (Czechia - cs_CZ)", value: "cs_CZ" },
        { label: "🇸lovakia (sk_SK)", value: "sk_SK" },
        { label: "🇭🇺 Hungarian (Hungary - hu_HU)", value: "hu_HU" },
        { label: "🇷🇴 Romanian (Romania - ro_RO)", value: "ro_RO" },
        { label: "🇧🇬 Bulgarian (Bulgaria - bg_BG)", value: "bg_BG" },
        { label: "🇬🇷 Greek (Greece - el_GR)", value: "el_GR" },
        { label: "🇹🇷 Turkish (Turkey - tr_TR)", value: "tr_TR" },
        { label: "🇸🇦 Arabic (Saudi Arabia - ar_SA)", value: "ar_SA" },
        { label: "🇮🇳 Hindi (India - hi_IN)", value: "hi_IN" },
        { label: "🇮🇩 Indonesian (Indonesia - id_ID)", value: "id_ID" },
        { label: "🇻🇳 Vietnamese (Vietnam - vi_VN)", value: "vi_VN" },
        { label: "🇹🇭 Thai (Thailand - th_TH)", value: "th_TH" },
        { label: "✏️ Custom Locale...", value: "__CUSTOM__" }
    ]

    readonly property var timezoneLabels: timezoneOptions.map(function(opt) { return opt.label; })
    readonly property var localeLabels: localeOptions.map(function(opt) { return opt.label; })

    function colorToHex(col) {
        var c = Qt.color(col);
        var r = Math.round(c.r * 255).toString(16);
        var g = Math.round(c.g * 255).toString(16);
        var b = Math.round(c.b * 255).toString(16);
        if (r.length === 1) r = "0" + r;
        if (g.length === 1) g = "0" + g;
        if (b.length === 1) b = "0" + b;
        return "#" + r + g + b;
    }

    ColorDialog {
        id: colorPickerDialog
        title: i18n("Select Color")
        onAccepted: {
            if (configPage.activeColorCallback) {
                configPage.activeColorCallback(configPage.colorToHex(selectedColor));
            }
        }
    }

    function openColorPicker(currentColor, callback) {
        try {
            colorPickerDialog.selectedColor = Qt.color(currentColor || "#ffffff");
        } catch(e) {
            colorPickerDialog.selectedColor = Qt.color("#ffffff");
        }
        activeColorCallback = callback;
        colorPickerDialog.open();
    }

    property var rowsList: []
    property bool isLoaded: false
    property bool isSaving: false

    ListModel {
        id: sharedFontModel
        ListElement { text: "(Default)"; fontName: "" }
        ListElement { text: "Sans Serif"; fontName: "Sans Serif" }
        ListElement { text: "Serif"; fontName: "Serif" }
        ListElement { text: "Monospace"; fontName: "Monospace" }
    }

    ListModel {
        id: sharedFontOnlyModel
        ListElement { text: "Sans Serif"; fontName: "Sans Serif" }
        ListElement { text: "Serif"; fontName: "Serif" }
        ListElement { text: "Monospace"; fontName: "Monospace" }
    }

    ListModel {
        id: shapeTypesModel
        ListElement { text: "Circle / Ellipse / Oblong"; value: "circle" }
        ListElement { text: "Square / Rectangle"; value: "square" }
        ListElement { text: "Pill / Capsule"; value: "pill" }
        ListElement { text: "Triangle (3 sides)"; value: "triangle" }
        ListElement { text: "Pentagon (5 sides)"; value: "pentagon" }
        ListElement { text: "Hexagon (6 sides)"; value: "hexagon" }
        ListElement { text: "Heptagon (7 sides)"; value: "heptagon" }
        ListElement { text: "Octagon (8 sides)"; value: "octagon" }
        ListElement { text: "Nonagon (9 sides)"; value: "nonagon" }
        ListElement { text: "Decagon (10 sides)"; value: "decagon" }
    }

    onCfg_rowsJsonChanged: {
        if (isLoaded && !isSaving) {
            loadRowsFromJson();
        }
    }

    function getPlasmoidConfig() {
        try {
            if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration) return plasmoid.configuration;
            if (typeof kcm !== "undefined" && kcm && kcm.plasmoid && kcm.plasmoid.configuration) return kcm.plasmoid.configuration;
            if (typeof kcm !== "undefined" && kcm && kcm.widget && kcm.widget.configuration) return kcm.widget.configuration;
            if (configPage.Plasmoid && configPage.Plasmoid.configuration) return configPage.Plasmoid.configuration;
            if (configPage.parent && configPage.parent.plasmoid && configPage.parent.plasmoid.configuration) return configPage.parent.plasmoid.configuration;
        } catch(e) {}
        return null;
    }

    function getPlasmoidRoot() {
        try {
            if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.rootItem) return plasmoid.rootItem;
            if (configPage.parent && configPage.parent.plasmoid && configPage.parent.plasmoid.rootItem) return configPage.parent.plasmoid.rootItem;
        } catch(e) {}
        return null;
    }

    Timer {
        id: liveEditDebounceTimer
        interval: 150 // 150ms debounce eliminates D-Bus payload spam on slider drag
        repeat: false
        property var pendingOverrideJson: undefined

        onTriggered: {
            configPage.pushLiveEditingStateNow(pendingOverrideJson);
        }
    }

    function pushLiveEditingState(overrideRowsJson) {
        if (!isLoaded) return;
        liveEditDebounceTimer.pendingOverrideJson = overrideRowsJson;
        liveEditDebounceTimer.restart();
    }

    function pushLiveEditingStateNow(overrideRowsJson) {
        if (!isLoaded) return;
        try {
            isEditingHolder.value = true;
            editingRowsJsonHolder.text = (overrideRowsJson !== undefined) ? overrideRowsJson : (rowsJsonHolder.text || cfg_rowsJson);
            editingFontFamilyHolder.text = (typeof fontCombo !== "undefined" && fontCombo && fontCombo.selectedFont) ? fontCombo.selectedFont : cfg_fontFamily;
            editingBgTypeHolder.value = (typeof bgTypeCombo !== "undefined" && bgTypeCombo && bgTypeCombo.currentIndex !== undefined) ? bgTypeCombo.currentIndex : cfg_bgType;
            editingBgColorHolder.text = (typeof bgColorInput !== "undefined" && bgColorInput && bgColorInput.text) ? bgColorInput.text : cfg_bgColor;

            editingOverlayTypeHolder.value = (typeof overlayTypeCombo !== "undefined" && overlayTypeCombo && overlayTypeCombo.currentIndex !== undefined) ? overlayTypeCombo.currentIndex : cfg_overlayType;
            editingOverlayColorHolder.text = (typeof overlayColorInput !== "undefined" && overlayColorInput && overlayColorInput.text) ? overlayColorInput.text : cfg_overlayColor;
            editingOverlayOpacityHolder.value = (typeof overlayOpacitySlider !== "undefined" && overlayOpacitySlider) ? overlayOpacitySlider.value : cfg_overlayOpacity;
            editingOverlayFileHolder.text = (typeof overlayFileInput !== "undefined" && overlayFileInput && overlayFileInput.text) ? overlayFileInput.text : cfg_overlayFile;

            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.isEditing = true;
                pConfig.editingRowsJson = editingRowsJsonHolder.text;
                pConfig.editingFontFamily = editingFontFamilyHolder.text;
                pConfig.editingBgType = editingBgTypeHolder.value;
                pConfig.editingBgColor = editingBgColorHolder.text;

                pConfig.editingOverlayType = editingOverlayTypeHolder.value;
                pConfig.editingOverlayColor = editingOverlayColorHolder.text;
                pConfig.editingOverlayOpacity = editingOverlayOpacityHolder.value;
                pConfig.editingOverlayFile = editingOverlayFileHolder.text;
            }
        } catch(e) {
            console.log("[CustomCalendar Config] Error in pushLiveEditingStateNow:", e);
        }
    }

    function clearEditingState() {
        try {
            isEditingHolder.value = false;
            editingRowsJsonHolder.text = "";
            editingFontFamilyHolder.text = "";
            editingBgTypeHolder.value = -1;
            editingBgColorHolder.text = "";

            editingOverlayTypeHolder.value = -1;
            editingOverlayColorHolder.text = "";
            editingOverlayOpacityHolder.value = -1.0;
            editingOverlayFileHolder.text = "";

            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.isEditing = false;
                pConfig.editingRowsJson = "";
                pConfig.editingFontFamily = "";
                pConfig.editingBgType = -1;
                pConfig.editingBgColor = "";

                pConfig.editingOverlayType = -1;
                pConfig.editingOverlayColor = "";
                pConfig.editingOverlayOpacity = -1.0;
                pConfig.editingOverlayFile = "";
            }
        } catch(e) {}
    }

    function syncToPlasmoidConfig() {
        if (!isLoaded) return;
        try {
            var pConfig = getPlasmoidConfig();
            if (pConfig) {
                pConfig.rowsJson = rowsJsonHolder.text;
                pConfig.fontFamily = (typeof fontCombo !== "undefined" && fontCombo && fontCombo.selectedFont) ? fontCombo.selectedFont : cfg_fontFamily;
                pConfig.bgType = (typeof bgTypeCombo !== "undefined" && bgTypeCombo && bgTypeCombo.currentIndex !== undefined) ? bgTypeCombo.currentIndex : cfg_bgType;
                pConfig.bgColor = (typeof bgColorInput !== "undefined" && bgColorInput && bgColorInput.text) ? bgColorInput.text : cfg_bgColor;

                pConfig.overlayType = (typeof overlayTypeCombo !== "undefined" && overlayTypeCombo && overlayTypeCombo.currentIndex !== undefined) ? overlayTypeCombo.currentIndex : cfg_overlayType;
                pConfig.overlayColor = (typeof overlayColorInput !== "undefined" && overlayColorInput && overlayColorInput.text) ? overlayColorInput.text : cfg_overlayColor;
                pConfig.overlayOpacity = (typeof overlayOpacitySlider !== "undefined" && overlayOpacitySlider) ? overlayOpacitySlider.value : cfg_overlayOpacity;
                pConfig.overlayFile = (typeof overlayFileInput !== "undefined" && overlayFileInput && overlayFileInput.text) ? overlayFileInput.text : cfg_overlayFile;
            }
        } catch(e) {}
    }

    Component.onCompleted: {
        loadRowsFromJson();
        pushLiveEditingState();
        asyncFontLoadTimer.start();
    }

    Component.onDestruction: {
        clearEditingState();
    }



    function ensureFontInModels(fontName) {
        if (!fontName || typeof fontName !== "string" || fontName.trim() === "") return;
        var name = fontName.trim();

        var foundInShared = false;
        for (var i = 0; i < sharedFontModel.count; i++) {
            if (sharedFontModel.get(i).fontName.toLowerCase() === name.toLowerCase()) {
                foundInShared = true;
                break;
            }
        }
        if (!foundInShared) {
            sharedFontModel.append({ "text": name, "fontName": name });
        }

        var foundInOnly = false;
        for (var j = 0; j < sharedFontOnlyModel.count; j++) {
            if (sharedFontOnlyModel.get(j).fontName.toLowerCase() === name.toLowerCase()) {
                foundInOnly = true;
                break;
            }
        }
        if (!foundInOnly) {
            sharedFontOnlyModel.append({ "text": name, "fontName": name });
        }
    }

    Timer {
        id: asyncFontLoadTimer
        interval: 150
        repeat: false
        onTriggered: {
            buildSharedFontModels();
        }
    }

    function buildSharedFontModels() {
        if (sharedFontModel.count > 10) return; // Already populated
        var rawFonts = Qt.fontFamilies();
        var seen = {};
        var cleanList = [];
        var weightSuffixRegex = /\s+(Thin|ExtraLight|UltraLight|Light|Book|Regular|Medium|SemiBold|DemiBold|Bold|ExtraBold|UltraBold|Black|Heavy|Hair|Four|Eight)$/i;

        // Preserve any preselected fonts already added to sharedFontModel
        for (var s = 0; s < sharedFontModel.count; s++) {
            var sf = sharedFontModel.get(s).fontName.trim();
            if (sf) {
                seen[sf.toLowerCase()] = true;
                cleanList.push(sf);
            }
        }

        for (var j = 0; j < rawFonts.length; j++) {
            var fontName = rawFonts[j].trim();
            if (!fontName) continue;

            // Filter out redundant Noto regional sub-fonts to keep font list ultra-fast and readable
            if (fontName.indexOf("Noto ") === 0 && fontName !== "Noto Sans" && fontName !== "Noto Serif" && fontName !== "Noto Mono" && fontName !== "Noto Color Emoji") {
                continue;
            }

            var match = fontName.match(weightSuffixRegex);
            if (match) {
                var baseName = fontName.substring(0, match.index).trim();
                if (seen[baseName.toLowerCase()]) continue;
            }

            var key = fontName.toLowerCase();
            if (!seen[key]) {
                seen[key] = true;
                cleanList.push(fontName);
            }
        }

        // Ultra-fast case-insensitive string sort
        cleanList.sort(function(a, b) {
            var la = a.toLowerCase();
            var lb = b.toLowerCase();
            return la < lb ? -1 : (la > lb ? 1 : 0);
        });

        sharedFontModel.clear();
        sharedFontOnlyModel.clear();

        sharedFontModel.append({ "text": "(Default)", "fontName": "" });

        for (var k = 0; k < cleanList.length; k++) {
            var fn = cleanList[k];
            sharedFontModel.append({ "text": fn, "fontName": fn });
            sharedFontOnlyModel.append({ "text": fn, "fontName": fn });
        }
    }

    function loadRowsFromJson() {
        try {
            if (cfg_rowsJson && cfg_rowsJson.length > 0) {
                rowsList = JSON.parse(cfg_rowsJson);
            } else {
                rowsList = [
                    { "format": "dddd", "align": "center", "fontSize": 18, "color": "#ffffff", "effectColor": "", "weight": "400", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "dd mmm yyy", "align": "center", "fontSize": 28, "color": "#ffffff", "effectColor": "", "weight": "400", "effect": "none", "opacity": 1.0, "timeZone": "" },
                    { "format": "H:i", "align": "center", "fontSize": 48, "color": "#ffffff", "weight": "600", "effect": "none", "opacity": 1.0, "timeZone": "" }
                ];
            }
        } catch(e) {
            rowsList = [];
        }
        ensureFontInModels(cfg_fontFamily);
        rowsModel.clear();
        for (var i = 0; i < rowsList.length; i++) {
            var item = rowsList[i];
            if (item.fontFamily) {
                ensureFontInModels(item.fontFamily);
            }
            if (!item.effect) {
                item.effect = item.glow ? "glow" : "none";
            }
            if (item.opacity === undefined) {
                item.opacity = 1.0;
            }
            if (!item.effectColor) {
                item.effectColor = "";
            }
            if (!item.timeZone) {
                item.timeZone = "";
            }
            if (!item.weight) {
                item.weight = "400";
            }
            if (!item.fontFamily) {
                item.fontFamily = "";
            }
            var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX !== undefined ? item.offsetX : 0);
            var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin !== undefined ? item.topMargin : 0);
            item.offsetWidth = offX;
            item.offsetX = offX;
            item.offsetHeight = offY;
            item.topMargin = offY;

            if (item.rotation === undefined) {
                item.rotation = 0;
            }
            if (item.letterSpacing === undefined) {
                item.letterSpacing = 0;
            }
            if (item.effectSize === undefined) {
                item.effectSize = 2;
            }
            if (!item.clickCommand) {
                item.clickCommand = "";
            }
            var isSh = (item.isShape === true || item.isShape === "true") && (!item.format || item.format === "");
            item.isShape = isSh;
            if (isSh) {
                if (!item.shapeType) item.shapeType = "circle";
                if (item.shapeWidth === undefined) item.shapeWidth = 100;
                if (item.shapeHeight === undefined) item.shapeHeight = 100;
                if (!item.color) item.color = "#3b82f6";
                item.format = "";
                item.showTimeZone = false;
                item.showLocale = false;
                item.showFontFamily = false;
                item.showWeight = false;
                item.showLetterSpacing = false;
            } else {
                item.isShape = false;
                item.shapeType = "";
                if (!item.format) item.format = "dddd";
            }

            item.fromCenter = (item.fromCenter === true || item.fromCenter === "true");
            item.showTimeZone = !item.isShape && item.timeZone !== "";
            item.showLocale = !item.isShape && item.locale !== "";
            item.showClickCommand = item.clickCommand !== "";
            item.showFontFamily = !item.isShape && item.fontFamily !== "";
            item.showWeight = !item.isShape && String(item.weight) !== "400";
            item.showAlign = item.align !== undefined && item.align !== "center";
            item.showOpacity = item.opacity !== 1.0;
            item.showOffsets = (offX !== 0 || offY !== 0 || item.fromCenter === true);
            item.showRotation = item.rotation !== 0;
            item.showLetterSpacing = !item.isShape && item.letterSpacing !== 0;
            item.showEffect = item.effect !== "none";

            rowsModel.append(item);
        }
        isLoaded = true;
        saveRowsToJson(true);
    }

    function cleanStockDefaults() {
        for (var i = 0; i < rowsModel.count; i++) {
            var item = rowsModel.get(i);
            var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX || 0);
            var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin || 0);
            if (offX === 0 && offY === 0 && !item.fromCenter) rowsModel.setProperty(i, "showOffsets", false);
            if (item.rotation === 0) rowsModel.setProperty(i, "showRotation", false);
            if (item.letterSpacing === 0) rowsModel.setProperty(i, "showLetterSpacing", false);
            if (item.opacity === 1.0) rowsModel.setProperty(i, "showOpacity", false);
            if (String(item.weight) === "400") rowsModel.setProperty(i, "showWeight", false);
            if (item.align === "center") rowsModel.setProperty(i, "showAlign", false);
            if (!item.fontFamily || item.fontFamily === "") rowsModel.setProperty(i, "showFontFamily", false);
            if (!item.timeZone || item.timeZone === "") rowsModel.setProperty(i, "showTimeZone", false);
            if (!item.locale || item.locale === "") rowsModel.setProperty(i, "showLocale", false);
            if (!item.clickCommand || item.clickCommand === "") rowsModel.setProperty(i, "showClickCommand", false);
            if (!item.effect || item.effect === "none") rowsModel.setProperty(i, "showEffect", false);
        }
    }

    function markChanged() {
        if (!isLoaded) return;
        try { configPage.needsSave = true; } catch(e) {}
        try { configPage.unrepresentedNeedsSave = true; } catch(e) {}
        try {
            if (typeof kcm !== "undefined" && kcm) {
                kcm.needsSave = true;
                kcm.unrepresentedNeedsSave = true;
            }
        } catch(e) {}
    }

    function serializeRowItem(item) {
        var offX = item.offsetWidth !== undefined ? item.offsetWidth : (item.offsetX !== undefined ? item.offsetX : 0);
        var offY = item.offsetHeight !== undefined ? item.offsetHeight : (item.topMargin !== undefined ? item.topMargin : 0);
        var isSh = (item.isShape === true || item.isShape === "true") && (!item.format || item.format === "");

        if (isSh) {
            return {
                "isShape": true,
                "shapeType": item.shapeType || "circle",
                "shapeWidth": item.shapeWidth || 100,
                "shapeHeight": item.shapeHeight || 100,
                "color": item.color || "#3b82f6",
                "align": item.showAlign ? (item.align || "center") : "center",
                "opacity": item.showOpacity && item.opacity !== undefined ? item.opacity : 1.0,
                "offsetWidth": item.showOffsets ? offX : 0,
                "offsetHeight": item.showOffsets ? offY : 0,
                "offsetX": item.showOffsets ? offX : 0,
                "topMargin": item.showOffsets ? offY : 0,
                "fromCenter": item.showOffsets && (item.fromCenter === true || item.fromCenter === "true"),
                "rotation": item.rotation !== undefined ? item.rotation : 0,
                "effect": item.showEffect ? (item.effect || "none") : "none",
                "effectColor": item.showEffect ? (item.effectColor || "") : "",
                "effectSize": item.showEffect && item.effectSize !== undefined ? item.effectSize : 2,
                "clickCommand": item.showClickCommand ? (item.clickCommand || "") : ""
            };
        } else {
            return {
                "format": item.format || "",
                "fontFamily": item.showFontFamily ? (item.fontFamily || "") : "",
                "align": item.showAlign ? (item.align || "center") : "center",
                "fontSize": item.fontSize || 24,
                "color": item.color || "#ffffff",
                "effectColor": item.showEffect ? (item.effectColor || "") : "",
                "weight": item.showWeight ? String(item.weight || "400") : "400",
                "effect": item.showEffect ? (item.effect || "none") : "none",
                "opacity": item.showOpacity && item.opacity !== undefined ? item.opacity : 1.0,
                "offsetWidth": item.showOffsets ? offX : 0,
                "offsetHeight": item.showOffsets ? offY : 0,
                "offsetX": item.showOffsets ? offX : 0,
                "topMargin": item.showOffsets ? offY : 0,
                "fromCenter": item.showOffsets && (item.fromCenter === true || item.fromCenter === "true"),
                "rotation": item.rotation !== undefined ? item.rotation : 0,
                "letterSpacing": item.showLetterSpacing && item.letterSpacing !== undefined ? item.letterSpacing : 0,
                "effectSize": item.showEffect && item.effectSize !== undefined ? item.effectSize : 2,
                "timeZone": item.showTimeZone ? (item.timeZone || "") : "",
                "locale": item.showLocale ? (item.locale || "") : "",
                "clickCommand": item.showClickCommand ? (item.clickCommand || "") : "",
                "glow": item.showEffect && item.effect === "glow"
            };
        }
    }

    Timer {
        id: debounceSaveTimer
        interval: 150
        repeat: false
        onTriggered: {
            saveRowsToJsonDirect(false);
        }
    }

    function saveRowsToJson(skipMarkChanged) {
        if (!isLoaded) return;
        if (skipMarkChanged) {
            saveRowsToJsonDirect(true);
        } else {
            debounceSaveTimer.restart();
        }
    }

    function saveRowsToJsonDirect(skipMarkChanged) {
        if (!isLoaded) return;
        var arr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            arr.push(serializeRowItem(rowsModel.get(i)));
        }
        var jsonStr = JSON.stringify(arr);
        isSaving = true;
        rowsJsonHolder.text = jsonStr;
        pushLiveEditingState(jsonStr);
        if (!skipMarkChanged) {
            markChanged();
        }
        isSaving = false;
    }

    function save() {
        cleanStockDefaults();
        if (!isLoaded) return;
        var arr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            arr.push(serializeRowItem(rowsModel.get(i)));
        }
        var jsonStr = JSON.stringify(arr);
        isSaving = true;
        rowsJsonHolder.text = jsonStr;
        syncToPlasmoidConfig();
        clearEditingState();
        isSaving = false;
    }

    function getExportPresetJson() {
        var rowsArr = [];
        for (var i = 0; i < rowsModel.count; i++) {
            rowsArr.push(serializeRowItem(rowsModel.get(i)));
        }

        var preset = {
            "generator": "Custom Calendar & Clock Plasmoid",
            "version": "1.3.0",
            "fontFamily": fontCombo.selectedFont,
            "bgType": bgTypeCombo.currentIndex,
            "bgColor": bgColorInput.text || "#1e293b",
            "rows": rowsArr
        };

        return JSON.stringify(preset, null, 2);
    }

    // Security & Import Architecture:
    // Power users have full freedom to author custom shell commands for row click actions.
    // To prevent silent command injection from third-party JSON presets (e.g. shared online),
    // applyImportedJson() performs an automated pre-import security audit scan on incoming JSON payloads.
    // If clickCommands are detected, import is paused and commandSecurityAuditDialog displays an interactive
    // line-by-line review allowing the user to explicitly Trust & Enable, Strip Commands, or Cancel Import.
    property var pendingImportPayload: null

    function applyImportedJson(jsonText) {
        try {
            if (!jsonText || jsonText.trim().length === 0) {
                importPresetDialog.statusMessage = i18n("Please paste or select a valid JSON preset.");
                importPresetDialog.isError = true;
                return;
            }
            var data = JSON.parse(jsonText);
            var targetRows = [];

            if (Array.isArray(data)) {
                targetRows = data;
            } else if (typeof data === "object" && data !== null) {
                if (data.rows && Array.isArray(data.rows)) {
                    targetRows = data.rows;
                }
            } else {
                importPresetDialog.statusMessage = i18n("Invalid JSON format.");
                importPresetDialog.isError = true;
                return;
            }

            if (!targetRows || targetRows.length === 0) {
                importPresetDialog.statusMessage = i18n("No valid rows found in JSON preset.");
                importPresetDialog.isError = true;
                return;
            }

            var commandsFound = [];
            for (var c = 0; c < targetRows.length; c++) {
                var rCmd = targetRows[c].clickCommand;
                if (rCmd && typeof rCmd === "string" && rCmd.trim().length > 0) {
                    commandsFound.push({
                        rowIndex: c + 1,
                        fmt: targetRows[c].format || "Shape",
                        cmd: rCmd.trim()
                    });
                }
            }

            var payload = { data: data, targetRows: targetRows, commands: commandsFound };
            if (commandsFound.length > 0) {
                configPage.pendingImportPayload = payload;
                commandSecurityAuditDialog.open();
            } else {
                executeImportData(payload, true);
            }
        } catch(e) {
            importPresetDialog.statusMessage = i18n("JSON Parsing Error: ") + e.message;
            importPresetDialog.isError = true;
        }
    }

    function executeImportData(payload, keepCommands) {
        if (!payload || !payload.targetRows) return;
        try {
            var data = payload.data;
            var targetRows = payload.targetRows;

            if (!keepCommands) {
                for (var i = 0; i < targetRows.length; i++) {
                    targetRows[i].clickCommand = "";
                }
            }

            if (typeof data === "object" && !Array.isArray(data) && data !== null) {
                if (data.fontFamily !== undefined && data.fontFamily !== "") {
                    fontCombo.selectedFont = data.fontFamily;
                }
                if (data.bgType !== undefined && data.bgType >= 0 && data.bgType <= 2) {
                    bgTypeCombo.currentIndex = data.bgType;
                }
                if (data.bgColor !== undefined && data.bgColor !== "") {
                    bgColorInput.text = data.bgColor;
                }
            }

            cfg_rowsJson = JSON.stringify(targetRows);
            loadRowsFromJson();
            save();
            importPresetDialog.statusMessage = i18n("Preset applied successfully!");
            importPresetDialog.isError = false;
            importPresetDialog.close();
            configPage.pendingImportPayload = null;
        } catch(e) {
            importPresetDialog.statusMessage = i18n("Error applying preset: ") + e.message;
            importPresetDialog.isError = true;
        }
    }

    function readJsonFile(fileUrl) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", fileUrl, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    importJsonArea.text = xhr.responseText;
                    importPresetDialog.statusMessage = i18n("File loaded. Click 'Apply Preset' to import.");
                    importPresetDialog.isError = false;
                } else {
                    importPresetDialog.statusMessage = i18n("Failed to read file.");
                    importPresetDialog.isError = true;
                }
            }
        };
        xhr.send();
    }

    function writeJsonFile(fileUrl, content) {
        var xhr = new XMLHttpRequest();
        xhr.open("PUT", fileUrl, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    exportPresetDialog.title = i18n("Export Design Preset (Saved!)");
                }
            }
        };
        try {
            xhr.send(content);
        } catch(e) {}
    }

    Dialog {
        id: exportPresetDialog
        title: i18n("Export Design Preset")
        modal: true
        anchors.centerIn: parent
        width: Math.min(configPage.width * 0.9, 580)
        height: Math.min(configPage.height * 0.9, 420)
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Label {
                text: i18n("Copy this JSON preset snippet to share your design with others:")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextArea {
                    id: exportJsonArea
                    font.family: "Monospace"
                    font.pixelSize: 12
                    wrapMode: TextEdit.Wrap
                    readOnly: true
                    selectByMouse: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: i18n("📋 Copy to Clipboard")
                    icon.name: "edit-copy"
                    onClicked: {
                        exportJsonArea.selectAll();
                        exportJsonArea.copy();
                        copyNotification.visible = true;
                    }
                }
                Label {
                    id: copyNotification
                    text: i18n("Copied!")
                    color: Kirigami.Theme.positiveTextColor
                    visible: false
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: i18n("📂 Save to File...")
                    icon.name: "document-save-as"
                    onClicked: {
                        exportFileDialog.open();
                    }
                }
            }
        }
    }

    Dialog {
        id: importPresetDialog
        title: i18n("Import Design Preset")
        modal: true
        anchors.centerIn: parent
        width: Math.min(configPage.width * 0.9, 580)
        height: Math.min(configPage.height * 0.9, 420)
        standardButtons: Dialog.Close

        property string statusMessage: ""
        property bool isError: false

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Label {
                text: i18n("Paste a JSON preset string below or load from a file:")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextArea {
                    id: importJsonArea
                    font.family: "Monospace"
                    font.pixelSize: 12
                    wrapMode: TextEdit.Wrap
                    placeholderText: i18n("Paste JSON preset code here...")
                    selectByMouse: true
                }
            }

            Label {
                text: importPresetDialog.statusMessage
                color: importPresetDialog.isError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                visible: importPresetDialog.statusMessage.length > 0
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: i18n("📂 Load from File...")
                    icon.name: "document-open"
                    onClicked: {
                        importFileDialog.open();
                    }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: i18n("🚀 Apply Preset")
                    icon.name: "dialog-ok-apply"
                    highlighted: true
                    onClicked: {
                        applyImportedJson(importJsonArea.text);
                    }
                }
            }
        }
    }

    FileDialog {
        id: importFileDialog
        title: i18n("Open Preset File")
        fileMode: FileDialog.OpenFile
        nameFilters: [i18n("JSON Files (*.json)"), i18n("All Files (*)")]
        onAccepted: {
            readJsonFile(selectedFile);
        }
    }

    FileDialog {
        id: exportFileDialog
        title: i18n("Save Preset File")
        fileMode: FileDialog.SaveFile
        nameFilters: [i18n("JSON Files (*.json)"), i18n("All Files (*)")]
        currentFile: "custom-calendar-preset.json"
        onAccepted: {
            writeJsonFile(selectedFile, exportJsonArea.text);
        }
    }

    FileDialog {
        id: overlayFileDialog
        title: i18n("Select Overlay Media File")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            i18n("Media Files (*.png *.jpg *.jpeg *.gif *.webp *.mp4 *.webm *.ogv *.mov *.avi *.3gp *.mkv)"),
            i18n("Image Files (*.png *.jpg *.jpeg *.gif *.webp)"),
            i18n("Video Files (*.mp4 *.webm *.ogv *.mov *.avi *.3gp *.mkv)"),
            i18n("All Files (*)")
        ]
        onAccepted: {
            // Strip the file:// protocol prefix if present, as Qt Quick handles local paths directly
            var path = String(selectedFile);
            if (path.indexOf("file://") === 0) {
                path = path.substring(7);
            }
            overlayFileInput.text = path;
            pushLiveEditingState();
            markChanged();
        }
    }

    Dialog {
        id: commandSecurityAuditDialog
        title: i18n("⚠️ Security Review: Executable Commands Detected")
        modal: true
        anchors.centerIn: parent
        width: Math.min(configPage.width * 0.95, 580)
        height: Math.min(configPage.height * 0.95, 450)
        standardButtons: Dialog.NoButton

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: i18n("The imported layout contains custom shell commands that will execute when rows are clicked. Please review them carefully:")
                wrapMode: Text.WordWrap
                font.bold: true
                color: Kirigami.Theme.warningTextColor
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: auditCommandsListView
                    model: configPage.pendingImportPayload ? configPage.pendingImportPayload.commands : []
                    clip: true
                    spacing: 6

                    delegate: Rectangle {
                        width: auditCommandsListView.width
                        implicitHeight: col.implicitHeight + 12
                        color: Kirigami.Theme.alternateBackgroundColor
                        border.color: Kirigami.Theme.focusColor
                        radius: 6

                        Column {
                            id: col
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            Text {
                                text: "Row " + modelData.rowIndex + " ('" + modelData.fmt + "')"
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Text {
                                text: modelData.cmd
                                color: Kirigami.Theme.negativeTextColor
                                font.family: "Monospace"
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                width: parent.width
                            }
                        }
                    }
                }
            }

            Label {
                text: i18n("Do you trust the author of this preset and want to enable these click commands?")
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: i18n("Cancel Import")
                    icon.name: "dialog-cancel"
                    onClicked: {
                        commandSecurityAuditDialog.close();
                        configPage.pendingImportPayload = null;
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: i18n("Import (Strip Commands)")
                    icon.name: "edit-clear"
                    onClicked: {
                        configPage.executeImportData(configPage.pendingImportPayload, false);
                        commandSecurityAuditDialog.close();
                    }
                }

                Button {
                    text: i18n("Trust & Enable Commands")
                    icon.name: "security-high"
                    highlighted: true
                    onClicked: {
                        configPage.executeImportData(configPage.pendingImportPayload, true);
                        commandSecurityAuditDialog.close();
                    }
                }
            }
        }
    }

    ListModel {
        id: rowsModel
        dynamicRoles: true

        function removeRow(idx) {
            if (count > 1 && idx >= 0 && idx < count) {
                remove(idx);
                saveToJson();
            }
        }

        function moveRow(fromIdx, toIdx) {
            if (fromIdx >= 0 && fromIdx < count && toIdx >= 0 && toIdx < count) {
                move(fromIdx, toIdx, 1);
                saveToJson();
            }
        }

        function saveToJson() {
            saveRowsToJson();
        }
    }

    Kirigami.FormLayout {
        id: formLayout

        RowLayout {
            Kirigami.FormData.label: i18n("Design Presets:")
            spacing: 8

            Button {
                text: i18n("📤 Export Preset")
                icon.name: "document-export"
                onClicked: {
                    exportJsonArea.text = getExportPresetJson();
                    copyNotification.visible = false;
                    exportPresetDialog.open();
                }
            }

            Button {
                text: i18n("📥 Import Preset")
                icon.name: "document-import"
                onClicked: {
                    importJsonArea.text = "";
                    importPresetDialog.statusMessage = "";
                    importPresetDialog.open();
                }
            }
        }

        ComboBox {
            id: fontCombo
            Kirigami.FormData.label: i18n("Font Family:")

            property string selectedFont: "Sans Serif"
            model: sharedFontOnlyModel
            textRole: "text"
            valueRole: "fontName"

            delegate: ItemDelegate {
                width: parent ? parent.width : 200
                contentItem: Text {
                    text: model.text
                    font.family: (model.fontName && model.fontName !== "") ? model.fontName : fontCombo.font.family
                    font.pixelSize: 14
                    color: parent.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                highlighted: fontCombo.currentIndex === index
            }

            Binding on currentIndex {
                value: {
                    var f = fontCombo.selectedFont;
                    if (!f) return 0;
                    for (var m = 0; m < sharedFontOnlyModel.count; m++) {
                        if (sharedFontOnlyModel.get(m).fontName.toLowerCase() === f.toLowerCase()) return m;
                    }
                    return 0;
                }
            }

            onActivated: function(index) {
                if (index >= 0 && index < sharedFontOnlyModel.count) {
                    selectedFont = sharedFontOnlyModel.get(index).fontName;
                    pushLiveEditingState();
                    markChanged();
                }
            }
        }

        ComboBox {
            id: bgTypeCombo
            Kirigami.FormData.label: i18n("Background Style:")
            model: [
                i18n("Blurred Glass"),
                i18n("Solid Color"),
                i18n("Transparent (No Background)")
            ]
            onActivated: function(index) {
                pushLiveEditingState();
                markChanged();
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background Color:")
            visible: bgTypeCombo.currentIndex !== 2

            Rectangle {
                id: bgColorSwatch
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 4
                color: bgColorInput.text || "#1e293b"
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        configPage.openColorPicker(bgColorInput.text, function(hex) {
                            bgColorInput.text = hex;
                            bgColorInput.textEdited();
                            pushLiveEditingState();
                            markChanged();
                        });
                    }
                }
            }

            TextField {
                id: bgColorInput
                Layout.fillWidth: true
                placeholderText: "#1e293b"
                onTextEdited: {
                    pushLiveEditingState();
                    markChanged();
                }
            }
        }

        // Design Overlay Configuration
        ComboBox {
            id: overlayTypeCombo
            Kirigami.FormData.label: i18n("Overlay Type:")
            model: [
                i18n("None"),
                i18n("Solid Color"),
                i18n("Media File (Image/GIF/Video)")
            ]
            onActivated: function(index) {
                pushLiveEditingState();
                markChanged();
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Overlay Color:")
            visible: overlayTypeCombo.currentIndex === 1

            Rectangle {
                id: overlayColorSwatch
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 4
                color: overlayColorInput.text || "#000000"
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        configPage.openColorPicker(overlayColorInput.text, function(hex) {
                            overlayColorInput.text = hex;
                            overlayColorInput.textEdited();
                            pushLiveEditingState();
                            markChanged();
                        });
                    }
                }
            }

            TextField {
                id: overlayColorInput
                Layout.fillWidth: true
                placeholderText: "#000000"
                onTextEdited: {
                    pushLiveEditingState();
                    markChanged();
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Overlay Media File:")
            visible: overlayTypeCombo.currentIndex === 2

            TextField {
                id: overlayFileInput
                Layout.fillWidth: true
                placeholderText: i18n("Select local image, GIF, or video...")
                onTextEdited: {
                    pushLiveEditingState();
                    markChanged();
                }
            }

            Button {
                text: i18n("Browse...")
                icon.name: "document-open"
                onClicked: {
                    overlayFileDialog.open();
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Overlay Opacity:")
            visible: overlayTypeCombo.currentIndex !== 0

            Slider {
                id: overlayOpacitySlider
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                stepSize: 0.05
                value: overlayOpacityHolder.value
                onMoved: {
                    overlayOpacityHolder.value = value;
                    pushLiveEditingState();
                    markChanged();
                }
            }

            Label {
                text: Math.round(overlayOpacitySlider.value * 100) + "%"
                Layout.preferredWidth: 35
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: rowsModel

                delegate: Frame {
                    id: delegateFrame
                    Layout.fillWidth: true
                    padding: 8

                    property bool isItemShape: (model.isShape === true || model.isShape === "true") && (model.format === undefined || model.format === "")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        // Header Row (Row title + Reorder & Remove controls)
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: delegateFrame.isItemShape ? (i18n("Shape ") + (index + 1)) : (i18n("Row ") + (index + 1))
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: i18n("▲")
                                enabled: index > 0
                                onClicked: {
                                    rowsModel.moveRow(index, index - 1);
                                }
                            }
                            Button {
                                text: i18n("▼")
                                enabled: index < rowsModel.count - 1
                                onClicked: {
                                    rowsModel.moveRow(index, index + 1);
                                }
                            }
                            Button {
                                text: i18n("Remove")
                                enabled: rowsModel.count > 1
                                onClicked: {
                                    rowsModel.removeRow(index);
                                }
                            }
                        }

                        // Shape Always-Visible Controls
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: delegateFrame.isItemShape

                            Label { text: i18n("Shape:") }
                            ComboBox {
                                id: shapeCombo
                                textRole: "text"
                                valueRole: "value"
                                model: shapeTypesModel
                                currentIndex: {
                                    var st = model.shapeType || "circle";
                                    for (var s = 0; s < shapeTypesModel.count; s++) {
                                        if (shapeTypesModel.get(s).value === st) return s;
                                    }
                                    return 0;
                                }
                                onActivated: function(sIdx) {
                                    if (sIdx >= 0 && sIdx < shapeTypesModel.count) {
                                        rowsModel.setProperty(index, "shapeType", shapeTypesModel.get(sIdx).value);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            Label { text: i18n("W:") }
                            SpinBox {
                                from: 1
                                to: 1000
                                stepSize: 5
                                value: model.shapeWidth || 100
                                onValueModified: {
                                    rowsModel.setProperty(index, "shapeWidth", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("H:") }
                            SpinBox {
                                from: 1
                                to: 1000
                                stepSize: 5
                                value: model.shapeHeight || 100
                                onValueModified: {
                                    rowsModel.setProperty(index, "shapeHeight", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("Color:") }
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 4
                                color: model.color || "#3b82f6"
                                border.color: Kirigami.Theme.disabledTextColor
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        configPage.openColorPicker(model.color || "#3b82f6", function(hex) {
                                            if (configPage.isLoaded) {
                                                rowsModel.setProperty(index, "color", hex);
                                                rowsModel.saveToJson();
                                            }
                                        });
                                    }
                                }
                            }
                            TextField {
                                Layout.preferredWidth: 80
                                Binding on text { value: model.color || "#3b82f6" }
                                placeholderText: "#3b82f6"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "color", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            ComboBox {
                                id: addShapeOptionCombo
                                textRole: "text"
                                model: [
                                    { text: i18n("+ Add Option..."), value: "" },
                                    { text: i18n("Click Command"), value: "clickCommand" },
                                    { text: i18n("Alignment"), value: "align" },
                                    { text: i18n("Opacity"), value: "opacity" },
                                    { text: i18n("Offsets (X/Y)"), value: "offsets" },
                                    { text: i18n("Rotation (°)"), value: "rotation" },
                                    { text: i18n("Shape Effect"), value: "effect" }
                                ]
                                currentIndex: 0
                                onActivated: function(idx) {
                                    if (idx <= 0) return;
                                    var val = addShapeOptionCombo.model[idx].value;
                                    if (val === "clickCommand") { rowsModel.setProperty(index, "clickCommand", "kcalc"); rowsModel.setProperty(index, "showClickCommand", true); }
                                    else if (val === "align") { rowsModel.setProperty(index, "align", "left"); rowsModel.setProperty(index, "showAlign", true); }
                                    else if (val === "opacity") { rowsModel.setProperty(index, "opacity", 0.8); rowsModel.setProperty(index, "showOpacity", true); }
                                    else if (val === "offsets") {
                                        rowsModel.setProperty(index, "offsetWidth", 10);
                                        rowsModel.setProperty(index, "offsetX", 10);
                                        rowsModel.setProperty(index, "offsetHeight", -10);
                                        rowsModel.setProperty(index, "topMargin", -10);
                                        rowsModel.setProperty(index, "showOffsets", true);
                                    }
                                    else if (val === "rotation") { rowsModel.setProperty(index, "rotation", 45); rowsModel.setProperty(index, "showRotation", true); }
                                    else if (val === "effect") { rowsModel.setProperty(index, "effect", "glow"); rowsModel.setProperty(index, "showEffect", true); }
                                    rowsModel.saveToJson();
                                    currentIndex = 0;
                                }
                            }
                        }

                        // Core Always-Visible Controls (Format, Font Size, Text Color, + Add Option...)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: !delegateFrame.isItemShape

                            Label { text: i18n("Format:") }
                            TextField {
                                Layout.fillWidth: true
                                Binding on text { value: model.format || "" }
                                placeholderText: "e.g. dddd, dd mmm yyy, H:i"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "format", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            Label { text: i18n("Size:") }
                            SpinBox {
                                from: 1
                                to: 1000
                                value: model.fontSize || 24
                                onValueModified: {
                                    rowsModel.setProperty(index, "fontSize", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("Color:") }
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 4
                                color: model.color || "#ffffff"
                                border.color: Kirigami.Theme.disabledTextColor
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        configPage.openColorPicker(model.color || "#ffffff", function(hex) {
                                            if (configPage.isLoaded) {
                                                rowsModel.setProperty(index, "color", hex);
                                                rowsModel.saveToJson();
                                            }
                                        });
                                    }
                                }
                            }
                            TextField {
                                Layout.preferredWidth: 80
                                Binding on text { value: model.color || "#ffffff" }
                                placeholderText: "#ffffff"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "color", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            ComboBox {
                                id: addOptionCombo
                                textRole: "text"
                                valueRole: "value"
                                model: [
                                    { text: i18n("+ Add Option..."), value: "" },
                                    { text: i18n("Timezone"), value: "timeZone" },
                                    { text: i18n("Locale"), value: "locale" },
                                    { text: i18n("Click Command"), value: "clickCommand" },
                                    { text: i18n("Font Family"), value: "fontFamily" },
                                    { text: i18n("Font Weight"), value: "weight" },
                                    { text: i18n("Alignment"), value: "align" },
                                    { text: i18n("Opacity"), value: "opacity" },
                                    { text: i18n("Offsets (X/Y)"), value: "offsets" },
                                    { text: i18n("Rotation (°)"), value: "rotation" },
                                    { text: i18n("Letter Spacing"), value: "letterSpacing" },
                                    { text: i18n("Text Effect"), value: "effect" }
                                ]
                                currentIndex: 0
                                onActivated: function(idx) {
                                    if (idx <= 0) return;
                                    var val = addOptionCombo.model[idx].value;
                                    if (val === "timeZone") { rowsModel.setProperty(index, "timeZone", "UTC"); rowsModel.setProperty(index, "showTimeZone", true); }
                                    else if (val === "locale") { rowsModel.setProperty(index, "locale", "ja_JP"); rowsModel.setProperty(index, "showLocale", true); }
                                    else if (val === "clickCommand") { rowsModel.setProperty(index, "clickCommand", "kcalc"); rowsModel.setProperty(index, "showClickCommand", true); }
                                    else if (val === "fontFamily") { rowsModel.setProperty(index, "fontFamily", sharedFontModel.count > 1 ? sharedFontModel.get(1).fontName : "Sans Serif"); rowsModel.setProperty(index, "showFontFamily", true); }
                                    else if (val === "weight") { rowsModel.setProperty(index, "weight", "700"); rowsModel.setProperty(index, "showWeight", true); }
                                    else if (val === "align") { rowsModel.setProperty(index, "align", "left"); rowsModel.setProperty(index, "showAlign", true); }
                                    else if (val === "opacity") { rowsModel.setProperty(index, "opacity", 0.8); rowsModel.setProperty(index, "showOpacity", true); }
                                    else if (val === "offsets") {
                                        rowsModel.setProperty(index, "offsetWidth", 10);
                                        rowsModel.setProperty(index, "offsetX", 10);
                                        rowsModel.setProperty(index, "offsetHeight", -10);
                                        rowsModel.setProperty(index, "topMargin", -10);
                                        rowsModel.setProperty(index, "showOffsets", true);
                                    }
                                    else if (val === "rotation") { rowsModel.setProperty(index, "rotation", 45); rowsModel.setProperty(index, "showRotation", true); }
                                    else if (val === "letterSpacing") { rowsModel.setProperty(index, "letterSpacing", 2); rowsModel.setProperty(index, "showLetterSpacing", true); }
                                    else if (val === "effect") { rowsModel.setProperty(index, "effect", "glow"); rowsModel.setProperty(index, "showEffect", true); }
                                    rowsModel.saveToJson();
                                    currentIndex = 0;
                                }
                            }
                        }

                        // 9. Rotation
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showRotation === true
                            spacing: 8
                            Label { text: i18n("Rotation (°):") }
                            SpinBox {
                                from: -360
                                to: 360
                                stepSize: 5
                                value: model.rotation !== undefined ? model.rotation : 0
                                onValueModified: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "rotation", value);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                            Slider {
                                Layout.fillWidth: true
                                from: -180
                                to: 180
                                stepSize: 1
                                value: model.rotation !== undefined ? model.rotation : 0
                                onMoved: {
                                    if (configPage.isLoaded) {
                                        var v = Math.round(value);
                                        rowsModel.setProperty(index, "rotation", v);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "rotation", 0);
                                    rowsModel.setProperty(index, "showRotation", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // --- Dynamic Optional Setting Rows (Only visible when set) ---

                        // 1. Timezone
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: !delegateFrame.isItemShape && (rowsModel.get(index) ? (rowsModel.get(index).showTimeZone === true || rowsModel.get(index).showTimeZone === "true") : false)
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label { text: i18n("Timezone:") }

                                ComboBox {
                                    id: tzCombo
                                    Layout.fillWidth: true
                                    model: configPage.timezoneLabels

                                    property string currentTzVal: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).timeZone || "") : ""

                                    function getIndexForValue(val) {
                                        var clean = (val || "").trim().toUpperCase();
                                        for (var k = 0; k < configPage.timezoneOptions.length - 1; k++) {
                                            if (configPage.timezoneOptions[k].value.toUpperCase() === clean) {
                                                return k;
                                            }
                                        }
                                        return configPage.timezoneOptions.length - 1;
                                    }

                                    currentIndex: getIndexForValue(currentTzVal)

                                    onActivated: function(comboIdx) {
                                        if (configPage.isLoaded) {
                                            var rIdx = index;
                                            var selVal = configPage.timezoneOptions[comboIdx].value;
                                            if (selVal !== "__CUSTOM__") {
                                                rowsModel.setProperty(rIdx, "timeZone", selVal);
                                                rowsModel.setProperty(rIdx, "showTimeZone", true);
                                                rowsModel.saveToJson();
                                            }
                                        }
                                    }
                                }

                                Button {
                                    text: "✕"
                                    onClicked: {
                                        var rIdx = index;
                                        rowsModel.setProperty(rIdx, "timeZone", "");
                                        rowsModel.setProperty(rIdx, "showTimeZone", false);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            TextField {
                                Layout.fillWidth: true
                                visible: tzCombo.currentIndex === configPage.timezoneOptions.length - 1
                                text: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).timeZone || "") : ""
                                placeholderText: "e.g. Europe/Madrid, America/Sao_Paulo, UTC+3:30..."
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        var rIdx = index;
                                        rowsModel.setProperty(rIdx, "timeZone", text);
                                        rowsModel.setProperty(rIdx, "showTimeZone", true);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                        }

                        // 2. Locale
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: !delegateFrame.isItemShape && (rowsModel.get(index) ? (rowsModel.get(index).showLocale === true || rowsModel.get(index).showLocale === "true") : false)
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label { text: i18n("Locale:") }

                                ComboBox {
                                    id: locCombo
                                    Layout.fillWidth: true
                                    model: configPage.localeLabels

                                    property string currentLocVal: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).locale || "") : ""

                                    function getIndexForValue(val) {
                                        var clean = (val || "").trim().toLowerCase();
                                        for (var k = 0; k < configPage.localeOptions.length - 1; k++) {
                                            if (configPage.localeOptions[k].value.toLowerCase() === clean) {
                                                return k;
                                            }
                                        }
                                        return configPage.localeOptions.length - 1;
                                    }

                                    currentIndex: getIndexForValue(currentLocVal)

                                    onActivated: function(comboIdx) {
                                        if (configPage.isLoaded) {
                                            var rIdx = index;
                                            var selVal = configPage.localeOptions[comboIdx].value;
                                            if (selVal !== "__CUSTOM__") {
                                                rowsModel.setProperty(rIdx, "locale", selVal);
                                                rowsModel.setProperty(rIdx, "showLocale", true);
                                                rowsModel.saveToJson();
                                            }
                                        }
                                    }
                                }

                                Button {
                                    text: "✕"
                                    onClicked: {
                                        var rIdx = index;
                                        rowsModel.setProperty(rIdx, "locale", "");
                                        rowsModel.setProperty(rIdx, "showLocale", false);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            TextField {
                                Layout.fillWidth: true
                                visible: locCombo.currentIndex === configPage.localeOptions.length - 1
                                text: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).locale || "") : ""
                                placeholderText: "e.g. ja_JP, fr_FR, de_DE, es_ES, uk_UA, zh_CN..."
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        var rIdx = index;
                                        rowsModel.setProperty(rIdx, "locale", text);
                                        rowsModel.setProperty(rIdx, "showLocale", true);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                        }

                        // 3. Click Command
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showClickCommand === true
                            Label { text: i18n("Click Command:") }
                            TextField {
                                Layout.fillWidth: true
                                Binding on text { value: model.clickCommand || "" }
                                placeholderText: "Executable command on click (e.g. kcalc, korganizer, brave)"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "clickCommand", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "clickCommand", "");
                                    rowsModel.setProperty(index, "showClickCommand", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 4. Custom Font Family
                        RowLayout {
                            Layout.fillWidth: true
                            visible: !delegateFrame.isItemShape && (rowsModel.get(index) ? (rowsModel.get(index).showFontFamily === true || rowsModel.get(index).showFontFamily === "true") : false)
                            Label { text: i18n("Font Family:") }
                            ComboBox {
                                id: rowFontCombo
                                Layout.fillWidth: true
                                model: sharedFontModel
                                textRole: "text"
                                valueRole: "fontName"
                                property string currentFVal: (index >= 0 && index < rowsModel.count && rowsModel.get(index)) ? (rowsModel.get(index).fontFamily || "") : ""
                                delegate: ItemDelegate {
                                    width: parent ? parent.width : 200
                                    contentItem: Text {
                                        text: model.text
                                        font.family: (model.fontName && model.fontName !== "") ? model.fontName : rowFontCombo.font.family
                                        font.pixelSize: 14
                                        color: parent.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: rowFontCombo.currentIndex === index
                                }
                                Binding on currentIndex {
                                    value: {
                                        var f = rowFontCombo.currentFVal;
                                        if (!f || f === "") return 0;
                                        for (var m = 1; m < sharedFontModel.count; m++) {
                                            if (sharedFontModel.get(m).fontName.toLowerCase() === f.toLowerCase()) return m;
                                        }
                                        return 0;
                                    }
                                }
                                onActivated: function(idx) {
                                    var rIdx = index;
                                    var selected = (idx <= 0) ? "" : sharedFontModel.get(idx).fontName;
                                    rowsModel.setProperty(rIdx, "fontFamily", selected);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "fontFamily", "");
                                    rowsModel.setProperty(index, "showFontFamily", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 5. Font Weight
                        RowLayout {
                            Layout.fillWidth: true
                            visible: !delegateFrame.isItemShape && model.showWeight === true
                            Label { text: i18n("Font Weight:") }
                            ComboBox {
                                id: weightCombo
                                model: [
                                    { text: i18n("Light (300)"), value: "300" },
                                    { text: i18n("Normal (400)"), value: "400" },
                                    { text: i18n("SemiBold (600)"), value: "600" },
                                    { text: i18n("Bold (700)"), value: "700" },
                                    { text: i18n("Black (900)"), value: "900" }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                Binding on currentIndex {
                                    value: {
                                        var w = String(model.weight || "400");
                                        if (w === "300") return 0;
                                        if (w === "400") return 1;
                                        if (w === "600") return 2;
                                        if (w === "700") return 3;
                                        if (w === "900") return 4;
                                        return 1;
                                    }
                                }
                                onActivated: function(idx) {
                                    var selectedWeight = weightCombo.model[idx].value;
                                    rowsModel.setProperty(index, "weight", selectedWeight);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "weight", "400");
                                    rowsModel.setProperty(index, "showWeight", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 6. Alignment
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showAlign === true
                            Label { text: i18n("Alignment:") }
                            ComboBox {
                                id: alignCombo
                                model: ["center", "left", "right"]
                                Binding on currentIndex {
                                    value: {
                                        var a = model.align || "center";
                                        if (a === "left") return 1;
                                        if (a === "right") return 2;
                                        return 0;
                                    }
                                }
                                onActivated: function(idx) {
                                    var selectedAlign = alignCombo.model[idx];
                                    rowsModel.setProperty(index, "align", selectedAlign);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "align", "center");
                                    rowsModel.setProperty(index, "showAlign", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 7. Opacity
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showOpacity === true
                            Label { text: i18n("Opacity (%):") }
                            SpinBox {
                                from: 10
                                to: 100
                                stepSize: 5
                                value: Math.round((model.opacity !== undefined ? model.opacity : 1.0) * 100)
                                onValueModified: {
                                    rowsModel.setProperty(index, "opacity", value / 100.0);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "opacity", 1.0);
                                    rowsModel.setProperty(index, "showOpacity", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 8. Offsets (Width X / Height Y)
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showOffsets === true
                            spacing: 8

                            Label { text: i18n("Offset Width (X):") }
                            SpinBox {
                                from: -1000
                                to: 1000
                                stepSize: 2
                                value: model.offsetWidth !== undefined ? model.offsetWidth : (model.offsetX !== undefined ? model.offsetX : 0)
                                onValueModified: {
                                    rowsModel.setProperty(index, "offsetWidth", value);
                                    rowsModel.setProperty(index, "offsetX", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("Offset Height (Y):") }
                            SpinBox {
                                from: -1000
                                to: 1000
                                stepSize: 2
                                value: model.offsetHeight !== undefined ? model.offsetHeight : (model.topMargin !== undefined ? model.topMargin : 0)
                                onValueModified: {
                                    rowsModel.setProperty(index, "offsetHeight", value);
                                    rowsModel.setProperty(index, "topMargin", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            CheckBox {
                                text: i18n("From Direct Center")
                                checked: model.fromCenter === true || model.fromCenter === "true"
                                onCheckedChanged: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "fromCenter", checked);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "offsetWidth", 0);
                                    rowsModel.setProperty(index, "offsetX", 0);
                                    rowsModel.setProperty(index, "offsetHeight", 0);
                                    rowsModel.setProperty(index, "topMargin", 0);
                                    rowsModel.setProperty(index, "fromCenter", false);
                                    rowsModel.setProperty(index, "showOffsets", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 10. Letter Spacing
                        RowLayout {
                            Layout.fillWidth: true
                            visible: !delegateFrame.isItemShape && model.showLetterSpacing === true
                            Label { text: i18n("Letter Spacing (px):") }
                            SpinBox {
                                from: -1000
                                to: 1000
                                stepSize: 1
                                value: model.letterSpacing !== undefined ? model.letterSpacing : 0
                                onValueModified: {
                                    rowsModel.setProperty(index, "letterSpacing", value);
                                    rowsModel.saveToJson();
                                }
                            }
                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "letterSpacing", 0);
                                    rowsModel.setProperty(index, "showLetterSpacing", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                        // 11. Text Effect
                        RowLayout {
                            Layout.fillWidth: true
                            visible: model.showEffect === true
                            spacing: 8

                            Label { text: i18n("Effect:") }
                            ComboBox {
                                id: effectCombo
                                model: [
                                    { text: i18n("None"), value: "none" },
                                    { text: i18n("Neon Glow"), value: "glow" },
                                    { text: i18n("Normal Shadow"), value: "normalShadow" },
                                    { text: i18n("Drop Shadow"), value: "shadow" },
                                    { text: i18n("Outer Stroke"), value: "stroke" }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                Binding on currentIndex {
                                    value: {
                                        var e = model.effect || "none";
                                        if (e === "glow") return 1;
                                        if (e === "normalShadow") return 2;
                                        if (e === "shadow") return 3;
                                        if (e === "stroke") return 4;
                                        return 0;
                                    }
                                }
                                onActivated: function(idx) {
                                    var selectedEffect = effectCombo.model[idx].value;
                                    rowsModel.setProperty(index, "effect", selectedEffect);
                                    rowsModel.saveToJson();
                                }
                            }

                            Label { text: i18n("Color:") }
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 4
                                color: model.effectColor && model.effectColor.length > 0 ? model.effectColor : "transparent"
                                border.color: Kirigami.Theme.disabledTextColor
                                border.width: 1

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 1
                                    color: "#ff0000"
                                    visible: !model.effectColor || model.effectColor.length === 0
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        configPage.openColorPicker(model.effectColor || "#000000", function(hex) {
                                            if (configPage.isLoaded) {
                                                rowsModel.setProperty(index, "effectColor", hex);
                                                rowsModel.saveToJson();
                                            }
                                        });
                                    }
                                }
                            }
                            TextField {
                                Layout.preferredWidth: 80
                                Binding on text { value: model.effectColor || "" }
                                placeholderText: "#000000"
                                onTextEdited: {
                                    if (configPage.isLoaded) {
                                        rowsModel.setProperty(index, "effectColor", text);
                                        rowsModel.saveToJson();
                                    }
                                }
                            }

                            Label { text: i18n("Size:") }
                            SpinBox {
                                from: 1
                                to: 50
                                stepSize: 1
                                value: model.effectSize !== undefined ? model.effectSize : 2
                                onValueModified: {
                                    rowsModel.setProperty(index, "effectSize", value);
                                    rowsModel.saveToJson();
                                }
                            }

                            Button {
                                text: "✕"
                                onClicked: {
                                    rowsModel.setProperty(index, "effect", "none");
                                    rowsModel.setProperty(index, "effectColor", "");
                                    rowsModel.setProperty(index, "effectSize", 2);
                                    rowsModel.setProperty(index, "showEffect", false);
                                    rowsModel.saveToJson();
                                }
                            }
                        }

                    }
                }
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignLeft

                Button {
                    text: i18n("+ Add Row")
                    icon.name: "list-add"
                    onClicked: {
                        rowsModel.append({
                            "isShape": false,
                            "format": "H:i:ss",
                            "align": "center",
                            "fontSize": 24,
                            "color": "#ffffff",
                            "effectColor": "",
                            "weight": "400",
                            "effect": "none",
                            "opacity": 1.0,
                            "topMargin": 0,
                            "offsetX": 0,
                            "offsetWidth": 0,
                            "offsetHeight": 0,
                            "letterSpacing": 0,
                            "effectSize": 2,
                            "timeZone": "",
                            "locale": "",
                            "clickCommand": "",
                            "showTimeZone": false,
                            "showLocale": false,
                            "showClickCommand": false,
                            "showFontFamily": false,
                            "showWeight": false,
                            "showAlign": false,
                            "showOpacity": false,
                            "showOffsets": false,
                            "showLetterSpacing": false,
                            "showEffect": false
                        });
                        rowsModel.saveToJson();
                    }
                }

                Button {
                    text: i18n("+ Add Shape")
                    icon.name: "draw-polygon"
                    onClicked: {
                        rowsModel.append({
                            "isShape": true,
                            "shapeType": "circle",
                            "shapeWidth": 100,
                            "shapeHeight": 100,
                            "color": "#3b82f6",
                            "align": "center",
                            "opacity": 1.0,
                            "topMargin": 0,
                            "offsetX": 0,
                            "offsetWidth": 0,
                            "offsetHeight": 0,
                            "effect": "none",
                            "effectColor": "",
                            "effectSize": 2,
                            "clickCommand": "",
                            "showTimeZone": false,
                            "showLocale": false,
                            "showClickCommand": false,
                            "showFontFamily": false,
                            "showWeight": false,
                            "showAlign": false,
                            "showOpacity": false,
                            "showOffsets": false,
                            "showLetterSpacing": false,
                            "showEffect": false
                        });
                        rowsModel.saveToJson();
                    }
                }
            }
        }
    }
}
