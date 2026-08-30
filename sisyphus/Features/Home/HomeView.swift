//
//  HomeView.swift
//  sisyphus
//

import SwiftUI
import OSLog

struct HomeView: View {
    // MARK: Data retrieval logic
    @EnvironmentObject private var errorManager: ErrorManager
    let onFinished: (AppState) -> Void
    
    @State private var stacks: GetAllStacksResponse?

    @State private var dueWords: DueWordsResponse?
    
    @State private var userProfile: UserProfile?

    var totalDue: Int {
        dueWords?.wordAmount ?? 0
    }

    var totalDueWordAmount: Int {
        stacks?.wordAmount ?? 0
    }

    // TODO: Make this work with total words to learn "this" year
    var learned: Int { max(totalDueWordAmount - totalDue, 0) }

    private var wordOfTheDay: DueWord { getWordOfTheDay(dueWords: dueWords) }

    // MARK: Navigation
    @State private var selectedTab: String = "home"
    @State private var loadState: HomeLoadState = .loading

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                loadingView
            case .content:
                navContent
            case .wordListUnavailable:
                //EmptyStateView(
                
                
                WordlistNotLoadedView(
                    userProfile: userProfile,
                    onRetry: {
                        Task {
                            await loadHomeData()
                        }
                    },
                    onFinished: onFinished
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadHomeData()
        }
    }

    private enum HomeLoadState {
        case loading
        case content
        case wordListUnavailable
    }

    private var navContent: some View {
        NavBar(selected: $selectedTab) {
            NavigationStack {
                homePage
            }
            .tag("home")
            .tabItem {
                Label("Home", systemImage: "house.fill")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
    }

    private var loadingView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.1)

                Text("Loading your dashboard")
                    .font(.headline)

                Text("Fetching due words, stacks, and profile data.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
    }

    // MARK: Helpers

    /// Fraction of this stack's words that are no longer due. `s.wordAmount`
    /// is the stack's total word count; `s.words` are its currently-due
    /// words, so a stack with nothing left due is fully complete (1.0).
    private func progress(for s: Stack) -> Double {
        guard s.wordAmount > 0 else { return 0 }
        let rawProgress = Double(s.wordAmount) / Double(totalDueWordAmount)
        return (rawProgress * 100.0).rounded() / 100.0
    }

    private func pctText(for s: Stack) -> String {
        "\(Int((progress(for: s) * 100).rounded()))%"
    }

    private func getWordOfTheDay(dueWords: DueWordsResponse?) -> DueWord {
        guard let word = dueWords?.words.last else {
            return DueWord(
                wordId: UUID(),
                chapterId: UUID(),
                word: "Finis!",
                translation: "Gefeliciteerd! Je bent klaar!"
            )
        }
        return word
    }

    // MARK: Body
    private var homePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                heroSection
                ctaCard
                statsRow
                stacksSection
            }
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("LatiLearn")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Home")
    }

    // MARK: Hero
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VERBUM DIEI")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)

            Text(wordOfTheDay.word.capitalized)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(wordOfTheDay.translation)
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    
    // MARK: CTA Card

    private var ctaCard: some View {
        Group {
            if totalDue > 0 {
                NavigationLink(
                    destination: LearnView(
                        dueWords: dueWords?.words ?? [],
                        stack: nil
                    )
                ) {
                    ctaCardContent
                }
                .buttonStyle(.plain)
            } else {
                ctaCardContent
            }
        }
        .padding(.horizontal, 20)
    }

    private var ctaCardContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's session")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                    .tracking(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(totalDue)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text(totalDue == 1 ? "word due" : "words due")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if totalDue > 0 {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)

                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 52, height: 52)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
    }


    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(userProfile.map { String($0.streak) } ?? "?")", label: "Streak", icon: "flame.fill", tint: .orange)
            statCard(value: "\(userProfile.map { String($0.totalWordsLearned) } ?? "?")", label: "Learned", icon: "checkmark.seal.fill", tint: .green)
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(.callout, weight: .semibold))
                .foregroundColor(tint)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: Stacks
    private var stacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stacks")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                    .tracking(0.8)

                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(stacks?.stacks.filter { $0.id != 0 } ?? []) { s in
                    if s.words.count > 0 {
                        NavigationLink(
                            destination: LearnView(
                                dueWords: s.words,
                                stack: s
                            )
                        ) {
                            stackRow(for: s)
                        }
                        .buttonStyle(.plain)
                    } else {
                        stackRow(for: s)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }


    private func stackRow(for s: Stack) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Stack \(s.id)")
                    .font(.system(.title3, design: .serif, weight: .medium))

                HStack(spacing: 6) {
                    Text("\(s.words.count) due")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(pctText(for: s))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.secondary)

                let value = progress(for: s)

                ProgressView(value: value)
                    .frame(width: 60)
                    .tint(.accentColor)
            }

            if s.words.count > 0 {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.secondary.opacity(0.4))
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }


    @MainActor
    private func loadHomeData() async {
        loadState = .loading

        do {
            async let fetchedDueWords = getDueWordsService(limit: nil, offset: nil)
            async let fetchedStacks = getStacksService()
            async let fetchedUserProfile = getUserProfileService()

            let loadedStacks = try await fetchedStacks
            let loadedUserProfile = try await fetchedUserProfile

            stacks = loadedStacks
            userProfile = loadedUserProfile
            dueWords = try await fetchedDueWords // fire dueWords last so the userProfile gets loaded and gets passed to WordListNotLoadedView

            AppLogger.ui.info("Home data loaded successfully")
            loadState = .content
        } catch let error as APIClientError {
            switch error {
            case .emptyResponse(let statusCode) where statusCode == 204:
                AppLogger.ui.notice("Home data load found no word list loaded for this grade yet")
                loadState = .wordListUnavailable
            default:
                AppLogger.ui.error("Home data load failed: \(error.localizedDescription, privacy: .public)")
                errorManager.show(error.localizedDescription)
                loadState = .content
            }
        } catch {
            AppLogger.ui.error("Home data load failed: \(error.localizedDescription, privacy: .public)")
            errorManager.show(error.localizedDescription)
            loadState = .content
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView(onFinished: { _ in })
        }
        .environmentObject(ErrorManager())
    }
}
