/* Iris Tray — notifications. notificationmanager works as a standalone module. */
import QtQuick
import org.kde.notificationmanager as NotificationManager

Item {
    id: notif

    // Do Not Disturb: Plasma stores it as an "inhibited until" time in the future.
    readonly property bool dnd: {
        const until = notifSettings.notificationsInhibitedUntil;
        const byDate = until !== undefined && until !== null && !isNaN(until) && until > new Date();
        return byDate || notifSettings.notificationsInhibitedByApplication === true;
    }

    readonly property int unread: notifModel.activeNotificationsCount || 0

    readonly property string iconName: dnd ? "notifications-disabled" : "notifications"

    readonly property string tooltip: {
        if (dnd) {
            return i18n("Do not disturb");
        }
        return unread > 0
            ? i18np("%1 notification", "%1 notifications", unread)
            : i18n("No new notifications");
    }

    NotificationManager.Settings {
        id: notifSettings
    }

    NotificationManager.Notifications {
        id: notifModel
        showDismissed: false
        showExpired: false
    }

    function toggleDoNotDisturb(): void {
        if (dnd) {
            notifSettings.notificationsInhibitedUntil = undefined;
            notifSettings.revokeApplicationInhibitions();
        } else {
            const d = new Date();
            d.setFullYear(d.getFullYear() + 100);
            notifSettings.notificationsInhibitedUntil = d;
        }
        notifSettings.save();
    }
}
