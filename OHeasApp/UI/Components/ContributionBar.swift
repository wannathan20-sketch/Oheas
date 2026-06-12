//
//  ContributionBar.swift
//  OHeas
//
//  Contribution breakdown bars — shows how each factor affects the Body Budget Score.
//  贡献分解条 — 展示各因子对身体预算评分的影响。
//
//  Market reference: Whoop "Contributing Factors" bars, Oura Readiness contributors.
//

import OHeasCore
import SwiftUI

// MARK: - ContributionBar

/// A vertical stack of horizontal contribution bars showing how each `BudgetFactor`
/// affects the overall Body Budget Score.
///
/// Positive contributions (green) helped the score; negative (orange/red) hurt it.
/// Bars are proportional to contribution magnitude, sorted by absolute impact.
struct ContributionBar: View {
    let factors: [BudgetFactor]
    let language: AppLanguage

    /// Maximum number of factors to display (prevents visual overload).
    var maxItems: Int = 6

    var body: some View {
        let sorted = factors
            .sorted { abs($0.contribution) > abs($1.contribution) }
            .prefix(maxItems)

        if sorted.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 8) {
                Label(language.text(.budgetScoreFactorsLabel), systemImage: "rectangle.split.2x2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(Array(sorted), id: \.metric) { factor in
                    contributionRow(factor)
                }
            }
        }
    }

    // MARK: - Row

    private func contributionRow(_ factor: BudgetFactor) -> some View {
        let maxContribution = factors.map { abs($0.contribution) }.max() ?? 1
        let fraction = maxContribution > 0 ? abs(factor.contribution) / maxContribution : 0

        return HStack(spacing: 8) {
            // Metric icon
            Image(systemName: metricIcon(factor.metric))
                .font(.caption2)
                .foregroundStyle(metricColor(factor.metric))
                .frame(width: 14)

            // Metric name
            Text(language.metric(factor.metric))
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 48, alignment: .leading)

            // Contribution bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(contributionColor(factor).opacity(0.12))
                        .frame(height: 6)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 2)
                        .fill(contributionColor(factor))
                        .frame(width: max(4, geo.size.width * CGFloat(fraction)), height: 6)
                }
            }
            .frame(height: 6)

            // Contribution value
            Text(formatContribution(factor.contribution))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(contributionColor(factor))
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func contributionColor(_ factor: BudgetFactor) -> Color {
        let c = factor.contribution
        if c > 1 { return OhColor.success }
        if c < -1 { return OhColor.warning }
        return .secondary
    }

    private func formatContribution(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(Int(value.rounded()))"
    }

    /// Map BudgetFactor contribution strength to visual style.
    private func contributionWeight(_ factor: BudgetFactor) -> Double {
        abs(factor.contribution)
    }
}

// MARK: - Previews

#Preview("Contribution bars") {
    let factors: [BudgetFactor] = [
        BudgetFactor(metric: .sleepHours, contribution: 15, weight: 0.133,
                     explanation: "Sleep 7.2h, above baseline 6.8h"),
        BudgetFactor(metric: .hrv, contribution: 8, weight: 0.133,
                     explanation: "HRV 52ms, above baseline 48ms"),
        BudgetFactor(metric: .restingHeartRate, contribution: -10, weight: 0.133,
                     explanation: "RHR 62 bpm, above baseline 58 bpm"),
        BudgetFactor(metric: .steps, contribution: 5, weight: 0.125,
                     explanation: "Steps 8500, above baseline 7200"),
        BudgetFactor(metric: .exerciseMinutes, contribution: -6, weight: 0.125,
                     explanation: "Exercise 15 min, below baseline 25 min"),
    ]

    VStack(spacing: 20) {
        ContributionBar(factors: factors, language: .english)
            .padding()
            .background(OhColor.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

        ContributionBar(factors: [], language: .english)
            .padding()
            .background(OhColor.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }
    .padding()
}

#Preview("Chinese") {
    let factors: [BudgetFactor] = [
        BudgetFactor(metric: .sleepHours, contribution: 12, weight: 0.133,
                     explanation: "睡眠 7.2小时，高于基线 6.8小时"),
        BudgetFactor(metric: .hrv, contribution: -8, weight: 0.133,
                     explanation: "HRV 45ms，低于基线 52ms"),
    ]
    ContributionBar(factors: factors, language: .chinese)
        .padding()
        .background(OhColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        .padding()
}
