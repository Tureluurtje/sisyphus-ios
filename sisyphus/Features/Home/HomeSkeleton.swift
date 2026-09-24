//  HomeSkeleton.swift
//  sisyphus
//
//  Placeholder that mirrors HomeView's `homePage` layout while loading.
//

import SwiftUI

struct HomeSkeleton: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                heroSkeleton
                ctaSkeleton
                statsSkeleton
                stacksSkeleton
            }
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .allowsHitTesting(false)
    }

    // MARK: Hero — "VERBUM DIEI" / word / translation
    private var heroSkeleton: some View {
        VStack(alignment: .leading, spacing: 10) {
            SkeletonBar(width: 110, height: 10, cornerRadius: 4)
            SkeletonBar(width: 220, height: 30, cornerRadius: 8)
            SkeletonBar(width: 150, height: 14, cornerRadius: 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: CTA card — "Today's session" / N words due / play button
    private var ctaSkeleton: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                SkeletonBar(width: 110, height: 10, cornerRadius: 4)
                SkeletonBar(width: 150, height: 26, cornerRadius: 8)
            }

            Spacer()

            SkeletonCircle(size: 52)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: Stats row — Streak / Learned
    private var statsSkeleton: some View {
        HStack(spacing: 12) {
            statCardSkeleton
            statCardSkeleton
        }
        .padding(.horizontal, 20)
    }

    private var statCardSkeleton: some View {
        VStack(spacing: 10) {
            SkeletonCircle(size: 16)
            SkeletonBar(width: 40, height: 20, cornerRadius: 6)
            SkeletonBar(width: 52, height: 10, cornerRadius: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: Stacks section — header + 3 placeholder rows
    private var stacksSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonBar(width: 60, height: 10, cornerRadius: 4)
                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    stackRowSkeleton
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var stackRowSkeleton: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBar(width: 90, height: 18, cornerRadius: 6)
                SkeletonBar(width: 50, height: 10, cornerRadius: 4)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SkeletonBar(width: 36, height: 12, cornerRadius: 4)
                SkeletonBar(width: 60, height: 6, cornerRadius: 3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

#Preview("Home skeleton") {
    NavigationStack {
        HomeSkeleton()
    }
}
