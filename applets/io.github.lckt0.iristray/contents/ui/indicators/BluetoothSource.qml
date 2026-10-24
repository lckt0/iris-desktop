/* Iris Tray — Bluetooth. BluezQt.Manager works on its own. */
import QtQuick
import org.kde.bluezqt as BluezQt

Item {
    id: bt

    readonly property var manager: BluezQt.Manager
    readonly property bool available: manager && manager.rfkill
        ? manager.rfkill.state !== BluezQt.Rfkill.Unknown
        : (manager ? manager.adapters.length > 0 : false)
    readonly property bool powered: manager && manager.usableAdapter ? manager.usableAdapter.powered : false
    readonly property int connectedCount: {
        if (!manager) {
            return 0;
        }
        let n = 0;
        for (let i = 0; i < manager.devices.length; i++) {
            if (manager.devices[i].connected) {
                n++;
            }
        }
        return n;
    }

    readonly property string iconName: {
        if (!available) {
            return "bluetooth-disabled";
        }
        if (!powered) {
            return "preferences-system-bluetooth-inactive";
        }
        return connectedCount > 0
            ? "preferences-system-bluetooth-activated"
            : "preferences-system-bluetooth";
    }

    readonly property string tooltip: {
        if (!available) {
            return i18n("No Bluetooth adapter");
        }
        if (!powered) {
            return i18n("Bluetooth off");
        }
        return connectedCount > 0
            ? i18np("%1 device connected", "%1 devices connected", connectedCount)
            : i18n("Bluetooth on");
    }

    function togglePower(): void {
        const a = manager ? manager.usableAdapter : null;
        if (a) {
            a.powered = !a.powered;
        }
    }
}
