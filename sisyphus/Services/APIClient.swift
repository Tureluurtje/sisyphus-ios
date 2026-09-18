import Foundation
import SwiftData
import OSLog

// MARK: - DEBUG TOGGLE
enum NetworkDebug {
    static let verbose = true
}

// MARK: - API DTOs

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let tokens: [String: String]
}

struct RegisterRequest: Codable {
    let username: String
    let grade: Int
    let email: String
    let password: String
}

struct RegisterResponse: Codable {
    let tokens: [String: String]
}

struct RefreshRequest: Codable {
    let oldRefreshToken: String

    enum CodingKeys: String, CodingKey {
        case oldRefreshToken = "old_refresh_token"
    }
}

struct RefreshResponse: Codable {
    let tokens: [String: String]
}

struct UserProfile: Codable {
    let userId: UUID
    let username: String
    let email: String
    let grade: Int
    let totalWordsLearned: Int
    let streak: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case email
        case grade
        case totalWordsLearned = "total_words_learned"
        case streak
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Update Settings DTOs

/// Body for `PATCH /api/users/settings`.
/// Both fields are optional because PATCH semantics mean "only send what you want to change".
struct UpdateSettingsRequest: Codable {
    let grade: Int?
    let email: String?
}

struct PingServerApiResponse: Codable {
    let ok: Bool
    let components: [String: [String: String]]
}

struct LeaderboardEntry: Codable, Identifiable {
    let userId: UUID
    let rank: Int
    let username: String
    let xp: Int

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case rank
        case username
        case xp
    }
}

struct DueWordsDtoResponse: Codable {
    let wordAmount: Int
    let words: [DueWordDTO]
}

struct DueWordsResponse: Codable {
    let wordAmount: Int
    let words: [DueWord]
}

struct DueWordDTO: Codable {
    let wordId: UUID
    let chapterId: UUID
    let word: String
    let translation: String
}

struct GetAllStacksResponse: Codable {
    let wordAmount: Int
    let stacks: [Stack]
}

struct GetAllStacksDtoResponse: Codable {
    let wordAmount: Int
    let stacks: [StackDto]
}

struct StackDto: Codable {
    let stack_id: Int
    let words: [DueWordDTO]
    let wordAmount: Int
}

struct Stack: Identifiable, Codable {
    let id: Int
    let words: [DueWord]
    let wordAmount: Int
}

struct SubmitReviewRequest: Codable {
    let reviews: [ReviewedWord]
}

struct SubmitReviewResponse: Codable {
    let success: Bool
}

struct ReviewedWord: Codable {
    let wordId: UUID
    let reviewedAt: Date
    let correct: Int
    let incorrect: Int
    let averageResponseTimeMs: Int
}

// MARK: - Shared Date Coding

extension DateFormatter {
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.apiDateFormatter)
        return decoder
    }()
}

extension JSONEncoder {
    static let api: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.apiDateFormatter)
        return encoder
    }()
}

// MARK: - Cookie Helpers

private func cookieValue(named name: String, for url: URL) -> String? {
    HTTPCookieStorage.shared.cookies(for: url)?
        .first(where: { $0.name == name })?
        .value
}

private func attachCSRFToken(to request: inout URLRequest, for url: URL) {
    if let csrfToken = cookieValue(named: "csrf_token", for: url) {
        request.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-Token")
    }
}

// MARK: - Debug Dump Helpers

private func tokenFingerprint(_ value: String) -> String {
    guard value.count > 12 else { return "<short:\(value.count)>" }
    let prefix = value.prefix(8)
    let suffix = value.suffix(4)
    return "len=\(value.count) prefix=\(prefix) suffix=\(suffix)"
}

/// Dumps every cookie currently in `HTTPCookieStorage` that would be sent to `url`.
/// Only fires when `NetworkDebug.verbose` is true.
private func debugDumpCookies(for url: URL, label: String) {
    guard NetworkDebug.verbose else { return }

    let allCookies = HTTPCookieStorage.shared.cookies ?? []
    let cookiesForURL = HTTPCookieStorage.shared.cookies(for: url) ?? []

    AppLogger.network.notice("[\(label, privacy: .public)] Cookie dump for \(url.absoluteString, privacy: .public)")
    AppLogger.network.notice("[\(label, privacy: .public)] Total cookies in storage: \(allCookies.count, privacy: .public)")
    AppLogger.network.notice("[\(label, privacy: .public)] Cookies matching URL: \(cookiesForURL.count, privacy: .public)")

    if cookiesForURL.isEmpty {
        AppLogger.network.notice("[\(label, privacy: .public)] NO cookies match this URL - this is almost certainly why you get 401")
    }

    for cookie in cookiesForURL {
        let expires = cookie.expiresDate.map { ISO8601DateFormatter().string(from: $0) } ?? "session"
        AppLogger.network.notice("[\(label, privacy: .public)] cookie name=\(cookie.name, privacy: .public) domain=\(cookie.domain, privacy: .public) path=\(cookie.path, privacy: .public) secure=\(cookie.isSecure, privacy: .public) expires=\(expires, privacy: .public) value \(tokenFingerprint(cookie.value ?? ""), privacy: .public)")
    }

    // Also log cookies in storage that DON'T match (often a domain mismatch)
    let matchingNames = Set(cookiesForURL.map { "\($0.name)|\($0.domain)|\($0.path)" })
    for cookie in allCookies where !matchingNames.contains("\(cookie.name)|\(cookie.domain)|\(cookie.path)") {
        AppLogger.network.notice("[\(label, privacy: .public)] (stored but not sent) name=\(cookie.name, privacy: .public) domain=\(cookie.domain, privacy: .public) path=\(cookie.path, privacy: .public)")
    }
}

private func debugDumpRequest(_ request: URLRequest, label: String) {
    guard NetworkDebug.verbose else { return }

    AppLogger.network.notice("[\(label, privacy: .public)] \(request.httpMethod ?? "?", privacy: .public) \(request.url?.absoluteString ?? "?", privacy: .public)")

    if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
        for (k, v) in headers.sorted(by: { $0.key < $1.key }) {
            let lower = k.lowercased()
            let display: String
            if lower.contains("authorization") || lower.contains("cookie") || lower.contains("csrf") {
                display = "<\(v.count) chars>"
            } else {
                display = v
            }
            AppLogger.network.notice("[\(label, privacy: .public)] header \(k, privacy: .public) = \(display, privacy: .public)")
        }
    } else {
        AppLogger.network.notice("[\(label, privacy: .public)] No headers set on request")
    }

    if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
        AppLogger.network.notice("[\(label, privacy: .public)] body = \(bodyString, privacy: .public)")
    } else if request.httpBody == nil {
        AppLogger.network.notice("[\(label, privacy: .public)] body = nil")
    }
}

private func debugDumpResponse(data: Data, response: URLResponse, label: String) {
    guard NetworkDebug.verbose else { return }

    if let http = response as? HTTPURLResponse {
        AppLogger.network.notice("[\(label, privacy: .public)] status = \(http.statusCode, privacy: .public)")
        for (k, v) in http.allHeaderFields {
            AppLogger.network.notice("[\(label, privacy: .public)] response header \(String(describing: k), privacy: .public) = \(String(describing: v), privacy: .public)")
        }
    }

    if let bodyString = String(data: data, encoding: .utf8) {
        AppLogger.network.notice("[\(label, privacy: .public)] response body = \(bodyString, privacy: .public)")
    } else {
        AppLogger.network.notice("[\(label, privacy: .public)] response body = <\(data.count) bytes, non-UTF8>")
    }
}

// MARK: - Errors

enum APIClientError: Error {
    case nonHTTPResponse
    case badServerResponse(statusCode: Int, body: APIErrorResponse?)
    case emptyResponse(statusCode: Int)
    case decodingFailed
    case transportError(Error)

    var errorDescription: String? {
        switch self {
        case .nonHTTPResponse:
            return "The server returned a non-HTTP response."

        case .badServerResponse(let code, let body):
            return "Server returned status \(code): \(body?.error ?? "Unknown error")"

        case .emptyResponse(let statusCode):
            return statusCode == 204
                ? "The word list for this grade is not loaded yet."
                : "The server returned an empty response."

        case .decodingFailed:
            return "Failed to decode server response."

        case .transportError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - API Protocol

protocol APIClient {
    func login(email: String, password: String) async throws -> TokenPair
    func register(
        username: String,
        grade: Int,
        email: String,
        password: String
    ) async throws -> TokenPair

    func refreshTokens(
        oldRefreshTokenPair: RefreshTokenPair
    ) async throws -> TokenPair

    func getUserProfile() async throws -> UserProfile
    
    func requestAccountVerificationEmail(email: String) async throws
    func sendForgottenPasswordEmail(email: String) async throws

    /// PATCH /api/users/settings
    /// Only send the fields you want to change.
    func updateUserSettings(
        grade: Int?,
        email: String?,
        skipCSRF: Bool
    ) async throws -> UserProfile
    

    func fetchDifficultWords() async throws -> DueWordsResponse
    func submitDifficultReview(reviewedWords: [ReviewedWord]) async throws

    func getLeaderboard() async throws -> [LeaderboardEntry]
    func getCurrentLeaderboardEntry() async throws -> LeaderboardEntry

    func logout() async throws
    func delete() async throws

    func pingServerApi() async throws -> Bool

    func fetchDueWords(
        limit: Int?,
        offset: Int?
    ) async throws -> DueWordsResponse

    func getAllStacks() async throws -> GetAllStacksResponse

    func submitReview(
        reviewedWords: [ReviewedWord]
    ) async throws
}

// MARK: - Implementation

final class NetworkAPIClient: APIClient {

    private let baseURL = APIEndpointConfiguration.baseURL

    private let session: URLSession
    private var refreshTask: Task<Void, Error>?

    init() {
        let config = URLSessionConfiguration.default

        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared

        self.session = URLSession(
            configuration: config
        )
    }

    // MARK: - Authentication

    func login(email: String, password: String) async throws -> TokenPair {

        let url = baseURL
            .appendingPathComponent("api/auth/login")

        AppLogger.network.notice("POST \(url.path, privacy: .public)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(
            LoginRequest(email: email, password: password)
        )

        let (data, response) = try await session.data(for: request)

        if NetworkDebug.verbose {
            debugDumpRequest(request, label: "login request")
            debugDumpResponse(data: data, response: response, label: "login response")
            debugDumpCookies(for: url, label: "login-after")
        }

        try validate(response, data: data)

        let decoded = try JSONDecoder()
            .decode(LoginResponse.self, from: data)

        AppLogger.network.notice("POST \(url.path, privacy: .public) succeeded")

        return try mapTokens(decoded.tokens)
    }

    func register(
        username: String,
        grade: Int,
        email: String,
        password: String
    ) async throws -> TokenPair {

        let url = baseURL
            .appendingPathComponent("api/auth/register")

        AppLogger.network.notice("POST \(url.path, privacy: .public)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(
            RegisterRequest(
                username: username,
                grade: grade,
                email: email,
                password: password
            )
        )

        let (data, response) = try await session.data(for: request)

        if NetworkDebug.verbose {
            debugDumpRequest(request, label: "register request")
            debugDumpResponse(data: data, response: response, label: "register response")
            debugDumpCookies(for: url, label: "register-after")
        }

        try validate(response, data: data)

        let decoded = try JSONDecoder()
            .decode(RegisterResponse.self, from: data)

        AppLogger.network.notice("POST \(url.path, privacy: .public) succeeded")

        return try mapTokens(decoded.tokens)
    }

    func refreshTokens(
        oldRefreshTokenPair: RefreshTokenPair
    ) async throws -> TokenPair {

        let url = baseURL
            .appendingPathComponent("api/auth/refresh")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        attachCSRFToken(to: &request, for: url)

        request.httpBody = try JSONEncoder().encode(
            RefreshRequest(
                oldRefreshToken: oldRefreshTokenPair.refreshToken
            )
        )

        if NetworkDebug.verbose {
            AppLogger.network.notice("refreshTokens: using stored refresh token \(tokenFingerprint(oldRefreshTokenPair.refreshToken), privacy: .public)")
            debugDumpCookies(for: url, label: "refreshTokens-before")
            debugDumpRequest(request, label: "refreshTokens request")
        }

        let (data, response) = try await session.data(for: request)

        if NetworkDebug.verbose {
            debugDumpResponse(data: data, response: response, label: "refreshTokens response")
            debugDumpCookies(for: url, label: "refreshTokens-after")
        }

        try validate(response, data: data)

        let decoded = try JSONDecoder()
            .decode(RefreshResponse.self, from: data)

        return try mapTokens(decoded.tokens)
    }

    // MARK: - Automatic request sender (CORE LOGIC)

    private func send(
        _ request: URLRequest,
        retryOnUnauthorized: Bool = true
    ) async throws -> (Data, URLResponse) {

        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? "unknown"
        AppLogger.network.notice("\(method, privacy: .public) \(path, privacy: .public)")

        if NetworkDebug.verbose {
            debugDumpRequest(request, label: "send \(method) \(path)")
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            AppLogger.network.notice("\(method, privacy: .public) \(path, privacy: .public) returned a non-HTTP response")
            ErrorMonitoring.shared.service.captureError(
                APIClientError.nonHTTPResponse,
                context: ErrorContext(tags: ["feature": "network", "path": path])
            )
            throw APIClientError.nonHTTPResponse
        }

        AppLogger.network.notice("\(method, privacy: .public) \(path, privacy: .public) -> \(http.statusCode, privacy: .public)")

        if NetworkDebug.verbose {
            debugDumpResponse(data: data, response: response, label: "send \(method) \(path) response")
        }

        // ---- AUTO REFRESH FLOW ----
        if http.statusCode == 401, retryOnUnauthorized {
            AppLogger.auth.notice("Access token expired, attempting refresh before retrying \(path, privacy: .public)")

            if NetworkDebug.verbose {
                debugDumpCookies(for: request.url ?? baseURL, label: "send-before-refresh")
            }

            do {
                try await refreshAccessToken()
            } catch {
                if NetworkDebug.verbose {
                    AppLogger.auth.notice("refreshAccessToken threw: \(String(describing: error), privacy: .public)")
                }
                throw error
            }

            var retryRequest = request

            // Reattach cookies after refresh
            if let url = retryRequest.url {
                let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
                let headers = HTTPCookie.requestHeaderFields(with: cookies)

                for (k, v) in headers {
                    retryRequest.setValue(v, forHTTPHeaderField: k)
                }
            }

            // Reattach CSRF token after refresh (it may have rotated)
            if let url = retryRequest.url {
                attachCSRFToken(to: &retryRequest, for: url)
            }

            if NetworkDebug.verbose {
                debugDumpRequest(retryRequest, label: "send retry after refresh")
            }

            return try await send(
                retryRequest,
                retryOnUnauthorized: false
            )
        }

        try validate(response, data: data)
        return (data, response)
    }

    // MARK: - Refresh attempt (internal)

    private func refreshAccessToken() async throws {
        if let refreshTask {
            if NetworkDebug.verbose {
                AppLogger.auth.notice("refreshAccessToken: reusing in-flight refresh task")
            }
            return try await refreshTask.value
        }

        if NetworkDebug.verbose {
            AppLogger.auth.notice("refreshAccessToken: starting new refresh task")
        }

        let refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            try await self.attemptRefresh()
        }

        self.refreshTask = refreshTask
        defer { self.refreshTask = nil }

        try await refreshTask.value
    }

    private func attemptRefresh() async throws {

        let url = baseURL
            .appendingPathComponent("api/auth/refresh")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        attachCSRFToken(to: &request, for: url)

        // ---- DEBUG: what are we actually sending? ----
        if NetworkDebug.verbose {
            AppLogger.auth.notice("attemptRefresh -> \(url.absoluteString, privacy: .public)")
            debugDumpCookies(for: url, label: "attemptRefresh-before")
            debugDumpRequest(request, label: "attemptRefresh request")

            if let csrfHeader = request.value(forHTTPHeaderField: "X-CSRF-Token") {
                AppLogger.auth.notice("attemptRefresh: X-CSRF-Token present (\(csrfHeader.count) chars)")
            } else {
                AppLogger.auth.notice("attemptRefresh: X-CSRF-Token MISSING - refresh will likely 401/403")
            }

            if let refreshCookie = cookieValue(named: "refresh_token", for: url) {
                AppLogger.auth.notice("attemptRefresh: refresh_token cookie present \(tokenFingerprint(refreshCookie), privacy: .public)")
            } else {
                AppLogger.auth.notice("attemptRefresh: refresh_token COOKIE MISSING")
            }
        }

        let (data, response) = try await session.data(for: request)

        if NetworkDebug.verbose {
            debugDumpResponse(data: data, response: response, label: "attemptRefresh response")
            debugDumpCookies(for: url, label: "attemptRefresh-after")
        }

        do {
            try validate(response, data: data)
        } catch {
            if NetworkDebug.verbose {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                AppLogger.auth.notice("attemptRefresh FAILED status=\(status, privacy: .public) body=\(body, privacy: .public)")
            }
            AppLogger.auth.notice("Token refresh failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        _ = try JSONDecoder()
            .decode(RefreshResponse.self, from: data)

        AppLogger.auth.notice("Token refresh succeeded")
    }
    
    // MARK: - Account verification / password reset
    
    /// GET /api/auth/request-account-verification-email?email=...
    /// Server responds with `{ success: bool }` and emails the user a verification link.
    func requestAccountVerificationEmail(email: String) async throws {
        let baseEndpoint = baseURL
            .appendingPathComponent("api/auth/request-account-verification-email")

        var components = URLComponents(
            url: baseEndpoint,
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "email", value: email)]

        let url = components.url!
        let request = makeRequest(url: url, method: "GET")

        _ = try await send(request)
    }

    /// POST /api/auth/send-forgotten-password-email?email=...
    /// Server responds with `{ success: bool }` and emails the user a reset link.
    func sendForgottenPasswordEmail(email: String) async throws {
        let baseEndpoint = baseURL
            .appendingPathComponent("api/auth/send-forgotten-password-email")

        var components = URLComponents(
            url: baseEndpoint,
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "email", value: email)]

        let url = components.url!
        let request = makeRequest(url: url, method: "POST")

        _ = try await send(request)
    }

    // MARK: - Validation

    func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.nonHTTPResponse
        }

        guard (200...299).contains(http.statusCode) else {

            let decoded = try? JSONDecoder()
                .decode(APIErrorResponse.self, from: data)

            AppLogger.network.notice("Server returned \(http.statusCode, privacy: .public) for \(http.url?.path ?? "unknown", privacy: .public): \(decoded?.error ?? "no error body", privacy: .public)")

            let error = APIClientError.badServerResponse(
                statusCode: http.statusCode,
                body: decoded
            )

            if http.statusCode >= 500 {
                ErrorMonitoring.shared.service.captureError(
                    error,
                    context: ErrorContext(tags: [
                        "feature": "network",
                        "path": http.url?.path ?? "unknown",
                        "status": String(http.statusCode)
                    ])
                )
            }

            throw error
        }
    }

    // MARK: - Authenticated endpoints

    func getUserProfile() async throws -> UserProfile {

        let url = baseURL
            .appendingPathComponent("api/users/me")

        var request = makeRequest(url: url, method: "GET")
        attachCSRFToken(to: &request, for: url)

        let (data, _) = try await send(request)

        return try JSONDecoder.api.decode(UserProfile.self, from: data)
    }

    // MARK: - Update settings

    /// PATCH /api/users/settings
    ///
    /// Pass only the fields you want to update. Pass `nil` for the ones you want to leave alone.
    ///
    /// - Parameters:
    ///   - grade: New grade, or `nil` to leave unchanged.
    ///   - email: New email, or `nil` to leave unchanged.
    ///   - skipCSRF: Maps to the `skip_csrf` query parameter (default `false`). Only set this
    ///     to `true` if the server explicitly told you to for a specific flow.
    /// - Returns: The updated `UserProfile`.
    func updateUserSettings(
        grade: Int?,
        email: String?,
        skipCSRF: Bool = false
    ) async throws -> UserProfile {

        let baseEndpoint = baseURL
            .appendingPathComponent("api/users/settings")

        var components = URLComponents(
            url: baseEndpoint,
            resolvingAgainstBaseURL: false
        )!

        if skipCSRF {
            components.queryItems = [
                URLQueryItem(name: "skip_csrf", value: "true")
            ]
        }

        let url = components.url!

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Only attach CSRF if we're not explicitly skipping it
        if !skipCSRF {
            attachCSRFToken(to: &request, for: url)
        }

        // Encode the body. Optional fields are omitted when nil.
        request.httpBody = try JSONEncoder().encode(
            UpdateSettingsRequest(grade: grade, email: email)
        )

        if NetworkDebug.verbose {
            debugDumpRequest(request, label: "updateUserSettings request")
        }

        let (data, response) = try await send(request)

        if NetworkDebug.verbose {
            debugDumpResponse(data: data, response: response, label: "updateUserSettings response")
        }

        return try JSONDecoder.api.decode(UserProfile.self, from: data)
    }
    // MARK: - Difficult words

    /// GET /api/words/difficult
    /// Returns the words the user has been getting wrong most often.
    func fetchDifficultWords() async throws -> DueWordsResponse {
        let url = baseURL
            .appendingPathComponent("api/words/difficult")

        let request = makeRequest(url: url, method: "GET")

        let (data, response) = try await send(request)

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.nonHTTPResponse
        }

        guard http.statusCode != 204 else {
            throw APIClientError.emptyResponse(statusCode: 204)
        }

        let decoded = try JSONDecoder()
            .decode(DueWordsDtoResponse.self, from: data)

        return DueWordsResponse(
            wordAmount: decoded.wordAmount,
            words: decoded.words.map {
                DueWord(
                    wordId: $0.wordId,
                    chapterId: $0.chapterId,
                    word: $0.word,
                    translation: $0.translation
                )
            }
        )
    }

    /// POST /api/words/difficult/review
    /// Submits review results for difficult words. Body and response match the
    /// regular `/api/words/review` endpoint.
    func submitDifficultReview(reviewedWords: [ReviewedWord]) async throws {

        let url = baseURL
            .appendingPathComponent("api/words/difficult/review")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        attachCSRFToken(to: &request, for: url)

        request.httpBody = try JSONEncoder.api.encode(
            SubmitReviewRequest(reviews: reviewedWords)
        )

        if NetworkDebug.verbose {
            debugDumpRequest(request, label: "submitDifficultReview request")
        }

        let (data, response) = try await send(request)

        if NetworkDebug.verbose {
            debugDumpResponse(data: data, response: response, label: "submitDifficultReview response")
        }

        // The OpenAPI spec doesn't declare a response_model, so tolerate either
        // `{"success": true}` (matching /review) or an empty body.
        if !data.isEmpty {
            _ = try? JSONDecoder().decode(SubmitReviewResponse.self, from: data)
        }
    }

    func getLeaderboard() async throws -> [LeaderboardEntry] {
        let url = baseURL.appendingPathComponent("api/leaderboard")

        var request = makeRequest(url: url, method: "GET")
        attachCSRFToken(to: &request, for: url)

        let (data, _) = try await send(request)
        return try JSONDecoder.api.decode([LeaderboardEntry].self, from: data)
    }

    func getCurrentLeaderboardEntry() async throws -> LeaderboardEntry {
        let url = baseURL.appendingPathComponent("api/leaderboard/me")

        var request = makeRequest(url: url, method: "GET")
        attachCSRFToken(to: &request, for: url)

        let (data, _) = try await send(request)
        return try JSONDecoder.api.decode(LeaderboardEntry.self, from: data)
    }

    func fetchDueWords(
        limit: Int?,
        offset: Int?
    ) async throws -> DueWordsResponse {

        let baseEndpoint = baseURL
            .appendingPathComponent("api/words/due")

        var components = URLComponents(
            url: baseEndpoint,
            resolvingAgainstBaseURL: false
        )!

        var queryItems: [URLQueryItem] = []
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        let url = components.url!
        let request = makeRequest(url: url, method: "GET")

        let (data, response) = try await send(request)

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.nonHTTPResponse
        }

        guard http.statusCode != 204 else {
            throw APIClientError.emptyResponse(statusCode: 204)
        }

        let decoded = try JSONDecoder()
            .decode(DueWordsDtoResponse.self, from: data)

        return DueWordsResponse(
            wordAmount: decoded.wordAmount,
            words: decoded.words.map {
                DueWord(
                    wordId: $0.wordId,
                    chapterId: $0.chapterId,
                    word: $0.word,
                    translation: $0.translation
                )
            }
        )
    }

    func getAllStacks() async throws -> GetAllStacksResponse {

        let url = baseURL
            .appendingPathComponent("api/words/stacks")

        let request = makeRequest(url: url, method: "GET")

        let (data, _) = try await send(request)

        let decoded = try JSONDecoder()
            .decode(GetAllStacksDtoResponse.self, from: data)

        return GetAllStacksResponse(
            wordAmount: decoded.wordAmount,
            stacks: decoded.stacks.map { stackDto in
                Stack(
                    id: stackDto.stack_id,
                    words: stackDto.words.map {
                        DueWord(
                            wordId: $0.wordId,
                            chapterId: $0.chapterId,
                            word: $0.word,
                            translation: $0.translation
                        )
                    },
                    wordAmount: stackDto.wordAmount
                )
            }
        )
    }

    func submitReview(
        reviewedWords: [ReviewedWord]
    ) async throws {

        let url = baseURL
            .appendingPathComponent("api/words/review")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        attachCSRFToken(to: &request, for: url)

        request.httpBody = try JSONEncoder.api.encode(
            SubmitReviewRequest(
                reviews: reviewedWords
            )
        )

        let (data, _) = try await send(request)

        _ = try JSONDecoder().decode(
            SubmitReviewResponse.self,
            from: data
        )
    }

    func logout() async throws {

        let url = baseURL
            .appendingPathComponent("api/auth/logout")

        var request = makeRequest(url: url, method: "POST")
        attachCSRFToken(to: &request, for: url)

        _ = try await send(request)
    }

    func delete() async throws {

        let url = baseURL
            .appendingPathComponent("api/auth/delete")

        var request = makeRequest(url: url, method: "DELETE")
        attachCSRFToken(to: &request, for: url)

        _ = try await send(request)
    }

    func pingServerApi() async throws -> Bool {

        let url = baseURL
            .appendingPathComponent("api/health")

        let request = makeRequest(url: url, method: "GET")

        let (data, _) = try await send(request)

        let decoded = try JSONDecoder()
            .decode(PingServerApiResponse.self, from: data)

        return decoded.ok
    }

    // MARK: - Helpers

    private func mapTokens(_ tokens: [String: String]) throws -> TokenPair {

        guard
            let access = tokens["access_token"],
            let refresh = tokens["refresh_token"],
            let csrf = tokens["csrf_token"]
        else {
            throw APIClientError.decodingFailed
        }

        AppLogger.auth.notice("mapTokens: access \(tokenFingerprint(access), privacy: .public), refresh \(tokenFingerprint(refresh), privacy: .public), csrf \(tokenFingerprint(csrf), privacy: .public)")

        return TokenPair(
            accessToken: access,
            refreshToken: refresh,
            csrfToken: csrf
        )
    }

    private func makeRequest(
        url: URL,
        method: String,
        body: Data? = nil
    ) -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        if body != nil {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        let headers = HTTPCookie.requestHeaderFields(with: cookies)

        for (k, v) in headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        return request
    }
}
