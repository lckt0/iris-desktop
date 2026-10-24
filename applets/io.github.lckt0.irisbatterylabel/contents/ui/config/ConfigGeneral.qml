import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_showPercentSign: showPercentSign.checked
    property alias cfg_fontBold: fontBold.checked
    property alias cfg_colorizeStates: colorizeStates.checked
    property alias cfg_lowThreshold: lowThreshold.value
    property alias cfg_criticalThreshold: criticalThreshold.value

    QQC2.CheckBox {
        id: showPercentSign
        Kirigami.FormData.label: i18n("Text:")
        text: i18n("Append a % sign")
    }

    QQC2.CheckBox {
        id: fontBold
        text: i18n("Bold")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: colorizeStates
        Kirigami.FormData.label: i18n("Colour:")
        text: i18n("Colour the number while charging, low and critical")
    }

    QQC2.SpinBox {
        id: lowThreshold
        Kirigami.FormData.label: i18n("Low at:")
        enabled: colorizeStates.checked
        from: 1
        to: 99
    }

    QQC2.SpinBox {
        id: criticalThreshold
        Kirigami.FormData.label: i18n("Critical at:")
        enabled: colorizeStates.checked
        from: 1
        to: 99
    }

    QQC2.Label {
        Kirigami.FormData.label: i18n("Note:")
        text: i18n("This widget is only the number. Keep Plasma's own Battery and Brightness widget next to it for the icon, the brightness slider and power profiles — and turn its \"Show percentage\" option off.")
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        opacity: 0.7
    }
}
