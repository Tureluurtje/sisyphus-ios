import Foundation

/// Plain @Observable coordinator for onboarding's business state.
/// Owns the phase and the completion flag; owns no navigation/routing —
/// `RootView` decides what happens after `onFinished()` fires.
@Observable
final class OnboardingStore {

    private static let completedKey = "hasCompletedOnboarding"

    /// Durable, device-local flag. Survives relaunch; resets on reinstall
    /// (same as every UserDefaults-backed flag), which is expected —
    /// onboarding is meant to replay on a fresh install.
    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    /// The value moment: a single guaranteed-available demo flashcard, so
    /// every new user can reach it instantly regardless of whether their
    /// grade's real word list has loaded on the backend yet.
    static let demoWord = DueWord(
        wordId: UUID(),
        chapterId: UUID(),
        word: "deus",
        translation: "god"
    )

    private(set) var phase: OnboardingPhase = .practiceCard

    init() {
        OnboardingInstrumentation.markStarted()
    }

    /// Called once the demo card has been answered.
    func complete() {
        OnboardingInstrumentation.markValueMomentReached()
        OnboardingInstrumentation.markCompleted()
        Self.hasCompletedOnboarding = true
        phase = .completed
    }
}
