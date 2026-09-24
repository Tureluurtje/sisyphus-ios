//
//  PracticeView.swift
//  sisyphus
//

import SwiftUI

struct PracticeView: View {

    // MARK: - Loaded data
    @State private var difficultWords: [DueWord] = []
    @State private var difficultWordAmount: Int = 0
    @State private var isLoadingDifficult: Bool = true
    @State private var difficultError: String?

    // MARK: - Demo data (no endpoint yet)
    private var irregularVerbs: [DueWord] {
        [
            DueWord(wordId: UUID(), chapterId: UUID(), word: "sum", translation: "to be"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "possum", translation: "to be able"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "eo", translation: "to go"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "fero", translation: "to carry, bear"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "volo", translation: "to want, wish"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "nolo", translation: "to not want, be unwilling"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "malo", translation: "to prefer"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "fio", translation: "to become, be made"),
        ]
    }

    private var testPool: [DueWord] {
        difficultWords + irregularVerbs
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                difficultSection
                irregularCard
                testCard
            }
            .padding(.bottom, 32)
            .animation(.smooth(duration: 0.3), value: isLoadingDifficult)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if difficultWords.isEmpty && difficultError == nil {
                await loadDifficultWords()
            }
        }
    }

    // MARK: - Difficult words section (load / error / loaded)

    @ViewBuilder
    private var difficultSection: some View {
        if isLoadingDifficult {
            PracticeStatusCard(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "Difficult Words",
                subtitle: "Loading words you've been getting wrong…",
                state: .loading
            )
            .padding(.horizontal, 20)

        } else if let difficultError {
            PracticeStatusCard(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "Difficult Words",
                subtitle: difficultError,
                state: .error(actionTitle: "Try again") {
                    Task { await loadDifficultWords() }
                }
            )
            .padding(.horizontal, 20)

        } else if difficultWords.isEmpty {
            PracticeStatusCard(
                icon: "checkmark.seal.fill",
                tint: .green,
                title: "Difficult Words",
                subtitle: "You're all caught up — nothing flagged as difficult right now.",
                state: .empty
            )
            .padding(.horizontal, 20)

        } else {
            practiceCard(
                title: "Difficult Words",
                subtitle: "Words you've been getting wrong most often",
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                words: difficultWords,
                destination: LearnView(
                    dueWords: difficultWords,
                    stack: nil,
                    reviewEndpoint: .difficult
                )
            )
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EXERCITATIO")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)

            Text("Sharpen your Latin")
                .font(.system(.title, design: .serif, weight: .semibold))
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Irregular verbs card
    private var irregularCard: some View {
        practiceCard(
            title: "Irregular Verbs",
            subtitle: "sum, possum, eo, fero, and friends",
            icon: "bolt.fill",
            tint: .purple,
            words: irregularVerbs,
            destination: LearnView(dueWords: irregularVerbs, stack: nil),
            comingSoon: true
        )
    }

    // MARK: Test mode card
    private var testCard: some View {
        NavigationLink(destination: TestView(words: testPool)) {
            PracticeCardShell(
                icon: "checklist",
                tint: .accentColor,
                title: "Test Mode",
                subtitle: "Simulates a real test — no hints, score revealed at the end",
                count: testPool.count,
                previewWords: [],
                emphasized: true,
                comingSoon: true
            )
        }
        .buttonStyle(.microInteraction)
        .disabled(true)
        .padding(.horizontal, 20)
    }

    // MARK: Practice card
    private func practiceCard(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        words: [DueWord],
        destination: some View,
        comingSoon: Bool = false
    ) -> some View {
        NavigationLink(destination: destination) {
            PracticeCardShell(
                icon: icon,
                tint: tint,
                title: title,
                subtitle: subtitle,
                count: words.count,
                previewWords: Array(words.prefix(3)),
                comingSoon: comingSoon
            )
        }
        .buttonStyle(.microInteraction)
        .disabled(comingSoon)
        .padding(.horizontal, 20)
    }

    // MARK: - Loading
    @MainActor
    private func loadDifficultWords() async {
        isLoadingDifficult = true
        difficultError = nil

        do {
            let response = try await fetchDifficultWordsService()
            difficultWords = response.words
            difficultWordAmount = response.wordAmount
        } catch let error as AuthError {
            difficultError = error.userFacingMessage
        } catch {
            difficultError = error.localizedDescription
        }

        isLoadingDifficult = false
    }
}

// MARK: - Card Shell

private struct PracticeCardShell: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let count: Int
    let previewWords: [DueWord]
    var emphasized: Bool = false
    var comingSoon: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            topRow

            if !previewWords.isEmpty {
                Divider()
                    .padding(.leading, 16)

                wordPreview
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    emphasized ? Color.accentColor.opacity(0.4) : tint.opacity(0.15),
                    lineWidth: emphasized ? 1.5 : 1
                )
        )
        .overlay {
            if comingSoon {
                ComingSoonOverlay()
            }
        }
    }

    // MARK: Top row
    private var topRow: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tint)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if count > 0 {
                    Text("\(count) words")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(tint)
                        .padding(.top, 2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.secondary.opacity(0.4))
                .accessibilityHidden(true)
        }
        .padding(16)
    }

    // MARK: Word preview
    private var wordPreview: some View {
        VStack(spacing: 0) {
            ForEach(Array(previewWords.enumerated()), id: \.element.wordId) { index, word in
                HStack(spacing: 10) {
                    Text(word.word)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(word.translation)
                        .font(.system(.caption))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if index < previewWords.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }

            if count > previewWords.count {
                Divider()
                    .padding(.leading, 16)

                Text("+\(count - previewWords.count) more")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
    }
}

// MARK: - Status Card (loading / error / empty)

private struct PracticeStatusCard: View {

    enum State {
        case loading
        case error(actionTitle: String, action: () -> Void)
        case empty
    }

    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let state: State

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tint)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                switch state {
                case .loading:
                    ProgressView()
                        .controlSize(.mini)
                        .padding(.top, 4)

                case .error(let actionTitle, let action):
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.microInteraction)
                    .padding(.top, 4)

                case .empty:
                    EmptyView()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Coming Soon Overlay

private struct ComingSoonOverlay: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            VStack(spacing: 8) {
                Image(systemName: "hourglass")
                    .font(.system(size: 24, weight: .semibold))
                Text("Coming Soon")
                    .font(.headline)
            }
            .foregroundStyle(.secondary)
        }
        .allowsHitTesting(false)
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PracticeView()
        }
    }
}
