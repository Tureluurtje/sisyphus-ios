import OSLog

/// Centralized logging for the app using Apple's unified logging system.
///
/// Usage:
/// ```swift
/// AppLogger.network.info("Request started")
/// AppLogger.auth.debug("User: \(email, privacy: .private)")
/// AppLogger.words.error("Review submission failed: \(error.localizedDescription)")
/// ```
///
/// Privacy Levels:
/// - `.public` - Safe to log (IDs, counts, status codes)
/// - `.private` - Redacted in release (emails, usernames) - DEFAULT
/// - `.sensitive` - Always redacted (passwords, tokens)
///
/// Log Levels:
/// - `.debug` - Development only (compiled out in release)
/// - `.info` - General information
/// - `.notice` - Important events (persisted)
/// - `.warning` - Potential issues (persisted)
/// - `.error` - Errors (persisted)
/// - `.fault` - Critical failures (persisted, highlighted)
enum AppLogger {

    /// The subsystem identifier, matching the app's bundle identifier.
    static let subsystem = Bundle.main.bundleIdentifier ?? "tureluurtje.sisyphus"

    /// General/miscellaneous events that don't fit another category.
    static let general = Logger(subsystem: subsystem, category: "General")

    /// Network requests, responses, and API errors (NetworkAPIClient).
    static let network = Logger(subsystem: subsystem, category: "Network")

    /// Login, registration, token refresh, logout, account deletion.
    static let auth = Logger(subsystem: subsystem, category: "Auth")

    /// Word list loading, due words, stacks, and review submission.
    static let words = Logger(subsystem: subsystem, category: "Words")

    /// View lifecycle, navigation, and other UI-level events.
    static let ui = Logger(subsystem: subsystem, category: "UI")
}

// MARK: - Console.app Filtering

/*

 To view logs in Console.app:
 1. Open Console.app, select your device or simulator
 2. Filter by: subsystem:tureluurtje.sisyphus
 3. Optionally add: category:Network / category:Auth / category:Words / category:UI

 Terminal streaming:
 log stream --predicate 'subsystem == "tureluurtje.sisyphus"' --level debug

 */
