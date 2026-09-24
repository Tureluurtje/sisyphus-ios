import SwiftUI
import WidgetKit

private struct WidgetSnapshot: Codable {
    let dueCount: Int
    let streak: Int
    let learned: Int
    let word: String
    let translation: String

    static let placeholder = WidgetSnapshot(
        dueCount: 12,
        streak: 7,
        learned: 142,
        word: "fortuna",
        translation: "fortune"
    )
}

private struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: .now, snapshot: loadSnapshot())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func loadSnapshot() -> WidgetSnapshot {
        guard
            let data = UserDefaults(suiteName: "group.tureluurtje.sisyphus")?.data(forKey: "latestSnapshot"),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return .placeholder
        }
        return snapshot
    }
}

private struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

private struct SisyphusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sisyphus", systemImage: "book.closed.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text("\(entry.snapshot.dueCount)")
                .font(.system(size: 34, design: .rounded).weight(.bold))
                .contentTransition(.numericText())

            Text(entry.snapshot.dueCount == 1 ? "card due" : "cards due")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                Text("\(entry.snapshot.streak) day streak")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.orange)
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "sisyphus://learn"))
    }

    private var mediumView: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Today's review", systemImage: "play.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("\(entry.snapshot.dueCount) cards")
                    .font(.system(.title, design: .rounded, weight: .bold))

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text("\(entry.snapshot.streak) day streak")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("VERBUM DIEI")
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(entry.snapshot.word.capitalized)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .lineLimit(1)
                Text(entry.snapshot.translation)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "sisyphus://learn"))
    }

}

struct SisyphusWidget: Widget {
    let kind = "SisyphusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            SisyphusWidgetView(entry: entry)
        }
        .configurationDisplayName("Sisyphus")
        .description("Your review queue, streak, and word of the day.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}

@main
struct SisyphusWidgetBundle: WidgetBundle {
    var body: some Widget {
        SisyphusWidget()
    }
}
