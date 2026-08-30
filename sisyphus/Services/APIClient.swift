import Foundation
import SwiftData
import OSLog

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

struct PingServerApiResponse: Codable {
    let ok: Bool
    let components: [String: [String: String]]
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
    
    private let baseURL = URL(
        string: "https://sisyphus.kwako.nl"
    )!
    
    private let session: URLSession
    
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

        AppLogger.network.debug("POST \(url.path, privacy: .public)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(
            LoginRequest(email: email, password: password)
        )

        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)

        let decoded = try JSONDecoder()
            .decode(LoginResponse.self, from: data)

        AppLogger.network.debug("POST \(url.path, privacy: .public) succeeded")

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

        AppLogger.network.debug("POST \(url.path, privacy: .public)")

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
        try validate(response, data: data)

        let decoded = try JSONDecoder()
            .decode(RegisterResponse.self, from: data)

        AppLogger.network.debug("POST \(url.path, privacy: .public) succeeded")

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
        
        let (data, response) = try await session.data(for: request)
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
        AppLogger.network.debug("\(method, privacy: .public) \(path, privacy: .public)")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            AppLogger.network.error("\(method, privacy: .public) \(path, privacy: .public) returned a non-HTTP response")
            ErrorMonitoring.shared.service.captureError(
                APIClientError.nonHTTPResponse,
                context: ErrorContext(tags: ["feature": "network", "path": path])
            )
            throw APIClientError.nonHTTPResponse
        }

        AppLogger.network.debug("\(method, privacy: .public) \(path, privacy: .public) -> \(http.statusCode, privacy: .public)")

        // ---- AUTO REFRESH FLOW ----
        if http.statusCode == 401, retryOnUnauthorized {
            AppLogger.auth.notice("Access token expired, attempting refresh before retrying \(path, privacy: .public)")
            try await attemptRefresh()

            var retryRequest = request

            // Reattach cookies after refresh
            if let url = retryRequest.url {
                let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
                let headers = HTTPCookie.requestHeaderFields(with: cookies)

                for (k, v) in headers {
                    retryRequest.setValue(v, forHTTPHeaderField: k)
                }
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

    private func attemptRefresh() async throws {

        let url = baseURL
            .appendingPathComponent("api/auth/refresh")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        attachCSRFToken(to: &request, for: url)


        let (data, response) = try await session.data(for: request)

        do {
            try validate(response, data: data)
        } catch {
            AppLogger.auth.warning("Token refresh failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        _ = try JSONDecoder()
            .decode(RefreshResponse.self, from: data)

        AppLogger.auth.notice("Token refresh succeeded")
    }

    // MARK: - Validation

    func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.nonHTTPResponse
        }

        guard (200...299).contains(http.statusCode) else {

            let decoded = try? JSONDecoder()
                .decode(APIErrorResponse.self, from: data)

            AppLogger.network.error("Server returned \(http.statusCode, privacy: .public) for \(http.url?.path ?? "unknown", privacy: .public): \(decoded?.error ?? "no error body", privacy: .public)")

            let error = APIClientError.badServerResponse(
                statusCode: http.statusCode,
                body: decoded
            )

            // Only 5xx is an actual backend bug worth monitoring — 4xx here
            // is routine (bad credentials, validation, expected conflicts).
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
            .appendingPathComponent("api/auth/me")

        var request = makeRequest(url: url, method: "GET")
        attachCSRFToken(to: &request, for: url)

        let (data, _) = try await send(request)

        return try JSONDecoder.api.decode(UserProfile.self, from: data)
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
