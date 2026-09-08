import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configTokensPage

    ListModel {
        id: tokenModel

        ListElement { token: "dddd / EEEE"; desc: "Full day of week name"; example: "Saturday"; category: "Date" }
        ListElement { token: "ddd / EEE"; desc: "Short day of week name"; example: "Sat"; category: "Date" }
        ListElement { token: "mmmm / MMMM"; desc: "Full month name"; example: "August"; category: "Date" }
        ListElement { token: "mmm / MMM"; desc: "Short month name"; example: "Aug"; category: "Date" }
        ListElement { token: "mm / MM"; desc: "Zero-padded month number (01-12)"; example: "08"; category: "Date" }
        ListElement { token: "yyyy / YYYY"; desc: "Full 4-digit year"; example: "2026"; category: "Date" }
        ListElement { token: "yy / YY"; desc: "2-digit year"; example: "26"; category: "Date" }
        ListElement { token: "do"; desc: "Day of month with ordinal suffix"; example: "1st, 2nd, 3rd, 14th"; category: "Date" }
        ListElement { token: "dd"; desc: "Zero-padded day of month (01-31)"; example: "01"; category: "Date" }
        ListElement { token: "d"; desc: "Single/double digit day of month (1-31)"; example: "1"; category: "Date" }
        ListElement { token: "HH"; desc: "Zero-padded 24-hour clock (00-23)"; example: "09"; category: "Time" }
        ListElement { token: "H"; desc: "24-hour clock (0-23)"; example: "9"; category: "Time" }
        ListElement { token: "hh"; desc: "Zero-padded 12-hour clock (01-12)"; example: "09"; category: "Time" }
        ListElement { token: "h"; desc: "12-hour clock (1-12)"; example: "9"; category: "Time" }
        ListElement { token: "i / MN"; desc: "Zero-padded minutes (00-59)"; example: "05"; category: "Time" }
        ListElement { token: "ss"; desc: "Zero-padded seconds (00-59)"; example: "08"; category: "Time" }
        ListElement { token: "s"; desc: "Seconds (0-59)"; example: "8"; category: "Time" }
        ListElement { token: "A"; desc: "Uppercase AM/PM indicator"; example: "AM / PM"; category: "Time" }
        ListElement { token: "a"; desc: "Lowercase am/pm indicator"; example: "am / pm"; category: "Time" }
        ListElement { token: "WW"; desc: "Zero-padded ISO week number"; example: "31"; category: "Misc" }
        ListElement { token: "W"; desc: "ISO week number"; example: "31"; category: "Misc" }
        ListElement { token: "TZ"; desc: "Target timezone name"; example: "Asia/Tokyo"; category: "Misc" }
        ListElement { token: "X"; desc: "Unix epoch timestamp in seconds"; example: "1785579846"; category: "Misc" }
    }

    ColumnLayout {
        Kirigami.FormData.label: i18n("Format Reference:")
        Layout.fillWidth: true
        spacing: 12

        // Escaping Literal Text Tip Card
        Kirigami.AbstractCard {
            Layout.fillWidth: true

            header: RowLayout {
                spacing: 8
                Kirigami.Icon {
                    source: "dialog-information"
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                }
                Label {
                    text: i18n("Escaping Literal Text with Square Brackets [...]")
                    font.bold: true
                    font.pixelSize: 14
                }
            }

            contentItem: ColumnLayout {
                spacing: 6

                Label {
                    text: i18n("Any text inside square brackets [Like This] is treated as literal text and will not be parsed as date/time format tokens.")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: i18n("Why is this necessary?")
                    font.bold: true
                }

                Label {
                    text: i18n("Letters like d, m, y, h, i, s, a, w, x are active tokens. To include words containing those letters (e.g. 'of', 'in', 'at', 'Day'), enclose them in brackets:\n• do [of] MMMM, yyyy  ➔  1st of August, 2026\n• HH:i [in] TZ  ➔  14:32 in Europe/London\n• [Day] dddd, [Week] W  ➔  Day Saturday, Week 34")
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                    color: Kirigami.Theme.disabledTextColor
                    Layout.fillWidth: true
                }
            }
        }

        // Search Filter
        Kirigami.SearchField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: i18n("Filter tokens (e.g. month, year, time, HH, dddd)...")
        }

        // Format Token Table Card
        Kirigami.AbstractCard {
            Layout.fillWidth: true

            header: Label {
                text: i18n("Date & Time Format Specifiers")
                font.bold: true
                font.pixelSize: 14
            }

            contentItem: ColumnLayout {
                spacing: 0

                // Header Row
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: Kirigami.Theme.alternateBackgroundColor
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Label {
                            text: i18n("Token")
                            font.bold: true
                            Layout.preferredWidth: 140
                        }
                        Label {
                            text: i18n("Description")
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Label {
                            text: i18n("Example Output")
                            font.bold: true
                            Layout.preferredWidth: 160
                        }
                    }
                }

                Repeater {
                    model: tokenModel

                    delegate: Rectangle {
                        id: tokenRow

                        property string filterQuery: searchField.text.trim().toLowerCase()
                        property bool matchesFilter: {
                            if (filterQuery === "") return true;
                            return model.token.toLowerCase().indexOf(filterQuery) !== -1 ||
                                   model.desc.toLowerCase().indexOf(filterQuery) !== -1 ||
                                   model.example.toLowerCase().indexOf(filterQuery) !== -1;
                        }

                        visible: matchesFilter
                        Layout.fillWidth: true
                        implicitHeight: visible ? 36 : 0
                        color: index % 2 === 0 ? "transparent" : Kirigami.Theme.alternateBackgroundColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Label {
                                text: model.token
                                font.bold: true
                                font.family: "monospace"
                                font.pixelSize: 13
                                color: Kirigami.Theme.highlightColor
                                Layout.preferredWidth: 140
                            }
                            Label {
                                text: model.desc
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                text: model.example
                                font.family: "monospace"
                                color: Kirigami.Theme.disabledTextColor
                                Layout.preferredWidth: 160
                            }
                        }
                    }
                }
            }
        }

        // Example Format Strings Card
        Kirigami.AbstractCard {
            Layout.fillWidth: true

            header: Label {
                text: i18n("Common Example Format Strings")
                font.bold: true
                font.pixelSize: 14
            }

            contentItem: ColumnLayout {
                spacing: 6

                RowLayout {
                    spacing: 8
                    Label { text: "dddd"; font.bold: true; font.family: "monospace"; Layout.preferredWidth: 200 }
                    Label { text: "➔ Saturday"; color: Kirigami.Theme.disabledTextColor }
                }
                RowLayout {
                    spacing: 8
                    Label { text: "dd mmm yyy"; font.bold: true; font.family: "monospace"; Layout.preferredWidth: 200 }
                    Label { text: "➔ 01 Aug 2026"; color: Kirigami.Theme.disabledTextColor }
                }
                RowLayout {
                    spacing: 8
                    Label { text: "do [of] MMMM, yyyy"; font.bold: true; font.family: "monospace"; Layout.preferredWidth: 200 }
                    Label { text: "➔ 1st of August, 2026"; color: Kirigami.Theme.disabledTextColor }
                }
                RowLayout {
                    spacing: 8
                    Label { text: "HH:i:ss"; font.bold: true; font.family: "monospace"; Layout.preferredWidth: 200 }
                    Label { text: "➔ 14:32:05"; color: Kirigami.Theme.disabledTextColor }
                }
                RowLayout {
                    spacing: 8
                    Label { text: "hh:i A ([Timezone:] TZ)"; font.bold: true; font.family: "monospace"; Layout.preferredWidth: 200 }
                    Label { text: "➔ 02:32 PM (Timezone: Asia/Tokyo)"; color: Kirigami.Theme.disabledTextColor }
                }
                RowLayout {
                    spacing: 8
                    Label { text: "[Week] W - dddd"; font.bold: true; font.family: "monospace"; Layout.preferredWidth: 200 }
                    Label { text: "➔ Week 34 - Saturday"; color: Kirigami.Theme.disabledTextColor }
                }
            }
        }
    }
}
