//
//  ErrorHostModifier.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI

struct ErrorHostModifier: ViewModifier {

    @EnvironmentObject var errorManager: ErrorManager

    func body(content: Content) -> some View {
        ZStack {
            content

            if errorManager.isShowing, let message = errorManager.message {
                ErrorPopupView(message: message)
                    .zIndex(999)
            }
        }
    }
}

extension View {
    func withErrorHost() -> some View {
        self.modifier(ErrorHostModifier())
    }
}
