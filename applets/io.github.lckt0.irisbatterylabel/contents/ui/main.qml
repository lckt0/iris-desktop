/*
    Iris Battery Percent — plain text next to the battery icon
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    The stock battery applet draws the percentage inside the icon; this
    applet shows it next to the icon as a separate number. The stock applet
    stays as it is (brightness and power profiles live in its popup).

    Colour only where it means something: `pos` while charging, `neu` when
    low, `neg` when critical. Otherwise the normal text colour.
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

    // ------------------------------------------------------------- kaynak
    readonly property var batData: pmSource.data["Battery"]
    readonly property bool hasBattery: batData ? (batData["Has Battery"] === true) : false
    readonly property int percent: batData ? (batData["Percent"] || 0) : 0
    readonly property string state: batData ? String(batData["State"] || "") : ""
    readonly property bool charging: state === "Charging"
    readonly property bool full: state === "FullyCharged" || (charging && percent >= 100)

    // The smoothed estimate jumps less; fall back to the raw value.
    readonly property int remainingMsec: {
        if (!batData) {
            return 0;
        }
        return batData["Smoothed Remaining msec"] || batData["Remaining msec"] || 0;
    }

    // ---------------------------------------------------------------- visuals
    readonly property bool critical: !charging && percent <= cfg.criticalThreshold
    readonly property bool low: !charging && !critical && percent <= cfg.lowThreshold

    readonly property color textColor: {
        if (!cfg.colorizeStates) {
            return Kirigami.Theme.textColor;
        }
        if (critical) {
            return Kirigami.Theme.negativeTextColor;
        }
        if (low) {
            return Kirigami.Theme.neutralTextColor;
        }
        if (charging) {
            return Kirigami.Theme.positiveTextColor;
        }
        return Kirigami.Theme.textColor;
    }

    readonly property string displayText: {
        if (!hasBattery) {
            return "";
        }
        return percent + (cfg.showPercentSign ? "%" : "");
    }

    // Take no space in the panel when there is no battery.
    Plasmoid.status: hasBattery ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

    preferredRepresentation: fullRepresentation

    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.preferredWidth: hasBattery ? label.implicitWidth : 0
    Layout.preferredHeight: hasBattery ? label.implicitHeight : 0
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: sourceName => executable.disconnectSource(sourceName)
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: root.displayText
        color: root.textColor
        // Assigning the whole font group and font.bold is an error; bind fields one by one.
        font.family: Kirigami.Theme.defaultFont.family
        font.pointSize: Kirigami.Theme.defaultFont.pointSize
        font.bold: root.cfg.fontBold
        renderType: Text.NativeRendering

        Behavior on color {
            enabled: Kirigami.Units.longDuration > 1
            ColorAnimation { duration: 140 }
        }
    }

    // --------------------------------------------------------------- ipucu
    toolTipMainText: {
        if (!hasBattery) {
            return i18n("No battery");
        }
        if (full) {
            return i18n("Fully charged");
        }
        return charging ? i18n("Charging — %1%", percent) : i18n("On battery — %1%", percent);
    }

    toolTipSubText: {
        if (!hasBattery || full || remainingMsec <= 0) {
            return "";
        }
        const totalMinutes = Math.round(remainingMsec / 60000);
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        const span = hours > 0 ? i18n("%1 h %2 min", hours, minutes) : i18n("%1 min", minutes);
        return charging ? i18n("%1 until full", span) : i18n("%1 remaining", span);
    }

    // ---------------------------------------------------------- interaction
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: executable.connectSource("kcmshell6 kcm_powerdevilprofilesconfig")
    }
}
