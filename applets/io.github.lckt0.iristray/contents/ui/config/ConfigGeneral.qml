import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_iconSize: iconSize.value
    property alias cfg_itemSpacing: itemSpacing.value
    property alias cfg_showNetwork: showNetwork.checked
    property alias cfg_showVolume: showVolume.checked
    property alias cfg_showBluetooth: showBluetooth.checked
    property alias cfg_showBattery: showBattery.checked
    property alias cfg_showBatteryPercent: showBatteryPercent.checked
    property alias cfg_showNotifications: showNotifications.checked
    property alias cfg_animationsEnabled: animations.checked

    QQC2.SpinBox {
        id: iconSize
        Kirigami.FormData.label: i18n("Icon size:")
        from: 8
        to: 48
    }

    QQC2.SpinBox {
        id: itemSpacing
        Kirigami.FormData.label: i18n("Spacing:")
        from: 0
        to: 24
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: showNetwork
        Kirigami.FormData.label: i18n("Show:")
        text: i18n("Network")
    }

    QQC2.CheckBox {
        id: showVolume
        text: i18n("Volume")
    }

    QQC2.CheckBox {
        id: showBluetooth
        text: i18n("Bluetooth")
    }

    QQC2.CheckBox {
        id: showBattery
        text: i18n("Battery")
    }

    QQC2.CheckBox {
        id: showBatteryPercent
        text: i18n("Battery percentage as text")
        enabled: showBattery.checked
        leftPadding: Kirigami.Units.gridUnit
    }

    QQC2.CheckBox {
        id: showNotifications
        text: i18n("Notification bell")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: animations
        Kirigami.FormData.label: i18n("Motion:")
        text: i18n("Enable animations")
    }

    QQC2.Label {
        Kirigami.FormData.label: i18n("Actions:")
        text: i18n("Click volume to mute, Bluetooth to toggle power, and the bell to toggle do-not-disturb. Scroll over volume to change it. Right-click any indicator to open its settings.")
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        opacity: 0.7
    }
}
