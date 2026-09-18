//
//  RootView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI

struct RootView: View {
    @State private var state: AppState = .loading
    @State private var refreshID = UUID()

    var body: some View {
        NavigationStack {
            switch state {
            case .loading:
                SplashView { state = $0 }
            case .serverError:
                ServerError()
            case .authenticated:
                HomeView(
                    onFinished: { state = $0 },
                    onRequestRefresh: {
                        // Changing this forces SwiftUI to rebuild everything below,
                        // which is the "app refresh" we want after a grade change.
                        refreshID = UUID()
                    }
                )
            case .unauthenticated:
                LoginView(onAuthenticated: {
                    state = .authenticated
                })
            }
        }
        .id(refreshID)
    }
}

#Preview {
    RootView()
}
