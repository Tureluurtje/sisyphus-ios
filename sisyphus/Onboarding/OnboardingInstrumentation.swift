import Foundation
import OSLog

/// Local-only value-moment reach-rate markers — no analytics SDK required.
///
/// Every write is idempotent (first stamp wins) so a re-entrant path (e.g. the
/// user backgrounds the app between screens) never overwrites a real
/// timestamp with a later, less meaningful one. Wire these into a real
/// analytics provider if one is ever added to the project.
enum OnboardingInstrumentation {
    private static let startedAtKey = "onboarding.startedAt"
    private static let valueMomentAtKey = "onboarding.valueMomentAt"
    private static let completedAtKey = "onboarding.completedAt"

    static func markStarted(now: Date = .now, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: startedAtKey) == nil else { return }
        defaults.set(now, forKey: startedAtKey)
        AppLogger.ui.notice("Onboarding started")
    }

    static func markValueMomentReached(now: Date = .now, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: valueMomentAtKey) == nil else { return }
        defaults.set(now, forKey: valueMomentAtKey)

        if let startedAt = defaults.object(forKey: startedAtKey) as? Date {
            let seconds = now.timeIntervalSince(startedAt)
            AppLogger.ui.notice("Onboarding value moment reached in \(seconds, format: .fixed(precision: 1), privacy: .public)s")
        } else {
            AppLogger.ui.notice("Onboarding value moment reached")
        }
    }

    static func markCompleted(now: Date = .now, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: completedAtKey) == nil else { return }
        defaults.set(now, forKey: completedAtKey)
        AppLogger.ui.notice("Onboarding completed")
    }

    /// Clears all markers. Call alongside resetting the completion flag when
    /// re-testing onboarding from a debug menu.
    static func resetForTesting(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: startedAtKey)
        defaults.removeObject(forKey: valueMomentAtKey)
        defaults.removeObject(forKey: completedAtKey)
    }
}
