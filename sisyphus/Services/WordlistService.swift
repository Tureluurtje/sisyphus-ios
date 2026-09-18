import OSLog

func getDueWordsService(
    limit: Int? = nil,
    offset: Int? = nil,
    apiClient: APIClient = NetworkAPIClient()
) async throws -> DueWordsResponse {

    do {
        let response = try await apiClient.fetchDueWords(limit: limit, offset: offset)
        AppLogger.words.debug("Fetched \(response.words.count, privacy: .public) due words (\(response.wordAmount, privacy: .public) total)")
        return response
    } catch {
        AppLogger.words.error("Failed to fetch due words: \(error.localizedDescription, privacy: .public)")
        captureIfUnexpected(error, feature: "words")
        throw error
    }
}

func getStacksService(apiClient: APIClient = NetworkAPIClient()) async throws -> GetAllStacksResponse {
    do {
        let response = try await apiClient.getAllStacks()
        AppLogger.words.debug("Fetched \(response.stacks.count, privacy: .public) stacks")
        return response
    } catch {
        AppLogger.words.error("Failed to fetch stacks: \(error.localizedDescription, privacy: .public)")
        captureIfUnexpected(error, feature: "words")
        throw error
    }
}

func submitSingleWordReview(
    reviewedWord: ReviewedWord,
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    try await submitMultipleWordsReview(reviewedWords: [reviewedWord], apiClient: apiClient)
}

func submitMultipleWordsReview(
    reviewedWords: [ReviewedWord],
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    do {
        try await apiClient.submitReview(reviewedWords: reviewedWords)
        AppLogger.words.debug("Submitted \(reviewedWords.count, privacy: .public) word review(s)")
    } catch {
        AppLogger.words.error("Failed to submit \(reviewedWords.count, privacy: .public) word review(s): \(error.localizedDescription, privacy: .public)")
        captureIfUnexpected(error, feature: "words")
        throw error
    }
    
}// MARK: - Difficult words

func fetchDifficultWordsService(
    apiClient: APIClient = NetworkAPIClient()
) async throws -> DueWordsResponse {
    do {
        return try await apiClient.fetchDifficultWords()
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.network.notice("Difficult words fetch failed: \(mapped.userFacingMessage, privacy: .public)")
        throw mapped
    }
}

func submitDifficultReviewService(
    reviewedWords: [ReviewedWord],
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    do {
        try await apiClient.submitDifficultReview(reviewedWords: reviewedWords)
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.network.notice("Difficult review submit failed: \(mapped.userFacingMessage, privacy: .public)")
        throw mapped
    }
}

/// `APIClientError` cases are either already captured at the network layer
/// (5xx responses, non-HTTP responses) or are expected app states (204 "word
/// list not loaded yet") — capturing them again here would double-count or
/// flag normal behavior as a bug. What's left uncaptured, and genuinely
/// worth monitoring, is anything else: a raw `DecodingError` from a backend
/// response shape no longer matching this app's models, for example.
private func captureIfUnexpected(_ error: Error, feature: String) {
    guard !(error is APIClientError) else { return }
    ErrorMonitoring.shared.service.captureError(error, context: ErrorContext(tags: ["feature": feature]))
}
