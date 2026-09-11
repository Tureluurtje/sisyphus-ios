//
//  SplashView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI
import OSLog

struct SplashView: View {

    let onFinished: (AppState) -> Void

    @State private var isActive = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .scaleEffect(isActive ? 1 : 0.6)
                .opacity(isActive ? 1 : 0)

            Text("Loading")
            ProgressView()
        }
        .onAppear {
            withAnimation(reduceMotion ? .linear(duration: 0.15) : .spring(duration: 0.8)) {
                isActive = true
            }
        }
        .task {
            let serverActive = await pingServer()
            if serverActive {
                await checkAuthentication()
            }
            // TODO: Load words in
        }
    }

    private func pingServer() async -> Bool {
        do {
            let serverActive: Bool = try await pingServerService()

            if !serverActive {
                AppLogger.network.warning("Server ping reported unhealthy")
                await MainActor.run {
                    onFinished(.serverError)
                }
            }

            return serverActive

        } catch {
            AppLogger.network.error("Server ping failed: \(error.localizedDescription, privacy: .public)")
            await MainActor.run {
                onFinished(.serverError)
            }
            return false
        }
    }
    
    private func checkAuthentication() async {
        do {
            try await refreshService()

            await MainActor.run {
                // Phase-first: a restored session doesn't mean onboarding was
                // ever finished (e.g. the user force-quit right after
                // registering, before answering the practice card).
                onFinished(.authenticated)
            }

        } catch AuthError.missingTokens {
            await MainActor.run {
                onFinished(.unauthenticated)
            }

        } catch {
            AppLogger.auth.error("Authentication check failed: \(error.localizedDescription, privacy: .public)")

            await MainActor.run {
                onFinished(.unauthenticated)
            }
        }
    }
}


struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onFinished: { _ in })
    }
}
