import SwiftUI

/// Shared background gradient for full-screen decorative/placeholder states
/// (Leaderboard, "word list not loaded", the generic `EmptyStateView`).
/// Previously each screen hardcoded the same light pastel RGB values, which
/// ignored Dark Mode entirely — this adapts to `colorScheme` instead.
enum DecorativeBackground {
    static func gradientColors(for colorScheme: ColorScheme) -> [Color] {
        switch colorScheme {
        case .dark:
            return [
                Color(red: 0.07, green: 0.08, blue: 0.11),
                Color(red: 0.05, green: 0.06, blue: 0.09),
                Color(red: 0.09, green: 0.08, blue: 0.08)
            ]
        default:
            return [
                Color(red: 0.95, green: 0.96, blue: 0.99),
                Color(red: 0.89, green: 0.92, blue: 0.98),
                Color(red: 0.98, green: 0.97, blue: 0.95)
            ]
        }
    }
}
