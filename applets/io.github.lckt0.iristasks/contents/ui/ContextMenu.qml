/*
    Iris Tasks — task context menu
    SPDX-FileCopyrightText: 2026 lckt0 <lckt0@protonmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager

PlasmaExtras.Menu {
    id: menu

    required property var modelIndex
    required property TaskManager.TasksModel tasksModel
    required property var tasksRoot

    readonly property var atm: TaskManager.AbstractTasksModel

    placement: {
        switch (menu.tasksRoot.effectiveLocation) {
        case PlasmaCore.Types.LeftEdge:
            return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        case PlasmaCore.Types.TopEdge:
            return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        case PlasmaCore.Types.RightEdge:
            return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
        default:
            return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
        }
    }

    function get(role: int): var {
        return menu.tasksModel.data(menu.modelIndex, role);
    }

    function show(): void {
        openRelative();
    }

    onStatusChanged: {
        if (status === PlasmaExtras.Menu.Closed) {
            menu.destroy();
        }
    }

    PlasmaExtras.MenuItem {
        text: i18n("Minimize")
        icon: "window-minimize"
        visible: menu.get(menu.atm.IsMinimizable) === true
        checkable: true
        checked: menu.get(menu.atm.IsMinimized) === true
        onClicked: menu.tasksModel.requestToggleMinimized(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        text: i18n("Maximize")
        icon: "window-maximize"
        visible: menu.get(menu.atm.IsMaximizable) === true
        checkable: true
        checked: menu.get(menu.atm.IsMaximized) === true
        onClicked: menu.tasksModel.requestToggleMaximized(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        text: i18n("Full Screen")
        icon: "view-fullscreen"
        visible: menu.get(menu.atm.IsFullScreenable) === true
        checkable: true
        checked: menu.get(menu.atm.IsFullScreen) === true
        onClicked: menu.tasksModel.requestToggleFullScreen(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        separator: true
    }

    PlasmaExtras.MenuItem {
        text: i18n("Keep Above Others")
        icon: "window-keep-above"
        checkable: true
        checked: menu.get(menu.atm.IsKeepAbove) === true
        onClicked: menu.tasksModel.requestToggleKeepAbove(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        text: i18n("Keep Below Others")
        icon: "window-keep-below"
        checkable: true
        checked: menu.get(menu.atm.IsKeepBelow) === true
        onClicked: menu.tasksModel.requestToggleKeepBelow(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        text: i18n("All Desktops")
        icon: "window-pin"
        visible: menu.get(menu.atm.IsVirtualDesktopsChangeable) === true
        checkable: true
        checked: menu.get(menu.atm.IsOnAllVirtualDesktops) === true
        onClicked: menu.tasksModel.requestVirtualDesktops(menu.modelIndex, [])
    }

    PlasmaExtras.MenuItem {
        separator: true
    }

    PlasmaExtras.MenuItem {
        text: i18n("Open New Window")
        icon: "window-new"
        visible: menu.get(menu.atm.CanLaunchNewInstance) === true
        onClicked: menu.tasksModel.requestNewInstance(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        text: menu.get(menu.atm.IsGroupParent) === true ? i18n("Close All") : i18n("Close")
        icon: "window-close"
        visible: menu.get(menu.atm.IsClosable) === true
        onClicked: menu.tasksModel.requestClose(menu.modelIndex)
    }
}
