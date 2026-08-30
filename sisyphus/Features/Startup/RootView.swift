//
//  RootView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI

struct RootView: View {
    @State private var state: AppState = .loading
    @State private var onboardingStore = OnboardingStore()

    var body: some View {
        NavigationStack {
            switch state {
            case .loading:
                SplashView { state = $0 }
            case .serverError:
                ServerError()
            case .onboarding:
                OnboardingRootView(store: onboardingStore, onFinished: { state = .authenticated })
            case .authenticated:
                HomeView(onFinished: { state = $0 })
            case .unauthenticated:
                LoginView(onAuthenticated: {
                    state = OnboardingStore.hasCompletedOnboarding ? .authenticated : .onboarding
                })
            }
        }
        .id(state)
    }
}




#Preview {
    RootView()
}
