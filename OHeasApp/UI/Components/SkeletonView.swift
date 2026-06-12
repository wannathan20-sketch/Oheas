//
//  SkeletonView.swift
//  OHeas
//
//  SkeletonView.swift — OHeas UI component.
//  SkeletonView.swift — OHeas UI 组件。
//


import SwiftUI

// MARK: - Shimmer Modifier

/// Adds a shimmering gradient animation overlaid on the view.
/// Use in combination with `.redacted(reason: .placeholder)` for a loading skeleton effect.
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.4), location: 0.5),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(15))
                .scaleEffect(x: 1.5, y: 3)
                .offset(x: phase * 400)
                .mask(content)
            )
            .onAppear {
                withAnimation(OhAnimation.shimmer) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Card

/// A single skeleton card placeholder with shimmer animation.
struct SkeletonCard: View {
    let height: CGFloat

    init(height: CGFloat = 120) {
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: Radius.small)
            .fill(Color(.systemGray5))
            .frame(height: height)
            .shimmer()
    }
}

// MARK: - Skeleton Section

/// A skeleton section with title placeholder and content cards.
struct SkeletonSection: View {
    let cardCount: Int
    let cardHeight: CGFloat

    init(cardCount: Int = 3, cardHeight: CGFloat = 80) {
        self.cardCount = cardCount
        self.cardHeight = cardHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title skeleton
            RoundedRectangle(cornerRadius: Radius.tiny)
                .fill(Color(.systemGray4))
                .frame(width: 120, height: 20)
                .shimmer()

            // Card skeletons
            ForEach(0..<cardCount, id: \.self) { _ in
                SkeletonCard(height: cardHeight)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
    }
}

// MARK: - Skeleton Loading View

/// Full-page skeleton loading view composed of multiple sections.
struct SkeletonLoadingView: View {
    let sections: [(cardCount: Int, cardHeight: CGFloat)]

    init(sections: [(cardCount: Int, cardHeight: CGFloat)] = [
        (1, 140),   // Body budget
        (1, 100),   // Signals / Recommendation
        (1, 200),   // Feedback / Yesterday
    ]) {
        self.sections = sections
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                SkeletonSection(cardCount: section.cardCount, cardHeight: section.cardHeight)
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Skeleton Card") {
    SkeletonCard(height: 120)
        .padding()
}

#Preview("Skeleton Section") {
    SkeletonSection(cardCount: 3, cardHeight: 80)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Full Loading") {
    ScrollView {
        SkeletonLoadingView()
    }
    .background(Color(.systemGroupedBackground))
}
