//
//  AuthService.swift
//  sisyphus
//
//  Created by Arthur Kwak on 14/06/2026.
//

import KeychainAccess
import Foundation
import OSLog

private enum EmailValidation {
    static let regex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        )
    }()
}

private func makeKeychain() -> Keychain {
    Keychain(service: "com.sisyphus.auth")
        .accessibility(.whenUnlockedThisDeviceOnly)
}

func loginService(
    email: String,
    password: String,
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    do {
        let newTokenPair: TokenPair = try await apiClient.login(email: email, password: password)

        let keychain = makeKeychain()

        keychain["access-token"] = newTokenPair.accessToken
        keychain["refresh-token"] = newTokenPair.refreshToken
        keychain["csrf-token"] = newTokenPair.csrfToken

        AppLogger.auth.notice("Login succeeded for \(email, privacy: .private)")
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.auth.warning("Login failed for \(email, privacy: .private): \(mapped.userFacingMessage, privacy: .public)")
        throw mapped
    }
}

func registerService(
    username: String,
    grade: Int,
    email: String,
    password: String,
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    do {
        let tokenPair = try await apiClient.register(
            username: username,
            grade: grade,
            email: email,
            password: password
        )

        let keychain = makeKeychain()
        keychain["access-token"] = tokenPair.accessToken
        keychain["refresh-token"] = tokenPair.refreshToken
        keychain["csrf-token"] = tokenPair.csrfToken

        AppLogger.auth.notice("Registration succeeded for \(username, privacy: .private)")
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.auth.warning("Registration failed for \(username, privacy: .private): \(mapped.userFacingMessage, privacy: .public)")
        throw mapped
    }
}

func refreshService(apiClient: APIClient = NetworkAPIClient()) async throws {
    let keychain = makeKeychain()

    // First try to get refresh and csrf token from keychain
    guard
        let refreshToken = keychain[string: "refresh-token"],
        let csrfToken = keychain[string: "csrf-token"]
    else {
        AppLogger.auth.debug("No stored refresh token, skipping session restore")
        throw AuthError.missingTokens
    }

    // Prepare tokens
    let oldRefreshTokenPair = RefreshTokenPair(refreshToken: refreshToken, csrfToken: csrfToken)

    // Attempt access/refresh token refresh
    let newTokenPair: TokenPair = try await apiClient.refreshTokens(oldRefreshTokenPair: oldRefreshTokenPair)

    keychain["access-token"] = newTokenPair.accessToken
    keychain["refresh-token"] = newTokenPair.refreshToken
    keychain["csrf-token"] = newTokenPair.csrfToken
}

func getUserProfileService(apiClient: APIClient = NetworkAPIClient()) async throws -> UserProfile {
    return try await apiClient.getUserProfile()
}

func pingServerService(apiClient: APIClient = NetworkAPIClient()) async throws -> Bool {
    return try await apiClient.pingServerApi()
}

func logoutService(apiClient: APIClient = NetworkAPIClient()) async throws {
    let keychain = makeKeychain()

    defer {
        keychain["access-token"] = nil
        keychain["refresh-token"] = nil
        keychain["csrf-token"] = nil
        AppLogger.auth.notice("Local session cleared (logout)")
    }

    try await apiClient.logout()
}

func accountDeletionService(apiClient: APIClient = NetworkAPIClient()) async throws {
    let keychain = makeKeychain()

    defer {
        keychain["access-token"] = nil
        keychain["refresh-token"] = nil
        keychain["csrf-token"] = nil
        AppLogger.auth.notice("Local session cleared (account deletion)")
    }

    try await apiClient.delete()
}

func mapAuthError(_ error: APIClientError) -> AuthError {
    switch error {

    case .badServerResponse(let statusCode, let body):

        let message = body?.error.lowercased() ?? ""

        if statusCode == 422, message.contains("password") {
            return .weakPassword
        }

        guard statusCode == 409, let body else {
            return .serverMessage(body?.error ?? "Request failed")
        }

        if message.contains("username") {
            return .usernameConflict
        }

        if message.contains("email") {
            return .emailConflict
        }

        return .serverMessage(body.error)

    case .emptyResponse:
        return .unknown

    case .transportError:
        return .unknown

    case .nonHTTPResponse:
        return .unknown

    case .decodingFailed:
        return .unknown
    }
}

func isValidEmail(_ email: String) -> Bool {
    guard let regex = EmailValidation.regex else { return false }

    let range = NSRange(email.startIndex..., in: email)
    return regex.firstMatch(in: email, options: [], range: range) != nil
}
