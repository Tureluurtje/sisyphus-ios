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
    @State private var showSkeleton = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if showSkeleton {
                NavigationStack {
                    HomeSkeleton()
                }
                .transition(.opacity)
            } else {
                brandedSplash
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.4), value: showSkeleton)
        .task {
            if let requirement = await AppUpdateService.checkForRequiredUpdate() {
                onFinished(.updateRequired(requirement))
                return
            }

            let serverActive = await pingServer()
            if serverActive {
                await checkAuthentication()
            }
            // TODO: Load words in
        }
    }

    // MARK: - Branded splash

    private var brandedSplash: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(
                reduceMotion
                    ? .linear(duration: 0.15)
                    : .spring(duration: 0.8).delay(0.1)
            ) {
                isActive = true
            }
        }
    }

    // MARK: - Networking

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

            // Auth succeeded — we know we're going to HomeView, so it's safe
            // to swap the branded splash for the Home skeleton. RootView's
            // transition will carry this straight into HomeView's own
            // skeleton, so there's no visible gap.
            await MainActor.run {
                showSkeleton = true
            }

            // Brief hold so the crossfade actually reads before we hand off.
            try? await Task.sleep(for: .milliseconds(180))

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
