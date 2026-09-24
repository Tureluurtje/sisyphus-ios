import Foundation
import StoreKit
import UIKit

enum AppReviewManager {
    private static let launchCountKey = "appLaunchCount"
    private static let lastPromptDateKey = "lastReviewPromptDate"
    private static let minimumLaunches = 5
    private static let promptCooldown: TimeInterval = 90 * 24 * 60 * 60

    static var canShowRateButton: Bool {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: launchCountKey) >= minimumLaunches else { return false }

        guard let lastPromptDate = defaults.object(forKey: lastPromptDateKey) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastPromptDate) >= promptCooldown
    }

    static func recordLaunch() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: launchCountKey) + 1, forKey: launchCountKey)
    }

    static func requestReview() {
        guard canShowRateButton else { return }
        UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)

        DispatchQueue.main.async {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive })
            else { return }

            AppStore.requestReview(in: scene)
        }
    }
}
