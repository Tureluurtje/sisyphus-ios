// WordlistNotLoadedView

import SwiftUI

struct WordlistNotLoadedView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: String = "home"

    let userProfile: UserProfile?
    let onRetry: () -> Void
    let onFinished: (AppState) -> Void

    var body: some View {
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
    }

    private var emptyStateContent: some View {
        ZStack {
            LinearGradient(
                colors: DecorativeBackground.gradientColors(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.accentColor.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -120, y: -220)

            Circle()
                .fill(Color.orange.opacity(0.12))
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

                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)

                VStack(spacing: 10) {
                    Text("Word list not loaded yet")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("The word list for this grade isn't loaded in yet. Please try again later.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)

                Button(action: onRetry) {
                    Label("Try again", systemImage: "arrow.clockwise")
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
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    WordlistNotLoadedView(userProfile: nil, onRetry: {}, onFinished: { _ in })
}
