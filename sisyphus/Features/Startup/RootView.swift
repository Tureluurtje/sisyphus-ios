//
//  RootView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI

struct RootView: View {
    @State private var state: AppState = .loading

    var body: some View {
        NavigationStack {
            switch state {
            case .loading:
                SplashView { state = $0 }
            case .serverError:
                ServerError()
            case .authenticated:
                HomeView(onFinished: { state = $0 })
            case .unauthenticated:
                LoginView(onAuthenticated: {
                    state = .authenticated
                })
            }
        }
        .id(state)
    }
}




#Preview {
    RootView()
}
