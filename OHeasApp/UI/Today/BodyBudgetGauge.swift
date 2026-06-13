//
//  BodyBudgetGauge.swift
//  OHeas
//
//  Recovery detail card — 3 key metric sparkline rows + explanation + contribution breakdown.
//  恢复指标详情卡片 — 三项关键指标折线行 + 说明 + 贡献分解。
//
//  Phase 18: Score ring moved to TodaySummaryHeader; this card now focuses on
//  metric details and contribution factors.
//

import OHeasCore
import SwiftUI

/// Recovery detail card showing three key metrics as horizontal columns,
/// a category-driven explanation, signal summaries, and contribution breakdown.
///
/// Phase 23: transformed from vertical rows to horizontal 3-column compact strip
/// with sparklines, following the Oura Recovery compact layout pattern.
struct BodyBudgetGauge: View {
    let score: BodyBudgetScore?
    let today: DailyHealthMetrics
    let quality: DataQualityReport
    let detectedSignals: [HealthSignal]
    let recentDailyMetrics: [DailyHealthMetrics]
    let language: AppLanguage

    // MARK: - Cached sparkline data

    private struct SparklineCache {
        let sleep: [Double?]
        let hrv: [Double?]
        let rhr: [Double?]
    }

    private var sparklineCache: SparklineCache {
        let recent = recentDailyMetrics.suffix(7)
        return SparklineCache(
            sleep: recent.map(\.sleepHours),
            hrv: recent.map(\.hrv),
            rhr: recent.map(\.restingHeartRate)
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            // Three key recovery metrics — horizontal 3-column layout
            HStack(alignment: .top, spacing: 4) {
                let cache = sparklineCache
                metricColumn(
                    label: language.metric(.sleepHours),
                    icon: "bed.double.fill",
                    color: OhColor.sleep,
                    value: today.sleepHours.map { String(format: "%.1f", $0) } ?? language.missing,
                    unit: "h",
                    sparkline: cache.sleep
                )
                metricColumn(
                    label: language.metric(.hrv),
                    icon: "waveform.path.ecg",
                    color: OhColor.hrv,
                    value: today.hrv.map { String(format: "%.0f", $0) } ?? language.missing,
                    unit: "ms",
                    sparkline: cache.hrv
                )
                metricColumn(
                    label: language.metric(.restingHeartRate),
                    icon: "heart.fill",
                    color: OhColor.restingHR,
                    value: today.restingHeartRate.map { String(format: "%.0f", $0) } ?? language.missing,
                    unit: "bpm",
                    sparkline: cache.rhr
                )
            }

            Divider()

            // Category-driven explanation
            VStack(alignment: .leading, spacing: 6) {
                Label(explanationText, systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !detectedSignals.isEmpty {
                    Text(signalSummaryText)
                        .font(.caption)
                        .foregroundStyle(detectedSignals.contains(where: { $0.severity == .high }) ? .red : .orange)
                }
                if quality.overallConfidence != .high {
                    Text(language.confidence(quality.overallConfidence) + " " + language.text(.dataConfidence).lowercased())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Contribution breakdown
            if let factors = score?.factors, !factors.isEmpty {
                ContributionBar(factors: factors, language: language)
            }
        }
        .padding()
        .background(OhColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.large))
        .shadow(color: .black.opacity(OhShadow.card.opacity), radius: OhShadow.card.radius, y: OhShadow.card.y)
    }

    // MARK: - Metric column

    /// A single compact metric column: icon + label, value with unit,
    /// mini sparkline, and trend direction word.
    private func metricColumn(
        label: String, icon: String, color: Color,
        value: String, unit: String, sparkline: [Double?]
    ) -> some View {
        VStack(spacing: 4) {
            // Header: icon + metric name
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Value + unit (header style: "睡眠 7.2h ↑")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                if let trend = sparklineTrend(sparkline) {
                    Image(systemName: trendArrow(trend))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(trendColor(trend))
                }
            }

            // Mini sparkline
            SparklineView(values: sparkline, color: color)
                .frame(width: 50, height: 20)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sparkline trend helpers

    private func sparklineTrend(_ values: [Double?]) -> Trend.Direction? {
        Trend.compute(from: values)?.direction
    }

    private func trendArrow(_ direction: Trend.Direction) -> String {
        switch direction {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .flat: "arrow.right"
        }
    }

    private func trendColor(_ direction: Trend.Direction) -> Color {
        switch direction {
        case .up: OhColor.success
        case .down: OhColor.warning
        case .flat: .secondary
        }
    }

    // MARK: - Helpers

    private var explanationText: String {
        if let score = score {
            return language.budgetScoreExplanation(score.category)
        }
        switch quality.overallConfidence {
        case .high: return language.text(.bodyBudgetExplanationHigh)
        case .medium: return language.text(.bodyBudgetExplanationMedium)
        case .low: return language.text(.bodyBudgetExplanationLow)
        }
    }

    private var signalSummaryText: String {
        let highCount = detectedSignals.filter { $0.severity == .high }.count
        if highCount > 0 {
            return String(format: language.text(.signalSummaryHigh), highCount)
        }
        return String(format: language.text(.signalSummaryGeneral), detectedSignals.count)
    }
}

// MARK: - Previews

#Preview("Recovery detail card") {
    BodyBudgetGauge(
        score: BodyBudgetScore(value: 78, category: .good,
                               recoverySubscore: 75, activitySubscore: 70,
                               subjectiveSubscore: 80, signalPenalty: 0),
        today: DailyHealthMetrics(date: Date()),
        quality: DataQualityReport(
            perMetricStatus: [:], overallConfidence: .high,
            missingReasons: [], shouldAskUserFollowup: false,
            suggestedFollowupQuestion: nil
        ),
        detectedSignals: [],
        recentDailyMetrics: [],
        language: .english
    )
    .padding()
}
