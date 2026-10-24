/*
    Iris Tasks — a single task button
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

Item {
    id: task

    // Provided by the Repeater
    required property int index
    required property var model
    property var tasksRoot: null
    property var taskModelRef: null

    readonly property bool isActive: model.IsActive === true
    readonly property bool isMinimized: model.IsMinimized === true
    readonly property bool needsAttention: model.IsDemandingAttention === true
    readonly property bool isGroupParent: model.IsGroupParent === true
    readonly property int childCount: model.ChildCount || 0

    readonly property string title: model.display || model.AppName || ""
    readonly property string appName: model.AppName || ""

    readonly property bool vertical: tasksRoot ? tasksRoot.vertical : false

    width: tasksRoot ? (vertical ? tasksRoot.taskBreadth : tasksRoot.cellLength) : 0
    height: tasksRoot ? (vertical ? tasksRoot.taskThickness : tasksRoot.taskThickness) : 0

    // The title is only shown when it fits; on a narrow panel the task shrinks to its icon.
    readonly property bool labelVisible: tasksRoot
        ? (tasksRoot.cfg.showLabels && width >= 76)
        : false

    // Animate width changes as windows open and close.
    Behavior on width {
        enabled: tasksRoot ? tasksRoot.animate : false
        NumberAnimation {
            duration: tasksRoot ? tasksRoot.durBase : 0
            easing.type: Easing.OutCubic
        }
    }

    // Fade in new tasks
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity {
        enabled: tasksRoot ? tasksRoot.animate : false
        NumberAnimation {
            duration: tasksRoot ? tasksRoot.durBase : 0
            easing.type: Easing.OutCubic
        }
    }

    // Slight press-in when clicked.
    scale: mouseArea.pressed ? 0.97 : 1.0
    Behavior on scale {
        enabled: tasksRoot ? tasksRoot.animate : false
        NumberAnimation {
            duration: tasksRoot ? tasksRoot.durFast : 0
            easing.type: Easing.OutCubic
        }
    }

    // ------------------------------------------------------------- zemin
    // The active task's background and indicator are drawn by a sliding layer
    // in main.qml; this only handles hover/pressed.
    Rectangle {
        id: taskBackground
        anchors.fill: parent
        radius: tasksRoot ? tasksRoot.radius : 2
        color: {
            if (!tasksRoot) {
                return "transparent";
            }
            if (mouseArea.pressed) {
                return tasksRoot.pressedColor;
            }
            if (mouseArea.containsMouse && !task.isActive) {
                return tasksRoot.hoverColor;
            }
            if (task.isActive) {
                // the active background is drawn by the sliding layer below
                return "transparent";
            }
            return tasksRoot.restColor;
        }

        Behavior on color {
            enabled: tasksRoot ? tasksRoot.animate : false
            ColorAnimation { duration: tasksRoot ? tasksRoot.durFast : 0 }
        }
    }

    // --------------------------------------------------- attention indicator
    Rectangle {
        id: attentionBar

        readonly property int thickness: task.tasksRoot ? task.tasksRoot.cfg.indicatorThickness : 2
        readonly property bool onNearEdge: {
            if (!task.tasksRoot) {
                return false;
            }
            const inner = task.tasksRoot.cfg.indicatorEdge === 1;
            if (task.vertical) {
                return (task.tasksRoot.effectiveLocation === PlasmaCore.Types.LeftEdge) !== inner;
            }
            return (task.tasksRoot.effectiveLocation === PlasmaCore.Types.TopEdge) !== inner;
        }

        visible: task.needsAttention
        color: task.tasksRoot ? task.tasksRoot.attentionColor : "orange"

        width: task.vertical ? thickness : Math.max(8, task.width - 8)
        height: task.vertical ? Math.max(8, task.height - 8) : thickness
        radius: Math.min(width, height) / 2

        x: task.vertical ? (onNearEdge ? 0 : task.width - width) : (task.width - width) / 2
        y: task.vertical ? (task.height - height) / 2 : (onNearEdge ? 0 : task.height - height)

        // Only runs for windows demanding attention; a slow two-step fade.
        SequentialAnimation on opacity {
            running: task.needsAttention && (task.tasksRoot ? task.tasksRoot.animate : false)
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
        }
    }

    // ------------------------------------------------------------- content
    Item {
        id: taskContent
        anchors.fill: parent
        // Minimised tasks are not dimmed; state is shown only by the active indicator.

        readonly property int pad: 6
        readonly property int gap: 6

        Kirigami.Icon {
            id: taskIcon
            source: task.model.decoration
            width: task.tasksRoot ? task.tasksRoot.effectiveIconSize : 16
            height: width
            x: task.labelVisible ? taskContent.pad : Math.round((task.width - width) / 2)
            y: Math.round((task.height - height) / 2)
            active: mouseArea.containsMouse
            smooth: true
        }

        Text {
            id: taskLabel
            visible: task.labelVisible
            text: task.title
            color: task.tasksRoot ? task.tasksRoot.fgColor : "white"
            elide: Text.ElideRight
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            font: Kirigami.Theme.defaultFont

            x: taskIcon.x + taskIcon.width + taskContent.gap
            y: 0
            height: task.height
            width: Math.max(0, task.width - x - taskContent.pad
                - (badge.visible ? badge.width + taskContent.gap : 0))
        }

        // Number of windows in the group
        Rectangle {
            id: badge
            visible: task.isGroupParent && task.childCount > 1 && task.labelVisible
            width: Math.max(14, badgeText.implicitWidth + 8)
            height: 14
            x: task.width - width - taskContent.pad
            y: Math.round((task.height - height) / 2)
            radius: task.tasksRoot ? task.tasksRoot.radius : 2
            color: task.tasksRoot
                ? Qt.rgba(task.tasksRoot.fgColor.r, task.tasksRoot.fgColor.g, task.tasksRoot.fgColor.b, 0.14)
                : "gray"

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: task.childCount
                color: task.tasksRoot ? task.tasksRoot.fgColor : "white"
                font: Kirigami.Theme.smallFont
            }
        }
    }

    // --------------------------------------------------------------- ipucu
    PlasmaCore.ToolTipArea {
        id: toolTip
        anchors.fill: parent
        active: (task.tasksRoot ? task.tasksRoot.cfg.showTooltips : true) && !task.labelVisible
        interactive: false
        location: task.tasksRoot ? task.tasksRoot.effectiveLocation : PlasmaCore.Types.Floating
        mainText: task.appName
        subText: (task.title !== task.appName) ? task.title : ""
    }

    // ------------------------------------------------------------ interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: mouse => {
            if (!task.taskModelRef || task.index < 0) {
                return;
            }
            const idx = task.taskModelRef.index(task.index, 0);

            if (mouse.button === Qt.LeftButton) {
                if (task.isActive && !task.isMinimized) {
                    task.taskModelRef.requestToggleMinimized(idx);
                } else {
                    task.taskModelRef.requestActivate(idx);
                }
            } else if (mouse.button === Qt.MiddleButton) {
                const action = task.tasksRoot ? task.tasksRoot.cfg.middleClickAction : 0;
                if (action === 0) {
                    task.taskModelRef.requestClose(idx);
                } else if (action === 1) {
                    task.taskModelRef.requestNewInstance(idx);
                }
            } else if (mouse.button === Qt.RightButton) {
                if (task.tasksRoot) {
                    task.tasksRoot.openContextMenu(task, task.index);
                }
            }
        }
    }

    // Publish the geometry so the minimise animation targets this button.
    function publishGeometry(): void {
        if (!task.taskModelRef || !task.visible || task.width <= 0) {
            return;
        }
        const global = task.mapToGlobal(0, 0);
        task.taskModelRef.requestPublishDelegateGeometry(
            task.taskModelRef.index(task.index, 0),
            Qt.rect(global.x, global.y, task.width, task.height),
            task);
    }

    onWidthChanged: Qt.callLater(publishGeometry)
    onXChanged: Qt.callLater(publishGeometry)
}
