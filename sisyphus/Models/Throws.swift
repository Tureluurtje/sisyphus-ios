//
//  Throws.swift
//  sisyphus
//

import Foundation

enum AuthError: Error {
    // MARK: - Registration / login conflicts
    case usernameConflict
    case emailConflict
    case accountAlreadyExists
    case accountNotFound

    // MARK: - Input validation
    case invalidEmail
    case invalidUsername
    case weakPassword
    case passwordMismatch
    case invalidCode
    case expiredCode

    // MARK: - Account state
    case accountNotVerified

    // MARK: - Session / token state
    case missingTokens
    case expiredSession
    case invalidCredentials
    case unauthorized
    case tooManyAttempts(retryAfter: Int?)

    // MARK: - Rate limiting / availability
    case rateLimited
    case networkUnavailable

    // MARK: - Server / generic
    case serverMessage(String)
    case unknown

    // MARK: - User-facing copy
    var userFacingMessage: String {
        switch self {
        // Conflicts
        case .usernameConflict:
            return "That username is already taken. Try a different one."
        case .emailConflict:
            return "An account with that email already exists. Try signing in instead."
        case .accountAlreadyExists:
            return "You already have an account. Try signing in."
        case .accountNotFound:
            return "We couldn't find an account with those details."

        // Validation
        case .invalidEmail:
            return "That doesn't look like a valid email address."
        case .invalidUsername:
            return "Usernames must be 3–20 characters and can only contain letters, numbers, and underscores."
        case .weakPassword:
            return "Passwords must be at least 8 characters and include a mix of letters and numbers."
        case .passwordMismatch:
            return "Those passwords don't match. Please try again."
        case .invalidCode:
            return "That code is incorrect. Double-check and try again."
        case .expiredCode:
            return "That code has expired. Request a new one."

        // Account state
        case .accountNotVerified:
            return "Your email isn't verified yet. Open the link we sent to confirm your account."

        // Session
        case .missingTokens:
            return "Your session ended. Please sign in again."
        case .expiredSession:
            return "Your session expired for security reasons. Please sign in again."
        case .invalidCredentials:
            return "Incorrect email or password."
        case .unauthorized:
            return "You're not authorized to do that. Please sign in again."
        case .tooManyAttempts(let retryAfter):
            if let retryAfter {
                return "Too many attempts. Try again in \(retryAfter) seconds."
            }
            return "Too many attempts. Please wait a moment and try again."

        // Availability
        case .rateLimited:
            return "You're going a bit fast. Please wait a moment and try again."
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."

        // Server / fallback
        case .serverMessage(let message):
            return message
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    // MARK: - Recovery hint (optional, for UI that wants a secondary line)
    var recoverySuggestion: String? {
        switch self {
        case .usernameConflict, .invalidUsername:
            return "Try adding a number or underscore."
        case .emailConflict, .accountAlreadyExists:
            return "Sign in instead, or reset your password."
        case .accountNotFound:
            return "Check the spelling, or register a new account."
        case .invalidEmail:
            return "Example: you@example.com"
        case .weakPassword:
            return "Try a longer passphrase."
        case .passwordMismatch:
            return "Re-enter both fields carefully."
        case .invalidCode, .expiredCode:
            return "Request a new code."
        case .accountNotVerified:
            return "Resend the verification email below."
        case .missingTokens, .expiredSession, .unauthorized:
            return "Return to the login screen to continue."
        case .invalidCredentials:
            return "Forgot your password? Reset it."
        case .tooManyAttempts, .rateLimited:
            return "Wait a few moments before retrying."
        case .networkUnavailable:
            return "Check Wi-Fi or cellular data."
        case .serverMessage, .unknown:
            return nil
        }
    }

    // MARK: - Whether the user can retry the same action immediately
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .rateLimited, .tooManyAttempts, .serverMessage, .unknown:
            return true
        default:
            return false
        }
    }

    // MARK: - Whether the client should force a re-authentication
    var requiresReauthentication: Bool {
        switch self {
        case .missingTokens, .expiredSession, .unauthorized:
            return true
        default:
            return false
        }
    }

    // MARK: - Whether the account just needs to be verified to proceed
    var isUnverifiedAccount: Bool {
        if case .accountNotVerified = self { return true }
        return false
    }
}

// MARK: - Convenience

extension AuthError {
    /// Maps an HTTP status + optional server-provided code/message to the
    /// closest matching `AuthError`. Prefers the server `code` when present
    /// because it's stable, and falls back to substring matching on the
    /// human-readable message.
    static func from(
        statusCode: Int,
        serverCode: String? = nil,
        serverMessage: String? = nil
    ) -> AuthError {
        let code = serverCode?.uppercased() ?? ""
        let message = serverMessage?.lowercased() ?? ""

        // Codes are the reliable signal.
        if code == "ACCOUNT_NOT_VERIFIED"
            || code == "EMAIL_NOT_VERIFIED"
            || code == "USER_NOT_VERIFIED"
            || code == "UNVERIFIED_ACCOUNT" {
            return .accountNotVerified
        }

        if code == "REFRESH_TOKEN_INVALID"
            || code == "TOKEN_INVALID"
            || code == "TOKEN_EXPIRED" {
            return .expiredSession
        }

        if code == "INVALID_CREDENTIALS" {
            return .invalidCredentials
        }

        if code == "RATE_LIMITED" || code == "TOO_MANY_REQUESTS" {
            return .rateLimited
        }

        if code == "WEAK_PASSWORD" {
            return .weakPassword
        }

        if code == "USERNAME_CONFLICT" {
            return .usernameConflict
        }

        if code == "EMAIL_CONFLICT" {
            return .emailConflict
        }

        // Fall back to status + free-text message.
        switch statusCode {
        case 400:
            if message.contains("verif") { return .accountNotVerified }
            if message.contains("code") { return .invalidCode }
            if message.contains("email") { return .invalidEmail }
            if message.contains("password") { return .weakPassword }
            return .serverMessage(serverMessage ?? "Bad request")

        case 401:
            if message.contains("verif") { return .accountNotVerified }
            return .invalidCredentials

        case 403:
            if message.contains("verif") { return .accountNotVerified }
            return .unauthorized

        case 404:
            return .accountNotFound

        case 409:
            if message.contains("username") { return .usernameConflict }
            if message.contains("email") { return .emailConflict }
            return .accountAlreadyExists

        case 410:
            return .expiredCode

        case 422:
            if message.contains("verif") { return .accountNotVerified }
            if message.contains("password") { return .weakPassword }
            if message.contains("email") { return .invalidEmail }
            if message.contains("username") { return .invalidUsername }
            return .serverMessage(serverMessage ?? "Validation failed")

        case 429:
            return .rateLimited

        case 500...599:
            return .serverMessage(serverMessage ?? "The server is having trouble. Try again shortly.")

        default:
            return serverMessage.map(AuthError.serverMessage) ?? .unknown
        }
    }
}

struct APIErrorResponse: Decodable {
    let error: String
    let code: String
    let detail: String?
}
