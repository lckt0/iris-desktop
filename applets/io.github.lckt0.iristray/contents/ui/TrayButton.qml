/*
    Iris Tray — a single indicator button
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: button

    property var trayRoot: null
    property string iconName: ""
    property string label: ""
    property string tipMain: ""
    property string tipSub: ""
    property int badgeCount: 0

    signal activated
    signal secondary
    signal scrolled(int steps)

    readonly property int box: trayRoot ? trayRoot.iconSize : 16

    implicitWidth: box + (labelText.visible ? labelText.implicitWidth + 4 : 0)
    implicitHeight: box
    width: implicitWidth
    height: implicitHeight

    // ---------------------------------------------------------------- zemin
    Rectangle {
        anchors.centerIn: parent
        width: button.width + 8
        height: button.box + 8
        radius: button.trayRoot ? button.trayRoot.radius : 2
        color: {
            if (!button.trayRoot) {
                return "transparent";
            }
            if (mouse.pressed) {
                return button.trayRoot.pressedColor;
            }
            if (mouse.containsMouse) {
                return button.trayRoot.hoverColor;
            }
            return "transparent";
        }

        Behavior on color {
            enabled: button.trayRoot ? button.trayRoot.animate : false
            ColorAnimation { duration: button.trayRoot ? button.trayRoot.durFast : 0 }
        }
    }

    // ----------------------------------------------------------------- ikon
    Kirigami.Icon {
        id: glyph
        source: button.iconName
        width: button.box
        height: button.box
        x: 0
        y: Math.round((button.height - height) / 2)
        active: mouse.containsMouse
        smooth: true

        // Cross-fade when the icon changes (volume/signal level).
        Behavior on opacity {
            enabled: button.trayRoot ? button.trayRoot.animate : false
            NumberAnimation { duration: button.trayRoot ? button.trayRoot.durFast : 0 }
        }
    }

    // -------------------------------------------------------------- rozet
    Rectangle {
        visible: button.badgeCount > 0
        width: Math.max(7, badgeText.implicitWidth + 4)
        height: 7
        radius: 2
        color: button.trayRoot ? button.trayRoot.attentionColor : "orange"
        x: glyph.x + glyph.width - width + 2
        y: glyph.y - 1

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: button.badgeCount > 9 ? "9+" : button.badgeCount
            color: "#000000"
            font.pixelSize: 6
            font.bold: true
        }
    }

    // ---------------------------------------------------------------- etiket
    Text {
        id: labelText
        visible: button.label.length > 0
        text: button.label
        color: button.trayRoot ? button.trayRoot.fgColor : "white"
        font: Kirigami.Theme.smallFont
        x: glyph.x + glyph.width + 4
        y: Math.round((button.height - implicitHeight) / 2)
    }

    // ---------------------------------------------------------------- ipucu
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        location: button.trayRoot ? button.trayRoot.effectiveLocation : PlasmaCore.Types.Floating
        mainText: button.tipMain
        subText: button.tipSub
        interactive: false
    }

    // ---------------------------------------------------------- interaction
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property int accum: 0

        onClicked: ev => {
            if (ev.button === Qt.LeftButton) {
                button.activated();
            } else {
                button.secondary();
            }
        }

        onWheel: wheel => {
            accum += wheel.angleDelta.y;
            let steps = 0;
            while (accum >= 120) {
                accum -= 120;
                steps += 1;
            }
            while (accum <= -120) {
                accum += 120;
                steps -= 1;
            }
            if (steps !== 0) {
                button.scrolled(steps);
            }
        }
    }
}
