pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "code/globals.js" as Globals
import "code/utils.js" as Utils
import "components" as Components
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: appearanceRoot
    property alias parentLayout: parentLayout

    property int currentTab
    property int currentState
    property string cfg_globalSettings
    property alias cfg_isEnabled: headerComponent.isEnabled
    property bool ready: false
    property var settingsItem: null

    // Iris fork: separate floating / fixed appearance sets ------------------
    property bool cfg_separateFloatingFixed
    property string cfg_globalSettingsFloating
    property string cfg_globalSettingsFixed
    property int cfg_configEditVariant
    // Guards the first build of the form; reloads before that are pointless.
    property bool pageReady: false

    readonly property bool editingFloating: cfg_configEditVariant === 0

    // The set the form below is editing right now.
    readonly property string activeConfigString: {
        if (!cfg_separateFloatingFixed) {
            return cfg_globalSettings;
        }
        const raw = editingFloating ? cfg_globalSettingsFloating : cfg_globalSettingsFixed;
        return Utils.isVariantUnseeded(raw) ? cfg_globalSettings : raw;
    }

    function setActiveConfigString(newString) {
        if (!cfg_separateFloatingFixed) {
            cfg_globalSettings = newString;
        } else if (editingFloating) {
            cfg_globalSettingsFloating = newString;
        } else {
            cfg_globalSettingsFixed = newString;
        }
    }

    // Both sets start as a copy of the single configuration that existed
    // before, so enabling the split never changes how the panel looks.
    function seedVariants() {
        if (Utils.isVariantUnseeded(cfg_globalSettingsFloating)) {
            cfg_globalSettingsFloating = cfg_globalSettings;
        }
        if (Utils.isVariantUnseeded(cfg_globalSettingsFixed)) {
            cfg_globalSettingsFixed = cfg_globalSettings;
        }
    }

    // Rebuild the form so every control re-reads the newly selected set
    // instead of keeping bindings to the previous one.
    function reloadSettingsItem() {
        if (!pageReady) {
            return;
        }
        ready = false;
        if (settingsItem) {
            settingsItem.destroy();
            settingsItem = null;
        }
        Qt.callLater(() => {
            settingsItem = settingsComp.createObject(layout);
            ready = true;
        });
    }

    onCfg_separateFloatingFixedChanged: {
        if (cfg_separateFloatingFixed) {
            seedVariants();
        }
        reloadSettingsItem();
    }

    onCfg_configEditVariantChanged: reloadSettingsItem()
    property var followVisbility: {
        "widgets": {
            "background": {
                "panel": true,
                "widget": false,
                "tray": false
            },
            "foreground": {
                "panel": true,
                "widget": true,
                "tray": false
            }
        },
        "panel": {
            "background": {
                "panel": false,
                "widget": false,
                "tray": false
            },
            "foreground": {
                "panel": true,
                "widget": false,
                "tray": false
            }
        },
        "trayWidgets": {
            "background": {
                "panel": true,
                "widget": true,
                "tray": false
            },
            "foreground": {
                "panel": true,
                "widget": true,
                "tray": true
            }
        }
    }

    ColumnLayout {
        id: layout
        enabled: cfg_isEnabled
        width: appearanceRoot.availableWidth
        height: Math.max(implicitHeight, appearanceRoot.availableHeight)
        spacing: 0

        Components.FloatingFixedSelector {
            Layout.fillWidth: true
            separateEnabled: appearanceRoot.cfg_separateFloatingFixed
            selectedVariant: appearanceRoot.cfg_configEditVariant
            onSeparateToggled: enabled => appearanceRoot.cfg_separateFloatingFixed = enabled
            onVariantSelected: variant => appearanceRoot.cfg_configEditVariant = variant
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            text: i18n("Not getting the expected result? Make sure you're editing the correct element.<br>Custom blur not working? Try reinstalling/rebuilding the C++ plugin using the latest source, <a href=\"%1\">see instructions</a>.", "https://github.com/luisbocanegra/plasma-panel-colorizer#build-from-source-with-c-plugin")
            visible: true
            type: Kirigami.MessageType.Information
            onLinkActivated: Qt.openUrlExternally(link)
        }

        Button {
            text: {
                if (!appearanceRoot.cfg_separateFloatingFixed) {
                    return i18n("Restore default (removes all customizations)");
                }
                return appearanceRoot.editingFloating ? i18n("Restore default (floating set only)") : i18n("Restore default (fixed set only)");
            }
            icon.name: "kt-restore-defaults-symbolic"
            onClicked: {
                appearanceRoot.setActiveConfigString(JSON.stringify(Globals.defaultConfig));
                appearanceRoot.reloadSettingsItem();
            }
            Layout.fillWidth: true
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.largeSpacing
        }

        Kirigami.FormLayout {
            id: parentLayout

            Layout.fillWidth: true
            RowLayout {
                Kirigami.FormData.label: i18n("Element:")
                ComboBox {
                    id: targetComponent
                    textRole: "name"
                    valueRole: "value"
                    model: [
                        {
                            "name": i18n("Panel"),
                            "value": "panel"
                        },
                        {
                            "name": i18n("Widgets"),
                            "value": "widgets"
                        },
                        {
                            "name": i18n("Tray widgets"),
                            "value": "trayWidgets"
                        }
                    ]
                }
                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("Part of the panel on which the options below will be applied.")
                }
            }
            ColumnLayout {
                Components.PanelElementHint {
                    target: targetComponent.currentIndex
                }
            }
        }

        Component {
            id: settingsComp
            Components.FormWidgetSettings {
                currentTab: appearanceRoot.currentTab
                configString: appearanceRoot.activeConfigString
                handleString: true
                elementState: appearanceRoot.currentState
                elementName: targetComponent.currentValue
                elementFriendlyName: targetComponent.currentText
                followVisbility: appearanceRoot.followVisbility[targetComponent.currentValue]
                onElementStateChanged: appearanceRoot.currentState = elementState
                onTabChanged: currentTab => {
                    appearanceRoot.currentTab = currentTab;
                }
                onUpdateConfigString: (newString, newConfig) => {
                    if (!appearanceRoot.ready) {
                        return;
                    }
                    Qt.callLater(() => {
                        console.error("Components.FormWidgetSettings, Updated config string");
                        appearanceRoot.setActiveConfigString(JSON.stringify(newConfig));
                    });
                }
            }
        }

        Component.onCompleted: {
            if (appearanceRoot.cfg_separateFloatingFixed) {
                appearanceRoot.seedVariants();
            }
            Qt.callLater(() => {
                appearanceRoot.settingsItem = settingsComp.createObject(layout);
                appearanceRoot.ready = true;
                appearanceRoot.pageReady = true;
            });
        }
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: !appearanceRoot.settingsItem
            Kirigami.LoadingPlaceholder {
                anchors.centerIn: parent
            }
        }
    }

    Component.onDestruction: {
        if (appearanceRoot.settingsItem) {
            appearanceRoot.settingsItem.destroy();
            appearanceRoot.settingsItem = null;
        }
    }

    Connections {
        target: Qt.application
        function onAboutToQuit() {
            if (appearanceRoot.settingsItem) {
                appearanceRoot.settingsItem.destroy();
                appearanceRoot.settingsItem = null;
            }
        }
    }

    header: ColumnLayout {
        Components.Header {
            id: headerComponent
        }
    }
}
