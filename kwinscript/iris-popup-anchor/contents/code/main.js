/*
    Iris Popup Anchor — opens panel applet popups pinned to the top-right
    corner of the screen.

    A script rather than a window rule: Plasma writes the popup position
    through the plasma-shell protocol after mapping, which overrides rules.
    The script re-applies the position whenever the geometry changes.

    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

// NET::AppletPopup — the popup window opened by a panel applet
var APPLET_POPUP = 18;

// Only the position is pinned; forcing the size desynchronises Plasma's
// frame from the window.
var MARGIN = 0;     // flush with the right edge
var TOP_GAP = 0;    // directly below the panel

// Stop if Plasma keeps writing its own position back.
var MAX_APPLY = 24;

function targetRect(win) {
    var area;
    try {
        area = workspace.clientArea(KWin.PlacementArea, win);
    } catch (e) {
        area = null;
    }
    if (!area || !area.width) {
        area = { x: 0, y: 0, width: workspace.workspaceWidth, height: workspace.workspaceHeight };
    }
    var g0 = win.frameGeometry;
    return {
        x: area.x + area.width - g0.width - MARGIN,
        y: area.y + TOP_GAP,
        width: g0.width,
        height: g0.height
    };
}

function isTarget(win) {
    if (!win || win.windowType !== APPLET_POPUP) {
        return false;
    }
    return String(win.resourceClass || "").indexOf("plasmashell") !== -1;
}

function anchor(win, state) {
    if (!isTarget(win)) {
        return;
    }
    var t = targetRect(win);
    var g = win.frameGeometry;
    if (g.x === t.x && g.y === t.y && g.width === t.width && g.height === t.height) {
        return;
    }
    if (state.applied >= MAX_APPLY) {
        return;
    }
    state.applied += 1;
    win.frameGeometry = t;
}

workspace.windowAdded.connect(function (win) {
    if (!isTarget(win)) {
        return;
    }
    var state = { applied: 0 };
    anchor(win, state);
    // Plasma also sets the position after mapping; re-apply on every change.
    win.frameGeometryChanged.connect(function () {
        anchor(win, state);
    });
});

// Also place popups that are already open when the script loads.
var existing = (typeof workspace.windowList === "function")
    ? workspace.windowList() : workspace.clientList();
for (var i = 0; i < existing.length; i++) {
    anchor(existing[i], { applied: 0 });
}
