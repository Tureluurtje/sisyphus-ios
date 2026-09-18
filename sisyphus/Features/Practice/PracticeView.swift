//
//  PracticeView.swift
//  sisyphus
//

import SwiftUI

struct PracticeView: View {
    // MARK: Demo data
    // TODO: replace with real backend calls, e.g.
    //   getDifficultWordsService() -> [DueWord]
    //   getIrregularVerbsService() -> [DueWord]

    private var difficultWords: [DueWord] {
        [
            DueWord(wordId: UUID(), chapterId: UUID(), word: "ferre", translation: "to carry, bear (irregular)"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "quisque", translation: "each, every one"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "utrum...an", translation: "whether...or"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "nescioquis", translation: "someone or other"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "quamvis", translation: "although, however much"),
            DueWord(wordId: UUID(), chapterId: UUID(), word: "dein", translation: "then, next"),
        ]
    }

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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header
                practiceCard(
                    title: "Difficult Words",
                    subtitle: "Words you've been getting wrong most often",
                    icon: "exclamationmark.triangle.fill",
                    tint: .orange,
                    count: difficultWords.count,
                    words: difficultWords
                )
                practiceCard(
                    title: "Irregular Verbs",
                    subtitle: "sum, possum, eo, fero, and friends",
                    icon: "bolt.fill",
                    tint: .purple,
                    count: irregularVerbs.count,
                    words: irregularVerbs
                )
            }
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: Practice card
    private func practiceCard(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        count: Int,
        words: [DueWord]
    ) -> some View {
        NavigationLink(
            destination: LearnView(dueWords: words, stack: nil)
        ) {
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

                    Text("\(count) words")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(tint)
                        .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.secondary.opacity(0.4))
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tint.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PracticeView()
        }
    }
}
