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
}
