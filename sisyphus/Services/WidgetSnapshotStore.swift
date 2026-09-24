import Foundation
import WidgetKit

enum WidgetSnapshotStore {
    static let suiteName = "group.tureluurtje.sisyphus"

    private struct Snapshot: Codable {
        let dueCount: Int
        let streak: Int
        let learned: Int
        let word: String
        let translation: String
    }

    static func update(dueCount: Int, streak: Int, learned: Int, word: DueWord) {
        let snapshot = Snapshot(
            dueCount: dueCount,
            streak: streak,
            learned: learned,
            word: word.word,
            translation: word.translation
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: suiteName)?.set(data, forKey: "latestSnapshot")
        WidgetCenter.shared.reloadTimelines(ofKind: "SisyphusWidget")
    }
}
