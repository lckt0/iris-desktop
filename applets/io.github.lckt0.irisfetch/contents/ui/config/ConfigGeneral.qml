import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_refreshSeconds: refreshSeconds.value
    property alias cfg_fontPixelSize: fontPixelSize.value
    property alias cfg_showLogo: showLogo.checked
    property alias cfg_extraArguments: extraArguments.text

    QQC2.SpinBox {
        id: refreshSeconds
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 10
        to: 3600
        stepSize: 10
        textFromValue: value => i18n("%1 s", value)
        valueFromText: text => parseInt(text)
    }

    QQC2.SpinBox {
        id: fontPixelSize
        Kirigami.FormData.label: i18n("Text size:")
        from: 6
        to: 48
        textFromValue: value => i18n("%1 px", value)
        valueFromText: text => parseInt(text)
    }

    QQC2.CheckBox {
        id: showLogo
        Kirigami.FormData.label: i18n("Logo:")
        text: i18n("Show the distribution logo")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.TextField {
        id: extraArguments
        Kirigami.FormData.label: i18n("Extra fastfetch arguments:")
        placeholderText: "--config ~/.config/fastfetch/desktop.jsonc"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    }

    QQC2.Label {
        Kirigami.FormData.label: i18n("Note:")
        text: i18n("Modules, keys and colours come from your fastfetch config. The shell is your login shell.")
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        opacity: 0.7
    }
}
