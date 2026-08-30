//
//  LeaderboardView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 13/06/2026.
//

import SwiftUI

struct LeaderboardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 92, height: 92)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)

                VStack(spacing: 10) {
                    Text("Leaderboard")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("The leaderboard is coming soon!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
        }
    }
}
