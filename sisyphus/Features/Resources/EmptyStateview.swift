//
//  EmptyStateview.swift
//  sisyphus
//
//  Created by Arthur Kwak on 17/06/2026.
//

import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: String = "home"

    // MARK: - Content
    let icon: String
    let title: String
    let message: String

    // MARK: - Appearance
    var iconColor: Color = .primary
    /// `nil` (the default) adapts to `colorScheme` via `DecorativeBackground`.
    /// Pass an explicit array only if a specific caller needs to override it.
    var gradientColors: [Color]? = nil
    var accentBlobColor: Color = .accentColor
    var secondaryBlobColor: Color = .orange

    // MARK: - Actions
    /// Label shown on the retry button. Only used if `onRetry` is non-nil.
    var retryLabel: String = "Try again"
    var retryIcon: String = "arrow.clockwise"
    var onRetry: (() -> Void)? = nil

    // MARK: - Tab bar shell
    /// Whether to wrap the empty state in the app's tab bar (Home / Leaderboard / Profile).
    /// Set to `false` to show just the empty state content on its own, e.g. when this
    /// view is pushed onto an existing NavigationStack or shown modally.
    var showTabBar: Bool = true

    // MARK: - Dependencies (tab bar shell)
    /// Only required when `showTabBar` is `true`.
    var userProfile: UserProfile? = nil
    var onFinished: (AppState) -> Void = { _ in }

    var body: some View {
        if showTabBar {
            NavBar(selected: $selectedTab) {
                NavigationStack {
                    emptyStateContent
                }
                .tag("home")
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                
                NavigationStack {
                    PracticeView()
                }
                .tag("practice")
                .tabItem {
                    Label("Practice", systemImage: "target")
                }

                NavigationStack {
                    LeaderboardView()
                }
                .tag("leaderboard")
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }

                NavigationStack {
                    ProfileView(userProfile: userProfile, onFinished: onFinished)
                }
                .tag("profile")
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
            }
        } else {
            emptyStateContent
        }
    }

    private var emptyStateContent: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors ?? DecorativeBackground.gradientColors(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(accentBlobColor.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -120, y: -220)

            Circle()
                .fill(secondaryBlobColor.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 150, y: 180)

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 92, height: 92)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)

                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)

                if let onRetry {
                    Button(action: onRetry) {
                        Label(retryLabel, systemImage: retryIcon)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 360)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Previews

#Preview("With retry, with tab bar") {
    EmptyStateView(
        icon: "tray.full.fill",
        title: "Word list not loaded yet",
        message: "The word list for this grade isn't loaded in yet. Please try again later.",
        onRetry: {}
    )
}

#Preview("Without retry, with tab bar") {
    EmptyStateView(
        icon: "wifi.slash",
        title: "No connection",
        message: "Check your internet connection and try again later."
    )
}

#Preview("Custom colors, no retry") {
    EmptyStateView(
        icon: "checkmark.seal.fill",
        title: "All caught up",
        message: "You've completed every lesson in this chapter.",
        iconColor: .green,
        accentBlobColor: .green,
        secondaryBlobColor: .mint
    )
}

#Preview("No tab bar (pushed/modal use)") {
    NavigationStack {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            title: "Something went wrong",
            message: "We couldn't load this lesson. Please try again.",
            iconColor: .red,
            accentBlobColor: .red,
            onRetry: {},
            showTabBar: false
        )
    }
}
