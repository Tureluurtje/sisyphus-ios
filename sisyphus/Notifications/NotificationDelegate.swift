import Foundation
import UserNotifications
import OSLog

/// Handles notifications while the app is in the foreground, and logs when a
/// delivered notification is tapped.
///
/// There's no custom deep-linking wired up yet — tapping the reminder just
/// brings the app to the foreground (the OS default). Routing straight into
/// the review screen from here would need the project's deep-linking
/// infrastructure, which doesn't exist yet.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    static let shared = NotificationDelegate()

    private override init() {}

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        AppLogger.general.notice("Notification tapped: \(response.notification.request.identifier, privacy: .public)")
    }
}
