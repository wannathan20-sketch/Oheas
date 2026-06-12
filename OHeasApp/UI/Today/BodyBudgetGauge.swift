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

/// Recovery detail card showing three key metrics with sparklines,
/// a category-driven explanation, signal summaries, and contribution breakdown.
struct BodyBudgetGauge: View {
    let score: BodyBudgetScore?
    let today: DailyHealthMetrics
    let quality: DataQualityReport
    let detectedSignals: [HealthSignal]
    let recentDailyMetrics: [DailyHealthMetrics]
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            // Three key recovery metrics with sparklines (full width)
            VStack(spacing: 10) {
                gaugeMetricRow(
                    icon: "bed.double.fill", color: OhColor.sleep,
                    label: language.metric(.sleepHours),
                    value: today.sleepHours.map { String(format: "%.1fh", $0) } ?? language.missing,
                    sparkline: recentDailyMetrics.suffix(7).map(\.sleepHours)
                )
                gaugeMetricRow(
                    icon: "waveform.path.ecg", color: OhColor.hrv,
                    label: language.metric(.hrv),
                    value: today.hrv.map { String(format: "%.0fms", $0) } ?? language.missing,
                    sparkline: recentDailyMetrics.suffix(7).map(\.hrv)
                )
                gaugeMetricRow(
                    icon: "heart.fill", color: OhColor.restingHR,
                    label: language.metric(.restingHeartRate),
                    value: today.restingHeartRate.map { String(format: "%.0fbpm", $0) } ?? language.missing,
                    sparkline: recentDailyMetrics.suffix(7).map(\.restingHeartRate)
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

    private func gaugeMetricRow(icon: String, color: Color, label: String, value: String, sparkline: [Double?]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            Text(value)
                .font(.subheadline.weight(.semibold))

            Spacer()

            SparklineView(values: sparkline, color: color)
                .frame(width: 50)
        }
        .padding(.vertical, 2)
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
