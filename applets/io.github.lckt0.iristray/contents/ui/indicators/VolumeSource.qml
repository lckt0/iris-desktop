/*
    Iris Tray — volume indicator.

    SinkModel does not expose a "defaultSink" property to QML, so the default
    output is found by checking the `default` flag of each row's PulseObject.
    The role number is discovered once at start-up. The object is a QObject,
    so volume/mute changes arrive through bindings without polling.
*/
import QtQuick
import org.kde.plasma.private.volume as PA

Item {
    id: vol

    readonly property int maxVolume: 65536

    property int pulseRole: -1
    property var sink: null

    readonly property bool muted: sink ? sink.muted === true : true
    readonly property int percent: sink ? Math.round(sink.volume / maxVolume * 100) : 0

    readonly property string iconName: {
        if (!sink || muted || percent === 0) {
            return "audio-volume-muted";
        }
        if (percent <= 33) {
            return "audio-volume-low";
        }
        if (percent <= 66) {
            return "audio-volume-medium";
        }
        return "audio-volume-high";
    }

    readonly property string tooltip: {
        if (!sink) {
            return i18n("No audio device");
        }
        if (muted) {
            return i18n("Muted");
        }
        return i18n("%1%", percent);
    }

    PA.SinkModel {
        id: sinkModel
    }

    // Find the PulseObject role by looking for an object with volume/muted in the first row.
    function findPulseRole(): int {
        if (sinkModel.count <= 0) {
            return -1;
        }
        const idx = sinkModel.index(0, 0);
        for (let r = 256; r < 300; r++) {
            const v = sinkModel.data(idx, r);
            if (v && typeof v === "object"
                && v.volume !== undefined && v.muted !== undefined) {
                return r;
            }
        }
        return -1;
    }

    function refreshSink(): void {
        if (pulseRole < 0) {
            pulseRole = findPulseRole();
        }
        if (pulseRole < 0 || sinkModel.count <= 0) {
            sink = null;
            return;
        }
        let fallback = null;
        for (let i = 0; i < sinkModel.count; i++) {
            const o = sinkModel.data(sinkModel.index(i, 0), pulseRole);
            if (!o) {
                continue;
            }
            if (fallback === null) {
                fallback = o;
            }
            if (o["default"] === true) {
                sink = o;
                return;
            }
        }
        sink = fallback;
    }

    Connections {
        target: sinkModel
        function onCountChanged(): void { vol.refreshSink(); }
        function onDataChanged(): void { vol.refreshSink(); }
        function onModelReset(): void { vol.pulseRole = -1; vol.refreshSink(); }
    }

    Component.onCompleted: refreshSink()

    function toggleMute(): void {
        if (sink) {
            sink.muted = !sink.muted;
        }
    }

    function changeVolume(steps: int): void {
        if (!sink) {
            return;
        }
        const step = Math.round(maxVolume * 0.05);
        let v = sink.volume + steps * step;
        v = Math.max(0, Math.min(maxVolume, v));
        sink.volume = v;
        if (v > 0 && sink.muted) {
            sink.muted = false;
        }
    }
}
