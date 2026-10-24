/*
    Iris Tray — a single tray item
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: item

    required property var model
    property var trayRoot: null
    property bool inPopup: false

    readonly property string itemId: String(model.Id || "")
    readonly property string itemTitle: String(model.Title || model.ToolTipTitle || itemId)
    readonly property int status: model.effectiveStatus
    readonly property bool needsAttention: status === PlasmaCore.Types.NeedsAttentionStatus
    readonly property string sniSource: String(model.DataEngineSource || "")

    readonly property bool hidden: trayRoot
        ? trayRoot.isHidden(itemId, status)
        : false

    // Visible items in the panel, hidden ones in the overflow area.
    visible: inPopup ? hidden : !hidden

    readonly property int box: trayRoot
        ? (inPopup ? Math.round(trayRoot.iconSize * 1.6) : trayRoot.iconSize)
        : 16

    width: visible ? box : 0
    height: visible ? box : 0

    opacity: visible ? 1 : 0
    Behavior on opacity {
        enabled: trayRoot ? trayRoot.animate : false
        NumberAnimation { duration: trayRoot ? trayRoot.durBase : 0 }
    }

    // ---------------------------------------------------------------- zemin
    Rectangle {
        anchors.centerIn: parent
        width: item.box + (item.inPopup ? 10 : 6)
        height: width
        radius: item.trayRoot ? item.trayRoot.radius : 2
        color: {
            if (!item.trayRoot) {
                return "transparent";
            }
            if (mouse.pressed) {
                return item.trayRoot.pressedColor;
            }
            if (mouse.containsMouse) {
                return item.trayRoot.hoverColor;
            }
            return "transparent";
        }

        Behavior on color {
            enabled: item.trayRoot ? item.trayRoot.animate : false
            ColorAnimation { duration: item.trayRoot ? item.trayRoot.durFast : 0 }
        }
    }

    // ----------------------------------------------------------------- ikon
    Kirigami.Icon {
        id: trayIcon
        anchors.centerIn: parent
        width: item.box
        height: item.box
        source: {
            if (item.needsAttention) {
                const a = item.model.AttentionIconName;
                if (a && String(a).length > 0) {
                    return a;
                }
                if (item.model.AttentionIcon) {
                    return item.model.AttentionIcon;
                }
            }
            const n = item.model.IconName;
            if (n && String(n).length > 0) {
                return n;
            }
            return item.model.Icon || "";
        }
        active: mouse.containsMouse
        smooth: true

        // Items demanding attention slowly fade out and back.
        SequentialAnimation on opacity {
            running: item.needsAttention && (item.trayRoot ? item.trayRoot.animate : false)
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 750; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutSine }
        }
    }

    // Overlay badge (e.g. sync state)
    Kirigami.Icon {
        visible: String(item.model.OverlayIconName || "").length > 0
        source: item.model.OverlayIconName || ""
        width: Math.round(item.box * 0.6)
        height: width
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        smooth: true
    }

    // ---------------------------------------------------------------- ipucu
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        location: item.trayRoot ? item.trayRoot.effectiveLocation : PlasmaCore.Types.Floating
        mainText: String(item.model.ToolTipTitle || item.itemTitle)
        subText: String(item.model.ToolTipSubTitle || "")
        interactive: false
    }

    // --------------------------------------------------------- interaction
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        property int wheelAccum: 0

        function globalPoint(): point {
            return item.mapToGlobal(item.width / 2, item.height / 2);
        }

        onClicked: ev => {
            if (!item.trayRoot || item.sniSource === "") {
                return;
            }
            const g = globalPoint();
            const gx = Math.round(g.x);
            const gy = Math.round(g.y);

            // Ctrl+left click: move the item to the overflow area and back
            if (ev.button === Qt.LeftButton && (ev.modifiers & Qt.ControlModifier)) {
                item.trayRoot.setHidden(item.itemId, !item.hidden);
                return;
            }

            if (ev.button === Qt.LeftButton) {
                // For items that behave as a menu, left click opens the menu too.
                if (item.model.ItemIsMenu === true) {
                    item.trayRoot.callItem(item.sniSource, "ContextMenu", gx, gy);
                } else {
                    item.trayRoot.callItem(item.sniSource, "Activate", gx, gy);
                }
            } else if (ev.button === Qt.MiddleButton) {
                item.trayRoot.callItem(item.sniSource, "SecondaryActivate", gx, gy);
            } else if (ev.button === Qt.RightButton) {
                item.trayRoot.callItem(item.sniSource, "ContextMenu", gx, gy);
            }
        }

        onWheel: wheel => {
            if (!item.trayRoot || item.sniSource === "") {
                return;
            }
            const dy = wheel.angleDelta.y;
            const dx = wheel.angleDelta.x;
            if (dy !== 0) {
                wheelAccum += dy;
                while (wheelAccum >= 120) {
                    wheelAccum -= 120;
                    item.trayRoot.scrollItem(item.sniSource, 1, "vertical");
                }
                while (wheelAccum <= -120) {
                    wheelAccum += 120;
                    item.trayRoot.scrollItem(item.sniSource, -1, "vertical");
                }
            } else if (dx !== 0) {
                item.trayRoot.scrollItem(item.sniSource, dx > 0 ? 1 : -1, "horizontal");
            }
        }
    }
}
