/*
    SPDX-FileCopyrightText: 2011 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2011 Viranch Mehta <viranch.mehta@gmail.com>
    SPDX-FileCopyrightText: 2013 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2023 Natalie Clarius <natalie.clarius@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.components as WorkspaceComponents
import org.kde.kirigami as Kirigami

import org.kde.plasma.private.battery

MouseArea {
    id: root

    readonly property bool isConstrained: [PlasmaCore.Types.Vertical, PlasmaCore.Types.Horizontal].includes(Plasmoid.formFactor)
        || Plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentForcesSquarePlasmoids
    property int batteryPercent: 0
    property bool batteryPluggedIn: false
    property bool hasBatteries: false
    property bool hasInternalBatteries: false
    property bool hasCumulative: false

    required property bool isSomehowFullyCharged
    required property bool isDischarging
    required property bool isCharging

    // Iris: the percentage is drawn next to the icon instead of inside it.
    // Only in horizontal panels; vertical panels and the desktop behave as stock.
    readonly property bool showSideLabel: Plasmoid.configuration.showPercentage
        && Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        && overallBatteryInfo.visible
    readonly property int lowThreshold: 20
    readonly property int criticalThreshold: 10

    Layout.minimumWidth: showSideLabel ? height + Kirigami.Units.smallSpacing + sideLabel.implicitWidth : -1
    Layout.preferredWidth: Layout.minimumWidth

    required property bool isManuallyInhibited
    required property bool isInDefaultPowerProfile
    required property bool isInPowersaveProfile
    required property bool isInBalancedProfile
    required property bool isInPerformanceProfile

    property alias model: view.model

    activeFocusOnTab: true
    hoverEnabled: true

    Accessible.name: Plasmoid.title
    Accessible.description: `${toolTipMainText}; ${toolTipSubText}`
    Accessible.role: Accessible.Button

    property string activeProfileIconSrc: isInPowersaveProfile   ? "battery-profile-powersave-symbolic"
                                        : isInBalancedProfile    ? "speedometer"
                                        : isInPerformanceProfile ? "battery-profile-performance-symbolic"
                                        : Plasmoid.icon

    readonly property string powerModeIconSrc: isManuallyInhibited
            ? "system-suspend-inhibited-symbolic"
            : !isInDefaultPowerProfile
            ? activeProfileIconSrc
            : Plasmoid.icon

    // Shown for no batteries or manual inhibition while not discharging
    Kirigami.Icon {
        id: powerModeIcon

        anchors.fill: parent

        visible: root.isConstrained && (!root.hasInternalBatteries || (root.isManuallyInhibited && !root.isDischarging))
        source: root.powerModeIconSrc
        active: root.containsMouse
    }

    Item {
        id: overallBatteryInfo

        anchors.fill: parent

        visible: root.isConstrained && !powerModeIcon.visible && root.hasInternalBatteries

        // Show normal battery icon
        WorkspaceComponents.BatteryIcon {
            id: overallBatteryIcon

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.showSideLabel ? height : parent.width

            active: root.containsMouse
            hasBattery: root.hasCumulative
            percent: root.batteryPercent
            isSomehowFullyCharged: root.isSomehowFullyCharged
            pluggedIn: root.batteryPluggedIn
            preferSymbolic: true
            powerProfileIconName: root.isInDefaultPowerProfile ? ""
                                : root.isInPowersaveProfile    ? "powersave"
                                : root.isInBalancedProfile     ? "balanced"
                                : root.isInPerformanceProfile  ? "performance"
                                : ""
        }

        Text {
            id: sideLabel

            anchors.left: overallBatteryIcon.right
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.verticalCenter: parent.verticalCenter

            visible: root.showSideLabel
            text: i18ndc("plasma_applet_org.kde.plasma.battery", "battery percentage below battery icon", "%1%", root.batteryPercent)
            color: root.isCharging ? Kirigami.Theme.positiveTextColor
                 : !root.isDischarging ? Kirigami.Theme.textColor
                 : root.batteryPercent <= root.criticalThreshold ? Kirigami.Theme.negativeTextColor
                 : root.batteryPercent <= root.lowThreshold ? Kirigami.Theme.neutralTextColor
                 : Kirigami.Theme.textColor
            // Assigning the whole font group conflicts with font.bold; set fields one by one.
            font.family: Kirigami.Theme.defaultFont.family
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
            font.bold: true
            renderType: Text.NativeRendering

            Behavior on color {
                enabled: Kirigami.Units.longDuration > 1
                ColorAnimation { duration: 140 }
            }
        }

        WorkspaceComponents.BadgeOverlay {
            id: badge

            anchors.right: parent.right
            anchors.bottom: parent.bottom

            visible: Plasmoid.configuration.showPercentage && !root.isSomehowFullyCharged && !root.showSideLabel

            text: i18ndc("plasma_applet_org.kde.plasma.battery", "battery percentage below battery icon", "%1%", root.batteryPercent)

            // Non-default state to center if the badge is wider than the icon
            states: [
                State {
                    when: badge.width >= overallBatteryInfo.width
                    AnchorChanges {
                        target: badge
                        anchors.right: undefined
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            ]
        }
    }

    //Show all batteries
    GridView {
        id: view

        visible: !root.isConstrained

        anchors.fill: parent

        contentHeight: height
        contentWidth: width

        cellWidth: Math.min(height, width)
        cellHeight: cellWidth

        // Don't block events from MouseArea, and don't let users drag the batteries around
        interactive: false

        clip: true

        // We have any batteries; show their status
        delegate: Item {
            id: batteryContainer

            width: view.cellWidth
            height: view.cellHeight

            // Show normal battery icon
            WorkspaceComponents.BatteryIcon {
                id: batteryIcon

                anchors.fill: parent

                active: root.containsMouse
                hasBattery: PluggedIn
                percent: Percent
                pluggedIn: ChargeState === BatteryControlModel.Charging
            }

            WorkspaceComponents.BadgeOverlay {
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                visible: Plasmoid.configuration.showPercentage && !root.isSomehowFullyCharged

                text: i18ndc("plasma_applet_org.kde.plasma.battery", "battery percentage below battery icon", "%1%", Percent)
                icon: batteryIcon
            }
        }
    }
}
