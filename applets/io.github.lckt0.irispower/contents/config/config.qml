import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "battery-profile-powersave-symbolic"
        source: "config/ConfigGeneral.qml"
    }
}
