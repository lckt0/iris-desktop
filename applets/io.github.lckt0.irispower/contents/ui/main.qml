/*
    Iris Power — battery power draw averaged over the last minute
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    The instantaneous value jumps around, so the panel shows a time-weighted
    average over the last `windowSeconds`. Charging and discharging are kept
    apart: the window resets when the state changes.

    Each sample is a single `cat`. `power_now` is used if the battery provides
    it, otherwise current_now × voltage_now.
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

    // ------------------------------------------------------------- kaynak
    property string batteryPath: ""
    property bool hasPowerNow: false
    readonly property string detectCmd: "for d in /sys/class/power_supply/*; do "
        + "[ \"$(cat $d/type 2>/dev/null)\" = Battery ] || continue; "
        + "[ \"$(cat $d/scope 2>/dev/null)\" = Device ] && continue; "
        + "if [ -r $d/power_now ]; then echo \"$d 1\"; else echo \"$d 0\"; fi; break; done"
    readonly property string readCmd: !batteryPath ? ""
        : hasPowerNow ? `cat ${batteryPath}/status ${batteryPath}/power_now`
                      : `cat ${batteryPath}/status ${batteryPath}/current_now ${batteryPath}/voltage_now`

    // ------------------------------------------------------------- durum
    // Samples: { t: ms, w: watts }. Mode: "dis" (on battery) or "ac".
    property var samples: []
    property string regime: ""
    property string status: ""
    property real instant: NaN
    property real average: NaN
    property real minW: NaN
    property real maxW: NaN
    property real spanMs: 0
    property bool missing: false

    readonly property bool onBattery: regime === "dis"
    readonly property bool idleOnAc: regime === "ac" && !isNaN(average) && average < 0.1
    readonly property bool warmingUp: spanMs < cfg.windowSeconds * 1000 - cfg.sampleIntervalMs

    function fmt(w) {
        return w.toLocaleString(Qt.locale(), 'f', 1);
    }

    readonly property string displayText: {
        if (missing) {
            return "—";
        }
        if (isNaN(average)) {
            return "…";
        }
        if (idleOnAc) {
            return "⚡";
        }
        return onBattery ? "-" + fmt(average) + "W" : fmt(average) + "W⚡";
    }

    readonly property color textColor: onBattery && average >= cfg.wattageThreshold
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.textColor

    function addSample(stat, watts) {
        const now = Date.now();
        const reg = stat === "Discharging" ? "dis" : "ac";
        let list = reg === regime ? samples.slice() : [];
        regime = reg;
        status = stat;
        instant = watts;

        list.push({ t: now, w: watts });
        const cutoff = now - cfg.windowSeconds * 1000;
        // Clamp the first sample to the window start; its weight is trimmed.
        while (list.length > 1 && list[1].t <= cutoff) {
            list.shift();
        }
        samples = list;

        // Time-weighted average: each sample holds until the next one.
        // The last sample is weighted by one sampling interval.
        let sum = 0, span = 0, lo = Infinity, hi = -Infinity;
        for (let i = 0; i < list.length; i++) {
            const start = Math.max(list[i].t, cutoff);
            const end = i + 1 < list.length ? list[i + 1].t : now + cfg.sampleIntervalMs;
            const dt = Math.max(end - start, 0);
            sum += list[i].w * dt;
            span += dt;
            lo = Math.min(lo, list[i].w);
            hi = Math.max(hi, list[i].w);
        }
        average = span > 0 ? sum / span : watts;
        minW = lo;
        maxW = hi;
        spanMs = list.length > 1 ? now - Math.max(list[0].t, cutoff) : 0;
    }

    function parseReading(out) {
        const lines = out.trim().split("\n");
        const stat = lines[0] ? lines[0].trim() : "";
        let watts = NaN;
        if (hasPowerNow && lines.length >= 2) {
            watts = Math.abs(parseFloat(lines[1])) / 1e6;
        } else if (lines.length >= 3) {
            watts = Math.abs(parseFloat(lines[1]) * parseFloat(lines[2])) / 1e12;
        }
        if (!stat || isNaN(watts)) {
            return;
        }
        addSample(stat, watts);
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = data["stdout"] || "";
            if (source === root.detectCmd) {
                const parts = out.trim().split(" ");
                if (parts.length === 2) {
                    root.batteryPath = parts[0];
                    root.hasPowerNow = parts[1] === "1";
                    root.missing = false;
                } else {
                    root.missing = true;
                }
            } else if (data["exit code"] === 0) {
                root.parseReading(out);
            }
            // Disconnect each time so the same command can run again.
            exec.disconnectSource(source);
        }
    }

    Timer {
        interval: root.cfg.sampleIntervalMs
        running: root.readCmd !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: exec.connectSource(root.readCmd)
    }

    Component.onCompleted: exec.connectSource(detectCmd)

    Plasmoid.status: missing ? PlasmaCore.Types.HiddenStatus : PlasmaCore.Types.ActiveStatus

    // ---------------------------------------------------------------- visuals
    preferredRepresentation: fullRepresentation

    // Fixed width for the widest possible text so the panel does not shift.
    TextMetrics {
        id: widest
        font: label.font
        text: "-88.8W⚡"
    }

    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.preferredWidth: Math.ceil(widest.advanceWidth)
    Layout.minimumWidth: Layout.preferredWidth
    Layout.preferredHeight: label.implicitHeight

    Text {
        id: label

        anchors.centerIn: parent
        text: root.displayText
        color: root.textColor
        // Assigning the whole font group conflicts with font.bold; set fields one by one.
        font.family: Kirigami.Theme.defaultFont.family
        font.pointSize: Kirigami.Theme.defaultFont.pointSize
        font.bold: root.cfg.fontBold
        font.features: { "tnum": 1 }
        renderType: Text.NativeRendering

        Behavior on color {
            enabled: Kirigami.Units.longDuration > 1
            ColorAnimation { duration: 140 }
        }
    }

    // --------------------------------------------------------------- ipucu
    toolTipMainText: {
        if (missing) {
            return i18n("No battery");
        }
        if (isNaN(average)) {
            return i18n("Measuring…");
        }
        const secs = Math.round(Math.min(spanMs, cfg.windowSeconds * 1000) / 1000);
        const label = onBattery ? i18n("Draw") : i18n("Charging");
        return warmingUp
            ? i18n("%1: %2 W (average of %3 s so far)", label, fmt(average), secs)
            : i18n("%1: %2 W (average of %3 s)", label, fmt(average), cfg.windowSeconds);
    }

    toolTipSubText: {
        if (missing || isNaN(average)) {
            return "";
        }
        return i18n("Now %1 W · min %2 W · max %3 W\n%4 samples · battery: %5",
                    fmt(instant), fmt(minW), fmt(maxW), samples.length, status);
    }
}
