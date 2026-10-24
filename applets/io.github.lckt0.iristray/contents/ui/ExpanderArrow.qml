/*
    Iris Tray — overflow arrow
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: arrow

    readonly property var trayRoot: Plasmoid.rootItem

    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 6
        height: parent.height + 6
        radius: 2
        color: {
            if (mouse.pressed) {
                return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.18);
            }
            if (mouse.containsMouse) {
                return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.10);
            }
            return "transparent";
        }
        Behavior on color {
            ColorAnimation { duration: 90 }
        }
    }

    // Simple chevron: points away from the panel edge and rotates when open.
    Canvas {
        id: chevron
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.62)
        height: Math.round(parent.height * 0.62)

        readonly property color strokeColor: Kirigami.Theme.textColor
        property real rot: Plasmoid.expanded ? 180 : 0

        rotation: {
            switch (Plasmoid.location) {
            case PlasmaCore.Types.TopEdge:    return 180 + rot;
            case PlasmaCore.Types.LeftEdge:   return 90 + rot;
            case PlasmaCore.Types.RightEdge:  return 270 + rot;
            default:                          return 0 + rot;
            }
        }

        Behavior on rot {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        onStrokeColorChanged: requestPaint()
        onWidthChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width;
            const h = height;
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = Math.max(1.2, w * 0.13);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(w * 0.22, h * 0.38);
            ctx.lineTo(w * 0.5, h * 0.66);
            ctx.lineTo(w * 0.78, h * 0.38);
            ctx.stroke();
        }
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        location: Plasmoid.location
        mainText: i18n("Hidden icons")
        interactive: false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Plasmoid.expanded = !Plasmoid.expanded
    }
}
