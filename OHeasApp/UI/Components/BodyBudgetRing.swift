//
//  BodyBudgetRing.swift
//  OHeas
//
//  Circular gauge ring displaying the Body Budget Score (0-100).
//  Inspired by Oura Readiness ring and Whoop Recovery %.
//  受 Oura Readiness 圆环和 Whoop Recovery 百分比启发。
//

import SwiftUI
import OHeasCore

/// An animated circular gauge ring that displays the Body Budget Score.
struct BodyBudgetRing: View {
    let score: BodyBudgetScore?
    let language: AppLanguage
    let size: CGFloat
    let lineWidth: CGFloat
    let reduceMotion: Bool

    @State private var animatedProgress: CGFloat = 0

    init(
        score: BodyBudgetScore?,
        language: AppLanguage,
        size: CGFloat = 90,
        lineWidth: CGFloat = 12,
        reduceMotion: Bool = false
    ) {
        self.score = score
        self.language = language
        self.size = size
        self.lineWidth = lineWidth
        self.reduceMotion = reduceMotion
    }

    var body: some View {
        ZStack {
            // Track circle
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress * gaugeFraction)
                .stroke(scoreColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : OhAnimation.gauge(), value: animatedProgress)

            // Center text
            VStack(spacing: 2) {
                if let score = score {
                    Text("\(score.value)")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    Text(language.budgetCategory(score.category))
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(language.text(.loading))
                        .font(.system(size: size * 0.12))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { animateIfNeeded() }
        .onChange(of: score?.value) { _, _ in animateIfNeeded() }
    }

    // MARK: - Helpers

    private func animateIfNeeded() {
        animatedProgress = 0
        guard !reduceMotion else {
            animatedProgress = 1
            return
        }
        withAnimation(OhAnimation.gauge()) {
            animatedProgress = 1
        }
    }

    /// The gauge fills proportionally to the score from 0 to 1.
    /// Minimum visible fill is 0.15 (even a score of 0 shows a sliver).
    private var gaugeFraction: CGFloat {
        guard let score = score else { return 0.15 }
        let fraction = CGFloat(score.value) / 100.0
        return max(0.15, fraction)
    }

    private var trackColor: Color {
        scoreColor.opacity(0.15)
    }

    /// Score-driven color: green → yellow → orange → red gradient.
    var scoreColor: Color {
        guard let score = score else { return OhColor.gaugeTrackColor }
        let v = Double(score.value) / 100.0
        switch v {
        case 0.70...:  return Color.green
        case 0.55...:  return Color.yellow
        case 0.35...:  return Color.orange
        default:       return Color.red
        }
    }
}

// MARK: - OhColor gauge fallback

extension OhColor {
    static let gaugeTrackColor = Color.secondary.opacity(0.15)
}
