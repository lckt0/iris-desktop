import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_showOnlyCurrentDesktop: currentDesktop.checked
    property alias cfg_showOnlyCurrentScreen: currentScreen.checked
    property alias cfg_showOnlyCurrentActivity: currentActivity.checked
    property alias cfg_groupingEnabled: grouping.checked
    property alias cfg_wheelCyclesTasks: wheelCycles.checked
    property alias cfg_animationsEnabled: animations.checked
    property alias cfg_showTooltips: tooltips.checked
    property int cfg_middleClickAction

    QQC2.CheckBox {
        id: currentDesktop
        Kirigami.FormData.label: i18n("Show only tasks from:")
        text: i18n("the current virtual desktop")
    }

    QQC2.CheckBox {
        id: currentScreen
        text: i18n("the current screen")
    }

    QQC2.CheckBox {
        id: currentActivity
        text: i18n("the current activity")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: grouping
        Kirigami.FormData.label: i18n("Grouping:")
        text: i18n("Group windows of the same application")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.ComboBox {
        id: middleClick
        Kirigami.FormData.label: i18n("Middle click:")
        model: [i18n("Close window"), i18n("Open new window"), i18n("Do nothing")]
        currentIndex: page.cfg_middleClickAction
        onActivated: page.cfg_middleClickAction = currentIndex
    }

    QQC2.CheckBox {
        id: wheelCycles
        Kirigami.FormData.label: i18n("Mouse wheel:")
        text: i18n("Cycle through tasks")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: animations
        Kirigami.FormData.label: i18n("Motion:")
        text: i18n("Enable animations")
    }

    QQC2.CheckBox {
        id: tooltips
        text: i18n("Show tooltips when titles are hidden")
    }
}
