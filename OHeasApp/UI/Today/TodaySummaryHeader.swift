//
//  TodaySummaryHeader.swift
//  OHeas
//
//  Score-first summary header — compressed hero gradient + large score ring
//  + "One Big Thing" daily insight.
//
//  Market reference: Oura v2025 "One Big Thing", Whoop Recovery ring front-and-center.
//

import OHeasCore
import SwiftUI

/// The top section of TodayView: gradient greeting area + prominent score ring +
/// a single distilled insight line ("One Big Thing").
///
/// Replaces the separate TodayHeroSection + BodyBudgetRing pairing with a unified
/// score-first layout where the ring is the visual anchor of the entire page.
struct TodaySummaryHeader: View {
    let score: BodyBudgetScore?
    let today: DailyHealthMetrics
    let quality: DataQualityReport
    let detectedSignals: [HealthSignal]
    let dataSource: HealthDataSource
    let language: AppLanguage
    let reduceMotion: Bool
    /// Current check-in streak count (for flame display).
    var checkInStreak: Int = 0

    @State private var heroGlow = false

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }

    var body: some View {
        VStack(spacing: 0) {
            // Compressed gradient header (80pt vs old 140pt)
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text(language.formatDate(Date.now, dateStyle: .long))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if checkInStreak > 0 {
                        StreakFlameView(
                            count: checkInStreak,
                            language: language,
                            reduceMotion: reduceMotion
                        )
                        .padding(.trailing, 8)
                    }
                    dataSourceBadge
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }

            // Score ring — overlaps the gradient boundary for visual continuity
            BodyBudgetRing(
                score: score,
                language: language,
                size: 110,
                lineWidth: 14,
                reduceMotion: reduceMotion
            )
            .padding(.top, -30)

            // "One Big Thing" insight
            VStack(spacing: 4) {
                if let insight = oneBigThing {
                    Text(insight)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text(language.text(.loading))
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(OhAnimation.glow) { heroGlow = true }
        }
    }

    // MARK: - Greeting

    private var greeting: String {
        switch hour {
        case 6..<12: language.text(.greetingMorning)
        case 12..<18: language.text(.greetingAfternoon)
        default: language.text(.greetingEvening)
        }
    }

    // MARK: - Gradient

    private var gradientColors: [Color] {
        let glow = heroGlow
        let hasSignals = !detectedSignals.isEmpty
        let hasHighSignal = detectedSignals.contains(where: { $0.severity == .high })

        switch quality.overallConfidence {
        case .high where hasHighSignal:
            return [.orange.opacity(glow ? 0.55 : 0.38), .yellow.opacity(glow ? 0.26 : 0.16), OhColor.groupedBg]
        case .high where hasSignals:
            return [.indigo.opacity(glow ? 0.50 : 0.34), .mint.opacity(glow ? 0.24 : 0.15), OhColor.groupedBg]
        case .high:
            return [.mint.opacity(glow ? 0.72 : 0.52), .teal.opacity(glow ? 0.34 : 0.22), OhColor.groupedBg]
        case .medium:
            return [.orange.opacity(glow ? 0.42 : 0.28), .yellow.opacity(glow ? 0.20 : 0.12), OhColor.groupedBg]
        case .low:
            return [.gray.opacity(glow ? 0.38 : 0.26), .indigo.opacity(glow ? 0.20 : 0.12), OhColor.groupedBg]
        }
    }

    // MARK: - One Big Thing

    /// A single distilled insight based on the score category and detected signals.
    /// Uses the existing `budgetScoreExplanation` for category-driven text,
    /// augmented with signal-specific language when high-severity signals are present.
    private var oneBigThing: String? {
        guard let score = score else { return nil }
        var base = language.budgetScoreExplanation(score.category)

        // Augment with signal count for strained/depleted states
        let highCount = detectedSignals.filter { $0.severity == .high }.count
        if highCount > 0 && (score.category == .strained || score.category == .depleted) {
            base += " " + String(format: language.text(.signalSummaryHigh), highCount)
        }

        return base
    }

    // MARK: - Data Source Badge

    private var dataSourceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: dataSource == .appleHealth ? "applewatch" : "testtube.2")
                .font(.caption.weight(.semibold))
            Text(language.dataSource(dataSource))
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(dataSource == .appleHealth ? .green : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Excellent score") {
    TodaySummaryHeader(
        score: BodyBudgetScore(value: 92, category: .excellent,
                               recoverySubscore: 88, activitySubscore: 85,
                               subjectiveSubscore: 90, signalPenalty: 0),
        today: DailyHealthMetrics(date: Date()),
        quality: DataQualityReport(
            perMetricStatus: [:], overallConfidence: .high,
            missingReasons: [], shouldAskUserFollowup: false,
            suggestedFollowupQuestion: nil
        ),
        detectedSignals: [],
        dataSource: .appleHealth,
        language: .english,
        reduceMotion: false
    )
}

#Preview("Strained with signals") {
    TodaySummaryHeader(
        score: BodyBudgetScore(value: 42, category: .strained,
                               recoverySubscore: 35, activitySubscore: 50,
                               subjectiveSubscore: 45, signalPenalty: 15),
        today: DailyHealthMetrics(date: Date()),
        quality: DataQualityReport(
            perMetricStatus: [:], overallConfidence: .medium,
            missingReasons: [], shouldAskUserFollowup: false,
            suggestedFollowupQuestion: nil
        ),
        detectedSignals: [
            HealthSignal(type: .sleepLow, severity: .high,
                        evidence: "Sleep 5.2h vs baseline 7.0h",
                        explanation: "Sleep significantly below baseline"),
            HealthSignal(type: .hrvLow, severity: .medium,
                        evidence: "HRV 32ms vs baseline 48ms",
                        explanation: "HRV below baseline")
        ],
        dataSource: .appleHealth,
        language: .english,
        reduceMotion: false
    )
}
