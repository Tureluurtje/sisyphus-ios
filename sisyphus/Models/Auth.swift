//
//  Auth.swift
//  sisyphus
//
//  Created by Arthur Kwak on 14/06/2026.
//

struct TokenPair: Decodable {
    let accessToken: String
    let refreshToken: String
    let csrfToken: String
}

struct RefreshTokenPair {
    let refreshToken: String
    let csrfToken: String
}

enum AppState {
    case loading
    case serverError
    case authenticated
    case unauthenticated
}
