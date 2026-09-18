import Foundation

@MainActor
func getLeaderboardService(
    apiClient: APIClient? = nil
) async throws -> [LeaderboardEntry] {
    let apiClient = apiClient ?? NetworkAPIClient()
    return try await apiClient.getLeaderboard()
}

@MainActor
func getCurrentLeaderboardEntryService(
    apiClient: APIClient? = nil
) async throws -> LeaderboardEntry {
    let apiClient = apiClient ?? NetworkAPIClient()
    return try await apiClient.getCurrentLeaderboardEntry()
}
