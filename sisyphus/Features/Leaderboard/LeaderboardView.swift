import SwiftUI
import OSLog

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var entries: [LeaderboardEntry] = []
    @State private var currentEntry: LeaderboardEntry?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var orderedEntries: [LeaderboardEntry] {
        entries.sorted { $0.rank < $1.rank }
    }

    private var podiumEntries: [LeaderboardEntry] {
        Array(orderedEntries.prefix(3))
    }

    private var listEntries: [LeaderboardEntry] {
        var rows = Array(orderedEntries.dropFirst(3))

        if let currentEntry, !orderedEntries.contains(where: { $0.id == currentEntry.id }) {
            rows.append(currentEntry)
        }

        return rows.sorted { $0.rank < $1.rank }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                content
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
        .task {
            await loadLeaderboard(showLoading: true)
        }
        .refreshable {
            await loadLeaderboard(showLoading: false)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .padding(.vertical, 48)
        } else if let errorMessage {
            ContentUnavailableView {
                Label("Couldn't load leaderboard", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try again") {
                    Task {
                        await loadLeaderboard(showLoading: true)
                    }
                }
            }
            .padding(.vertical, 24)
        } else if orderedEntries.isEmpty {
            ContentUnavailableView(
                "No rankings yet",
                systemImage: "trophy",
                description: Text("Complete a review to appear on the leaderboard.")
            )
            .padding(.vertical, 24)
        } else {
            if podiumEntries.count == 3 {
                podium
            }

            listSection
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOP LEARNERS")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)

            Text("This year")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private var podium: some View {
        HStack(alignment: .bottom, spacing: 12) {
            PodiumColumn(user: podiumEntries[1], place: 2, isCurrentUser: isCurrentUser(podiumEntries[1]))
            PodiumColumn(user: podiumEntries[0], place: 1, isCurrentUser: isCurrentUser(podiumEntries[0]))
            PodiumColumn(user: podiumEntries[2], place: 3, isCurrentUser: isCurrentUser(podiumEntries[2]))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(cardBackground)
        .overlay(cardBorder)
        .padding(.horizontal, 20)
    }

    private var listSection: some View {
        VStack(spacing: 0) {
            ForEach(listEntries) { entry in
                LeaderboardRow(
                    user: entry,
                    isCurrentUser: isCurrentUser(entry)
                )

                if entry.id != listEntries.last?.id {
                    Divider()
                        .padding(.leading, 66)
                }
            }
        }
        .background(cardBackground)
        .overlay(cardBorder)
        .padding(.horizontal, 20)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(UIColor.secondarySystemGroupedBackground))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
    }

    private func isCurrentUser(_ entry: LeaderboardEntry) -> Bool {
        entry.id == currentEntry?.id
    }

    @MainActor
    private func loadLeaderboard(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil

        do {
            async let fetchedEntries = getLeaderboardService()
            async let fetchedCurrentEntry = getCurrentLeaderboardEntryService()

            entries = try await fetchedEntries
            currentEntry = try await fetchedCurrentEntry
            AppLogger.ui.info("Leaderboard loaded")
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.ui.error("Leaderboard failed to load: \(error.localizedDescription, privacy: .public)")
        }

        isLoading = false
    }
}

private struct PodiumColumn: View {
    let user: LeaderboardEntry
    let place: Int
    let isCurrentUser: Bool

    private var avatarSize: CGFloat {
        place == 1 ? 76 : 60
    }

    private var pedestalHeight: CGFloat {
        place == 1 ? 68 : (place == 2 ? 48 : 38)
    }

    private var placeColor: Color {
        switch place {
        case 1:
            return Color(red: 0.82, green: 0.62, blue: 0.18)
        case 2:
            return Color(red: 0.55, green: 0.58, blue: 0.63)
        default:
            return Color(red: 0.72, green: 0.45, blue: 0.20)
        }
    }

    private var initials: String {
        let letters = user.username
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        return String(letters).uppercased()
    }

    var body: some View {
        VStack(spacing: 8) {
            Group {
                if place == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(placeColor)
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
            .overlay {
                Circle().stroke(
                    isCurrentUser ? Color.accentColor : placeColor,
                    lineWidth: place == 1 ? 3 : 2
                )
            }

            VStack(spacing: 2) {
                Text(user.username)
                    .font(.system(size: place == 1 ? 15 : 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(user.xp) XP")
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

private struct LeaderboardRow: View {
    let user: LeaderboardEntry
    let isCurrentUser: Bool

    private var initials: String {
        let letters = user.username
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
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
            .overlay {
                Circle().stroke(
                    isCurrentUser ? Color.accentColor : .clear,
                    lineWidth: 2
                )
            }

            Text(user.username)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(isCurrentUser ? .accentColor : .primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(user.xp)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.primary)

                Text("XP")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            isCurrentUser
                ? Color.accentColor.opacity(0.08)
                : Color.clear
        )
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
