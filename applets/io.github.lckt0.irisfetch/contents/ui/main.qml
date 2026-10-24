/*
    Iris Fetch — fastfetch output drawn natively on the desktop
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    fastfetch's own formatting is used (modules, keys and colours come from
    ~/.config/fastfetch/config.jsonc), but QML does the alignment: a tab
    separates key and value and the key column has one width in a grid, so
    Nerd Font glyph widths or `\e[nG` cursor codes cannot shift the rows.

    The command runs in the login shell (without reading its rc files),
    otherwise fastfetch reports "sh" as the shell. The TERMINAL line is left
    as fastfetch sees it ("plasmashell").
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

    // ------------------------------------------------------------- ortam
    // Once: the login shell.
    readonly property string envCmd: "getent passwd \"$(id -un)\" | cut -d: -f7"
    property bool envReady: false
    property string loginShell: ""

    readonly property string logoCmd: "fastfetch --pipe false --logo-position top "
        + "--logo-padding-top 0 --logo-padding-left 0 --logo-padding-right 0 -s none"

    readonly property string infoCmd: {
        if (!envReady) {
            return "";
        }
        // Tab separator; fastfetch gets a real tab character.
        const ff = `fastfetch --pipe false --logo none --key-width 0 --separator "\t" ${cfg.extraArguments}`;
        const shell = loginShell || "/bin/sh";
        const name = shell.split("/").pop();
        const flags = name === "fish" ? "--no-config"
                    : name === "bash" ? "--norc --noprofile"
                    : name === "zsh" ? "-f"
                    : "";
        return `${shellQuote(shell)} ${flags} -c ${shellQuote(ff)}`;
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    // ------------------------------------------------------------- veri
    property string logoHtml: ""
    // { gap: true } ya da { key: html, value: html }
    property var rows: []

    // ------------------------------------------------------ ANSI → HTML
    // 16 colours tuned for a dark background (what fastfetch uses, plus
    // bold). 256-colour and 24-bit codes are handled too.
    readonly property var ansiPalette: [
        "#3a3a3a", "#e06c75", "#98c379", "#e5c07b", "#61afef", "#c678dd", "#56b6c2", "#dcdfe4",
        "#6b6b6b", "#ff7b86", "#b5e890", "#f0d58a", "#82c4ff", "#d99af0", "#7fd3dd", "#ffffff"
    ]

    function color256(n) {
        if (n < 16) {
            return ansiPalette[n];
        }
        if (n >= 232) {
            const v = 8 + (n - 232) * 10;
            return Qt.rgba(v / 255, v / 255, v / 255, 1).toString();
        }
        const i = n - 16;
        const c = [Math.floor(i / 36), Math.floor(i / 6) % 6, i % 6].map(x => x ? (55 + x * 40) / 255 : 0);
        return Qt.rgba(c[0], c[1], c[2], 1).toString();
    }

    function escapeHtml(s, keepSpaces) {
        let out = s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        return keepSpaces ? out.replace(/ /g, "&nbsp;") : out;
    }

    // Escape sequences other than SGR (cursor movement etc.) are dropped.
    function ansiToHtml(line, keepSpaces) {
        const re = /\x1b\[([0-9;?]*)([A-Za-z])/g;
        let html = "", fg = "", bold = false, last = 0, m;
        const emit = text => {
            if (!text) {
                return;
            }
            let t = escapeHtml(text, keepSpaces);
            if (bold) {
                t = `<b>${t}</b>`;
            }
            if (fg) {
                t = `<span style="color:${fg}">${t}</span>`;
            }
            html += t;
        };
        while ((m = re.exec(line)) !== null) {
            emit(line.slice(last, m.index));
            last = re.lastIndex;
            if (m[2] !== "m") {
                continue;
            }
            const codes = m[1] === "" ? [0] : m[1].split(";").map(Number);
            for (let i = 0; i < codes.length; i++) {
                const c = codes[i];
                if (c === 0) { fg = ""; bold = false; }
                else if (c === 1) { bold = true; }
                else if (c === 22) { bold = false; }
                else if (c === 39) { fg = ""; }
                else if (c >= 30 && c <= 37) { fg = ansiPalette[c - 30]; }
                else if (c >= 90 && c <= 97) { fg = ansiPalette[c - 90 + 8]; }
                else if (c === 38 && codes[i + 1] === 5) { fg = color256(codes[i + 2]); i += 2; }
                else if (c === 38 && codes[i + 1] === 2) {
                    fg = Qt.rgba(codes[i + 2] / 255, codes[i + 3] / 255, codes[i + 4] / 255, 1).toString();
                    i += 4;
                }
            }
        }
        emit(line.slice(last));
        return html;
    }

    function stripAnsi(s) {
        return s.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "");
    }

    function parseInfo(out) {
        const list = [];
        for (const raw of out.split("\n")) {
            const tab = raw.indexOf("\t");
            if (tab < 0) {
                // Empty line (break) or a custom module that only prints colour codes.
                if (stripAnsi(raw).trim() === "" && list.length > 0 && !list[list.length - 1].gap) {
                    list.push({ gap: true });
                }
                continue;
            }
            list.push({
                key: ansiToHtml(raw.slice(0, tab).replace(/\s+(\x1b\[[0-9;]*m)*$/, "$1"), true),
                value: ansiToHtml(raw.slice(tab + 1), false)
            });
        }
        while (list.length > 0 && list[list.length - 1].gap) {
            list.pop();
        }
        rows = list;
    }

    function parseLogo(out) {
        const lines = out.replace(/\s+$/, "").split("\n");
        logoHtml = lines.map(l => ansiToHtml(l, true)).join("<br>");
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = data["stdout"] || "";
            if (source === root.envCmd) {
                root.loginShell = out.trim();
                root.envReady = true;
            } else if (source === root.logoCmd) {
                root.parseLogo(out);
            } else if (source === root.infoCmd) {
                root.parseInfo(out);
            }
            exec.disconnectSource(source);
        }
    }

    function refresh() {
        if (infoCmd) {
            exec.connectSource(infoCmd);
        }
    }

    onInfoCmdChanged: refresh()

    Timer {
        interval: root.cfg.refreshSeconds * 1000
        running: root.envReady
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        exec.connectSource(envCmd);
        exec.connectSource(logoCmd);
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        }
    ]

    // ---------------------------------------------------------------- visuals
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Layout.preferredWidth: content.implicitWidth
    Layout.preferredHeight: content.implicitHeight
    Layout.minimumWidth: content.implicitWidth
    Layout.minimumHeight: content.implicitHeight

    readonly property string monoFamily: Kirigami.Theme.fixedWidthFont.family

    FontMetrics {
        id: metrics
        font.family: root.monoFamily
        font.pixelSize: root.cfg.fontPixelSize
    }

    Row {
        id: content

        spacing: metrics.averageCharacterWidth * 4

        Text {
            id: logo

            visible: root.cfg.showLogo && root.logoHtml !== ""
            text: root.logoHtml
            textFormat: Text.RichText
            color: Kirigami.Theme.textColor
            font.family: root.monoFamily
            font.pixelSize: root.cfg.fontPixelSize
            lineHeightMode: Text.FixedHeight
            lineHeight: metrics.height
            renderType: Text.NativeRendering
        }

        GridLayout {
            id: grid

            columns: 2
            columnSpacing: metrics.averageCharacterWidth * 2
            rowSpacing: 0

            Repeater {
                model: root.rows

                delegate: Text {
                    required property var modelData
                    required property int index

                    // Blank lines keep their height.
                    text: modelData.gap ? "" : modelData.key
                    textFormat: Text.RichText
                    color: Kirigami.Theme.textColor
                    font.family: root.monoFamily
                    font.pixelSize: root.cfg.fontPixelSize
                    renderType: Text.NativeRendering
                    Layout.row: index
                    Layout.column: 0
                }
            }

            Repeater {
                model: root.rows

                delegate: Text {
                    required property var modelData
                    required property int index

                    text: modelData.gap ? "" : modelData.value
                    textFormat: Text.RichText
                    color: Kirigami.Theme.textColor
                    font.family: root.monoFamily
                    font.pixelSize: root.cfg.fontPixelSize
                    renderType: Text.NativeRendering
                    Layout.row: index
                    Layout.column: 1
                }
            }
        }
    }
}
