//
//  LearnView.swift
//  sisyphus
//

import SwiftUI
import SwiftData
import OSLog

// MARK: - Which endpoint reviews get submitted to

enum ReviewEndpoint {
    /// POST /api/words/review — the default for due-word and stack sessions.
    case standard

    /// POST /api/words/difficult/review — used by the Practice tab's
    /// "Difficult Words" card so its results feed the difficult-word model.
    case difficult
}


struct LearnView: View {
    @EnvironmentObject var errorManager: ErrorManager

    // Word logic
    let dueWords: [DueWord]

    // Possible stack for stack name etc.
    let stack: Stack?

    // Reuse hooks for onboarding's practice-card value moment (see Onboarding/).
    // Defaults preserve existing behavior for every other call site.
    var isPracticeMode: Bool = false
    var showBackButton: Bool = true
    var title: String? = nil
    var onComplete: (() -> Void)? = nil

    /// Where reviews should be submitted. Defaults to the standard endpoint
    /// so nothing else in the app has to change.
    var reviewEndpoint: ReviewEndpoint = .standard


    // UI
    @State private var inReview = false
    @State private var reviewWords: [DueWord] = []
    @State private var locallyRepeatedWordIDs: Set<UUID> = []
    @State private var currentIndex = 0
    @State private var showingFront = true

    @State private var correctCount = 0
    @State private var incorrectCount = 0

    @State private var dragOffset: CGFloat = 0
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = 0

    @State private var transitionTask: Task<Void, Never>? = nil

    @AppStorage("repeatIncorrectWords") private var repeatIncorrectWords = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var totalCount: Int { dueWords.count }

    private var flipAnimation: Animation {
        reduceMotion ? .linear(duration: 0.1) : .easeInOut(duration: 0.2)
    }

    private var answerAnimation: Animation {
        reduceMotion ? .linear(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.8)
    }

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return min(Double(currentIndex) / Double(totalCount), 1)
    }

    private var sessionName: String {
        title ?? stack.map { "Stack \($0.id)" } ?? "Today's words"
    }

    private var sessionDescription: String {
        stack == nil
            ? "A focused review of the words waiting for you today."
            : "A focused review of the cards waiting in this stack."
    }

    var body: some View {
        Group {
            if inReview {
                reviewPage
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                startPage
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .animation(.smooth(duration: 0.3), value: inReview)
        .trackScreen(isPracticeMode ? "Onboarding Practice Card" : "Learn")
        .toolbar {
            if showBackButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        finishOrDismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                }
            }
        }
        .task {
            reviewWords = dueWords.shuffled()
            locallyRepeatedWordIDs = []
            currentIndex = 0
            showingFront = true
            correctCount = 0
            incorrectCount = 0
            // Practice mode (onboarding's single demo card) skips straight to
            // the card — real sessions show the "Ready to review" start page.
            inReview = isPracticeMode
        }
    }

    // MARK: Start Page
    private var startPage: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text(stack == nil ? "TODAY'S SESSION" : "STACK REVIEW")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                Text(sessionName)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))

                Text(sessionDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(dueWords.count)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(dueWords.count == 1 ? "word due" : "words due")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                sessionStep(number: "1", title: "Reveal", subtitle: "Tap a card")
                sessionStep(number: "2", title: "Answer", subtitle: "Swipe or choose")
            }
            .padding(.horizontal, 20)

            Spacer()

            Button {
                inReview = true
                Haptics.medium()
            } label: {
                HStack {
                    Text(dueWords.isEmpty ? "No cards due" : "Review \(dueWords.count) \(dueWords.count == 1 ? "card" : "cards")")
                        .font(.headline)
                    Image(systemName: dueWords.isEmpty ? "checkmark" : "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(dueWords.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func sessionStep(number: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Review Page
    private var reviewPage: some View {
        VStack(spacing: 20) {
            progressHeader

            if currentIndex < reviewWords.count {
                flashcard(for: reviewWords[currentIndex])
                    .padding(.horizontal, 20)

                Spacer()

                if !showingFront {
                    answerButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                } else {
                    Text("Tap the card to reveal the translation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 32)
                }
            } else {
                completionView
            }
        }
        .padding(.top, 12)
    }

    // MARK: Progress Header
    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(min(currentIndex + 1, totalCount)) of \(totalCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(correctCount)")
                            .font(.caption.weight(.semibold))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(incorrectCount)")
                            .font(.caption.weight(.semibold))
                    }
                }
                .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .tint(.accentColor)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Flashcard
    private func flashcard(for word: DueWord) -> some View {
        VStack(spacing: 16) {
            Spacer()

            if showingFront {
                Text("LATIN")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                Text(word.word)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
            } else {
                Text("TRANSLATION")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                Text(word.translation)
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
            }

            Spacer()

            if showingFront {
                Image(systemName: "hand.tap.fill")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
        .offset(x: dragOffset + cardOffset)
        .rotationEffect(.degrees(Double((dragOffset + cardOffset) / 20)))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showingFront ? "Latin word: \(word.word)" : "Translation: \(word.translation)")
        .accessibilityHint(showingFront ? "Double tap to reveal the translation" : "Double tap to hide the translation")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            withAnimation(flipAnimation) {
                showingFront.toggle()
            }
            Haptics.selection()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard !showingFront else { return }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    guard !showingFront else { return }

                    let shouldCompleteSwipe =
                        abs(value.translation.width) > abs(value.translation.height) &&
                        abs(value.translation.width) > 80

                    if shouldCompleteSwipe {
                        answerCard(isCorrect: value.translation.width > 0)
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    // MARK: Answer Buttons
    private var answerButtons: some View {
        HStack(spacing: 12) {
            Button {
                answerCard(isCorrect: false)
            } label: {
                HStack {
                    Image(systemName: "xmark")
                    Text("Wrong")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button {
                answerCard(isCorrect: true)
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Right")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    // MARK: Completion
    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            VStack(spacing: 6) {
                Text(totalCount > 0 && correctCount == totalCount ? "Veni, vidi, didici" : "Review complete")
                    .font(.system(.title, design: .serif, weight: .semibold))

                Text(
                    totalCount > 0 && correctCount == totalCount
                        ? "You conquered every card."
                        : "You finished all \(totalCount) cards."
                )
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                statPill(value: "\(correctCount)", label: "Right", tint: .green)
                statPill(value: "\(incorrectCount)", label: "Wrong", tint: .red)
            }
            .padding(.top, 8)

            Spacer()

            Button {
                finishOrDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 20)
        .onAppear {
            AppLogger.ui.info("Review session completed: \(correctCount, privacy: .public) correct, \(incorrectCount, privacy: .public) incorrect")
        }
    }

    private func finishOrDismiss() {
        if let onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }

    private func statPill(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(tint)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Logic
    private func answerCard(isCorrect: Bool) {
        let word = reviewWords[currentIndex]
        let isLocalRepeat = locallyRepeatedWordIDs.contains(word.wordId)

        if !isCorrect && repeatIncorrectWords {
            reviewWords.append(word)
            locallyRepeatedWordIDs.insert(word.wordId)
        }

        let reviewedWord = ReviewedWord(
            wordId: word.wordId,
            reviewedAt: Date(),
            correct: isCorrect ? 1 : 0,
            incorrect: isCorrect ? 0 : 1,
            averageResponseTimeMs: 1000 // Placeholder because backend doesn't handle it
        )

        if isCorrect {
            Haptics.success()
            if !isLocalRepeat {
                correctCount += 1
            }
        } else {
            Haptics.light()
            if !isLocalRepeat {
                incorrectCount += 1
            }
        }

        // Repeated attempts are local practice only and are not submitted.
        // Practice-mode cards (onboarding's demo word) aren't real backend
        // words, so there's nothing to submit a review for.
        if !isPracticeMode && !isLocalRepeat {
            Task {
                do {
                    try await submitReview(reviewedWord)
                } catch {
                    errorManager.show(error.localizedDescription)
                }
            }
        }

        let distance: CGFloat = 1000

        withAnimation(answerAnimation) {
            cardOffset = isCorrect ? distance : -distance
        }

        transitionTask?.cancel()

        transitionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dragOffset = 0
                cardOffset = 0
                showingFront = true
                currentIndex += 1
            }
        }
    }

    // MARK: - Review submission

    /// Routes the reviewed word to the endpoint this session is configured for.
    /// All existing sessions use `.standard`; only the Practice tab's difficult
    /// card opts into `.difficult`.
    private func submitReview(_ reviewedWord: ReviewedWord) async throws {
        let client = NetworkAPIClient()

        switch reviewEndpoint {
        case .standard:
            try await client.submitReview(reviewedWords: [reviewedWord])
        case .difficult:
            try await client.submitDifficultReview(reviewedWords: [reviewedWord])
        }
    }
}

struct LearnView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LearnView(dueWords: [], stack: nil)
        }
    }
}
