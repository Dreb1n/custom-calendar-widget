import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: aboutPage

    title: i18n("About")

    ColumnLayout {
        spacing: 16
        anchors.fill: parent

        // Header Section
        Kirigami.Card {
            Layout.fillWidth: true

            contentItem: ColumnLayout {
                spacing: 12

                RowLayout {
                    spacing: 16

                    Image {
                        source: Qt.resolvedUrl("icon.png")
                        implicitWidth: 48
                        implicitHeight: 48
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        spacing: 2

                        Label {
                            text: i18n("Custom Calendar and Clock")
                            font.bold: true
                            font.pointSize: 16
                        }

                        Label {
                            text: i18n("Version 1.4.1")
                            color: Kirigami.Theme.disabledTextColor
                        }

                    }

                }

                Label {
                    text: i18n("Customizable multi-row calendar and clock widget for KDE Plasma 6. Features include custom layouts, per-row format strings, live system font selection, advanced text masking shaders, video backgrounds, and color overlays.")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pointSize: 10
                }

            }

        }

        // Links / Actions Section
        Kirigami.Card {
            Layout.fillWidth: true

            contentItem: ColumnLayout {
                spacing: 12

                Label {
                    text: i18n("Links & Resources")
                    font.bold: true
                    font.pointSize: 12
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Button {
                        Layout.fillWidth: true
                        text: i18n("🌐 KDE Store Page (store.kde.org/p/2367412)")
                        icon.name: "get-hot-new-stuff"
                        onClicked: {
                            Qt.openUrlExternally("https://store.kde.org/p/2367412");
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: i18n("🐙 GitHub Repository (github.com/Dreb1n/custom-calendar-widget)")
                        icon.name: "vcs-git"
                        onClicked: {
                            Qt.openUrlExternally("https://github.com/Dreb1n/custom-calendar-widget");
                        }
                    }

                }

            }

        }

        // Author / License Section
        Kirigami.Card {
            Layout.fillWidth: true

            contentItem: ColumnLayout {
                spacing: 6

                Label {
                    text: i18n("Authors & Contributors")
                    font.bold: true
                    font.pointSize: 12
                }

                Label {
                    text: i18n("• Dreb1n (Creator & Lead Developer)")
                }

                Item {
                    implicitHeight: 6
                }

                Label {
                    text: i18n("License: GPL-2.0-or-later")
                    font.italic: true
                    color: Kirigami.Theme.disabledTextColor
                }

            }

        }

    }

}
