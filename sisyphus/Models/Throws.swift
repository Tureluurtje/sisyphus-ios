//
//  Throws.swift
//  sisyphus
//
//  Created by Arthur Kwak on 14/06/2026.
//

enum AuthError: Error {
    case usernameConflict
    case emailConflict
    case invalidEmail
    case weakPassword
    case missingTokens
    case serverMessage(String)
    case unknown

    var userFacingMessage: String {
        switch self {
        case .usernameConflict:
            return "Username already taken"
        case .emailConflict:
            return "Email already taken"
        case .invalidEmail:
            return "Email is invalid"
        case .weakPassword:
            return "Password is too weak"
        case .serverMessage(let message):
            return message
        case .missingTokens, .unknown:
            return "Something went wrong"
        }
    }
}

struct APIErrorResponse: Decodable {
    let error: String
    let code: String
    let detail: String?
}
