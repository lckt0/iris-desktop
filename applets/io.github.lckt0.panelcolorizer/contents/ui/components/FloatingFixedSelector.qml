import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * Iris fork: switch for the separate floating / fixed appearance sets, plus the
 * tab that picks which of the two the page below is editing.
 *
 * Purely presentational: it owns no configuration, it only reports the user's
 * intent so the hosting config page can write the right kcfg key.
 */
ColumnLayout {
    id: root

    /** Whether floating and fixed panel states use separate appearance sets. */
    property bool separateEnabled: false
    /** Set currently being edited: 0 = floating, 1 = fixed. */
    property int selectedVariant: 0

    signal separateToggled(bool enabled)
    signal variantSelected(int variant)

    spacing: Kirigami.Units.smallSpacing

    // The config page hands us its stored value only after this component has
    // been built, so the tab has to follow the property rather than sample it
    // once. A plain declarative binding would be dropped the first time the
    // user clicks a tab, hence the explicit re-sync.
    onSelectedVariantChanged: {
        if (variantTabs.currentIndex !== selectedVariant) {
            variantTabs.currentIndex = selectedVariant;
        }
    }

    CheckBox {
        id: separateCheck

        Layout.fillWidth: true
        text: i18n("Separate configuration for floating and fixed panel")
        checked: root.separateEnabled
        onToggled: root.separateToggled(checked)
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.gridUnit
        visible: !root.separateEnabled
        text: i18n("The same appearance is used whether the panel floats or not.")
        wrapMode: Text.WordWrap
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }

    TabBar {
        id: variantTabs

        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: root.separateEnabled

        TabButton {
            text: i18n("Floating")
        }

        TabButton {
            text: i18n("Fixed")
        }

        onCurrentIndexChanged: root.variantSelected(currentIndex)
        Component.onCompleted: currentIndex = root.selectedVariant
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: root.separateEnabled
        position: Kirigami.InlineMessage.Position.Header
        type: Kirigami.MessageType.Information
        text: root.selectedVariant === 0 ? i18n("Editing the <b>floating</b> set. It is applied while the panel is detached from the screen edge.") : i18n("Editing the <b>fixed</b> set. It is applied while the panel touches the screen edge, including when a maximized window makes a floating panel dock.")
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: root.separateEnabled
        type: Kirigami.MessageType.Information
        text: i18n("<b>Stock Panel Settings</b> and <b>Preset Overrides</b> are shared by both sets.")
    }

    Item {
        Layout.preferredHeight: Kirigami.Units.largeSpacing
    }
}
