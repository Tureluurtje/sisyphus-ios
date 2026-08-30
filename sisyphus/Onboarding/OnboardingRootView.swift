import SwiftUI

/// The root-swap target for onboarding (see `RootView`). Never a pushed
/// destination and owns no `NavigationStack` of its own at this level — the
/// one screen it shows wraps its own, matching how every other tab-root
/// screen in this app (see `HomeView`) owns its local stack.
struct OnboardingRootView: View {
    let store: OnboardingStore
    let onFinished: () -> Void

    var body: some View {
        switch store.phase {
        case .practiceCard:
            NavigationStack {
                LearnView(
                    dueWords: [OnboardingStore.demoWord],
                    stack: nil,
                    isPracticeMode: true,
                    showBackButton: false,
                    title: "Welcome",
                    onComplete: {
                        store.complete()
                        onFinished()
                    }
                )
            }

        case .completed:
            // RootView swaps this view out the moment onFinished() fires,
            // so this case is never actually rendered.
            EmptyView()
        }
    }
}

#Preview {
    OnboardingRootView(store: OnboardingStore(), onFinished: {})
        .environmentObject(ErrorManager())
}
