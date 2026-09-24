import SwiftUI
import OSLog

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingXPInfo = false
    @State private var entries: [LeaderboardEntry]
    @State private var currentEntry: LeaderboardEntry?
    @State private var isLoading: Bool
    @State private var errorMessage: String?
    private let isPreview: Bool

    init(
        previewEntries: [LeaderboardEntry] = [],
        previewCurrentEntry: LeaderboardEntry? = nil,
        previewLoading: Bool = true,
        isPreview: Bool = false
    ) {
        _entries = State(initialValue: previewEntries)
        _currentEntry = State(initialValue: previewCurrentEntry)
        _isLoading = State(initialValue: previewLoading)
        _errorMessage = State(initialValue: nil)
        self.isPreview = isPreview
    }

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
            if !isPreview {
                await loadLeaderboard(showLoading: true)
            }
        }
        .refreshable {
            await loadLeaderboard(showLoading: false)
        }
        .sheet(isPresented: $showingXPInfo) {
            XPInfoView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CERTAMEN")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)

                Text("Leaderboard")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))

                Text("Leaderboard for this year.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showingXPInfo = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
            }
        }
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

struct XPInfoView: View {
    @Environment(\.dismiss) private var dismiss

    private struct XPItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private let items: [XPItem] = [
        XPItem(
            icon: "checkmark.seal.fill",
            title: "Complete a review",
            detail: "Xp determents your place on the leaderboard."
        ),
        XPItem(
            icon: "target",
            title: "Accuracy matters",
            detail: "A word in stack 1 earns 1 XP, stack 2 earns 2, and so on up to stack 5. The better you know a word, the more it's worth."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("XP, or *experientia*, measures how much you've practiced. The more you review and the higher you get your words in the stacks, the faster you climb the leaderboard.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            HStack{
                                row(item)
                                
                                if item.id != items.last?.id {
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("How XP works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ item: XPItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))

                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    let currentUserId = UUID()

    let entries = [
        LeaderboardEntry(
            userId: UUID(),
            rank: 1,
            username: "Marcus Aurelius",
            xp: 2840
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 2,
            username: "Julia Felix",
            xp: 2510
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 3,
            username: "Gaius Maximus",
            xp: 2290
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 4,
            username: "Lucius",
            xp: 1985
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 5,
            username: "Claudia",
            xp: 1760
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 6,
            username: "Quintus",
            xp: 1595
        ),
        LeaderboardEntry(
            userId: currentUserId,
            rank: 7,
            username: "Cornelia",
            xp: 1430
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 8,
            username: "Titus",
            xp: 1280
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 9,
            username: "Octavia",
            xp: 1145
        ),
        LeaderboardEntry(
            userId: UUID(),
            rank: 10,
            username: "Publius",
            xp: 990
        )
    ]

    NavigationStack {
        LeaderboardView(
            previewEntries: entries,
            previewCurrentEntry: entries.first { $0.userId == currentUserId },
            previewLoading: false,
            isPreview: true
        )
    }
}


#Preview("XP Info") {
    XPInfoView()
}

#Preview("Leaderboard – XP sheet open") {
    // Manual preview: just render the sheet's content directly,
    // or add a `previewShowingXPInfo` flag to LeaderboardView if you
    // want the sheet open in the composite preview.
    NavigationStack {
        LeaderboardView(
            previewEntries: [],
            previewLoading: false,
            isPreview: true
        )
    }
}
