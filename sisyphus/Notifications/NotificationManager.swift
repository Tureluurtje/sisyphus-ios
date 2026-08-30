import Foundation
import UserNotifications
import OSLog

/// Local, on-device notification scheduling — a daily study reminder.
///
/// This is deliberately **not** remote push: the backend (see
/// `api-routes.json`) has no device-token or APNs integration, so there's
/// nothing server-side to register with. Everything here runs entirely on
/// the device via `UNUserNotificationCenter`, which needs no entitlement,
/// no Apple Developer push capability, and no server work.
@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    static let dailyReminderIdentifier = "daily-review-reminder"

    private init() {}

    /// Requests notification authorization. Call this only in direct
    /// response to the user opting in (e.g. flipping a Settings toggle on)
    /// — never at first launch, per Apple's notification design guidance:
    /// explain the value first, then ask at a meaningful moment.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            AppLogger.general.notice("Notification authorization \(granted ? "granted" : "denied", privacy: .public)")
            return granted
        } catch {
            AppLogger.general.error("Notification authorization request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Current system authorization status — lets the UI notice if the user
    /// revoked access from system Settings without touching the in-app toggle.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Schedules (or replaces) a repeating daily reminder at 5:00 PM local
    /// time. Re-adding with the same identifier replaces any existing
    /// pending request, so this is safe to call idempotently.
    func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Time to review"
        content.body = "A few minutes of Latin practice keeps your streak alive."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 17
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AppLogger.general.error("Failed to schedule daily reminder: \(error.localizedDescription, privacy: .public)")
            } else {
                AppLogger.general.notice("Daily reminder scheduled for 5:00 PM")
            }
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.dailyReminderIdentifier]
        )
        AppLogger.general.notice("Daily reminder canceled")
    }
}
