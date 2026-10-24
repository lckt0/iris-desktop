/* Iris Tray — network state. plasma-nm's ConnectionIcon provides the icon name directly. */
import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM

Item {
    id: net

    readonly property string iconName: connectionIcon.connectionIcon || "network-disconnected"
    readonly property string tooltip: networkStatus.activeConnections || networkStatus.networkStatus || ""

    PlasmaNM.ConnectionIcon {
        id: connectionIcon
    }

    PlasmaNM.NetworkStatus {
        id: networkStatus
    }
}
