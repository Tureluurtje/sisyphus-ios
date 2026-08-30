import Foundation

/// Protocol for error/crash monitoring services — distinct from
/// `ErrorManager` (which only drives the on-screen error banner users see).
/// This is developer-facing telemetry, never shown in the UI.
///
/// Usage:
/// ```swift
/// ErrorMonitoring.shared.service.captureError(error)
///
/// let context = ErrorContext(tags: ["feature": "auth"])
/// ErrorMonitoring.shared.service.captureError(error, context: context)
///
/// ErrorMonitoring.shared.service.addBreadcrumb(
///     Breadcrumb(category: "navigation", message: "Opened Profile")
/// )
/// ```
protocol ErrorMonitoringService: Sendable {

    /// Configure the service. Call once at app launch.
    func configure()

    /// Capture an error with optional context.
    func captureError(_ error: Error, context: ErrorContext?)

    /// Capture a message with severity level (no underlying `Error` value).
    func captureMessage(_ message: String, level: ErrorLevel)

    /// Add a breadcrumb for debugging context leading up to a future error.
    func addBreadcrumb(_ breadcrumb: Breadcrumb)

    /// Set the current user (anonymized IDs only — never PII).
    func setUser(_ user: MonitoringUser?)

    /// Clear user/session data. Call on logout.
    func reset()
}

extension ErrorMonitoringService {
    /// Capture an error without additional context.
    func captureError(_ error: Error) {
        captureError(error, context: nil)
    }
}

// MARK: - Error Level

enum ErrorLevel: String, Sendable, CaseIterable {
    case debug
    case info
    case warning
    case error
    case fatal
}

// MARK: - Monitoring User

/// User information attached to reports. Anonymized IDs only.
struct MonitoringUser: Sendable, Equatable {
    let id: String
    let username: String?
    let segment: String?

    init(id: String, username: String? = nil, segment: String? = nil) {
        self.id = id
        self.username = username
        self.segment = segment
    }
}

// MARK: - Central Access

/// Central access point for error monitoring.
///
/// Deliberately **not** actor-isolated: `ErrorMonitoringService` is
/// `Sendable`, and this app's error paths span plain `async` service
/// functions and synchronous throwing helpers (`APIClient.validate`) across
/// several actors — an isolated singleton would force an `await` hop at
/// every call site for no benefit, unlike a UI-facing type.
final class ErrorMonitoring: Sendable {

    static let shared = ErrorMonitoring()

    /// The active service. Change this to swap providers, e.g.
    /// `SentryErrorMonitoring()` once a real DSN and SPM package are added.
    let service: ErrorMonitoringService

    private init() {
        #if DEBUG
        service = DebugErrorMonitoring()
        #else
        service = MetricKitErrorMonitoring()
        #endif
    }

    /// Configure error monitoring. Call once at app launch.
    func configure() {
        service.configure()
    }
}
