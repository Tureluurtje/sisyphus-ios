//
//  TestView.swift
//  sisyphus
//

import SwiftUI

/// Simulates a real test: multiple-choice questions, no hints, no retries,
/// answers locked in once selected, score revealed only at the end.
struct TestView: View {
    let words: [DueWord]

    @State private var currentIndex = 0
    @State private var selectedOptionId: UUID?
    @State private var answers: [TestAnswer] = []
    @State private var questions: [TestQuestion] = []
    @State private var isFinished = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if questions.isEmpty {
                emptyView
            } else if isFinished {
                resultsView
            } else {
                questionView
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if questions.isEmpty {
                questions = Self.buildQuestions(from: words)
            }
        }
    }

    // MARK: Empty
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("Not enough words to build a test")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Question
    private var questionView: some View {
        let question = questions[currentIndex]

        return VStack(alignment: .leading, spacing: 24) {
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Question \(currentIndex + 1) of \(questions.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(answers.filter(\.isCorrect).count) correct so far")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ProgressView(value: Double(currentIndex), total: Double(questions.count))
                    .tint(.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Prompt
            VStack(alignment: .leading, spacing: 6) {
                Text("TRANSLATE")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                Text(question.prompt.word.capitalized)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            .padding(.horizontal, 20)

            // Options
            VStack(spacing: 10) {
                ForEach(question.options) { option in
                    optionRow(option, question: question)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Next button
            Button(action: advance) {
                Text(currentIndex == questions.count - 1 ? "Finish Test" : "Next Question")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selectedOptionId == nil ? Color.gray.opacity(0.3) : Color.accentColor)
                    )
                    .foregroundColor(.white)
            }
            .disabled(selectedOptionId == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func optionRow(_ option: TestOption, question: TestQuestion) -> some View {
        let isSelected = selectedOptionId == option.id

        return Button(action: {
            selectedOptionId = option.id
            Haptics.selection()
        }) {
            HStack {
                Text(option.translation)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.microInteraction)
    }

    private func advance() {
        guard let selectedOptionId,
              let question = questions[safe: currentIndex] else { return }

        let selectedOption = question.options.first { $0.id == selectedOptionId }
        let correct = selectedOption?.wordId == question.prompt.wordId

        answers.append(
            TestAnswer(
                prompt: question.prompt,
                selectedTranslation: selectedOption?.translation ?? "",
                isCorrect: correct
            )
        )

        self.selectedOptionId = nil

        if currentIndex == questions.count - 1 {
            isFinished = true
        } else {
            currentIndex += 1
        }
    }

    // MARK: Results
    private var resultsView: some View {
        let correctCount = answers.filter(\.isCorrect).count
        let total = answers.count
        let pct = total > 0 ? Int((Double(correctCount) / Double(total) * 100).rounded()) : 0

        return ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(pct)%")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(pct))

                    Text("\(correctCount) of \(total) correct")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 10) {
                    ForEach(answers, id: \.prompt.wordId) { answer in
                        HStack {
                            Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(answer.isCorrect ? .green : .red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(answer.prompt.word.capitalized)
                                    .font(.system(.body, design: .serif, weight: .medium))
                                if !answer.isCorrect {
                                    Text("You said: \(answer.selectedTranslation)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("Correct: \(answer.prompt.translation)")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                    }
                }
                .padding(.horizontal, 20)

                Button(action: restart) {
                    Text("Retake Test")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.accentColor)
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func scoreColor(_ pct: Int) -> Color {
        switch pct {
        case 90...100: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }

    private func restart() {
        answers = []
        currentIndex = 0
        selectedOptionId = nil
        isFinished = false
        questions = Self.buildQuestions(from: words)
    }

    // MARK: Question generation
    private static func buildQuestions(from words: [DueWord]) -> [TestQuestion] {
        guard words.count >= 4 else { return [] }

        return words.map { word -> TestQuestion in
            var distractorPool = words.filter { $0.wordId != word.wordId }
            distractorPool.shuffle()
            let distractors = Array(distractorPool.prefix(3))

            var options = distractors.map {
                TestOption(id: UUID(), wordId: $0.wordId, translation: $0.translation)
            }
            options.append(TestOption(id: UUID(), wordId: word.wordId, translation: word.translation))
            options.shuffle()

            return TestQuestion(prompt: word, options: options)
        }
    }
}

// MARK: Models

private struct TestQuestion {
    let prompt: DueWord
    let options: [TestOption]
}

private struct TestOption: Identifiable {
    let id: UUID
    let wordId: UUID
    let translation: String
}

private struct TestAnswer {
    let prompt: DueWord
    let selectedTranslation: String
    let isCorrect: Bool
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TestView(words: [
                DueWord(wordId: UUID(), chapterId: UUID(), word: "puella", translation: "girl"),
                DueWord(wordId: UUID(), chapterId: UUID(), word: "aqua", translation: "water"),
                DueWord(wordId: UUID(), chapterId: UUID(), word: "sum", translation: "to be"),
                DueWord(wordId: UUID(), chapterId: UUID(), word: "amo", translation: "to love"),
                DueWord(wordId: UUID(), chapterId: UUID(), word: "video", translation: "to see"),
            ])
        }
    }
}
