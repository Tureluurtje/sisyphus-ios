import Foundation

/// The onboarding flow's phase model.
///
/// This app's value moment — flipping a Latin flashcard and marking it right
/// or wrong — is reached through a single guaranteed-available demo card
/// ("deus" -> "god"), not the user's real due words. That decouples the value
/// moment from backend state entirely: unlike a typical ready-now/later split,
/// every new user reaches it instantly, regardless of whether their grade's
/// real word list has loaded on the server yet. Whether real words are ready
/// is something the app's existing Home flow already checks and handles
/// (`HomeView`'s `.wordListUnavailable` state) once onboarding hands off.
enum OnboardingPhase: Equatable {
    /// Screen 1 and the value moment itself.
    case practiceCard
    case completed
}
