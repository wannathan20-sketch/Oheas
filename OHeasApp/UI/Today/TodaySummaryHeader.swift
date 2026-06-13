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
/// a single distilled insight line ("One Big Thing") + compact 3-metric strip.
///
/// Replaces the separate TodayHeroSection + BodyBudgetRing pairing with a unified
/// score-first layout where the ring is the visual anchor of the entire page.
///
/// Phase 23: gradient extended to 140pt (Oura-style recovery backdrop),
/// compact 3-metric horizontal strip below ring replaces the bulky BodyBudgetGauge card.
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
    /// Tap action on the score ring (e.g., navigate to Trends).
    var onTapScoreRing: (() -> Void)?
    /// Recent daily metrics for computing trends in the compact strip.
    var recentDailyMetrics: [DailyHealthMetrics] = []

    @State private var heroGlow = false
    @State private var glowCycles = 0

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }

    var body: some View {
        VStack(spacing: 0) {
            // Extended gradient header (140pt) — Oura-style recovery backdrop
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)

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
                .padding(.bottom, 72)  // push greeting up into the taller gradient
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
            .onTapGesture {
                onTapScoreRing?()
            }

            // Compact 3-metric horizontal strip — at-a-glance sleep/HRV/RHR
            metricStrip
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // "One Big Thing" insight — card with left accent bar
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(OhColor.primary.opacity(0.5))
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.tiny))

                    if let insight = oneBigThing {
                        Text(insight)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(language.text(.loading))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(12)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(OhAnimation.glow.repeatCount(3, autoreverses: true)) {
                heroGlow = true
            }
        }
    }

    // MARK: - Compact Metric Strip

    /// Three key recovery metrics in a compact horizontal row:
    /// each shows icon + value + trend arrow. Replaces the bulky BodyBudgetGauge.
    private var metricStrip: some View {
        HStack(spacing: 0) {
            metricPill(
                icon: "bed.double.fill",
                color: OhColor.sleep,
                value: today.sleepHours.map { String(format: "%.1fh", $0) } ?? language.missing,
                trend: sleepTrend
            )
            Spacer()
            metricPill(
                icon: "waveform.path.ecg",
                color: OhColor.hrv,
                value: today.hrv.map { String(format: "%.0fms", $0) } ?? language.missing,
                trend: hrvTrend
            )
            Spacer()
            metricPill(
                icon: "heart.fill",
                color: OhColor.restingHR,
                value: today.restingHeartRate.map { String(format: "%.0fbpm", $0) } ?? language.missing,
                trend: rhrTrend
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }

    private func metricPill(icon: String, color: Color, value: String, trend: Trend?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.caption.weight(.semibold))
            TrendIndicator(trend: trend, higherIsBetter: icon != "heart.fill")
        }
        .frame(minWidth: 0)
    }

    // MARK: - Trend computation

    private var sleepTrend: Trend? {
        Trend.compute(from: recentDailyMetrics.suffix(7).map(\.sleepHours))
    }
    private var hrvTrend: Trend? {
        Trend.compute(from: recentDailyMetrics.suffix(7).map(\.hrv))
    }
    private var rhrTrend: Trend? {
        Trend.computeInverted(from: recentDailyMetrics.suffix(7).map(\.restingHeartRate))
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
