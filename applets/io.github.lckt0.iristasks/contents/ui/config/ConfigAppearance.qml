import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_showLabels: showLabels.checked
    property alias cfg_maxTaskWidth: maxWidth.value
    property alias cfg_minTaskWidth: minWidth.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_taskSpacing: spacing.value
    property alias cfg_indicatorThickness: indicatorThickness.value
    property alias cfg_fillWidth: fillWidth.checked
    property int cfg_indicatorEdge

    QQC2.CheckBox {
        id: showLabels
        Kirigami.FormData.label: i18n("Labels:")
        text: i18n("Show window titles")
    }

    QQC2.CheckBox {
        id: fillWidth
        text: i18n("Fill available panel space")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.SpinBox {
        id: maxWidth
        Kirigami.FormData.label: i18n("Maximum task width:")
        from: 60
        to: 420
        stepSize: 10
    }

    QQC2.SpinBox {
        id: minWidth
        Kirigami.FormData.label: i18n("Collapsed task width:")
        from: 24
        to: 120
        stepSize: 2
    }

    QQC2.SpinBox {
        id: spacing
        Kirigami.FormData.label: i18n("Spacing between tasks:")
        from: 0
        to: 12
    }

    QQC2.SpinBox {
        id: iconSize
        Kirigami.FormData.label: i18n("Icon size (0 = automatic):")
        from: 0
        to: 64
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.SpinBox {
        id: indicatorThickness
        Kirigami.FormData.label: i18n("Active indicator thickness:")
        from: 1
        to: 6
    }

    QQC2.ComboBox {
        id: indicatorEdge
        Kirigami.FormData.label: i18n("Active indicator edge:")
        model: [i18n("Screen edge side"), i18n("Inner side")]
        currentIndex: page.cfg_indicatorEdge
        onActivated: page.cfg_indicatorEdge = currentIndex
    }
}
