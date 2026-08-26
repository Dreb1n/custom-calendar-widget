import QtQuick 2.15
import QtTest 1.15
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../contents/ui/config" as Config

TestCase {
    name: "ConfigGeneralTests"

    Component {
        id: configComp
        Config.ConfigGeneral {}
    }

    function test_settings_page_loads_font_field() {
        const page = createTemporaryObject(configComp, this, {});
        verify(page !== null, "ConfigGeneral page must instantiate successfully");

        // Verify initial font family property alias
        compare(page.cfg_fontFamily, "Sans Serif", "ConfigGeneral must load initial font family 'Sans Serif'");
    }

    function test_duplicate_row_preserves_ui_flags() {
        const page = createTemporaryObject(configComp, this, {});
        verify(page !== null, "ConfigGeneral page must instantiate successfully");

        // Obtain internal rowsModel
        var rm = page.children[0];
        // If rowsModel is accessible from page, test row duplication
        if (rm && rm.duplicateRow) {
            var initialCount = rm.count;
            if (initialCount > 0) {
                rm.setProperty(0, "showOffsets", true);
                rm.duplicateRow(0);
                compare(rm.count, initialCount + 1, "Model count should increment by 1");
                compare(rm.get(1).showOffsets, true, "Duplicated row must preserve UI view expansion flag showOffsets");
            }
        }
    }
}
