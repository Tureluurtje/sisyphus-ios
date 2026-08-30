import Foundation
import SwiftUI

/// Context attached to a captured error: indexed tags, extra debugging data,
/// and an optional custom grouping fingerprint.
///
/// ```swift
/// let context = ErrorContext(tags: ["feature": "auth", "action": "login"])
/// ErrorMonitoring.shared.service.captureError(error, context: context)
/// ```
struct ErrorContext: Sendable {
    var tags: [String: String]
    var extra: [String: String]
    var fingerprint: [String]?

    init(
        tags: [String: String] = [:],
        extra: [String: String] = [:],
        fingerprint: [String]? = nil
    ) {
        self.tags = tags
        self.extra = extra
        self.fingerprint = fingerprint
    }
}

extension ErrorContext {
    func tag(_ key: String, _ value: String) -> ErrorContext {
        var copy = self
        copy.tags[key] = value
        return copy
    }

    func with(_ key: String, _ value: String) -> ErrorContext {
        var copy = self
        copy.extra[key] = value
        return copy
    }
}

// MARK: - Breadcrumb

/// A single event leading up to a future error, for later context.
struct Breadcrumb: Sendable {
    let timestamp: Date
    let category: String
    let message: String
    let level: ErrorLevel
    let data: [String: String]?

    init(
        category: String,
        message: String,
        level: ErrorLevel = .info,
        data: [String: String]? = nil
    ) {
        self.timestamp = .now
        self.category = category
        self.message = message
        self.level = level
        self.data = data
    }
}

extension Breadcrumb {
    static func navigation(_ screenName: String) -> Breadcrumb {
        Breadcrumb(category: "navigation", message: "Viewed \(screenName)")
    }

    static func user(_ action: String, data: [String: String]? = nil) -> Breadcrumb {
        Breadcrumb(category: "user", message: action, data: data)
    }
}

// MARK: - SwiftUI Navigation Tracking

extension View {
    /// Adds a navigation breadcrumb when this view appears.
    func trackScreen(_ name: String) -> some View {
        onAppear {
            ErrorMonitoring.shared.service.addBreadcrumb(.navigation(name))
        }
    }
}
