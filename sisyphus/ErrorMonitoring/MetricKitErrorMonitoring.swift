import Foundation
import MetricKit
import OSLog

/// Apple-native crash/hang monitoring — no third-party SDK, no account, no
/// DSN. This is what "use Apple's own analytics" actually gets you:
///
/// - Real crash reports are **also** automatically visible for free in
///   Xcode Organizer (Window > Organizer > Crashes) and App Store Connect
///   once the app ships, with zero code, for users who opted into sharing
///   analytics with developers (Settings > Privacy & Security > Analytics &
///   Improvements). That channel exists independently of this file.
/// - This class integrates that same OS-level signal *inside* the running
///   app via MetricKit, so a crash/hang shows up in this app's own logs.
///
/// Real limits, to set expectations correctly:
/// - Apple has no hosted endpoint for reporting your own caught `Error`
///   values — there's no Apple equivalent of `SentrySDK.capture(error:)`.
///   `captureError`/`captureMessage` below only log locally via
///   `AppLogger`; they don't leave the device. Wire them to your own
///   backend if you want handled errors collected remotely.
/// - MetricKit diagnostic payloads are OS-batched and typically delivered
///   roughly once every 24 hours, never immediately after the event.
final class MetricKitErrorMonitoring: NSObject, ErrorMonitoringService, @unchecked Sendable {

    func configure() {
        MXMetricManager.shared.add(self)
        AppLogger.general.notice("MetricKit crash/hang observer registered")
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
        // Apple's own crash reporting is anonymous by OS design — there's
        // no per-user tagging to set here.
    }

    func reset() {
        // No per-session state to clear for this provider.
    }
}

extension MetricKitErrorMonitoring: MXMetricManagerSubscriber {

    /// Required by MXMetricManagerSubscriber. Aggregated performance metrics
    /// (launch time, memory, battery, etc.) — not wired to anything by
    /// default. Add specific thresholds here if you want e.g. slow launches
    /// surfaced as `captureMessage` events.
    func didReceive(_ payloads: [MXMetricPayload]) {}

    /// Crash and hang diagnostics the OS itself observed since the last
    /// delivery. Full symbolicated detail is what shows up in Xcode
    /// Organizer / App Store Connect; this just confirms locally that
    /// something happened and roughly how often.
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let crashCount = payload.crashDiagnostics?.count ?? 0
            let hangCount = payload.hangDiagnostics?.count ?? 0

            if crashCount > 0 {
                AppLogger.general.fault("MetricKit reported \(crashCount, privacy: .public) crash diagnostic(s) for the previous period")
            }
            if hangCount > 0 {
                AppLogger.general.warning("MetricKit reported \(hangCount, privacy: .public) hang diagnostic(s) for the previous period")
            }
        }
    }
}
