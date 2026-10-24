import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_windowSeconds: windowSeconds.value
    property alias cfg_sampleIntervalMs: sampleIntervalMs.value
    property real cfg_wattageThreshold
    property alias cfg_fontBold: fontBold.checked

    QQC2.SpinBox {
        id: windowSeconds
        Kirigami.FormData.label: i18n("Average over:")
        from: 10
        to: 600
        stepSize: 10
        textFromValue: value => i18n("%1 s", value)
        valueFromText: text => parseInt(text)
    }

    QQC2.SpinBox {
        id: sampleIntervalMs
        Kirigami.FormData.label: i18n("Sample every:")
        from: 1000
        to: 10000
        stepSize: 500
        textFromValue: value => i18n("%1 s", (value / 1000).toFixed(1))
        valueFromText: text => Math.round(parseFloat(text) * 1000)
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.SpinBox {
        id: threshold
        Kirigami.FormData.label: i18n("Red on battery above:")
        from: 1
        to: 100
        value: Math.round(page.cfg_wattageThreshold)
        onValueModified: page.cfg_wattageThreshold = value
        textFromValue: value => i18n("%1 W", value)
        valueFromText: text => parseInt(text)
    }

    QQC2.CheckBox {
        id: fontBold
        Kirigami.FormData.label: i18n("Text:")
        text: i18n("Bold")
    }
}
