/*
    Iris Tasks — minimal task manager
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    // ---------------------------------------------------------- orientation
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int effectiveLocation: Plasmoid.location

    readonly property var cfg: Plasmoid.configuration
    readonly property var atm: TaskManager.AbstractTasksModel

    // ------------------------------------------------------- animation length
    // No animation when the global animation factor is 0 or the user turns it off.
    readonly property bool animate: cfg.animationsEnabled && Kirigami.Units.longDuration > 1
    readonly property int durFast: animate ? 90 : 0
    readonly property int durBase: animate ? 140 : 0
    readonly property int durSlide: animate ? 180 : 0

    // ------------------------------------------------------------- renkler
    // Surfaces are the text colour at low opacity, so they work with any
    // colour scheme.
    readonly property color fgColor: Kirigami.Theme.textColor
    // Background steps: inactive tasks are faintly visible too.
    readonly property color restColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.10)
    readonly property color hoverColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.16)
    readonly property color activeColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.24)
    readonly property color pressedColor: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.30)
    readonly property color attentionColor: Kirigami.Theme.neutralTextColor

    readonly property int radius: 2

    // ---------------------------------------------------------------- metrics
    readonly property int hPad: 2
    readonly property int taskSpacing: cfg.taskSpacing

    readonly property int count: tasksModel.count

    // In a vertical panel each task is one row high; horizontally the layout distributes them.
    readonly property int taskThickness: vertical
        ? Math.max(22, Math.min(40, Kirigami.Units.iconSizes.smallMedium + 12))
        : Math.max(0, root.height - 2 * hPad)

    // Width per task in a horizontal panel: up to maxTaskWidth, shrinking to fit.
    readonly property int cellLength: {
        if (count <= 0) {
            return cfg.minTaskWidth;
        }
        const avail = (vertical ? root.height : root.width) - 2 * hPad;
        const gaps = taskSpacing * Math.max(0, count - 1);
        const per = Math.floor((avail - gaps) / count);
        return Math.max(24, Math.min(cfg.maxTaskWidth, per));
    }

    readonly property int taskLength: vertical ? taskThickness : cellLength
    readonly property int taskBreadth: vertical ? Math.max(0, root.width - 2 * hPad) : taskThickness

    readonly property int effectiveIconSize: {
        const box = taskThickness;
        const auto = Math.max(12, Math.min(24, box - 10));
        return cfg.iconSize > 0 ? Math.min(cfg.iconSize, box - 4) : auto;
    }

    // --------------------------------------------------------- panel layout
    Layout.fillWidth: !vertical && cfg.fillWidth
    Layout.fillHeight: vertical && cfg.fillWidth
    Layout.minimumWidth: vertical ? 0 : Math.min(count, 1) * cfg.minTaskWidth
    Layout.minimumHeight: vertical ? Math.min(count, 1) * cfg.minTaskWidth : 0
    Layout.preferredWidth: vertical
        ? Layout.minimumWidth
        : Math.max(1, count * (cfg.maxTaskWidth + taskSpacing))
    Layout.preferredHeight: vertical
        ? Math.max(1, count * (taskThickness + taskSpacing))
        : Layout.minimumHeight

    preferredRepresentation: fullRepresentation

    Plasmoid.constraintHints: Plasmoid.CanFillArea

    // =============================================================== modeller
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManager.TasksModel {
        id: tasksModel

        virtualDesktop: virtualDesktopInfo.currentDesktop
        screenGeometry: Plasmoid.containment.screenGeometry
        activity: activityInfo.currentActivity

        filterByVirtualDesktop: root.cfg.showOnlyCurrentDesktop
        filterByScreen: root.cfg.showOnlyCurrentScreen
        filterByActivity: root.cfg.showOnlyCurrentActivity
        filterNotMinimized: false
        // KWin marks minimised windows as hidden; with this filter on they would
        // drop off the taskbar. Windows that should be hidden use SkipTaskbar.
        filterHidden: false

        sortMode: TaskManager.TasksModel.SortManual
        launchInPlace: false
        separateLaunchers: false
        groupMode: root.cfg.groupingEnabled
            ? TaskManager.TasksModel.GroupApplications
            : TaskManager.TasksModel.GroupDisabled
        groupInline: false
        taskReorderingEnabled: true
    }

    // Row of the active task
    readonly property int activeRow: {
        const idx = tasksModel.activeTask;
        return (idx && idx.valid) ? idx.row : -1;
    }

    // Repeater items are recreated when the model changes and itemAt() is not
    // re-evaluated on its own, so this counter acts as a binding dependency.
    property int layoutRevision: 0

    Connections {
        target: tasksModel
        function onRowsInserted(): void { root.layoutRevision++; }
        function onRowsRemoved(): void { root.layoutRevision++; }
        function onModelReset(): void { root.layoutRevision++; }
        function onRowsMoved(): void { root.layoutRevision++; }
    }

    readonly property var activeRepeater: vertical ? repeaterVertical : repeater
    readonly property Item activeContainer: vertical ? taskColumn : taskRow

    readonly property Item activeItem: {
        const _rev = root.layoutRevision;               // dependency
        const _cnt = root.activeRepeater.count;         // dependency
        const r = root.activeRow;
        if (r < 0 || r >= _cnt) {
            return null;
        }
        return root.activeRepeater.itemAt(r);
    }

    // ================================================================ visuals
    Item {
        id: taskArea
        anchors.fill: parent
        anchors.margins: root.hPad
        clip: true

        // --- active task layer: slides from task to task
        Rectangle {
            id: activeLayer

            visible: root.activeItem !== null && opacity > 0
            opacity: root.activeItem !== null ? 1 : 0

            x: root.activeItem ? root.activeContainer.x + root.activeItem.x : 0
            y: root.activeItem ? root.activeContainer.y + root.activeItem.y : 0
            width: root.activeItem ? root.activeItem.width : 0
            height: root.activeItem ? root.activeItem.height : 0

            radius: root.radius
            color: root.activeColor

            Behavior on x {
                enabled: root.animate
                NumberAnimation { duration: root.durSlide; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                enabled: root.animate
                NumberAnimation { duration: root.durSlide; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                enabled: root.animate
                NumberAnimation { duration: root.durSlide; easing.type: Easing.OutCubic }
            }
            Behavior on height {
                enabled: root.animate
                NumberAnimation { duration: root.durSlide; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                enabled: root.animate
                NumberAnimation { duration: root.durFast }
            }

            // thin active line on the panel's screen-edge side
            Rectangle {
                id: indicator

                readonly property bool onNearEdge: {
                    const inner = root.cfg.indicatorEdge === 1;
                    if (root.vertical) {
                        return (root.effectiveLocation === PlasmaCore.Types.LeftEdge) !== inner;
                    }
                    return (root.effectiveLocation === PlasmaCore.Types.TopEdge) !== inner;
                }

                width: root.vertical ? root.cfg.indicatorThickness : Math.max(8, parent.width - 8)
                height: root.vertical ? Math.max(8, parent.height - 8) : root.cfg.indicatorThickness
                radius: Math.min(width, height) / 2
                color: root.fgColor

                anchors.horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
                anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
                anchors.top: (!root.vertical && onNearEdge) ? parent.top : undefined
                anchors.bottom: (!root.vertical && !onNearEdge) ? parent.bottom : undefined
                anchors.left: (root.vertical && onNearEdge) ? parent.left : undefined
                anchors.right: (root.vertical && !onNearEdge) ? parent.right : undefined
            }
        }

        // --- task layout: a Row when horizontal, a Column when vertical.
        // Row/Column reposition children as widths change, avoiding the
        // overlaps seen with ListView's cached positions.
        Row {
            id: taskRow
            visible: !root.vertical
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.taskSpacing

            Repeater {
                id: repeater
                model: root.vertical ? null : tasksModel
                delegate: Task { tasksRoot: root; taskModelRef: tasksModel }
            }
        }

        Column {
            id: taskColumn
            visible: root.vertical
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.taskSpacing

            Repeater {
                id: repeaterVertical
                model: root.vertical ? tasksModel : null
                delegate: Task { tasksRoot: root; taskModelRef: tasksModel }
            }
        }
    }

    // ============================================================== tekerlek
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        enabled: root.cfg.wheelCyclesTasks
        z: -1

        property int wheelDelta: 0

        onWheel: wheel => {
            if (!root.cfg.wheelCyclesTasks || tasksModel.count < 2) {
                return;
            }
            wheelDelta += (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x);
            let step = 0;
            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                step -= 1;
            }
            while (wheelDelta <= -120) {
                wheelDelta += 120;
                step += 1;
            }
            if (step === 0) {
                return;
            }
            let next = root.activeRow;
            if (next < 0) {
                next = 0;
            } else {
                next = (next + step) % tasksModel.count;
                if (next < 0) {
                    next += tasksModel.count;
                }
            }
            tasksModel.requestActivate(tasksModel.index(next, 0));
        }
    }

    // ========================================================== context menu
    property Component contextMenuComponent: Qt.createComponent("ContextMenu.qml")

    function openContextMenu(visualParent: Item, row: int): void {
        if (contextMenuComponent.status !== Component.Ready) {
            console.warn("iristasks: could not load the context menu:", contextMenuComponent.errorString());
            return;
        }
        const menu = contextMenuComponent.createObject(root, {
            visualParent: visualParent,
            modelIndex: tasksModel.index(row, 0),
            tasksModel: tasksModel,
            tasksRoot: root
        });
        if (menu) {
            menu.show();
        }
    }

    function taskModel(): var {
        return tasksModel;
    }
}
