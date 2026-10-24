/*
    Iris — splash screen. Pitch black with a single thin progress line.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

Rectangle {
    id: root
    color: "#000000"

    property int stage: 0

    // The line grows with each start-up stage. Nothing spins or pulses.
    Rectangle {
        id: track
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.16)
        height: 2
        radius: 1
        color: "#262626"

        Rectangle {
            id: bar
            height: parent.height
            radius: parent.radius
            color: "#ffffff"
            width: parent.width * Math.min(1.0, root.stage / 6.0)

            Behavior on width {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: track.top
        anchors.bottomMargin: 28
        text: "iris"
        color: "#6e6e6e"
        font.pixelSize: 15
        font.letterSpacing: 6
    }
}
