//
//  LeaderboardView.swift
//  sisyphus
//

import SwiftUI
import OSLog


struct LeaderboardUser: Identifiable {
    let id = UUID()
    let rank: Int
    let username: String
    let wordsLearned: Int
    let streak: Int
    let isCurrentUser: Bool
}


struct LeaderboardView: View {
    // Data
    private let users: [LeaderboardUser] = [
        LeaderboardUser(rank: 1,  username: "Marcus", wordsLearned: 184, streak: 12, isCurrentUser: false),
        LeaderboardUser(rank: 2,  username: "Julia",  wordsLearned: 167, streak: 9,  isCurrentUser: false),
        LeaderboardUser(rank: 3,  username: "Sofia",  wordsLearned: 158, streak: 21, isCurrentUser: false),
        LeaderboardUser(rank: 4,  username: "Diego",  wordsLearned: 142, streak: 7,  isCurrentUser: false),
        LeaderboardUser(rank: 5,  username: "You",    wordsLearned: 138, streak: 15, isCurrentUser: true),
        LeaderboardUser(rank: 6,  username: "Amara",  wordsLearned: 135, streak: 4,  isCurrentUser: false),
        LeaderboardUser(rank: 7,  username: "Kenji",  wordsLearned: 128, streak: 6,  isCurrentUser: false),
        LeaderboardUser(rank: 8,  username: "Priya",  wordsLearned: 119, streak: 11, isCurrentUser: false),
        LeaderboardUser(rank: 9,  username: "Liam",   wordsLearned: 112, streak: 8,  isCurrentUser: false),
        LeaderboardUser(rank: 10, username: "Nadia",  wordsLearned: 104, streak: 3,  isCurrentUser: false),
        LeaderboardUser(rank: 11, username: "Omar",   wordsLearned: 97,  streak: 5,  isCurrentUser: false),
        LeaderboardUser(rank: 12, username: "Elena",  wordsLearned: 91,  streak: 10, isCurrentUser: false),
        LeaderboardUser(rank: 13, username: "Tomas",  wordsLearned: 85,  streak: 2,  isCurrentUser: false),
        LeaderboardUser(rank: 14, username: "Yuki",   wordsLearned: 78,  streak: 6,  isCurrentUser: false),
        LeaderboardUser(rank: 15, username: "Zara",   wordsLearned: 72,  streak: 4,  isCurrentUser: false)
    ]

    private var first: LeaderboardUser { users[0] }
    private var second: LeaderboardUser { users[1] }
    private var third: LeaderboardUser { users[2] }
    private var remaining: [LeaderboardUser] { Array(users.dropFirst(3)) }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                podium
                listSection
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Leaderboard")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .onAppear {
            AppLogger.ui.info("Leaderboard viewed")
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOP LEARNERS")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)

            Text("This week")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: Podium
    private var podium: some View {
        HStack(alignment: .bottom, spacing: 12) {
            PodiumColumn(user: second, place: 2)
            PodiumColumn(user: first, place: 1)
            PodiumColumn(user: third, place: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: List
    private var listSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(remaining.enumerated()), id: \.element.id) { index, user in
                LeaderboardRow(user: user)

                if index < remaining.count - 1 {
                    Divider()
                        .padding(.leading, 66)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}


// MARK: - Podium Column

struct PodiumColumn: View {
    let user: LeaderboardUser
    let place: Int

    private var avatarSize: CGFloat {
        place == 1 ? 76 : 60
    }

    private var pedestalHeight: CGFloat {
        place == 1 ? 68 : (place == 2 ? 48 : 38)
    }

    private var placeColor: Color {
        switch place {
        case 1:  return Color(red: 0.82, green: 0.62, blue: 0.18)
        case 2:  return Color(red: 0.55, green: 0.58, blue: 0.63)
        default: return Color(red: 0.72, green: 0.45, blue: 0.20)
        }
    }

    private var initials: String {
        let parts = user.username.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        VStack(spacing: 8) {
            // Crown slot (keeps columns visually aligned)
            Group {
                if place == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.82, green: 0.62, blue: 0.18))
                }
            }
            .frame(height: 20)

            ZStack {
                Circle()
                    .fill(Color(UIColor.tertiarySystemGroupedBackground))

                Text(initials)
                    .font(.system(size: avatarSize * 0.36, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
            }
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Circle().stroke(placeColor, lineWidth: place == 1 ? 3 : 2)
            )

            VStack(spacing: 2) {
                Text(user.isCurrentUser ? "You" : user.username)
                    .font(.system(size: place == 1 ? 15 : 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(user.wordsLearned)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundColor(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(placeColor.opacity(0.15))

                Text("\(place)")
                    .font(.system(size: place == 1 ? 24 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(placeColor)
            }
            .frame(height: pedestalHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let user: LeaderboardUser

    private var initials: String {
        let parts = user.username.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            Text("\(user.rank)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 22, alignment: .leading)

            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 1, height: 28)

            ZStack {
                Circle()
                    .fill(Color(UIColor.tertiarySystemGroupedBackground))

                Text(initials)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
            }
            .frame(width: 36, height: 36)
            .overlay(
                Circle().stroke(
                    user.isCurrentUser ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(user.isCurrentUser ? "You" : user.username)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(user.isCurrentUser ? .accentColor : .primary)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)

                    Text("\(user.streak) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(user.wordsLearned)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.primary)

                Text("words")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            user.isCurrentUser
                ? Color.accentColor.opacity(0.08)
                : Color.clear
        )
    }
}


struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LeaderboardView()
        }
    }
}
