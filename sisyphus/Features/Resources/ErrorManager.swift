//
//  ErrorManager.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI
import Combine
import OSLog

@MainActor
final class ErrorManager: ObservableObject {

    @Published var message: String?
    @Published var isShowing: Bool = false

    private var dismissTask: Task<Void, Never>?

    func show(_ message: String) {
        AppLogger.general.notice("Showing error to user: \(message, privacy: .public)")

        dismissTask?.cancel()

        self.message = message
        self.isShowing = true

        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation {
                self?.isShowing = false
            }
        }
    }
}
