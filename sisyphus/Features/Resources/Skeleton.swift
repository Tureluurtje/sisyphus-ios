//
//  Skeleton.swift
//  sisyphus
//
//  Shared shimmering placeholders for loading states.
//

import SwiftUI

// MARK: - Colors

extension Color {
    /// Base fill for skeleton shapes. Adapts to light/dark via `.primary`.
    static let skeletonBase = Color.primary.opacity(0.08)
}

// MARK: - Skeleton primitives

/// A shimmering placeholder bar. When `width` is nil, expands to fill.
struct SkeletonBar: View {
    var width: CGFloat? = nil
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.skeletonBase)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .overlay {
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.35), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: animate ? 400 : -400)
                .animation(
                    reduceMotion
                        ? nil
                        : .linear(duration: 1.4).repeatForever(autoreverses: false),
                    value: animate
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear { animate = true }
            .accessibilityHidden(true)
    }
}

/// A shimmering placeholder circle.
struct SkeletonCircle: View {
    var size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(Color.skeletonBase)
            .frame(width: size, height: size)
            .overlay {
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.35), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: animate ? size : -size)
                .animation(
                    reduceMotion
                        ? nil
                        : .linear(duration: 1.4).repeatForever(autoreverses: false),
                    value: animate
                )
            }
            .clipShape(Circle())
            .onAppear { animate = true }
            .accessibilityHidden(true)
    }
}
