import Foundation
import os

/// Discards everything. Use for users who opt out of diagnostics, or in
/// unit tests where you don't want monitoring side effects.
final class NoOpErrorMonitoring: ErrorMonitoringService {
    func configure() {}
    func captureError(_ error: Error, context: ErrorContext?) {}
    func captureMessage(_ message: String, level: ErrorLevel) {}
    func addBreadcrumb(_ breadcrumb: Breadcrumb) {}
    func setUser(_ user: MonitoringUser?) {}
    func reset() {}
}

/// Debug-build implementation that routes everything through the app's own
/// `AppLogger` (category `.general`) instead of `print`, so it shows up
/// alongside every other log line in Console.app / the Xcode console.
final class DebugErrorMonitoring: ErrorMonitoringService {

    func configure() {
        AppLogger.general.notice("Error monitoring configured (debug mode — console only)")
    }

    func captureError(_ error: Error, context: ErrorContext?) {
        if let context, !context.tags.isEmpty {
            AppLogger.general.error("Captured error: \(error.localizedDescription, privacy: .public) tags=\(context.tags.description, privacy: .public)")
        } else {
            AppLogger.general.error("Captured error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func captureMessage(_ message: String, level: ErrorLevel) {
        switch level {
        case .debug: AppLogger.general.debug("\(message, privacy: .public)")
        case .info: AppLogger.general.info("\(message, privacy: .public)")
        case .warning: AppLogger.general.warning("\(message, privacy: .public)")
        case .error: AppLogger.general.error("\(message, privacy: .public)")
        case .fatal: AppLogger.general.fault("\(message, privacy: .public)")
        }
    }

    func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        AppLogger.general.debug("Breadcrumb [\(breadcrumb.category, privacy: .public)] \(breadcrumb.message, privacy: .public)")
    }

    func setUser(_ user: MonitoringUser?) {
        if let user {
            AppLogger.general.debug("Would set monitoring user: \(user.id, privacy: .private)")
        } else {
            AppLogger.general.debug("Cleared monitoring user")
        }
    }

    func reset() {
        AppLogger.general.debug("Error monitoring session reset")
    }
}
