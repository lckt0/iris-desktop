/* Iris Tray — battery. The powermanagement data engine is event driven. */
import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: bat

    readonly property var batData: pmSource.data["Battery"]
    readonly property bool hasBattery: batData ? (batData["Has Battery"] === true) : false
    readonly property int percent: batData ? (batData["Percent"] || 0) : 0
    readonly property string state: batData ? String(batData["State"] || "") : ""
    readonly property bool charging: state === "Charging" || state === "FullyCharged"
    readonly property bool full: percent >= 100 && charging

    readonly property string iconName: {
        if (!hasBattery) {
            return "battery-missing";
        }
        const step = Math.max(0, Math.min(100, Math.round(percent / 10) * 10));
        const pad = ("00" + step).slice(-3);
        if (full) {
            return "battery-full-charged";
        }
        return charging ? ("battery-" + pad + "-charging") : ("battery-" + pad);
    }

    readonly property string tooltip: {
        if (!hasBattery) {
            return i18n("No battery");
        }
        if (full) {
            return i18n("Fully charged");
        }
        return charging ? i18n("%1% — charging", percent) : i18n("%1%", percent);
    }

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }
}
