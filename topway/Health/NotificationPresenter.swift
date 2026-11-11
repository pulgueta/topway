import UserNotifications

/// Shows alerts as banners also while Topway is the active app, for example when the popover
/// is open, and keeps them in Notification Center. Without a delegate, macOS does not show them.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
