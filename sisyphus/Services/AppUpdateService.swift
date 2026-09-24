import Foundation
import OSLog

struct AppUpdateRequirement: Equatable {
    let currentVersion: String
    let latestVersion: String
    let storeURL: URL?
}

enum AppUpdateService {
    private struct LookupResponse: Decodable {
        let results: [LookupResult]
    }

    private struct LookupResult: Decodable {
        let version: String
        let trackViewURL: URL?

        enum CodingKeys: String, CodingKey {
            case version
            case trackViewURL = "trackViewUrl"
        }
    }

    static func checkForRequiredUpdate() async -> AppUpdateRequirement? {
        guard
            let bundleIdentifier = Bundle.main.bundleIdentifier,
            let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)&country=us")
        else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

            let lookup = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard
                let result = lookup.results.first,
                let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                compareVersions(result.version, isNewerThan: currentVersion)
            else {
                return nil
            }

            return AppUpdateRequirement(
                currentVersion: currentVersion,
                latestVersion: result.version,
                storeURL: result.trackViewURL
            )
        } catch {
            AppLogger.network.debug("App Store version check unavailable: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func compareVersions(_ candidate: String, isNewerThan current: String) -> Bool {
        let candidateParts = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let currentParts = current.split(separator: ".").map { Int($0) ?? 0 }
        let length = max(candidateParts.count, currentParts.count)

        for index in 0..<length {
            let candidatePart = index < candidateParts.count ? candidateParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0
            if candidatePart != currentPart {
                return candidatePart > currentPart
            }
        }

        return false
    }
}
