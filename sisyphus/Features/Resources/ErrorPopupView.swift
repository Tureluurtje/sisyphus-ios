//
//  ErrorPopupView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI

struct ErrorPopupView: View {
    let message: String

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)

                Text(message)
                    .foregroundColor(.white)
                    .font(.subheadline)

                Spacer()
            }
            .padding()
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
