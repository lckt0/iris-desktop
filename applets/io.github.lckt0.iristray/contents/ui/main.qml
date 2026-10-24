/*
    Iris Tray — Windows 11 style indicator cluster
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    Network, volume, Bluetooth, battery and notification indicators in one
    compact cluster. Icon names come from the system; the Iris icon theme
    provides Windows 11 style artwork for them.

    Application tray icons (StatusNotifierItem) stay in Plasma's own system
    tray; hosting that protocol requires a containment.
*/
import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int effectiveLocation: Plasmoid.location

    readonly property bool animate: cfg.animationsEnabled && Kirigami.Units.longDuration > 1
    readonly property int durFast: animate ? 90 : 0
    readonly property int durBase: animate ? 140 : 0

    readonly property color fgColor: Kirigami.Theme.textColor
    readonly property color hoverColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.10)
    readonly property color pressedColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.18)
    readonly property color attentionColor: Kirigami.Theme.neutralTextColor
    readonly property int radius: 2

    readonly property int iconSize: cfg.iconSize
    readonly property int itemSpacing: cfg.itemSpacing

    preferredRepresentation: fullRepresentation

    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.preferredWidth: vertical ? Math.max(iconSize, cluster.implicitWidth) : cluster.implicitWidth
    Layout.preferredHeight: vertical ? cluster.implicitHeight : Math.max(iconSize, root.height)
    Layout.minimumWidth: vertical ? 0 : cluster.implicitWidth
    Layout.minimumHeight: vertical ? cluster.implicitHeight : 0

    // =========================================================== komut yolu
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: sourceName => executable.disconnectSource(sourceName)
    }

    function run(cmd: string): void {
        executable.connectSource(cmd);
    }

    // ============================================================= kaynaklar
    // Each in its own Loader, so one failing does not break the rest.
    Loader {
        id: netLoader
        active: root.cfg.showNetwork
        source: "indicators/NetworkSource.qml"
    }

    Loader {
        id: volLoader
        active: root.cfg.showVolume
        source: "indicators/VolumeSource.qml"
    }

    Loader {
        id: btLoader
        active: root.cfg.showBluetooth
        source: "indicators/BluetoothSource.qml"
    }

    Loader {
        id: batLoader
        active: root.cfg.showBattery
        source: "indicators/BatterySource.qml"
    }

    Loader {
        id: notifLoader
        active: root.cfg.showNotifications
        source: "indicators/NotificationSource.qml"
    }

    // ================================================================ visuals
    Grid {
        id: cluster
        anchors.centerIn: parent
        columns: root.vertical ? 1 : 0
        rows: root.vertical ? 0 : 1
        flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
        spacing: root.itemSpacing

        // --- Network
        TrayButton {
            trayRoot: root
            visible: root.cfg.showNetwork && netLoader.item !== null
            iconName: netLoader.item ? netLoader.item.iconName : ""
            tipMain: i18n("Network")
            tipSub: netLoader.item ? netLoader.item.tooltip : ""
            onActivated: root.run("kcmshell6 kcm_networkmanagement")
            onSecondary: root.run("kcmshell6 kcm_networkmanagement")
        }

        // --- Ses
        TrayButton {
            trayRoot: root
            visible: root.cfg.showVolume && volLoader.item !== null
            iconName: volLoader.item ? volLoader.item.iconName : ""
            tipMain: i18n("Volume")
            tipSub: volLoader.item ? volLoader.item.tooltip : ""
            onActivated: {
                if (volLoader.item) {
                    volLoader.item.toggleMute();
                }
            }
            onSecondary: root.run("kcmshell6 kcm_pulseaudio")
            onScrolled: steps => {
                if (volLoader.item) {
                    volLoader.item.changeVolume(steps);
                }
            }
        }

        // --- Bluetooth
        TrayButton {
            trayRoot: root
            visible: root.cfg.showBluetooth && btLoader.item !== null && btLoader.item.available
            iconName: btLoader.item ? btLoader.item.iconName : ""
            tipMain: i18n("Bluetooth")
            tipSub: btLoader.item ? btLoader.item.tooltip : ""
            onActivated: {
                if (btLoader.item) {
                    btLoader.item.togglePower();
                }
            }
            onSecondary: root.run("kcmshell6 kcm_bluetooth")
        }

        // --- Batarya
        TrayButton {
            trayRoot: root
            visible: root.cfg.showBattery && batLoader.item !== null && batLoader.item.hasBattery
            iconName: batLoader.item ? batLoader.item.iconName : ""
            label: (root.cfg.showBatteryPercent && batLoader.item) ? (batLoader.item.percent + "%") : ""
            tipMain: i18n("Battery")
            tipSub: batLoader.item ? batLoader.item.tooltip : ""
            onActivated: root.run("kcmshell6 powerdevilprofilesconfig")
            onSecondary: root.run("kcmshell6 powerdevilprofilesconfig")
        }

        // --- Notification bell
        TrayButton {
            trayRoot: root
            visible: root.cfg.showNotifications && notifLoader.item !== null
            iconName: notifLoader.item ? notifLoader.item.iconName : ""
            badgeCount: notifLoader.item ? notifLoader.item.unread : 0
            tipMain: i18n("Notifications")
            tipSub: notifLoader.item ? notifLoader.item.tooltip : ""
            onActivated: {
                if (notifLoader.item) {
                    notifLoader.item.toggleDoNotDisturb();
                }
            }
            onSecondary: root.run("kcmshell6 kcm_notifications")
        }
    }
}
