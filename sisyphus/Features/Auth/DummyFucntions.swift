//
//  DummyFucntions.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/09/2026.
//

//
//  AuthServices+Dummy.swift
//  sisyphus
//
//  Temporary in-memory stubs for the auth flows so the UI can be built
//  and previewed before the real backend endpoints exist. Each function
//  has a short artificial delay so loaders/spinners behave realistically.
//
//  ⚠️ Replace with real networking calls before shipping.
//

import Foundation

// MARK: - Password reset

/// Sends a password reset code to the given email.
/// Dummy: always succeeds after a short delay.
func sendPasswordResetCodeService(email: String) async throws {
    try await Task.sleep(nanoseconds: 800_000_000)
    // Real implementation should call your backend, e.g.:
    // try await api.post("/auth/password/forgot", body: ["email": email])
}

/// Verifies a password reset code.
/// Dummy: accepts `123456` or any 6-digit code; rejects everything else.
func verifyPasswordResetCodeService(email: String, code: String) async throws {
    try await Task.sleep(nanoseconds: 800_000_000)

    guard code.count == 6, code.allSatisfy(\.isNumber) else {
        throw AuthError.invalidCode
    }
    // For a stricter demo, uncomment:
    // guard code == "123456" else { throw AuthError.invalidCode }
}

/// Applies a new password using a previously verified reset code.
/// Dummy: always succeeds.
func resetPasswordService(email: String, code: String, newPassword: String) async throws {
    try await Task.sleep(nanoseconds: 800_000_000)

    guard newPassword.count >= 8 else {
        throw AuthError.weakPassword
    }
}

// MARK: - Email verification

/// Sends an email verification code.
/// Dummy: always succeeds after a short delay.
func sendEmailVerificationCodeService(email: String) async throws {
    try await Task.sleep(nanoseconds: 800_000_000)
}

/// Verifies an email verification code.
/// Dummy: accepts `123456` or any 6-digit code; rejects everything else.
func verifyEmailCodeService(email: String, code: String) async throws {
    try await Task.sleep(nanoseconds: 800_000_000)

    guard code.count == 6, code.allSatisfy(\.isNumber) else {
        throw AuthError.invalidCode
    }
    // For a stricter demo, uncomment:
    // guard code == "123456" else { throw AuthError.invalidCode }
}
