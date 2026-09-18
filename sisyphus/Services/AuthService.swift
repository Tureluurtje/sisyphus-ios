//
//  AuthService.swift
//  sisyphus
//

import KeychainAccess
import Foundation
import OSLog

// MARK: - DEBUG TOGGLE
// Flip this to false before shipping to silence the verbose diagnostic logs.
enum AuthDebug {
    static let verbose = true
}

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

// MARK: - Keychain Debug Helpers

private func tokenFingerprint(_ value: String) -> String {
    guard value.count > 12 else { return "<short:\(value.count)>" }
    let prefix = value.prefix(8)
    let suffix = value.suffix(4)
    return "len=\(value.count) prefix=\(prefix) suffix=\(suffix)"
}

private func debugDumpKeychain(label: String) {
    guard AuthDebug.verbose else { return }

    let keychain = makeKeychain()
    AppLogger.auth.notice("[\(label, privacy: .public)] Keychain dump (service=com.sisyphus.auth)")

    let keys = [
        "access-token",
        "refresh-token",
        "csrf-token"
    ]

    for key in keys {
        do {
            if let value = try keychain.getString(key) {
                AppLogger.auth.notice("[\(label, privacy: .public)] key=\(key, privacy: .public) value PRESENT \(tokenFingerprint(value), privacy: .public)")
            } else {
                AppLogger.auth.notice("[\(label, privacy: .public)] key=\(key, privacy: .public) value MISSING (nil)")
            }
        } catch {
            AppLogger.auth.notice("[\(label, privacy: .public)] key=\(key, privacy: .public) read THREW: \(String(describing: error), privacy: .public)")
        }
    }

    do {
        let allKeys = try keychain.allKeys()
        AppLogger.auth.notice("[\(label, privacy: .public)] all keys in service: \(allKeys, privacy: .public)")
    } catch {
        AppLogger.auth.notice("[\(label, privacy: .public)] allKeys() THREW: \(String(describing: error), privacy: .public)")
    }
}

private func debugWriteKeychain(
    key: String,
    value: String,
    label: String
) {
    guard AuthDebug.verbose else {
        makeKeychain()[key] = value
        return
    }

    let keychain = makeKeychain()

    do {
        try keychain.set(value, key: key)
        AppLogger.auth.notice("[\(label, privacy: .public)] WROTE key=\(key, privacy: .public) \(tokenFingerprint(value), privacy: .public)")

        // Verify read-back immediately -- this catches silent failures
        if let readBack = try keychain.getString(key) {
            if readBack == value {
                AppLogger.auth.notice("[\(label, privacy: .public)] VERIFY OK key=\(key, privacy: .public)")
            } else {
                AppLogger.auth.notice("[\(label, privacy: .public)] VERIFY MISMATCH key=\(key, privacy: .public) wrote \(tokenFingerprint(value), privacy: .public) read \(tokenFingerprint(readBack), privacy: .public)")
            }
        } else {
            AppLogger.auth.notice("[\(label, privacy: .public)] VERIFY FAILED key=\(key, privacy: .public) wrote but read-back is nil")
        }
    } catch {
        AppLogger.auth.notice("[\(label, privacy: .public)] WRITE THREW key=\(key, privacy: .public) error=\(String(describing: error), privacy: .public)")
    }
}

private func debugDeleteKeychain(key: String, label: String) {
    let keychain = makeKeychain()
    do {
        try keychain.remove(key)
        if AuthDebug.verbose {
            AppLogger.auth.notice("[\(label, privacy: .public)] REMOVED key=\(key, privacy: .public)")
        }
    } catch {
        AppLogger.auth.notice("[\(label, privacy: .public)] REMOVE THREW key=\(key, privacy: .public) error=\(String(describing: error), privacy: .public)")
    }
}

// MARK: - Auth Services

func loginService(
    email: String,
    password: String,
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    do {
        let newTokenPair: TokenPair = try await apiClient.login(email: email, password: password)

        debugDumpKeychain(label: "loginService-before-write")

        debugWriteKeychain(
            key: "access-token",
            value: newTokenPair.accessToken,
            label: "loginService"
        )
        debugWriteKeychain(
            key: "refresh-token",
            value: newTokenPair.refreshToken,
            label: "loginService"
        )
        debugWriteKeychain(
            key: "csrf-token",
            value: newTokenPair.csrfToken,
            label: "loginService"
        )

        debugDumpKeychain(label: "loginService-after-write")

        AppLogger.auth.notice("Login succeeded for \(email, privacy: .private)")
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.auth.notice("Login failed for \(email, privacy: .private): \(mapped.userFacingMessage, privacy: .public)")
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

        debugDumpKeychain(label: "registerService-before-write")

        debugWriteKeychain(
            key: "access-token",
            value: tokenPair.accessToken,
            label: "registerService"
        )
        debugWriteKeychain(
            key: "refresh-token",
            value: tokenPair.refreshToken,
            label: "registerService"
        )
        debugWriteKeychain(
            key: "csrf-token",
            value: tokenPair.csrfToken,
            label: "registerService"
        )

        debugDumpKeychain(label: "registerService-after-write")

        AppLogger.auth.notice("Registration succeeded for \(username, privacy: .private)")
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.auth.notice("Registration failed for \(username, privacy: .private): \(mapped.userFacingMessage, privacy: .public)")
        throw mapped
    }
}

func refreshService(apiClient: APIClient = NetworkAPIClient()) async throws {
    let keychain = makeKeychain()

    debugDumpKeychain(label: "refreshService-entry")

    // Read both with throwing API so we see WHY it fails
    let refreshToken: String
    let csrfToken: String

    do {
        guard let storedRefresh = try keychain.getString("refresh-token") else {
            AppLogger.auth.notice("refreshService: refresh-token MISSING in keychain")
            throw AuthError.missingTokens
        }
        refreshToken = storedRefresh
        AppLogger.auth.notice("refreshService: refresh-token read OK \(tokenFingerprint(refreshToken), privacy: .public)")
    } catch let error as AuthError {
        throw error
    } catch {
        AppLogger.auth.notice("refreshService: refresh-token read THREW: \(String(describing: error), privacy: .public)")
        throw AuthError.missingTokens
    }

    do {
        guard let storedCsrf = try keychain.getString("csrf-token") else {
            AppLogger.auth.notice("refreshService: csrf-token MISSING in keychain")
            throw AuthError.missingTokens
        }
        csrfToken = storedCsrf
        AppLogger.auth.notice("refreshService: csrf-token read OK \(tokenFingerprint(csrfToken), privacy: .public)")
    } catch let error as AuthError {
        throw error
    } catch {
        AppLogger.auth.notice("refreshService: csrf-token read THREW: \(String(describing: error), privacy: .public)")
        throw AuthError.missingTokens
    }

    let oldRefreshTokenPair = RefreshTokenPair(
        refreshToken: refreshToken,
        csrfToken: csrfToken
    )

    AppLogger.auth.notice("refreshService: calling apiClient.refreshTokens(...)")

    let newTokenPair: TokenPair = try await apiClient.refreshTokens(
        oldRefreshTokenPair: oldRefreshTokenPair
    )

    AppLogger.auth.notice("refreshService: refresh succeeded, writing new tokens")

    debugWriteKeychain(
        key: "access-token",
        value: newTokenPair.accessToken,
        label: "refreshService"
    )
    debugWriteKeychain(
        key: "refresh-token",
        value: newTokenPair.refreshToken,
        label: "refreshService"
    )
    debugWriteKeychain(
        key: "csrf-token",
        value: newTokenPair.csrfToken,
        label: "refreshService"
    )

    debugDumpKeychain(label: "refreshService-after-write")
}

func getUserProfileService(apiClient: APIClient = NetworkAPIClient()) async throws -> UserProfile {
    return try await apiClient.getUserProfile()
}

func pingServerService(apiClient: APIClient = NetworkAPIClient()) async throws -> Bool {
    return try await apiClient.pingServerApi()
}

// MARK: - Account verification / password reset

func requestAccountVerificationEmailService(
    email: String,
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    do {
        try await apiClient.requestAccountVerificationEmail(email: email)
        AppLogger.auth.notice("Verification email requested for \(email, privacy: .private)")
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.auth.notice("Verification email request failed: \(mapped.userFacingMessage, privacy: .public)")
        throw mapped
    }
}

func sendForgottenPasswordEmailService(
    email: String,
    apiClient: APIClient = NetworkAPIClient()
) async throws {
    do {
        try await apiClient.sendForgottenPasswordEmail(email: email)
        AppLogger.auth.notice("Password reset email requested for \(email, privacy: .private)")
    } catch let error as APIClientError {
        let mapped = mapAuthError(error)
        AppLogger.auth.notice("Password reset email request failed: \(mapped.userFacingMessage, privacy: .public)")
        throw mapped
    }
}

/// Clears the stored tokens without hitting the server.
/// Used after registration to force the user to re-login *after* verifying their email.
func clearLocalSession() {
    let keychain = makeKeychain()
    try? keychain.remove("access-token")
    try? keychain.remove("refresh-token")
    try? keychain.remove("csrf-token")
    AppLogger.auth.notice("Local session cleared (manual)")
}

func logoutService(apiClient: APIClient = NetworkAPIClient()) async throws {
    defer {
        debugDeleteKeychain(key: "access-token", label: "logoutService")
        debugDeleteKeychain(key: "refresh-token", label: "logoutService")
        debugDeleteKeychain(key: "csrf-token", label: "logoutService")
        debugDumpKeychain(label: "logoutService-after-delete")
        AppLogger.auth.notice("Local session cleared (logout)")
    }

    try await apiClient.logout()
}

func accountDeletionService(apiClient: APIClient = NetworkAPIClient()) async throws {
    defer {
        debugDeleteKeychain(key: "access-token", label: "accountDeletionService")
        debugDeleteKeychain(key: "refresh-token", label: "accountDeletionService")
        debugDeleteKeychain(key: "csrf-token", label: "accountDeletionService")
        debugDumpKeychain(label: "accountDeletionService-after-delete")
        AppLogger.auth.notice("Local session cleared (account deletion)")
    }

    try await apiClient.delete()
}

func updateUserSettingsService(
    grade: Int? = nil,
    email: String? = nil,
    skipCSRF: Bool = false,
    apiClient: APIClient = NetworkAPIClient()
) async throws -> UserProfile {
    try await apiClient.updateUserSettings(
        grade: grade,
        email: email,
        skipCSRF: skipCSRF
    )
}

func mapAuthError(_ error: APIClientError) -> AuthError {
    switch error {

    case .badServerResponse(let statusCode, let body):

        let message = body?.error ?? ""
        let code = body?.code ?? ""

        // Prefer the stable server code when present. Fall back to the
        // shared AuthError.from mapper so status + substring logic stays
        // in one place.
        return AuthError.from(
            statusCode: statusCode,
            serverCode: code.isEmpty ? nil : code,
            serverMessage: message.isEmpty ? nil : message
        )

    case .emptyResponse:
        return .unknown

    case .transportError:
        return .networkUnavailable

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
